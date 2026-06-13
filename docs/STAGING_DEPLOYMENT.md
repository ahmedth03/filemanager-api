# HarfiDar — Staging Deployment Guide

## Architecture

```
Internet → Nginx (443/80) → Backend API (3000) → PostgreSQL (5432)
                                              → Redis (6379)
                                              → Cloudinary (CDN)
                                              → Firebase (FCM)
```

---

## Server Requirements

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| CPU | 2 vCPU | 4 vCPU |
| RAM | 2 GB | 4 GB |
| Disk | 20 GB SSD | 50 GB SSD |
| OS | Ubuntu 22.04 LTS | Ubuntu 22.04 LTS |
| Docker | 24+ | 24+ |

---

## 1. Server Preparation

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
newgrp docker

# Install Docker Compose plugin
sudo apt install docker-compose-plugin -y

# Create app directory
sudo mkdir -p /opt/harfidar
sudo chown $USER:$USER /opt/harfidar
cd /opt/harfidar
```

---

## 2. Clone Repository

```bash
git clone <repo-url> .
```

---

## 3. Configure Production Environment

```bash
cp backend/.env.example backend/.env
nano backend/.env
```

**Required values for production** (see ENVIRONMENT_VARIABLES.md for full reference):

```env
NODE_ENV=production
DATABASE_URL=postgresql://harfidar:<strong-password>@postgres:5432/harfidar_db
JWT_SECRET=<64-char random string>
JWT_REFRESH_SECRET=<64-char different random string>
CLOUDINARY_CLOUD_NAME=<your-cloud>
CLOUDINARY_API_KEY=<your-key>
CLOUDINARY_API_SECRET=<your-secret>
SMTP_HOST=<your-smtp>
SMTP_USER=<your-email>
SMTP_PASS=<app-password>
```

Generate strong secrets:
```bash
openssl rand -hex 32   # for JWT_SECRET
openssl rand -hex 32   # for JWT_REFRESH_SECRET
```

---

## 4. Build & Start All Services

```bash
# Production stack (backend + postgres + redis + nginx)
docker compose -f docker-compose.prod.yml up -d --build

# Verify all containers are running
docker compose -f docker-compose.prod.yml ps
```

Expected output:
```
NAME                 STATUS         PORTS
harfidar_postgres    healthy        
harfidar_redis       healthy        
harfidar_backend     Up             3000/tcp
harfidar_nginx       Up             0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp
```

---

## 5. Database Setup

```bash
# Run Prisma migrations
docker compose -f docker-compose.prod.yml exec backend \
  npx prisma migrate deploy

# Seed wilayas + specialties
docker compose -f docker-compose.prod.yml exec backend \
  npx ts-node prisma/seed.ts
```

---

## 6. Create Admin Account

```bash
docker compose -f docker-compose.prod.yml exec backend \
  npx ts-node -e "
    const { PrismaClient } = require('@prisma/client');
    const bcrypt = require('bcryptjs');
    const prisma = new PrismaClient();
    async function main() {
      const hash = await bcrypt.hash('YourAdminPassword123!', 12);
      await prisma.user.upsert({
        where: { email: 'admin@harfidar.dz' },
        update: { role: 'ADMIN', status: 'ACTIVE' },
        create: {
          email: 'admin@harfidar.dz',
          firstName: 'مدير',
          lastName: 'النظام',
          passwordHash: hash,
          role: 'ADMIN',
          status: 'ACTIVE',
          isEmailVerified: true,
        },
      });
      console.log('Admin created');
      await prisma.\$disconnect();
    }
    main();
  "
```

---

## 7. SSL / HTTPS (Let's Encrypt)

```bash
# Install certbot
sudo apt install certbot -y

# Obtain certificate (stop nginx first to free port 80)
docker compose -f docker-compose.prod.yml stop nginx
sudo certbot certonly --standalone -d api.harfidar.dz

# Update nginx/nginx.conf to reference cert paths, then restart
docker compose -f docker-compose.prod.yml up nginx -d
```

---

## 8. Smoke Tests

```bash
# Health check
curl https://api.harfidar.dz/api/v1/specialties

# Auth
curl -X POST https://api.harfidar.dz/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@harfidar.dz","password":"YourAdminPassword123!"}'

# WebSocket (Socket.IO)
wscat -c "wss://api.harfidar.dz/chat"
```

---

## 9. Monitoring & Logs

```bash
# Follow all logs
docker compose -f docker-compose.prod.yml logs -f

# Backend logs only
docker compose -f docker-compose.prod.yml logs -f backend

# Check resource usage
docker stats

# Postgres shell
docker compose -f docker-compose.prod.yml exec postgres \
  psql -U harfidar -d harfidar_db
```

---

## 10. Deployment Updates (Zero-Downtime)

```bash
git pull origin main

# Rebuild & restart backend only (DB persists in named volume)
docker compose -f docker-compose.prod.yml up -d --build backend

# Run any new migrations
docker compose -f docker-compose.prod.yml exec backend \
  npx prisma migrate deploy
```

---

## Rollback

```bash
git checkout <previous-tag>
docker compose -f docker-compose.prod.yml up -d --build backend
```

---

## GitHub Actions CD

The included `.github/workflows/cd.yml` automates deployment on push to `main`:
1. Runs tests
2. Builds Docker image
3. SSHes to server and runs `docker compose up -d --build`

Configure these GitHub Secrets:
```
SSH_HOST         — staging server IP
SSH_USER         — deploy user
SSH_PRIVATE_KEY  — SSH key for deploy user
```
