# HarfiDar — Monitoring & Logging Setup Guide

## 1. Application Logging

### Current logging (built-in)

The backend uses NestJS Logger at multiple levels:

```
INFO  — Service initialization, user registration, admin actions
WARN  — SMTP failures, Firebase unavailable, invalid tokens
ERROR — Unhandled exceptions, DB errors, Prisma errors
DEBUG — SQL queries (only in development)
```

LoggingInterceptor logs every HTTP request:
```
[HTTP] GET /api/v1/craftsmen 200 45ms 192.168.1.1 Mozilla/5.0
[HTTP] POST /api/v1/auth/login 401 12ms 192.168.1.1
```

### Production log configuration

In `docker-compose.prod.yml`, configure log rotation:
```yaml
services:
  backend:
    logging:
      driver: "json-file"
      options:
        max-size: "50m"
        max-file: "10"
```

### Centralised log shipping (recommended: Loki + Grafana)

```bash
# Install Promtail to ship Docker logs to Loki
docker run -d \
  --name promtail \
  -v /var/log:/var/log \
  -v /var/lib/docker/containers:/var/lib/docker/containers:ro \
  -v /etc/promtail:/etc/promtail \
  grafana/promtail:latest \
  -config.file=/etc/promtail/config.yml
```

`/etc/promtail/config.yml`:
```yaml
clients:
  - url: http://loki:3100/loki/api/v1/push

scrape_configs:
  - job_name: harfidar-backend
    docker_sd_configs:
      - host: unix:///var/run/docker.sock
        refresh_interval: 5s
    relabel_configs:
      - source_labels: ['__meta_docker_container_name']
        regex: '/harfidar_backend'
        action: keep
```

## 2. Uptime Monitoring

### UptimeRobot (free tier — 5 min intervals)

Configure HTTP monitors for:
| URL | Expected status | Alert on |
|-----|----------------|----------|
| `https://api.harfidar.dz/api/v1/specialties` | 200 | ≥ 2 failures |
| `https://harfidar.dz` | 200 | ≥ 2 failures |

### Custom health endpoint (add to app)

```typescript
// src/modules/health/health.controller.ts
@Get('/health')
@Public()
health() {
  return { status: 'ok', timestamp: new Date().toISOString() };
}
```

## 3. Infrastructure Metrics (Prometheus + Grafana)

```yaml
# docker-compose.monitoring.yml
services:
  prometheus:
    image: prom/prometheus:v2.48.0
    volumes:
      - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml
    ports: ["9090:9090"]

  grafana:
    image: grafana/grafana:10.2.0
    ports: ["3001:3000"]
    environment:
      GF_SECURITY_ADMIN_PASSWORD: "${GRAFANA_PASSWORD}"
    volumes:
      - grafana_data:/var/lib/grafana
```

`prometheus.yml`:
```yaml
global:
  scrape_interval: 15s
scrape_configs:
  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']
  - job_name: 'postgres'
    static_configs:
      - targets: ['postgres-exporter:9187']
  - job_name: 'redis'
    static_configs:
      - targets: ['redis-exporter:9121']
```

### Key dashboards to import
- Node Exporter Full: Grafana dashboard #1860
- PostgreSQL Database: Grafana dashboard #9628
- Redis: Grafana dashboard #11835

## 4. Alerting Rules

Critical alerts (PagerDuty / Telegram bot):
```yaml
groups:
  - name: harfidar
    rules:
      - alert: BackendDown
        expr: up{job="harfidar-backend"} == 0
        for: 1m
        annotations:
          summary: "HarfiDar backend is down"

      - alert: HighErrorRate
        expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
        for: 2m
        annotations:
          summary: "Error rate > 5%"

      - alert: DatabaseConnectionFailed
        expr: pg_up == 0
        for: 30s
        annotations:
          summary: "PostgreSQL is unreachable"

      - alert: DiskSpaceLow
        expr: node_filesystem_avail_bytes / node_filesystem_size_bytes < 0.15
        for: 5m
        annotations:
          summary: "Disk space below 15%"

      - alert: HighMemoryUsage
        expr: node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes < 0.1
        for: 5m
        annotations:
          summary: "Memory usage > 90%"
```

## 5. Log Queries (Loki / Grafana)

```logql
# All 5xx errors last hour
{container="harfidar_backend"} |= "ERROR" | json

# Failed login attempts
{container="harfidar_backend"} |= "Invalid credentials"

# Slow requests (> 1000ms)
{container="harfidar_backend"} |~ "[0-9]{4,}ms"

# Prisma errors
{container="harfidar_backend"} |= "PrismaClientKnownRequestError"
```

## 6. Error Tracking (Sentry — recommended)

```bash
npm install @sentry/node @sentry/nestjs
```

```typescript
// main.ts
import * as Sentry from '@sentry/node';
Sentry.init({ dsn: process.env.SENTRY_DSN, environment: process.env.NODE_ENV });
```

Set `SENTRY_DSN` environment variable.
