# HarfiDar — Database Backup & Restore Procedures

## Backup Strategy

| Type | Frequency | Retention | Method |
|------|-----------|-----------|--------|
| Full dump | Daily at 02:00 | 30 days | pg_dump |
| WAL/PITR | Continuous | 7 days | pg_basebackup or managed DB |
| Redis snapshot | Hourly | 24 h | Redis BGSAVE |
| Redis AOF | On write | 7 days | appendonly.aof |

## 1. PostgreSQL Backup

### Daily cron backup script
```bash
#!/bin/bash
# /opt/scripts/backup-db.sh
set -euo pipefail

DB_NAME="harfidar_prod"
DB_USER="harfidar"
BACKUP_DIR="/opt/backups/postgres"
DATE=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_${DATE}.sql.gz"
S3_BUCKET="s3://harfidar-backups/postgres/"

mkdir -p "$BACKUP_DIR"

PGPASSWORD="$DB_PASSWORD" pg_dump \
  -h "$DB_HOST" \
  -U "$DB_USER" \
  -d "$DB_NAME" \
  --no-owner \
  --no-acl \
  -Fc \
  | gzip > "$BACKUP_FILE"

echo "Backup created: $BACKUP_FILE ($(du -sh $BACKUP_FILE | cut -f1))"

# Upload to S3/Backblaze
aws s3 cp "$BACKUP_FILE" "$S3_BUCKET" --storage-class STANDARD_IA

# Delete local backups older than 7 days
find "$BACKUP_DIR" -name "*.sql.gz" -mtime +7 -delete

echo "Backup complete: $DATE"
```

### Install cron job
```bash
chmod +x /opt/scripts/backup-db.sh
echo "0 2 * * * root /opt/scripts/backup-db.sh >> /var/log/db-backup.log 2>&1" \
  > /etc/cron.d/harfidar-db-backup
```

### Docker Compose backup (local dev / staging)
```bash
docker exec harfidar_postgres pg_dump \
  -U harfidar harfidar_prod \
  --no-owner -Fc \
  | gzip > backup_$(date +%Y%m%d).sql.gz
```

## 2. PostgreSQL Restore

### Full restore from dump
```bash
# Stop application first
docker compose stop backend

# Restore
gunzip -c backup_YYYYMMDD.sql.gz | \
  PGPASSWORD="$DB_PASSWORD" pg_restore \
  -h "$DB_HOST" \
  -U "$DB_USER" \
  -d "$DB_NAME" \
  --no-owner \
  --no-acl \
  -c     # drop existing objects before restore

# Restart application
docker compose start backend
```

### Docker Compose restore
```bash
docker exec -i harfidar_postgres psql -U harfidar -c "DROP DATABASE IF EXISTS harfidar_prod;"
docker exec -i harfidar_postgres psql -U harfidar -c "CREATE DATABASE harfidar_prod;"
gunzip -c backup.sql.gz | docker exec -i harfidar_postgres pg_restore \
  -U harfidar -d harfidar_prod --no-owner -c
```

### Verify restore
```sql
-- Check row counts match pre-backup snapshot
SELECT schemaname, tablename, n_live_tup
FROM pg_stat_user_tables
ORDER BY n_live_tup DESC;
```

## 3. Redis Backup

### Manual snapshot
```bash
docker exec harfidar_redis redis-cli -a "$REDIS_PASSWORD" BGSAVE
# Wait for completion:
docker exec harfidar_redis redis-cli -a "$REDIS_PASSWORD" LASTSAVE
```

### Copy RDB file
```bash
docker cp harfidar_redis:/data/dump.rdb ./redis_backup_$(date +%Y%m%d).rdb
```

### Copy AOF file
```bash
docker cp harfidar_redis:/data/appendonly.aof ./redis_aof_$(date +%Y%m%d).aof
```

## 4. Redis Restore

```bash
# Stop Redis, copy backup file, restart
docker compose stop redis
docker cp ./redis_backup.rdb harfidar_redis:/data/dump.rdb
docker compose start redis
# Verify:
docker exec harfidar_redis redis-cli -a "$REDIS_PASSWORD" DBSIZE
```

## 5. Prisma Migration Rollback

Prisma does NOT support automatic rollback. For each migration, maintain a manual rollback SQL file.

```bash
# List applied migrations
npx prisma migrate status

# Apply a manual rollback (create rollback SQL manually)
psql -U harfidar -d harfidar_prod -f migrations/rollback/YYYYMMDD_rollback.sql

# Delete the migration record from _prisma_migrations
DELETE FROM _prisma_migrations WHERE migration_name = '20240601000000_init';
```

## 6. Backup Verification (Monthly)

```bash
# 1. Restore backup to a test database
createdb harfidar_restore_test
gunzip -c latest_backup.sql.gz | pg_restore -d harfidar_restore_test --no-owner

# 2. Verify critical tables
psql -d harfidar_restore_test -c "
  SELECT
    (SELECT COUNT(*) FROM \"User\") AS users,
    (SELECT COUNT(*) FROM \"PropertyListing\") AS listings,
    (SELECT COUNT(*) FROM \"Craftsman\") AS craftsmen;
"

# 3. Clean up
dropdb harfidar_restore_test
```

## 7. RTO / RPO Targets

| Scenario | RPO (data loss) | RTO (downtime) |
|----------|-----------------|----------------|
| Server failure | < 24h (daily backup) | < 2h |
| Data corruption | < 1h (with PITR) | < 1h |
| Accidental delete | < 24h | < 30 min |
| Full site loss | < 24h | < 4h |
