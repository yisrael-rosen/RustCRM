# 🚀 Production Deployment Guide

## 📋 Overview

Complete guide for deploying RustCRM to production.

---

## 🎯 Prerequisites

- Linux server (Ubuntu 22.04 recommended)
- Domain name with DNS configured
- SSL certificate (Let's Encrypt)
- Docker & Docker Compose installed

---

## 🔧 Production Setup

### 1. Server Preparation

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Install Nginx
sudo apt install nginx -y

# Install Certbot for SSL
sudo apt install certbot python3-certbot-nginx -y
```

### 2. Clone Repository

```bash
cd /opt
sudo git clone https://github.com/yourorg/RustCRM.git
cd RustCRM
```

### 3. Environment Configuration

Create production `.env`:

```bash
# Backend .env
DATABASE_URL=postgresql://rustcrm:STRONG_PASSWORD@postgres:5432/rustcrm
REDIS_URL=redis://redis:6379
JWT_SECRET=GENERATE_STRONG_SECRET_HERE
PORT=8000
HOST=0.0.0.0
RUST_LOG=info

# Frontend .env
VITE_API_URL=https://api.yourcompany.com/api/v1
```

**Generate strong secrets**:
```bash
# Generate JWT secret
openssl rand -base64 64

# Generate database password
openssl rand -base64 32
```

---

## 🐳 Docker Setup

### Production docker-compose.yml

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    container_name: rustcrm_postgres
    restart: unless-stopped
    environment:
      POSTGRES_USER: rustcrm
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: rustcrm
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./backups:/backups
    networks:
      - rustcrm_network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U rustcrm"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    container_name: rustcrm_redis
    restart: unless-stopped
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data
    networks:
      - rustcrm_network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile.prod
    container_name: rustcrm_backend
    restart: unless-stopped
    env_file:
      - ./backend/.env.production
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    networks:
      - rustcrm_network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile.prod
    container_name: rustcrm_frontend
    restart: unless-stopped
    depends_on:
      - backend
    networks:
      - rustcrm_network

  nginx:
    image: nginx:alpine
    container_name: rustcrm_nginx
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/ssl:/etc/nginx/ssl:ro
      - /var/log/nginx:/var/log/nginx
    depends_on:
      - backend
      - frontend
    networks:
      - rustcrm_network

volumes:
  postgres_data:
  redis_data:

networks:
  rustcrm_network:
    driver: bridge
```

### Backend Dockerfile

`backend/Dockerfile.prod`:
```dockerfile
# Build stage
FROM rust:1.75 as builder

WORKDIR /app

# Copy manifests
COPY Cargo.toml Cargo.lock ./

# Copy source
COPY src ./src
COPY migrations ./migrations

# Build for release
RUN cargo build --release

# Runtime stage
FROM debian:bookworm-slim

# Install required libraries
RUN apt-get update && \
    apt-get install -y libssl3 ca-certificates && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy binary from builder
COPY --from=builder /app/target/release/backend /app/backend
COPY --from=builder /app/migrations /app/migrations

# Create non-root user
RUN useradd -m -u 1001 rustcrm && \
    chown -R rustcrm:rustcrm /app

USER rustcrm

EXPOSE 8000

CMD ["/app/backend"]
```

### Frontend Dockerfile

`frontend/Dockerfile.prod`:
```dockerfile
# Build stage
FROM node:20-alpine as builder

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

# Runtime stage
FROM nginx:alpine

COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```

---

## 🌐 Nginx Configuration

`nginx/nginx.conf`:
```nginx
upstream backend {
    server backend:8000;
}

upstream frontend {
    server frontend:80;
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name yourcompany.com api.yourcompany.com;
    return 301 https://$server_name$request_uri;
}

# API Server
server {
    listen 443 ssl http2;
    server_name api.yourcompany.com;

    ssl_certificate /etc/nginx/ssl/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/privkey.pem;

    # SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Logging
    access_log /var/log/nginx/api_access.log;
    error_log /var/log/nginx/api_error.log;

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    limit_req zone=api burst=20;

    location / {
        proxy_pass http://backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # WebSocket support
    location /ws {
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}

# Frontend Server
server {
    listen 443 ssl http2;
    server_name yourcompany.com;

    ssl_certificate /etc/nginx/ssl/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/privkey.pem;

    root /usr/share/nginx/html;
    index index.html;

    # Logging
    access_log /var/log/nginx/frontend_access.log;
    error_log /var/log/nginx/frontend_error.log;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/json;

    location / {
        try_files $uri $uri/ /index.html;
    }

    # Cache static assets
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

---

## 🔒 SSL Setup

```bash
# Get SSL certificate
sudo certbot --nginx -d yourcompany.com -d api.yourcompany.com

# Copy certificates to nginx directory
sudo mkdir -p nginx/ssl
sudo cp /etc/letsencrypt/live/yourcompany.com/fullchain.pem nginx/ssl/
sudo cp /etc/letsencrypt/live/yourcompany.com/privkey.pem nginx/ssl/

# Auto-renewal (certbot handles this automatically)
sudo certbot renew --dry-run
```

---

## 💾 Database Backups

Create backup script `scripts/backup.sh`:
```bash
#!/bin/bash

BACKUP_DIR="/opt/RustCRM/backups"
DATE=$(date +%Y%m%d_%H%M%S)
CONTAINER="rustcrm_postgres"

mkdir -p $BACKUP_DIR

# Backup database
docker exec $CONTAINER pg_dump -U rustcrm rustcrm | gzip > "$BACKUP_DIR/backup_$DATE.sql.gz"

# Keep only last 30 days
find $BACKUP_DIR -name "backup_*.sql.gz" -mtime +30 -delete

echo "Backup completed: backup_$DATE.sql.gz"
```

Setup cron job:
```bash
# Edit crontab
sudo crontab -e

# Add backup job (runs daily at 2 AM)
0 2 * * * /opt/RustCRM/scripts/backup.sh
```

---

## 📊 Monitoring

### Health Checks

```bash
# Check backend health
curl https://api.yourcompany.com/health

# Check all containers
docker-compose ps

# Check logs
docker-compose logs -f backend
```

### System Monitoring (Optional)

Install Prometheus + Grafana:
```bash
# Add to docker-compose.yml
prometheus:
  image: prom/prometheus
  volumes:
    - ./prometheus.yml:/etc/prometheus/prometheus.yml
  ports:
    - "9090:9090"

grafana:
  image: grafana/grafana
  ports:
    - "3000:3000"
  depends_on:
    - prometheus
```

---

## 🚀 Deployment Process

### Initial Deployment

```bash
# 1. Build and start services
docker-compose -f docker-compose.prod.yml up -d --build

# 2. Run migrations
docker-compose exec backend sqlx migrate run

# 3. Check status
docker-compose ps
docker-compose logs
```

### Updates/Redeployment

```bash
# 1. Pull latest code
git pull origin main

# 2. Rebuild and restart
docker-compose -f docker-compose.prod.yml up -d --build

# 3. Run new migrations (if any)
docker-compose exec backend sqlx migrate run

# 4. Check logs
docker-compose logs -f
```

---

## 🔧 Maintenance

### Log Rotation

Configure log rotation in `/etc/logrotate.d/rustcrm`:
```
/var/log/nginx/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 www-data adm
    sharedscripts
    postrotate
        if [ -f /var/run/nginx.pid ]; then
            kill -USR1 `cat /var/run/nginx.pid`
        fi
    endscript
}
```

### Database Maintenance

```bash
# Vacuum database (monthly)
docker-compose exec postgres psql -U rustcrm -d rustcrm -c "VACUUM ANALYZE;"

# Check database size
docker-compose exec postgres psql -U rustcrm -d rustcrm -c "SELECT pg_size_pretty(pg_database_size('rustcrm'));"
```

---

## 📝 Deployment Checklist

Before going live:

- [ ] Environment variables configured
- [ ] Strong secrets generated
- [ ] SSL certificates installed
- [ ] Database backups configured
- [ ] Monitoring setup
- [ ] Log rotation configured
- [ ] Firewall rules set
- [ ] Rate limiting configured
- [ ] Health checks working
- [ ] Error tracking setup (Sentry)
- [ ] Performance testing done
- [ ] Security audit complete
- [ ] Documentation updated
- [ ] Team trained on deployment process

---

**Your RustCRM is now production-ready! 🎉**
