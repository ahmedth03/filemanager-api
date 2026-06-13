# HarfiDar — Local Development Setup

## Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| Node.js | 20 LTS | https://nodejs.org |
| Docker + Docker Compose | 24+ | https://docker.com |
| Flutter SDK | 3.16+ | https://flutter.dev/docs/get-started/install |
| Git | any | https://git-scm.com |

---

## 1. Clone & Navigate

```bash
git clone <repo-url> harfidar
cd harfidar
```

---

## 2. Start Infrastructure (PostgreSQL + Redis)

```bash
docker compose up postgres redis -d
```

Wait ~10 s for the healthchecks to pass.

---

## 3. Backend Setup

```bash
cd backend

# Install dependencies (includes nodemailer, firebase-admin, supertest)
npm install

# Copy environment file
cp .env.example .env
# Edit .env — at minimum set JWT secrets and Cloudinary credentials.
# All other values work as-is for local dev.

# Generate Prisma client
npx prisma generate

# Run migrations against local Postgres
npx prisma migrate deploy

# (Optional) Seed wilayas + specialties
npx ts-node prisma/seed.ts

# Start development server (hot-reload)
npm run start:dev
```

API is now available at `http://localhost:3000/api/v1`
Swagger UI: `http://localhost:3000/api/docs`

---

## 4. Flutter App Setup

```bash
cd ../frontend

# Install Flutter dependencies
flutter pub get

# Copy & configure API base URL
# Edit lib/core/config/api_config.dart
# Set baseUrl = 'http://10.0.2.2:3000/api/v1'  ← Android emulator
# Set baseUrl = 'http://localhost:3000/api/v1'   ← iOS simulator / web

# Run on device/emulator
flutter run
```

---

## 5. Run Tests

```bash
# Backend unit tests (293 tests, 11 suites)
cd backend && npm test

# Backend test coverage
npm run test:cov

# Backend E2E tests (requires running Postgres + Redis)
npm run test:e2e

# Flutter tests
cd frontend && flutter test
```

---

## 6. Useful Make Commands

```bash
make dev          # Start all services
make test         # Run backend tests
make migrate      # Run Prisma migrations
make seed         # Seed database
make logs         # Follow backend logs
make stop         # Stop all containers
```

---

## Environment Variables (minimum for local dev)

```env
DATABASE_URL=postgresql://harfidar:harfidar_pass@localhost:5432/harfidar_db
REDIS_HOST=localhost
REDIS_PORT=6379
JWT_SECRET=any-long-random-string
JWT_REFRESH_SECRET=any-other-long-random-string
NODE_ENV=development
```

The following are optional for local dev (gracefully degrade if absent):
- `SMTP_*` — emails print to console
- `CLOUDINARY_*` — image uploads fail with 500
- `FIREBASE_*` — push notifications silently skipped

---

## Create Admin Account

After seeding, create an admin via the API or directly in Postgres:

```bash
# Via psql (replace hash with bcrypt of your password)
docker compose exec postgres psql -U harfidar -d harfidar_db -c "
  UPDATE users SET role = 'ADMIN', status = 'ACTIVE'
  WHERE email = 'admin@harfidar.dz';
"
```

Or use the seed script — it creates `admin@harfidar.dz / Admin@123456` automatically if `ADMIN_EMAIL`/`ADMIN_PASSWORD` are set in `.env`.

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `Cannot connect to database` | Run `docker compose up postgres -d` and wait for healthcheck |
| `Prisma: Schema validation error` | Run `npx prisma generate` after any schema change |
| `redis ECONNREFUSED` | Run `docker compose up redis -d` |
| `nodemailer: Invalid login` | Emails are fire-and-forget; check SMTP credentials or ignore in dev |
| Flutter `SocketException` on Android emulator | Use `10.0.2.2` instead of `localhost` in `api_config.dart` |
