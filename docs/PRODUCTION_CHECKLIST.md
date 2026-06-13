# HarfiDar — Production Deployment Checklist

## Phase A: Infrastructure (1 week before launch)
- [ ] Production server provisioned: 8 vCPU / 16 GB RAM / 200 GB SSD (or managed Kubernetes)
- [ ] Separate managed PostgreSQL instance (AWS RDS, Supabase, or self-hosted with replicas)
- [ ] Separate managed Redis instance (ElastiCache or Redis Cloud)
- [ ] CDN configured for static assets (Cloudflare or AWS CloudFront)
- [ ] Cloudinary production account created with upload presets
- [ ] Firebase project created, FCM credentials exported
- [ ] Production SMTP service configured (SendGrid, Mailgun, or SES)
- [ ] Domain `harfidar.dz` DNS configured: A records for `api.harfidar.dz`
- [ ] Wildcard SSL certificate issued for `*.harfidar.dz`
- [ ] Automated backup to S3/Backblaze configured

## Phase B: Security Hardening (3 days before launch)
- [ ] Generate all secrets with `openssl rand -hex 32`
- [ ] `JWT_SECRET` ≥ 64 chars, stored in secrets manager (not .env file)
- [ ] `JWT_REFRESH_SECRET` different from JWT_SECRET, ≥ 64 chars
- [ ] Database password unique, rotated from staging
- [ ] Redis password unique, rotated from staging
- [ ] `ADMIN_EMAIL` set to real admin address; `ADMIN_PASSWORD` changed to strong password
- [ ] SSH: password auth disabled, key-only access
- [ ] UFW firewall: only ports 22 (restrict to IP), 80, 443 open externally
- [ ] Fail2ban installed and configured for SSH and nginx
- [ ] Docker daemon configured to run as non-root where possible
- [ ] Log levels set to `warn` or `error` in production (avoid leaking request details)

## Phase C: Database
- [ ] Production database `harfidar_prod` created with dedicated user
- [ ] Connection pooling configured (PgBouncer or Prisma connection limit)
- [ ] `prisma migrate deploy` run on production schema
- [ ] Seed run ONCE: `npx ts-node prisma/seed.ts`
- [ ] Manual admin account created with secure credentials
- [ ] Automated pg_dump daily backup with 30-day retention
- [ ] Point-in-time recovery (PITR) enabled on managed DB

## Phase D: Application Deployment
- [ ] Docker image tagged with Git SHA: `docker build -t harfidar-backend:${GIT_SHA}`
- [ ] Image pushed to private registry (ECR, GHCR, or Docker Hub private)
- [ ] Zero-downtime deployment strategy confirmed (blue-green or rolling)
- [ ] `NODE_ENV=production` set — disables Swagger, enables production CORS
- [ ] All 29 environment variables set (see ENVIRONMENT_VARIABLES.md)
- [ ] `docker compose up -d` (or `kubectl apply`) with production compose file
- [ ] Health check passes: all containers `healthy` within 60s

## Phase E: API Smoke Test (production)
- [ ] `GET https://api.harfidar.dz/api/v1/specialties` → 200
- [ ] Register a staging user (will be deleted after test)
- [ ] Verify email triggers (check inbox)
- [ ] JWT tokens issued with correct `exp` values (decode with jwt.io)
- [ ] Admin dashboard accessible with admin credentials
- [ ] Swagger UI NOT accessible (`/api/docs` → 404)

## Phase F: Mobile App
- [ ] Flutter app `BASE_URL` updated to `https://api.harfidar.dz/api/v1`
- [ ] Android release APK/AAB built with `flutter build appbundle --release`
- [ ] iOS IPA built with `flutter build ipa --release`
- [ ] App tested on physical device against production API
- [ ] Google Play internal track uploaded
- [ ] Apple TestFlight build uploaded

## Phase G: Monitoring & Alerting
- [ ] UptimeRobot (or equivalent) monitoring `https://api.harfidar.dz/api/v1/specialties`
- [ ] Alert on HTTP 5xx spike
- [ ] Alert on response time > 2s
- [ ] Alert on disk usage > 80%
- [ ] Alert on memory > 85%
- [ ] Docker container restart alert
- [ ] Error log aggregation (Papertrail, Logtail, or self-hosted Loki)

## Phase H: Rollback Plan
- [ ] Previous Docker image tag recorded
- [ ] Rollback command documented: `docker compose up -d --no-deps backend` with old tag
- [ ] Database migration rollback plan reviewed (Prisma: no automatic rollback — manual SQL)
- [ ] On-call engineer identified for launch day

## Phase I: Legal & Compliance
- [ ] Privacy policy published at `/privacy`
- [ ] Terms of service published at `/terms`
- [ ] Google Play data safety form completed
- [ ] App Store privacy nutrition label completed
