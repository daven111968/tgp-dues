#!/bin/bash

# ================================================================
# Tau Gamma Phi CBC Chapter Management System - Quick Deploy
# Complete automated deployment script for Ubuntu VPS
# ================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Print functions
print_header() {
    echo -e "\n${PURPLE}========================================${NC}"
    echo -e "${PURPLE}$1${NC}"
    echo -e "${PURPLE}========================================${NC}\n"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

print_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration variables
APP_NAME="TGP CBC Chapter Management"
APP_USER="tgpchapter"
APP_DIR="/opt/tgp-chapter"
DB_NAME="tgp_chapter_db"
DB_USER="tgp_user"
DOMAIN="your-domain.com"

print_header "TAU GAMMA PHI CBC CHAPTER MANAGEMENT SYSTEM"
echo "Quick Deploy Script v2.0"
echo "This script will completely set up your chapter management system"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root"
   echo "Please run: sudo ./quick-deploy.sh"
   exit 1
fi

# Get server information
print_step "Gathering server information..."
SERVER_IP=$(curl -s ifconfig.me || echo "Unable to detect")
HOSTNAME=$(hostname)
OS_VERSION=$(lsb_release -d | cut -f2)

echo "Server IP: $SERVER_IP"
echo "Hostname: $HOSTNAME"
echo "OS: $OS_VERSION"
echo ""

# Prompt for domain (optional)
read -p "Enter your domain name (press Enter to skip): " USER_DOMAIN
if [[ -n "$USER_DOMAIN" ]]; then
    DOMAIN="$USER_DOMAIN"
    print_info "Using domain: $DOMAIN"
else
    DOMAIN="$SERVER_IP"
    print_info "Using IP address: $DOMAIN"
fi

print_header "STEP 1: SYSTEM UPDATES & DEPENDENCIES"

print_step "Updating system packages..."
apt update && apt upgrade -y

print_step "Installing essential packages..."
apt install -y curl wget git htop ufw nginx postgresql postgresql-contrib openssl

print_step "Installing Node.js 20.x..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

print_step "Installing PM2 process manager..."
npm install -g pm2

print_step "Installing SSL certificate tools..."
apt install -y certbot python3-certbot-nginx

NODE_VERSION=$(node --version)
NPM_VERSION=$(npm --version)
print_success "Node.js $NODE_VERSION and npm $NPM_VERSION installed"

print_header "STEP 2: DATABASE SETUP"

print_step "Configuring PostgreSQL..."
systemctl start postgresql
systemctl enable postgresql

# Generate secure database password
DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)

print_step "Creating database and user..."
sudo -u postgres psql <<EOF
DROP DATABASE IF EXISTS $DB_NAME;
DROP USER IF EXISTS $DB_USER;
CREATE DATABASE $DB_NAME;
CREATE USER $DB_USER WITH ENCRYPTED PASSWORD '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
ALTER USER $DB_USER CREATEDB;
\q
EOF

print_success "Database '$DB_NAME' created with user '$DB_USER'"

print_header "STEP 3: APPLICATION USER & DIRECTORY"

print_step "Creating application user..."
if id "$APP_USER" &>/dev/null; then
    print_warning "User $APP_USER already exists"
else
    useradd -r -s /bin/bash -d $APP_DIR $APP_USER
    print_success "User $APP_USER created"
fi

print_step "Setting up application directory..."
mkdir -p $APP_DIR
mkdir -p $APP_DIR/logs
mkdir -p $APP_DIR/backups
chown -R $APP_USER:$APP_USER $APP_DIR

print_header "STEP 4: APPLICATION CONFIGURATION"

print_step "Creating environment configuration..."
SESSION_SECRET=$(openssl rand -base64 64)
cat > $APP_DIR/.env <<EOF
# Database Configuration
DATABASE_URL=postgresql://$DB_USER:$DB_PASSWORD@localhost:5432/$DB_NAME
PGHOST=localhost
PGPORT=5432
PGUSER=$DB_USER
PGPASSWORD=$DB_PASSWORD
PGDATABASE=$DB_NAME

# Application Configuration
NODE_ENV=production
PORT=3000

# Session Configuration
SESSION_SECRET=$SESSION_SECRET

# Chapter Configuration
CHAPTER_NAME=Tau Gamma Phi Rahugan CBC Chapter
EOF

chmod 600 $APP_DIR/.env
chown $APP_USER:$APP_USER $APP_DIR/.env

print_step "Creating PM2 configuration..."
cat > $APP_DIR/ecosystem.config.js <<'EOF'
module.exports = {
  apps: [{
    name: 'tgp-chapter-management',
    script: 'npm',
    args: 'start',
    cwd: '/opt/tgp-chapter',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    error_file: '/opt/tgp-chapter/logs/err.log',
    out_file: '/opt/tgp-chapter/logs/out.log',
    log_file: '/opt/tgp-chapter/logs/combined.log',
    time: true,
    kill_timeout: 5000,
    restart_delay: 1000
  }]
};
EOF

chown $APP_USER:$APP_USER $APP_DIR/ecosystem.config.js

print_header "STEP 5: WEB SERVER CONFIGURATION"

print_step "Configuring Nginx..."
cat > /etc/nginx/sites-available/tgp-chapter <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline' 'unsafe-eval'" always;

    # Rate limiting
    limit_req_zone \$binary_remote_addr zone=login:10m rate=5r/m;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_read_timeout 300;
        proxy_connect_timeout 300;
        proxy_send_timeout 300;
    }

    # Rate limit login attempts
    location /api/login {
        limit_req zone=login burst=3 nodelay;
        proxy_pass http://localhost:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Static assets with caching
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        add_header Vary Accept-Encoding;
    }

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied any;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/atom+xml
        image/svg+xml;
}
EOF

# Enable site and disable default
ln -sf /etc/nginx/sites-available/tgp-chapter /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test nginx configuration
nginx -t
print_success "Nginx configured successfully"

print_header "STEP 6: FIREWALL & SECURITY"

print_step "Configuring UFW firewall..."
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 'Nginx Full'
ufw --force enable

print_success "Firewall configured"

print_header "STEP 7: MANAGEMENT SCRIPTS"

print_step "Creating deployment script..."
cat > $APP_DIR/deploy.sh <<'EOF'
#!/bin/bash
set -e

echo "🚀 Deploying TGP Chapter Management System..."

cd /opt/tgp-chapter

# Install dependencies
echo "Installing dependencies..."
sudo -u tgpchapter npm ci --production

# Build application
echo "Building application..."
sudo -u tgpchapter npm run build

# Update database schema
echo "Updating database schema..."
sudo -u tgpchapter npm run db:push

# Restart application
echo "Restarting application..."
sudo -u tgpchapter pm2 restart tgp-chapter-management

echo "✅ Deployment completed successfully!"
EOF

chmod +x $APP_DIR/deploy.sh

print_step "Creating backup script..."
cat > $APP_DIR/backup.sh <<EOF
#!/bin/bash
set -e

BACKUP_DIR="/opt/tgp-chapter/backups"
TIMESTAMP=\$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="\$BACKUP_DIR/tgp_chapter_backup_\$TIMESTAMP.sql"

echo "Creating database backup..."
PGPASSWORD=$DB_PASSWORD pg_dump -h localhost -U $DB_USER -d $DB_NAME > \$BACKUP_FILE

# Compress backup
gzip \$BACKUP_FILE

echo "Backup created: \$BACKUP_FILE.gz"

# Clean old backups (keep 30 days)
find \$BACKUP_DIR -name "*.gz" -mtime +30 -delete

echo "✅ Backup completed successfully!"
EOF

chmod +x $APP_DIR/backup.sh

print_step "Creating application setup script..."
cat > $APP_DIR/setup-app.sh <<'EOF'
#!/bin/bash
set -e

echo "🔧 Setting up TGP Chapter Management Application..."

cd /opt/tgp-chapter

# Install dependencies
echo "Installing dependencies..."
npm install

# Build application
echo "Building application..."
npm run build

# Setup database schema
echo "Setting up database..."
npm run db:push

# Start application with PM2
echo "Starting application..."
pm2 start ecosystem.config.js

# Save PM2 configuration
pm2 save

# Setup PM2 startup
pm2 startup systemd -u tgpchapter --hp /opt/tgp-chapter

echo "✅ Application setup completed!"
echo "🌐 Access your application at: http://$(curl -s ifconfig.me)"
echo ""
echo "Default admin credentials:"
echo "Username: treasurer"
echo "Password: password123"
echo ""
echo "⚠️  IMPORTANT: Change the default password after first login!"
EOF

chmod +x $APP_DIR/setup-app.sh
chown $APP_USER:$APP_USER $APP_DIR/*.sh

print_step "Creating systemd service..."
cat > /etc/systemd/system/tgp-chapter.service <<EOF
[Unit]
Description=TGP Chapter Management System
Documentation=https://github.com/your-repo/tgp-chapter
After=network.target postgresql.service

[Service]
Type=forking
User=$APP_USER
WorkingDirectory=$APP_DIR
Environment=PATH=/usr/bin:/usr/local/bin
Environment=NODE_ENV=production
ExecStart=/usr/bin/pm2 start $APP_DIR/ecosystem.config.js --no-daemon
ExecReload=/usr/bin/pm2 reload $APP_DIR/ecosystem.config.js
ExecStop=/usr/bin/pm2 delete tgp-chapter-management
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload

print_header "STEP 8: STARTING SERVICES"

print_step "Starting PostgreSQL..."
systemctl start postgresql
systemctl enable postgresql

print_step "Starting Nginx..."
systemctl start nginx
systemctl enable nginx

print_success "All services started and enabled"

print_header "STEP 9: FINAL SETUP"

# Create cron job for automatic backups
print_step "Setting up automatic backups..."
cat > /etc/cron.d/tgp-chapter-backup <<EOF
# TGP Chapter Management System - Daily Database Backup
0 2 * * * $APP_USER $APP_DIR/backup.sh
EOF

print_success "Daily backups scheduled for 2:00 AM"

# Create info file
cat > $APP_DIR/server-info.txt <<EOF
TGP Chapter Management System - Server Information
==================================================

Server Details:
- IP Address: $SERVER_IP
- Hostname: $HOSTNAME
- OS: $OS_VERSION
- Domain: $DOMAIN

Application Details:
- User: $APP_USER
- Directory: $APP_DIR
- Port: 3000
- Environment: production

Database Details:
- Name: $DB_NAME
- User: $DB_USER
- Password: [stored in .env file]
- Host: localhost
- Port: 5432

Management Commands:
- Deploy updates: $APP_DIR/deploy.sh
- Backup database: $APP_DIR/backup.sh
- Setup application: $APP_DIR/setup-app.sh
- View logs: pm2 logs tgp-chapter-management
- Restart app: pm2 restart tgp-chapter-management
- Check status: pm2 status

Default Admin Credentials:
- Username: treasurer
- Password: password123
- ⚠️  CHANGE THIS PASSWORD AFTER FIRST LOGIN!

URLs:
- Application: http://$DOMAIN
- If using domain: Configure DNS A record to point to $SERVER_IP

SSL Setup (after DNS configuration):
sudo certbot --nginx -d $DOMAIN

Generated on: $(date)
EOF

chown $APP_USER:$APP_USER $APP_DIR/server-info.txt

print_header "DEPLOYMENT COMPLETED SUCCESSFULLY!"

echo ""
echo "🎉 Your TGP Chapter Management System is ready!"
echo ""
echo "📋 DEPLOYMENT SUMMARY:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ System updated and secured"
echo "✅ Node.js, PostgreSQL, and Nginx installed"
echo "✅ Database created and configured"
echo "✅ Application user and directories set up"
echo "✅ Nginx reverse proxy configured"
echo "✅ Firewall rules applied"
echo "✅ Management scripts created"
echo "✅ Automatic backups scheduled"
echo ""
echo "🔗 ACCESS INFORMATION:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🌐 Server IP: $SERVER_IP"
echo "🌐 Application URL: http://$DOMAIN"
echo "👤 Server User: $APP_USER"
echo "📁 App Directory: $APP_DIR"
echo ""
echo "🔑 DEFAULT ADMIN LOGIN:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Username: treasurer"
echo "Password: password123"
echo "⚠️  CHANGE THIS PASSWORD IMMEDIATELY AFTER LOGIN!"
echo ""
echo "📝 NEXT STEPS:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Copy your application files to: $APP_DIR"
echo "   Example: scp -r ./your-app/* root@$SERVER_IP:$APP_DIR/"
echo ""
echo "2. Set proper ownership:"
echo "   chown -R $APP_USER:$APP_USER $APP_DIR"
echo ""
echo "3. Setup the application:"
echo "   cd $APP_DIR"
echo "   sudo -u $APP_USER ./setup-app.sh"
echo ""
echo "4. Configure your domain DNS (if using domain):"
echo "   Point $DOMAIN to $SERVER_IP"
echo ""
echo "5. Setup SSL certificate (after DNS):"
echo "   certbot --nginx -d $DOMAIN"
echo ""
echo "📚 MANAGEMENT COMMANDS:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 Deploy updates: $APP_DIR/deploy.sh"
echo "💾 Backup database: $APP_DIR/backup.sh"
echo "📊 View logs: pm2 logs tgp-chapter-management"
echo "🔄 Restart app: pm2 restart tgp-chapter-management"
echo "📈 Check status: pm2 status"
echo "🔍 Server info: cat $APP_DIR/server-info.txt"
echo ""
echo "🔒 SECURITY NOTES:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Firewall configured (SSH and HTTP/HTTPS allowed)"
echo "✅ Rate limiting enabled for login attempts"
echo "✅ Security headers configured"
echo "✅ Database password auto-generated"
echo "✅ Application runs under dedicated user"
echo ""
echo "🎯 Your Tau Gamma Phi CBC Chapter Management System"
echo "   is now ready for production use!"
echo ""
echo "📞 Need help? Check the logs or contact your system administrator."
echo ""