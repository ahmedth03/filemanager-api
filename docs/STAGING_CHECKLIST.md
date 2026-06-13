# HarfiDar — Staging Deployment Checklist

A step-by-step pre-flight checklist before every staging deployment.

## 1. Infrastructure Prerequisites
- [ ] Ubuntu 22.04 LTS server with min 4 vCPU / 8 GB RAM / 80 GB SSD
- [ ] Docker 24+ and Docker Compose v2 installed
- [ ] Ports 80, 443, 3000, 5432, 6379 accessible internally; only 80/443 externally
- [ ] SSH access with sudo, non-root deploy user created
- [ ] DNS A-record for `api.staging.harfidar.dz` pointing to server IP
- [ ] SSL certificate issued via Let's Encrypt (certbot) or uploaded

## 2. Repository & Code
- [ ] Branch `main` (or release tag) is green on CI
- [ ] All 293 unit tests pass (`npm test`)
- [ ] TypeScript compiles clean (`npx tsc --noEmit` exits 0)
- [ ] No `.env` or secret files committed to git
- [ ] Docker image builds locally: `docker build -t harfidar-backend ./backend`

## 3. Environment Variables
- [ ] Copy `.env.example` → `.env` on server
- [ ] Set `NODE_ENV=production`
- [ ] Set strong `JWT_SECRET` (≥32 random chars, not the fallback)
- [ ] Set strong `JWT_REFRESH_SECRET` (≥32 random chars, different from JWT_SECRET)
- [ ] Set `DATABASE_URL` with staging PostgreSQL credentials
- [ ] Set `REDIS_HOST`, `REDIS_PORT`, `REDIS_PASSWORD`
- [ ] Set `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET`
- [ ] Set `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASS`
- [ ] Set `FRONTEND_URL` = `https://staging.harfidar.dz` (or test app URL)
- [ ] Set `APP_URL` = `https://api.staging.harfidar.dz`
- [ ] Set `ADMIN_EMAIL` and `ADMIN_PASSWORD` (change from defaults)

## 4. Database
- [ ] PostgreSQL 16 running and accessible
- [ ] Database `harfidar_staging` created
- [ ] Run migrations: `npx prisma migrate deploy`
- [ ] Run seed: `npx ts-node prisma/seed.ts` (58 wilayas, 25 specialties, admin user)
- [ ] Verify seed: connect to DB and count rows in `Wilaya`, `Specialty`, `User`
- [ ] Enable automated daily backups (pg_dump cron job)

## 5. Redis
- [ ] Redis 7 running with password authentication
- [ ] AOF persistence enabled (`appendonly yes`)
- [ ] Test connectivity: `redis-cli -a $REDIS_PASSWORD ping` → PONG

## 6. Docker Compose
- [ ] `docker compose config` validates without errors
- [ ] `docker compose up -d` starts all 3 services (postgres, redis, backend)
- [ ] All containers healthy: `docker compose ps` shows `healthy`
- [ ] Backend logs show: `🚀 HarfiDar API running on: ...`

## 7. API Health Checks
- [ ] `GET /api/v1/specialties` → 200 with 25 specialties
- [ ] `POST /api/v1/auth/register` → 201
- [ ] `POST /api/v1/auth/login` → 200 with tokens
- [ ] `GET /api/v1/craftsmen` → 200 (public)
- [ ] `GET /api/v1/listings` → 200 (public)
- [ ] `GET /api/v1/admin/dashboard` (with admin token) → 200

## 8. Security Checks
- [ ] Swagger UI disabled: `GET /api/docs` → 404 in production
- [ ] CORS rejects requests from non-whitelisted origins
- [ ] Rate limiting active: 6 rapid requests in 1s → 429
- [ ] JWT fallback secrets NOT in use (check logs for warnings)
- [ ] HTTPS enforced (HTTP → HTTPS redirect via nginx)
- [ ] Security headers present: check `curl -I https://api.staging.harfidar.dz/api/v1/specialties`

## 9. Reverse Proxy (nginx)
- [ ] nginx installed and configured
- [ ] SSL termination at nginx, proxy_pass to `localhost:3000`
- [ ] WebSocket upgrade headers configured (`Upgrade`, `Connection`)
- [ ] Gzip compression enabled
- [ ] Request body limit set (e.g., `client_max_body_size 20M`)

## 10. Smoke Test
- [ ] Register a test user end-to-end
- [ ] Verify email link works
- [ ] Create a craftsman profile
- [ ] Create a property listing
- [ ] Run chat flow (create room, send message)
- [ ] Test admin login and dashboard
- [ ] Confirm no 500 errors in backend logs: `docker logs harfidar_backend --tail 100`

## 11. Monitoring
- [ ] Log rotation configured (Docker `json-file` driver with max-size)
- [ ] Disk space > 20 GB free
- [ ] Alert on container restart (Docker healthcheck + uptime monitor)
