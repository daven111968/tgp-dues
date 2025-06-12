#!/bin/bash

# Quick deployment script for TGP Dues Management System
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

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

# Error handling function
handle_error() {
    print_error "Script failed at line $1"
    print_error "Last command: $2"
    exit 1
}

# Set up error trap
trap 'handle_error $LINENO "$BASH_COMMAND"' ERR

echo -e "${BLUE}TGP Rahugan CBC Dues Management System - Quick Deploy${NC}"
echo ""

# Update system
print_status "[1/8] Updating system packages..."
apt update && apt upgrade -y
print_success "System updated"

# Install Node.js
print_status "[2/8] Installing Node.js 20..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs
node_version=$(node --version)
npm_version=$(npm --version)
print_success "Node.js $node_version and npm $npm_version installed"

# Install PostgreSQL
print_status "[3/8] Installing PostgreSQL..."
apt install postgresql postgresql-contrib -y
systemctl start postgresql
systemctl enable postgresql
print_success "PostgreSQL installed and started"

# Setup database with better error handling
print_status "[4/8] Setting up database..."
cd /tmp  # Change to safe directory to avoid permission issues

# Create database
if sudo -u postgres createdb tgp_dues_db 2>/dev/null; then
    print_success "Database created"
else
    print_warning "Database might already exist"
fi

# Create user
if sudo -u postgres psql -c "CREATE USER rahuganmkc WITH ENCRYPTED PASSWORD 'rahugan2018';" 2>/dev/null; then
    print_success "Database user created"
else
    print_warning "User might already exist"
fi

# Grant privileges
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE tgp_dues_db TO rahuganmkc;" 2>/dev/null || true
sudo -u postgres psql -c "ALTER USER rahuganmkc CREATEDB;" 2>/dev/null || true
print_success "Database privileges configured"

# Configure PostgreSQL with robust error handling
print_status "[5/8] Configuring PostgreSQL authentication..."
PG_CONFIG=""

# Try multiple paths to find PostgreSQL config
for version in $(ls /etc/postgresql/ 2>/dev/null || echo ""); do
    if [ -f "/etc/postgresql/$version/main/pg_hba.conf" ]; then
        PG_CONFIG="/etc/postgresql/$version/main/pg_hba.conf"
        break
    fi
done

# Fallback: search for config file
if [ -z "$PG_CONFIG" ]; then
    PG_CONFIG=$(find /etc/postgresql -name "pg_hba.conf" 2>/dev/null | head -1)
fi

if [ -f "$PG_CONFIG" ]; then
    print_status "Found PostgreSQL config at: $PG_CONFIG"
    cp "$PG_CONFIG" "$PG_CONFIG.backup"
    sed -i 's/local   all             all                                     peer/local   all             all                                     md5/' "$PG_CONFIG"
    systemctl restart postgresql
    print_success "PostgreSQL authentication configured"
else
    print_warning "PostgreSQL config file not found, using default authentication"
fi

# Test database connection
if PGPASSWORD=rahugan2018 psql -U rahuganmkc -d tgp_dues_db -h localhost -c '\q' 2>/dev/null; then
    print_success "Database connection test successful"
else
    print_warning "Database connection test failed, but continuing..."
fi

# Install PM2
print_status "[6/8] Installing PM2 process manager..."
npm install -g pm2
print_success "PM2 installed"

# Setup application
print_status "[7/8] Setting up application..."
APP_DIR="/var/www/tgp-dues"
CURRENT_DIR=$(pwd)

# Create application directory
mkdir -p $APP_DIR
print_status "Created application directory: $APP_DIR"

# Copy files from current directory
print_status "Copying application files..."
cp -r * $APP_DIR/ 2>/dev/null || true
cd $APP_DIR

# Verify essential files exist
if [ ! -f "package.json" ]; then
    print_error "package.json not found. Make sure you're running this script from the project root directory."
    exit 1
fi

if [ ! -d "server" ]; then
    print_error "server directory not found. Make sure all project files are present."
    exit 1
fi

# Install dependencies
print_status "Installing application dependencies..."
npm install
print_success "Dependencies installed"

# Create environment file
print_status "Creating environment configuration..."
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
print_success "Environment file created"

# Stop any existing PM2 processes
pm2 stop all 2>/dev/null || true
pm2 delete all 2>/dev/null || true

# Start with PM2 directly
print_status "Starting application with PM2..."
if pm2 start "npx tsx server/index.ts" --name "tgp-dues" --max-memory-restart 1G; then
    print_success "Application started with PM2"
else
    print_error "Failed to start application with PM2"
    print_status "Checking if server directory exists..."
    ls -la server/
    exit 1
fi

pm2 save
pm2 startup systemd -u root --hp /root
print_success "PM2 configuration saved"

# Install and configure Nginx
print_status "[8/8] Setting up Nginx reverse proxy..."
apt install nginx -y
systemctl start nginx
systemctl enable nginx
print_success "Nginx installed"

# Get server IP
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ip.me 2>/dev/null || echo "localhost")
print_status "Server IP detected: $SERVER_IP"

# Create Nginx configuration
print_status "Creating Nginx configuration..."
cat > /etc/nginx/sites-available/tgp-dues << EOF
server {
    listen 80;
    server_name $SERVER_IP _;

    # Security headers
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options DENY;
    add_header X-XSS-Protection "1; mode=block";

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
        
        # Timeout settings
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
EOF

# Enable site and disable default
ln -sf /etc/nginx/sites-available/tgp-dues /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test and restart Nginx
if nginx -t; then
    systemctl restart nginx
    print_success "Nginx configured and restarted"
else
    print_error "Nginx configuration test failed"
    exit 1
fi

# Configure firewall
print_status "Configuring firewall..."
ufw --force enable
ufw allow ssh
ufw allow 80
ufw allow 443
print_success "Firewall configured"

# Final deployment test
print_status "Testing deployment..."
sleep 10

# Check PM2 status
if pm2 list | grep -q "tgp-dues.*online"; then
    print_success "✓ Application is running with PM2"
    APP_STATUS="✓ Online"
else
    print_error "✗ Application not running properly"
    APP_STATUS="✗ Error - Check logs with: pm2 logs tgp-dues"
fi

# Test HTTP response
if curl -s -o /dev/null -w "%{http_code}" http://localhost:5000 | grep -q "200\|302"; then
    print_success "✓ Application responding on port 5000"
    HTTP_STATUS="✓ Responding"
else
    print_warning "⚠ Application may not be responding on port 5000"
    HTTP_STATUS="⚠ Check connection"
fi

# Test database connection
if PGPASSWORD=rahugan2018 psql -U rahuganmkc -d tgp_dues_db -h localhost -c '\q' 2>/dev/null; then
    print_success "✓ Database connection successful"
    DB_STATUS="✓ Connected"
else
    print_warning "⚠ Database connection issues"
    DB_STATUS="⚠ Check credentials"
fi

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  TGP DUES MANAGEMENT SYSTEM DEPLOYED!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo -e "${BLUE}Application URL:${NC} http://$SERVER_IP"
echo -e "${BLUE}Application Directory:${NC} $APP_DIR"
echo ""
echo -e "${BLUE}System Status:${NC}"
echo -e "  PM2 Status: $APP_STATUS"
echo -e "  HTTP Status: $HTTP_STATUS"
echo -e "  Database Status: $DB_STATUS"
echo ""
echo -e "${BLUE}Login Credentials:${NC}"
echo -e "  ${GREEN}Admin Access:${NC}"
echo -e "    Username: treasurer"
echo -e "    Password: password123"
echo ""
echo -e "  ${GREEN}Member Examples:${NC}"
echo -e "    Usernames: juan.delacruz, mark.santos, paolo.rodriguez"
echo -e "    Password: member123"
echo ""
echo -e "${BLUE}Database Info:${NC}"
echo -e "  Database: tgp_dues_db"
echo -e "  Username: rahuganmkc"
echo -e "  Password: rahugan2018"
echo ""
echo -e "${BLUE}Management Commands:${NC}"
echo -e "  Check status: ${YELLOW}pm2 status${NC}"
echo -e "  View logs: ${YELLOW}pm2 logs tgp-dues${NC}"
echo -e "  Restart app: ${YELLOW}pm2 restart tgp-dues${NC}"
echo -e "  Stop app: ${YELLOW}pm2 stop tgp-dues${NC}"
echo ""
echo -e "${GREEN}Deployment completed successfully!${NC}"
echo ""