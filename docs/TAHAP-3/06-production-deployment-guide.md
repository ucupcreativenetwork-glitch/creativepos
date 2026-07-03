# TAHAP 3 — Production Deployment Guide

## CreativePOS Production Deployment

**Target OS:** Ubuntu Server 22.04/24.04 LTS  
**Domain:** creativepos.app

---

## Prerequisites

- Ubuntu Server with root/sudo access
- Domain DNS configured (A records)
- Docker & Docker Compose installed
- Git installed
- Minimum 4GB RAM, 2 vCPU, 40GB SSD

---

## Step 1: Server Preparation

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo apt install docker-compose-plugin -y

# Install Git
sudo apt install git -y

# Configure firewall
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

---

## Step 2: Clone Project

```bash
cd /opt
sudo git clone https://github.com/creative-network/creativepos.git
cd creativepos
sudo chown -R $USER:$USER /opt/creativepos
```

---

## Step 3: Environment Configuration

```bash
# Backend environment
cp backend/.env.example backend/.env
nano backend/.env
# Set: APP_KEY, DB_PASSWORD, REDIS, REVERB keys, MAIL, AWS S3

# Frontend environment
cp frontend/.env.example frontend/.env.local
nano frontend/.env.local
# Set: NEXT_PUBLIC_API_URL, NEXT_PUBLIC_WS_URL

# Docker environment
cp docker/.env.example docker/.env
nano docker/.env
# Set: DB passwords, domain names
```

### Generate APP_KEY

```bash
docker compose -f docker/docker-compose.yml run --rm backend php artisan key:generate
```

---

## Step 4: Build & Start Services

```bash
cd /opt/creativepos/docker

# Build all images
docker compose build

# Start services
docker compose up -d

# Verify all containers running
docker compose ps
```

Expected output:
```
NAME                    STATUS
creativepos-nginx       running
creativepos-frontend    running
creativepos-backend     running
creativepos-reverb      running
creativepos-horizon     running
creativepos-scheduler   running
creativepos-mysql       running
creativepos-redis       running
```

---

## Step 5: Database Setup

```bash
# Run migrations
docker compose exec backend php artisan migrate --force

# Seed initial data (packages, permissions, roles)
docker compose exec backend php artisan db:seed --force

# Create super admin
docker compose exec backend php artisan creativepos:create-super-admin
```

---

## Step 6: SSL Certificate

```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx -y

# Obtain certificates
sudo certbot --nginx -d creativepos.app \
  -d api.creativepos.app \
  -d ws.creativepos.app \
  -d "*.creativepos.app"

# Auto-renewal (verify)
sudo certbot renew --dry-run
```

---

## Step 7: Optimize Laravel

```bash
docker compose exec backend php artisan config:cache
docker compose exec backend php artisan route:cache
docker compose exec backend php artisan view:cache
docker compose exec backend php artisan event:cache
docker compose exec backend php artisan storage:link
```

---

## Step 8: Verify Deployment

```bash
# Health check - API
curl -s https://api.creativepos.app/api/v1/health | jq

# Health check - Frontend
curl -s -o /dev/null -w "%{http_code}" https://creativepos.app

# Check Horizon
# Visit: https://api.creativepos.app/horizon (protected)

# Check WebSocket
# Connect via browser dev tools to wss://ws.creativepos.app
```

---

## Step 9: Setup Cron & Backups

### Database Backup (daily at 02:00)

```bash
sudo crontab -e
```

```cron
# Database backup
0 2 * * * /opt/creativepos/docker/scripts/backup-db.sh >> /var/log/creativepos-backup.log 2>&1

# Docker log rotation
0 3 * * 0 docker system prune -f --volumes >> /var/log/docker-prune.log 2>&1
```

### Backup Script

```bash
#!/bin/bash
# docker/scripts/backup-db.sh
BACKUP_DIR="/opt/backups/creativepos"
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_DIR

docker compose -f /opt/creativepos/docker/docker-compose.yml exec -T mysql \
  mysqldump -u root -p"$DB_ROOT_PASSWORD" creativepos | gzip > "$BACKUP_DIR/db_$DATE.sql.gz"

# Keep last 30 days
find $BACKUP_DIR -name "db_*.sql.gz" -mtime +30 -delete
```

---

## Step 10: Monitoring Setup

```bash
# Create health check script
cat > /opt/creativepos/docker/scripts/health-check.sh << 'EOF'
#!/bin/bash
API_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://api.creativepos.app/api/v1/health)
FE_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://creativepos.app)

if [ "$API_STATUS" != "200" ] || [ "$FE_STATUS" != "200" ]; then
  echo "ALERT: CreativePOS health check failed! API=$API_STATUS FE=$FE_STATUS"
  # Send alert (email/telegram)
fi
EOF

chmod +x /opt/creativepos/docker/scripts/health-check.sh

# Cron every 5 minutes
# */5 * * * * /opt/creativepos/docker/scripts/health-check.sh
```

---

## Updating Production

```bash
cd /opt/creativepos

# Pull latest code
git pull origin main

# Rebuild & restart
cd docker
docker compose build
docker compose up -d

# Run migrations
docker compose exec backend php artisan migrate --force

# Clear & rebuild cache
docker compose exec backend php artisan optimize

# Restart queue workers
docker compose exec backend php artisan horizon:terminate
```

---

## Rollback Procedure

```bash
# Rollback code
git checkout <previous-commit-hash>

# Rebuild
cd docker && docker compose build && docker compose up -d

# Rollback migration (if needed)
docker compose exec backend php artisan migrate:rollback --step=1

# Restore database from backup
gunzip < /opt/backups/creativepos/db_YYYYMMDD.sql.gz | \
  docker compose exec -T mysql mysql -u root -p"$DB_ROOT_PASSWORD" creativepos
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| 502 Bad Gateway | Check `docker compose logs backend` |
| WebSocket not connecting | Verify Reverb container, check Nginx WS proxy |
| Queue jobs stuck | `docker compose restart horizon` |
| Permission denied | `docker compose exec backend chown -R www-data:www-data storage bootstrap/cache` |
| Migration failed | Check MySQL logs, verify DB credentials |
| High memory | Reduce Horizon `maxProcesses`, add swap |
| SSL expired | `sudo certbot renew` |

---

## Security Checklist

- [ ] `APP_DEBUG=false` in production
- [ ] Strong DB passwords (32+ chars)
- [ ] UFW firewall enabled (only 22, 80, 443)
- [ ] SSH key-only authentication
- [ ] Horizon dashboard protected by auth
- [ ] `.env` files not in git
- [ ] MySQL not exposed to public
- [ ] Redis not exposed to public
- [ ] Regular security updates (`apt upgrade`)
- [ ] Backup tested and verified