# HarfiDar — Incident Recovery Procedures

## Severity Levels

| Level | Definition | Response time | Notification |
|-------|-----------|---------------|--------------|
| P1 — Critical | API down, data loss risk, security breach | 15 min | All engineers, phone call |
| P2 — High | Core feature broken (auth, listings, chat) | 1 h | On-call engineer, Slack |
| P3 — Medium | Non-critical feature broken (notifications, search filters) | 4 h | Slack |
| P4 — Low | Cosmetic issue, minor inconvenience | Next business day | Ticket |

---

## Runbook 1 — API is down (P1)

```bash
# 1. Check container status
docker compose ps

# 2. Check backend logs for crash
docker logs harfidar_backend --tail 100

# 3. Restart backend
docker compose restart backend

# 4. If still failing, check DB connectivity
docker exec harfidar_backend npx prisma db execute --stdin <<< "SELECT 1;"

# 5. Check Redis connectivity
docker exec harfidar_redis redis-cli -a "$REDIS_PASSWORD" ping

# 6. If DB down, restart postgres
docker compose restart postgres
sleep 10
docker compose restart backend

# 7. Escalate if unresolved in 15 min → rollback
docker compose down
docker compose up -d --no-deps backend  # with previous image tag
```

## Runbook 2 — Database corruption / data loss (P1)

```bash
# 1. Stop application immediately to prevent further writes
docker compose stop backend

# 2. Identify the last clean backup
ls -lth /opt/backups/postgres/

# 3. Create a snapshot of current corrupt state (for forensics)
docker exec harfidar_postgres pg_dump -U harfidar harfidar_prod \
  | gzip > /opt/backups/corrupt_state_$(date +%Y%m%d_%H%M%S).sql.gz

# 4. Drop and recreate database
docker exec harfidar_postgres psql -U harfidar \
  -c "DROP DATABASE harfidar_prod; CREATE DATABASE harfidar_prod;"

# 5. Restore from backup
gunzip -c /opt/backups/postgres/latest.sql.gz | \
  docker exec -i harfidar_postgres pg_restore \
  -U harfidar -d harfidar_prod --no-owner

# 6. Re-run any migrations applied after the backup
npx prisma migrate deploy

# 7. Restart application
docker compose start backend

# 8. Verify counts and critical data
docker exec harfidar_postgres psql -U harfidar -d harfidar_prod \
  -c "SELECT COUNT(*) FROM \"User\";"
```

## Runbook 3 — Security breach / token compromise (P1)

```bash
# 1. Immediately rotate JWT secrets
# Update .env:
JWT_SECRET=$(openssl rand -hex 64)
JWT_REFRESH_SECRET=$(openssl rand -hex 64)

# 2. Restart application (all existing tokens invalidated)
docker compose restart backend

# 3. Force-logout all users by clearing sessions
docker exec harfidar_postgres psql -U harfidar -d harfidar_prod \
  -c "DELETE FROM \"UserSession\";"

# 4. Invalidate Redis session cache
docker exec harfidar_redis redis-cli -a "$REDIS_PASSWORD" FLUSHDB

# 5. Review access logs for attacker activity
docker logs harfidar_backend --since 24h | grep -E "admin|DELETE|status.*BANNED"

# 6. Ban compromised accounts if identified
# Via admin API: PATCH /api/v1/admin/users/:id/status { "status": "BANNED" }

# 7. Notify affected users if personal data accessed
```

## Runbook 4 — High memory / CPU usage (P2)

```bash
# 1. Identify memory consumers
docker stats --no-stream

# 2. Check for Redis memory runaway
docker exec harfidar_redis redis-cli -a "$REDIS_PASSWORD" INFO memory

# 3. Flush expired keys
docker exec harfidar_redis redis-cli -a "$REDIS_PASSWORD" \
  --eval /tmp/flush_expired.lua

# 4. Check for connection pool exhaustion
docker exec harfidar_postgres psql -U harfidar -d harfidar_prod \
  -c "SELECT COUNT(*), state FROM pg_stat_activity GROUP BY state;"

# 5. Restart backend to clear memory leaks
docker compose restart backend

# 6. Scale horizontally if load continues (add second backend container behind nginx upstream)
```

## Runbook 5 — Failed deployment / bad release (P2)

```bash
# 1. Note the current (broken) image tag
BROKEN_TAG=$(docker inspect harfidar_backend --format '{{.Config.Image}}')
echo "Broken: $BROKEN_TAG"

# 2. Roll back to previous image
PREV_TAG="harfidar-backend:previous-stable"  # stored in deploy notes
docker compose stop backend
sed -i "s|$BROKEN_TAG|$PREV_TAG|g" docker-compose.yml
docker compose up -d backend

# 3. Verify rollback success
curl -s https://api.harfidar.dz/api/v1/specialties | python3 -m json.tool | head -5

# 4. Post-mortem: identify what broke the deployment
git log --oneline -10
git diff $PREV_COMMIT $BROKEN_COMMIT

# 5. Open P2 incident ticket, document timeline
```

## Runbook 6 — Cloudinary outage (P3)

Cloudinary is used for image uploads. Application degrades gracefully — existing images still served from Cloudinary CDN, new uploads fail with HTTP 503.

```bash
# 1. Monitor https://status.cloudinary.com
# 2. No action needed — uploads return 503 during outage
# 3. When restored, uploads resume automatically — no restart needed
# 4. Inform users: "Image uploads temporarily unavailable"
```

## Runbook 7 — Email service outage (P3)

Email (verification, password reset) is non-critical — application already catches email errors and returns 200 to the user.

```bash
# 1. Check SMTP provider status page
# 2. If prolonged, switch to backup SMTP:
SMTP_HOST=backup-smtp.harfidar.dz
SMTP_USER=...
SMTP_PASS=...
docker compose restart backend

# 3. Pending verification tokens last 24h — users can re-request
```

## Post-Incident Template

```markdown
## Incident Report — [DATE]

**Severity:** P[1-4]
**Duration:** HH:MM to HH:MM (X minutes total)
**Impact:** [# users affected / features down]

### Timeline
- HH:MM — Alert triggered / issue reported
- HH:MM — On-call engineer paged
- HH:MM — Root cause identified
- HH:MM — Fix deployed
- HH:MM — Incident resolved

### Root Cause
[1-2 sentences]

### Resolution
[What was done]

### Action Items
- [ ] [Preventive measure 1]
- [ ] [Preventive measure 2]
```
