# HarfiDar — Production Environment Variables

All variables required to run the backend in production. Variables marked **REQUIRED** have no safe fallback and will cause startup failure or a security vulnerability if omitted.

---

## Application

| Variable | Required | Default | Example | Notes |
|----------|----------|---------|---------|-------|
| `NODE_ENV` | REQUIRED | `development` | `production` | Disables Swagger UI when `production` |
| `PORT` | Optional | `3000` | `3000` | Port the NestJS server listens on |
| `APP_URL` | Optional | `http://localhost:3000` | `https://api.harfidar.dz` | Used in emails and links |
| `FRONTEND_URL` | Optional | `http://localhost:8080` | `https://harfidar.dz` | CORS whitelist; also allows `*.harfidar.dz` |

---

## Database (PostgreSQL 16)

| Variable | Required | Default | Example | Notes |
|----------|----------|---------|---------|-------|
| `DATABASE_URL` | REQUIRED | — | `postgresql://harfidar:PASS@db.harfidar.dz:5432/harfidar_prod?schema=public` | Full Prisma connection string |

Connection string format:
```
postgresql://USER:PASSWORD@HOST:PORT/DATABASE?schema=public
```

For PgBouncer (transaction mode), append `?pgbouncer=true&connection_limit=5`.

---

## Redis 7

| Variable | Required | Default | Example | Notes |
|----------|----------|---------|---------|-------|
| `REDIS_HOST` | Optional | `localhost` | `redis.harfidar.dz` | Redis server hostname |
| `REDIS_PORT` | Optional | `6379` | `6379` | Redis port |
| `REDIS_PASSWORD` | Optional | — | `strong-redis-pass` | Required if Redis has AUTH enabled (always in production) |

---

## JWT Secrets

| Variable | Required | Default | Example | Notes |
|----------|----------|---------|---------|-------|
| `JWT_SECRET` | **REQUIRED** | `fallback-secret` ⚠️ | *(64 random chars)* | Access token signing secret — MUST change from default |
| `JWT_EXPIRES_IN` | Optional | `15m` | `15m` | Access token lifetime |
| `JWT_REFRESH_SECRET` | **REQUIRED** | `fallback-refresh-secret` ⚠️ | *(64 random chars)* | Refresh token signing secret — must differ from JWT_SECRET |
| `JWT_REFRESH_EXPIRES_IN` | Optional | `7d` | `7d` | Refresh token lifetime |

Generate secrets:
```bash
openssl rand -hex 64   # for JWT_SECRET
openssl rand -hex 64   # for JWT_REFRESH_SECRET (run again — must be different)
```

---

## Cloudinary (Image Storage)

| Variable | Required | Default | Example | Notes |
|----------|----------|---------|---------|-------|
| `CLOUDINARY_CLOUD_NAME` | REQUIRED for uploads | — | `harfidar-prod` | Without this, image endpoints return 500 |
| `CLOUDINARY_API_KEY` | REQUIRED for uploads | — | `123456789012345` | From Cloudinary dashboard |
| `CLOUDINARY_API_SECRET` | REQUIRED for uploads | — | `abcdefghij1234567890` | Never expose in client code |

Without Cloudinary credentials these endpoints fail:
`POST /craftsmen/portfolio`, `POST /listings/:id/images`, `POST /upload/single`, `POST /upload/multiple`

---

## Email (SMTP / NodeMailer)

| Variable | Required | Default | Example | Notes |
|----------|----------|---------|---------|-------|
| `SMTP_HOST` | Optional | `smtp.gmail.com` | `smtp.sendgrid.net` | SMTP server |
| `SMTP_PORT` | Optional | `587` | `587` | 587 = STARTTLS, 465 = TLS |
| `SMTP_USER` | Optional | — | `apikey` | SMTP username; for SendGrid use literal `apikey` |
| `SMTP_PASS` | Optional | — | `SG.xxxxxxx` | SMTP password / API key |
| `SMTP_FROM` | Optional | `HarfiDar <noreply@harfidar.dz>` | `HarfiDar <noreply@harfidar.dz>` | From address for all emails |

Without SMTP credentials, email sending fails silently. Users can register but will not receive verification/reset emails.

**Recommended provider:** SendGrid (reliable delivery to .dz domains) or AWS SES.

---

## Firebase / FCM (Push Notifications)

Option A — Inline service account credentials:

| Variable | Required | Default | Example | Notes |
|----------|----------|---------|---------|-------|
| `FIREBASE_PROJECT_ID` | Optional | — | `harfidar-prod` | Firebase project ID |
| `FIREBASE_CLIENT_EMAIL` | Optional | — | `firebase-adminsdk-xxx@harfidar-prod.iam.gserviceaccount.com` | Service account email |
| `FIREBASE_PRIVATE_KEY` | Optional | — | `-----BEGIN RSA PRIVATE KEY-----\n...` | Newlines escaped as `\n` |

Option B — Service account JSON file path:

| Variable | Required | Default | Example | Notes |
|----------|----------|---------|---------|-------|
| `FIREBASE_SERVICE_ACCOUNT_PATH` | Optional | — | `/secrets/firebase-service-account.json` | Path to service account JSON file |

Without Firebase credentials, push notifications are silently skipped.

---

## Rate Limiting

| Variable | Required | Default | Example | Notes |
|----------|----------|---------|---------|-------|
| `THROTTLE_TTL` | Optional | `60` | `60` | Base throttle window in seconds |
| `THROTTLE_LIMIT` | Optional | `100` | `100` | Base request limit per window |

Fixed tiers (hardcoded, not overridden by env):
- Short: 10 req / 1000 ms
- Medium: 50 req / 10 000 ms
- Long: 200 req / 60 000 ms

---

## Admin Defaults (Seed Only)

| Variable | Required | Default | Example | Notes |
|----------|----------|---------|---------|-------|
| `ADMIN_EMAIL` | Optional | `admin@harfidar.dz` | `admin@harfidar.dz` | Admin account created by seed |
| `ADMIN_PASSWORD` | Optional | `Admin@123456` ⚠️ | *(strong password)* | **MUST change from default before launch** |

These are only used during `npx ts-node prisma/seed.ts`. Change the admin password after first login.

---

## Complete Production `.env` Template

```bash
# ── Application ──────────────────────────────────────────────
NODE_ENV=production
PORT=3000
APP_URL=https://api.harfidar.dz
FRONTEND_URL=https://harfidar.dz

# ── Database ──────────────────────────────────────────────────
DATABASE_URL=postgresql://harfidar:CHANGEME@db.harfidar.dz:5432/harfidar_prod?schema=public

# ── Redis ─────────────────────────────────────────────────────
REDIS_HOST=redis.harfidar.dz
REDIS_PORT=6379
REDIS_PASSWORD=CHANGEME

# ── JWT ───────────────────────────────────────────────────────
JWT_SECRET=GENERATE_WITH_openssl_rand_hex_64
JWT_EXPIRES_IN=15m
JWT_REFRESH_SECRET=GENERATE_WITH_openssl_rand_hex_64_DIFFERENT_VALUE
JWT_REFRESH_EXPIRES_IN=7d

# ── Cloudinary ────────────────────────────────────────────────
CLOUDINARY_CLOUD_NAME=harfidar-prod
CLOUDINARY_API_KEY=YOUR_API_KEY
CLOUDINARY_API_SECRET=YOUR_API_SECRET

# ── Email ─────────────────────────────────────────────────────
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USER=apikey
SMTP_PASS=SG.YOUR_SENDGRID_KEY
SMTP_FROM=HarfiDar <noreply@harfidar.dz>

# ── Firebase FCM ──────────────────────────────────────────────
FIREBASE_PROJECT_ID=harfidar-prod
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxx@harfidar-prod.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN RSA PRIVATE KEY-----\nMIIE...\n-----END RSA PRIVATE KEY-----\n"

# ── Admin defaults (seed only) ────────────────────────────────
ADMIN_EMAIL=admin@harfidar.dz
ADMIN_PASSWORD=CHANGEME_STRONG_PASSWORD
```

---

## Variable Count Summary

| Category | Count | Hard Required |
|----------|-------|---------------|
| Application | 4 | NODE_ENV |
| Database | 1 | Yes |
| Redis | 3 | Password in prod |
| JWT | 4 | Both secrets |
| Cloudinary | 3 | For image uploads |
| Email / SMTP | 5 | Optional |
| Firebase / FCM | 3–4 | Optional |
| Rate limiting | 2 | Optional |
| Admin defaults | 2 | Optional (seed) |
| **Total** | **27–28** | **7 hard required** |

---

## Security Checklist

- [ ] `JWT_SECRET` ≠ `fallback-secret` and ≠ `JWT_REFRESH_SECRET`
- [ ] Both JWT secrets ≥ 64 characters
- [ ] `REDIS_PASSWORD` set and not empty
- [ ] `ADMIN_PASSWORD` changed from default
- [ ] `.env` file owned by deploy user, permissions `chmod 600 .env`
- [ ] `.env` never committed to git (covered by `.gitignore`)
- [ ] All secrets rotated from staging values
- [ ] Firebase private key newlines escaped as `\n` in `.env`
