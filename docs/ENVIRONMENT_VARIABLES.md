# HarfiDar — Environment Variables Reference

All variables are set in `backend/.env`. Copy from `backend/.env.example`.

---

## Required Variables

### Database

| Variable | Example | Description |
|----------|---------|-------------|
| `DATABASE_URL` | `postgresql://harfidar:pass@postgres:5432/harfidar_db` | Full Prisma connection string |

### JWT Security

| Variable | Example | Description |
|----------|---------|-------------|
| `JWT_SECRET` | `<64 random chars>` | Access token signing secret — **never reuse across environments** |
| `JWT_EXPIRES_IN` | `15m` | Access token TTL |
| `JWT_REFRESH_SECRET` | `<64 different random chars>` | Refresh token signing secret |
| `JWT_REFRESH_EXPIRES_IN` | `7d` | Refresh token TTL |

Generate secrets:
```bash
openssl rand -hex 32
```

### Application

| Variable | Example | Description |
|----------|---------|-------------|
| `PORT` | `3000` | HTTP listen port |
| `NODE_ENV` | `production` | `development` / `production` |
| `APP_URL` | `https://api.harfidar.dz` | Public API base URL (used in Swagger, emails) |
| `FRONTEND_URL` | `https://harfidar.dz` | Allowed CORS origin |

---

## Redis

| Variable | Default | Description |
|----------|---------|-------------|
| `REDIS_HOST` | `redis` | Redis hostname |
| `REDIS_PORT` | `6379` | Redis port |
| `REDIS_PASSWORD` | _(empty)_ | Redis AUTH password — set in production |

---

## Cloudinary (Image CDN) — Required for image uploads

Get credentials at https://cloudinary.com/console

| Variable | Description |
|----------|-------------|
| `CLOUDINARY_CLOUD_NAME` | Cloud name from Cloudinary dashboard |
| `CLOUDINARY_API_KEY` | API key |
| `CLOUDINARY_API_SECRET` | API secret |

Without Cloudinary: image upload endpoints return 500. Auth, chat, and all other features work normally.

---

## Email / SMTP — Optional but recommended

Used for: email verification, password reset, welcome email.

| Variable | Example | Description |
|----------|---------|-------------|
| `SMTP_HOST` | `smtp.gmail.com` | SMTP server hostname |
| `SMTP_PORT` | `587` | SMTP port (587=STARTTLS, 465=SSL) |
| `SMTP_USER` | `noreply@harfidar.dz` | SMTP username |
| `SMTP_PASS` | `app-specific-password` | SMTP password / app password |
| `SMTP_FROM` | `HarfiDar <noreply@harfidar.dz>` | From address |

**Gmail setup**: Enable 2FA → generate App Password at https://myaccount.google.com/apppasswords

Without SMTP: email verification links are skipped; users can still register (status starts as PENDING).

---

## Firebase Cloud Messaging — Optional

Used for push notifications to Flutter app.

**Option A: Individual env vars** (recommended for containers)

| Variable | Where to find |
|----------|--------------|
| `FIREBASE_PROJECT_ID` | Firebase Console → Project Settings → General |
| `FIREBASE_CLIENT_EMAIL` | Firebase Console → Service Accounts → Generate Key |
| `FIREBASE_PRIVATE_KEY` | Same JSON file — the `private_key` field |

> The `FIREBASE_PRIVATE_KEY` must include literal `\n` characters:
> ```env
> FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nMIIE...\n-----END PRIVATE KEY-----\n"
> ```

**Option B: Service account JSON file**

| Variable | Example |
|----------|---------|
| `FIREBASE_SERVICE_ACCOUNT_PATH` | `/app/firebase-service-account.json` |

Without Firebase: push notifications are silently skipped. In-app notifications still work.

---

## Rate Limiting

| Variable | Default | Description |
|----------|---------|-------------|
| `THROTTLE_TTL` | `60` | Window in seconds |
| `THROTTLE_LIMIT` | `100` | Max requests per window per IP |

The backend also has fixed throttle tiers (short/medium/long) configured in code.

---

## Admin Account Bootstrap

| Variable | Default | Description |
|----------|---------|-------------|
| `ADMIN_EMAIL` | `admin@harfidar.dz` | Initial admin email (used by seed script) |
| `ADMIN_PASSWORD` | `Admin@123456` | Initial admin password — **change in production** |

---

## Docker Compose Extra Variables

These affect `docker-compose.yml` and `docker-compose.prod.yml` but do NOT go in `backend/.env`:

| Variable | Default | Description |
|----------|---------|-------------|
| `POSTGRES_USER` | `harfidar` | Postgres superuser |
| `POSTGRES_PASSWORD` | `harfidar_secret` | Postgres password |
| `POSTGRES_DB` | `harfidar_db` | Database name |
| `REDIS_PASSWORD` | `redis_secret` | Redis password |
| `PGADMIN_EMAIL` | `admin@harfidar.dz` | pgAdmin login |
| `PGADMIN_PASSWORD` | `admin123` | pgAdmin password |
| `APP_PORT` | `3000` | Host port mapped to backend |
| `POSTGRES_PORT` | `5432` | Host port mapped to Postgres |

Set these in a root-level `.env` file:
```bash
cp .env.example .env   # if one exists at root
```

---

## Security Checklist for Production

- [ ] `JWT_SECRET` and `JWT_REFRESH_SECRET` are unique, random, ≥32 chars
- [ ] `POSTGRES_PASSWORD` and `REDIS_PASSWORD` are strong (not defaults)
- [ ] `NODE_ENV=production` is set
- [ ] `ADMIN_PASSWORD` has been changed after first login
- [ ] Cloudinary credentials are production project credentials (not test)
- [ ] Firebase private key is stored securely (not in git)
- [ ] SMTP credentials use an app-specific password, not your account password
- [ ] `backend/.env` is in `.gitignore` (it is)
