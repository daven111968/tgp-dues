#!/bin/bash

# Tau Gamma Phi CBC Chapter Management System - Ubuntu VPS Deployment Script
# This version can be run as root and will handle user creation automatically

set -e

echo "🚀 Starting deployment for Tau Gamma Phi CBC Chapter Management System..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
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

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root (use sudo)"
   exit 1
fi

# Update system
print_status "Updating system packages..."
apt update && apt upgrade -y

# Install Node.js 20.x
print_status "Installing Node.js 20.x..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

# Verify Node.js installation
NODE_VERSION=$(node --version)
NPM_VERSION=$(npm --version)
print_success "Node.js $NODE_VERSION and npm $NPM_VERSION installed successfully"

# Install PostgreSQL
print_status "Installing PostgreSQL..."
apt install -y postgresql postgresql-contrib

# Start and enable PostgreSQL
systemctl start postgresql
systemctl enable postgresql

# Install PM2 for process management
print_status "Installing PM2 process manager..."
npm install -g pm2

# Install Nginx
print_status "Installing Nginx..."
apt install -y nginx

# Install additional tools
print_status "Installing additional tools..."
apt install -y curl wget git htop ufw certbot python3-certbot-nginx

# Create application user
APP_USER="tgp-chapter"
if id "$APP_USER" &>/dev/null; then
    print_warning "User $APP_USER already exists"
else
    print_status "Creating application user: $APP_USER"
    useradd -m -s /bin/bash $APP_USER
    usermod -aG sudo $APP_USER
    
    # Set a temporary password (user should change this)
    echo "$APP_USER:TGP2024temp!" | chpasswd
    print_warning "Temporary password set for $APP_USER: TGP2024temp!"
    print_warning "Please change this password after deployment"
fi

# Create application directory
APP_DIR="/home/$APP_USER/tgp-chapter-management"
print_status "Setting up application directory: $APP_DIR"
mkdir -p $APP_DIR
chown $APP_USER:$APP_USER $APP_DIR

# Database setup
print_status "Setting up PostgreSQL database..."
DB_NAME="tgp_chapter_db"
DB_USER="tgp_user"
DB_PASSWORD=$(openssl rand -base64 32)

# Create database and user
sudo -u postgres psql -c "DROP DATABASE IF EXISTS $DB_NAME;"
sudo -u postgres psql -c "DROP USER IF EXISTS $DB_USER;"
sudo -u postgres psql -c "CREATE DATABASE $DB_NAME;"
sudo -u postgres psql -c "CREATE USER $DB_USER WITH ENCRYPTED PASSWORD '$DB_PASSWORD';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"
sudo -u postgres psql -c "ALTER USER $DB_USER CREATEDB;"

print_success "Database created: $DB_NAME"
print_success "Database user created: $DB_USER"

# Create environment file
print_status "Creating environment configuration..."
ENV_FILE="$APP_DIR/.env"
cat > $ENV_FILE <<EOF
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

# Session Configuration (generate your own secret)
SESSION_SECRET=$(openssl rand -base64 64)
EOF

chown $APP_USER:$APP_USER $ENV_FILE
chmod 600 $ENV_FILE

# Create PM2 ecosystem file
print_status "Creating PM2 configuration..."
PM2_CONFIG="$APP_DIR/ecosystem.config.js"
cat > $PM2_CONFIG <<EOF
module.exports = {
  apps: [{
    name: 'tgp-chapter-management',
    script: 'npm',
    args: 'run dev',
    cwd: '$APP_DIR',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    error_file: '$APP_DIR/logs/err.log',
    out_file: '$APP_DIR/logs/out.log',
    log_file: '$APP_DIR/logs/combined.log',
    time: true
  }]
};
EOF

chown $APP_USER:$APP_USER $PM2_CONFIG

# Create logs directory
mkdir -p $APP_DIR/logs
chown $APP_USER:$APP_USER $APP_DIR/logs

# Create Nginx configuration
print_status "Configuring Nginx..."
NGINX_CONFIG="/etc/nginx/sites-available/tgp-chapter"
cat > $NGINX_CONFIG <<EOF
server {
    listen 80;
    server_name localhost;  # Change this to your domain

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

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

    # Static assets caching
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied expired no-cache no-store private must-revalidate auth;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/javascript;
}
EOF

# Enable the site
ln -sf $NGINX_CONFIG /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
nginx -t

# Create deployment script
print_status "Creating deployment helper script..."
DEPLOY_SCRIPT="$APP_DIR/deploy.sh"
cat > $DEPLOY_SCRIPT <<EOF
#!/bin/bash

# Quick deployment script for updates
set -e

echo "Deploying Tau Gamma Phi CBC Chapter Management System..."

# Navigate to app directory
cd $APP_DIR

# Install dependencies
npm ci --production

# Build the application
npm run build

# Push database schema changes
npm run db:push

# Restart the application
pm2 restart tgp-chapter-management

echo "Deployment completed successfully!"
EOF

chmod +x $DEPLOY_SCRIPT
chown $APP_USER:$APP_USER $DEPLOY_SCRIPT

# Create backup script
print_status "Creating database backup script..."
BACKUP_SCRIPT="$APP_DIR/backup.sh"
cat > $BACKUP_SCRIPT <<EOF
#!/bin/bash

# Database backup script
set -e

BACKUP_DIR="$APP_DIR/backups"
mkdir -p \$BACKUP_DIR

# Create backup with timestamp
TIMESTAMP=\$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="\$BACKUP_DIR/tgp_chapter_backup_\$TIMESTAMP.sql"

echo "Creating database backup..."
PGPASSWORD=$DB_PASSWORD pg_dump -h localhost -U $DB_USER -d $DB_NAME > \$BACKUP_FILE

# Compress the backup
gzip \$BACKUP_FILE

echo "Backup created: \$BACKUP_FILE.gz"

# Keep only last 7 days of backups
find \$BACKUP_DIR -name "*.gz" -mtime +7 -delete

echo "Backup completed successfully!"
EOF

chmod +x $BACKUP_SCRIPT
chown $APP_USER:$APP_USER $BACKUP_SCRIPT

# Create systemd service for automatic startup
print_status "Creating systemd service..."
SERVICE_FILE="/etc/systemd/system/tgp-chapter.service"
cat > $SERVICE_FILE <<EOF
[Unit]
Description=Tau Gamma Phi CBC Chapter Management System
After=network.target postgresql.service

[Service]
Type=forking
User=$APP_USER
WorkingDirectory=$APP_DIR
Environment=PATH=/usr/bin:/usr/local/bin
Environment=NODE_ENV=production
ExecStart=/usr/bin/pm2 start $PM2_CONFIG --no-daemon
ExecReload=/usr/bin/pm2 reload $PM2_CONFIG
ExecStop=/usr/bin/pm2 delete tgp-chapter-management
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Create firewall rules
print_status "Configuring firewall..."
ufw allow OpenSSH
ufw allow 'Nginx Full'
ufw --force enable

# Create application files deployment script
print_status "Creating application setup script..."
SETUP_SCRIPT="$APP_DIR/setup-app.sh"
cat > $SETUP_SCRIPT <<EOF
#!/bin/bash

# Application setup script
# Run this as the tgp-chapter user after copying application files

set -e

echo "Setting up Tau Gamma Phi CBC Chapter Management System..."

# Navigate to app directory
cd $APP_DIR

# Install dependencies
npm install

# Build the application
npm run build

# Setup database schema
npm run db:push

# Start with PM2
pm2 start ecosystem.config.js

# Save PM2 configuration
pm2 save

# Setup PM2 startup
sudo env PATH=\$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u $APP_USER --hp /home/$APP_USER

echo "Application setup completed!"
echo "Access your application at: http://your-server-ip"
EOF

chmod +x $SETUP_SCRIPT
chown $APP_USER:$APP_USER $SETUP_SCRIPT

# Start services
print_status "Starting services..."
systemctl start nginx
systemctl enable nginx
systemctl start postgresql
systemctl enable postgresql

print_success "Deployment script setup completed!"

echo ""
echo "========================================"
echo "🎉 SERVER SETUP COMPLETE!"
echo "========================================"
echo ""
echo "Next steps:"
echo "1. Copy your application files to: $APP_DIR"
echo "   Example: scp -r ./your-app/* root@your-server:$APP_DIR/"
echo ""
echo "2. Set proper ownership:"
echo "   chown -R $APP_USER:$APP_USER $APP_DIR"
echo ""
echo "3. Switch to application user and setup:"
echo "   su - $APP_USER"
echo "   cd $APP_DIR"
echo "   ./setup-app.sh"
echo ""
echo "4. Update Nginx server_name in: $NGINX_CONFIG"
echo ""
echo "Server Information:"
echo "- Application User: $APP_USER"
echo "- Application Directory: $APP_DIR"
echo "- Database: $DB_NAME"
echo "- Database User: $DB_USER"
echo "- Password: (stored in $ENV_FILE)"
echo ""
echo "Login credentials for application user:"
echo "- Username: $APP_USER"
echo "- Temporary Password: TGP2024temp!"
echo "- Please change this password: passwd"
echo ""
echo "Useful commands:"
echo "- Deploy updates: $DEPLOY_SCRIPT"
echo "- Backup database: $BACKUP_SCRIPT"
echo "- View logs: pm2 logs tgp-chapter-management"
echo "- Restart app: pm2 restart tgp-chapter-management"
echo ""
echo "For SSL certificate (after setting domain):"
echo "certbot --nginx -d your-domain.com"
echo ""
echo "🚀 Ready to deploy your Tau Gamma Phi CBC Chapter Management System!"