#!/bin/bash

# Quick deployment script for TGP Dues Management System
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}TGP Rahugan CBC Dues Management System - Quick Deploy${NC}"

# Update system
echo -e "${BLUE}[1/8] Updating system...${NC}"
apt update && apt upgrade -y

# Install Node.js
echo -e "${BLUE}[2/8] Installing Node.js 20...${NC}"
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

# Install PostgreSQL
echo -e "${BLUE}[3/8] Installing PostgreSQL...${NC}"
apt install postgresql postgresql-contrib -y
systemctl start postgresql
systemctl enable postgresql

# Setup database (simplified)
echo -e "${BLUE}[4/8] Setting up database...${NC}"
sudo -u postgres createdb tgp_dues_db 2>/dev/null || echo "Database might already exist"
sudo -u postgres psql -c "CREATE USER rahuganmkc WITH ENCRYPTED PASSWORD 'rahugan2018';" 2>/dev/null || echo "User might already exist"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE tgp_dues_db TO rahuganmkc;"
sudo -u postgres psql -c "ALTER USER rahuganmkc CREATEDB;"

# Configure PostgreSQL (simplified approach)
echo -e "${BLUE}[5/8] Configuring PostgreSQL...${NC}"
PG_CONFIG=$(find /etc/postgresql -name "pg_hba.conf" | head -1)
if [ -f "$PG_CONFIG" ]; then
    cp "$PG_CONFIG" "$PG_CONFIG.backup"
    sed -i 's/local   all             all                                     peer/local   all             all                                     md5/' "$PG_CONFIG"
    systemctl restart postgresql
else
    echo "PostgreSQL config file not found, using default settings"
fi

# Install PM2
echo -e "${BLUE}[6/8] Installing PM2...${NC}"
npm install -g pm2

# Setup application
echo -e "${BLUE}[7/8] Setting up application...${NC}"
APP_DIR="/var/www/tgp-dues"
mkdir -p $APP_DIR

# Copy files from current directory
cp -r * $APP_DIR/ 2>/dev/null || true
cd $APP_DIR

# Install dependencies
npm install

# Create environment file
cat > .env << EOF
DATABASE_URL=postgresql://rahuganmkc:rahugan2018@localhost:5432/tgp_dues_db
NODE_ENV=production
PORT=5000
PGHOST=localhost
PGPORT=5432
PGUSER=rahuganmkc
PGPASSWORD=rahugan2018
PGDATABASE=tgp_dues_db
EOF

# Start with PM2 directly (no config file needed)
pm2 start "npx tsx server/index.ts" --name "tgp-dues" --max-memory-restart 1G
pm2 save
pm2 startup systemd -u root --hp /root

# Install and configure Nginx
echo -e "${BLUE}[8/8] Setting up Nginx...${NC}"
apt install nginx -y

SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo "your-server-ip")

cat > /etc/nginx/sites-available/tgp-dues << EOF
server {
    listen 80;
    server_name $SERVER_IP _;

    location / {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

ln -sf /etc/nginx/sites-available/tgp-dues /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl restart nginx

# Configure firewall
ufw --force enable
ufw allow ssh
ufw allow 80
ufw allow 443

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  Deployment Complete!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo -e "${BLUE}Application URL:${NC} http://$SERVER_IP"
echo ""
echo -e "${BLUE}Admin Login:${NC}"
echo -e "  Username: treasurer"
echo -e "  Password: password123"
echo ""
echo -e "${BLUE}Member Login Examples:${NC}"
echo -e "  Username: juan.delacruz, mark.santos, paolo.rodriguez"
echo -e "  Password: member123"
echo ""
echo -e "${BLUE}Management Commands:${NC}"
echo -e "  Check status: pm2 status"
echo -e "  View logs: pm2 logs tgp-dues"
echo -e "  Restart: pm2 restart tgp-dues"
echo ""

# Test the deployment
sleep 5
if pm2 list | grep -q "tgp-dues.*online"; then
    echo -e "${GREEN}✓ Application is running successfully${NC}"
else
    echo -e "${RED}✗ Application may have issues. Check logs with: pm2 logs tgp-dues${NC}"
fi