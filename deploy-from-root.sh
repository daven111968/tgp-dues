#!/bin/bash

# Tau Gamma Phi Rahugan CBC Chapter - Dues Management System Installer
# Ubuntu VPS Deployment Script (Root Directory Version)

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DB_NAME="tgp_dues_db"
DB_USER="rahuganmkc"
DB_PASSWORD="rahugan2018"
APP_DIR="/var/www/tgp-dues"
APP_PORT="5000"

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

check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_warning "Running as root. This is acceptable for VPS deployment."
        CURRENT_USER="root"
        HOME_DIR="/root"
    else
        CURRENT_USER=$USER
        HOME_DIR=$HOME
    fi
}

update_system() {
    print_status "Updating system packages..."
    apt update && apt upgrade -y
    print_success "System updated successfully"
}

install_nodejs() {
    print_status "Installing Node.js 20..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt-get install -y nodejs
    
    # Verify installation
    node_version=$(node --version)
    npm_version=$(npm --version)
    print_success "Node.js $node_version and npm $npm_version installed"
}

install_postgresql() {
    print_status "Installing PostgreSQL..."
    apt install postgresql postgresql-contrib -y
    systemctl start postgresql
    systemctl enable postgresql
    print_success "PostgreSQL installed and started"
}

setup_database() {
    print_status "Setting up database..."
    
    # Change to postgres home directory to avoid permission issues
    cd /var/lib/postgresql
    
    # Create database and user
    sudo -u postgres psql << EOF
CREATE DATABASE $DB_NAME;
CREATE USER $DB_USER WITH ENCRYPTED PASSWORD '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
ALTER USER $DB_USER CREATEDB;
\q
EOF

    # Configure PostgreSQL authentication
    print_status "Configuring PostgreSQL authentication..."
    
    # Find the correct PostgreSQL version and config path
    PG_VERSION=$(ls /etc/postgresql/ | head -1)
    if [ -z "$PG_VERSION" ]; then
        print_error "Could not find PostgreSQL version directory"
        return 1
    fi
    
    PG_CONFIG="/etc/postgresql/$PG_VERSION/main/pg_hba.conf"
    
    if [ ! -f "$PG_CONFIG" ]; then
        print_error "PostgreSQL config file not found at $PG_CONFIG"
        # Try alternative paths
        PG_CONFIG=$(find /etc/postgresql -name "pg_hba.conf" 2>/dev/null | head -1)
        if [ -z "$PG_CONFIG" ]; then
            print_error "Could not locate pg_hba.conf file"
            return 1
        fi
        print_status "Found config at: $PG_CONFIG"
    fi
    
    # Backup original config
    cp $PG_CONFIG $PG_CONFIG.backup
    
    # Update authentication method
    sed -i "s/local   all             all                                     peer/local   all             all                                     md5/" $PG_CONFIG
    
    # Restart PostgreSQL
    systemctl restart postgresql
    
    print_success "Database setup completed"
}

install_pm2() {
    print_status "Installing PM2 process manager..."
    npm install -g pm2
    print_success "PM2 installed"
}

install_nginx() {
    print_status "Installing Nginx..."
    apt install nginx -y
    systemctl start nginx
    systemctl enable nginx
    print_success "Nginx installed and started"
}

setup_application() {
    print_status "Setting up application from current directory..."
    
    # Current directory should contain the project files
    CURRENT_DIR=$(pwd)
    print_status "Current directory: $CURRENT_DIR"
    
    # Create app directory and copy files
    mkdir -p $APP_DIR
    
    # Copy all files except hidden ones and this script
    print_status "Copying application files to $APP_DIR..."
    find . -maxdepth 1 -name ".*" -prune -o -type f -print | grep -v "deploy" | while read file; do
        cp "$file" "$APP_DIR/"
    done
    
    # Copy directories
    find . -maxdepth 1 -type d -name ".*" -prune -o -type d ! -name "." -print | while read dir; do
        cp -r "$dir" "$APP_DIR/"
    done
    
    cd $APP_DIR
    
    # Install dependencies
    print_status "Installing application dependencies..."
    npm install
    
    # Create environment file
    print_status "Creating environment configuration..."
    cat > .env << EOF
DATABASE_URL=postgresql://$DB_USER:$DB_PASSWORD@localhost:5432/$DB_NAME
NODE_ENV=production
PORT=$APP_PORT
PGHOST=localhost
PGPORT=5432
PGUSER=$DB_USER
PGPASSWORD=$DB_PASSWORD
PGDATABASE=$DB_NAME
EOF

    print_success "Application setup completed"
}

setup_pm2_config() {
    print_status "Setting up PM2 configuration..."
    
    cd $APP_DIR
    
    # Create PM2 ecosystem file
    cat > ecosystem.config.js << EOF
module.exports = {
  apps: [{
    name: 'tgp-dues',
    script: 'server/index.ts',
    interpreter: 'npx',
    interpreter_args: 'tsx',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    env: {
      NODE_ENV: 'production',
      PORT: $APP_PORT
    }
  }]
}
EOF

    # Start application with PM2
    pm2 start ecosystem.config.js
    
    # Save PM2 configuration
    pm2 save
    
    # Set PM2 to start on boot
    if [[ $CURRENT_USER == "root" ]]; then
        pm2 startup systemd -u root --hp /root
        env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u root --hp /root
    else
        pm2 startup | grep "sudo env" | bash
    fi
    
    print_success "PM2 configuration completed"
}

setup_nginx() {
    print_status "Configuring Nginx reverse proxy..."
    
    # Get server IP
    SERVER_IP=$(curl -s ifconfig.me)
    
    # Create Nginx configuration
    tee /etc/nginx/sites-available/tgp-dues << EOF
server {
    listen 80;
    server_name $SERVER_IP _;

    location / {
        proxy_pass http://localhost:$APP_PORT;
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

    # Enable the site
    ln -sf /etc/nginx/sites-available/tgp-dues /etc/nginx/sites-enabled/
    
    # Remove default site
    rm -f /etc/nginx/sites-enabled/default
    
    # Test Nginx configuration
    nginx -t
    
    # Restart Nginx
    systemctl restart nginx
    
    print_success "Nginx configuration completed"
}

setup_firewall() {
    print_status "Configuring firewall..."
    
    # Enable UFW firewall
    ufw --force enable
    
    # Allow SSH, HTTP, and HTTPS
    ufw allow ssh
    ufw allow 80
    ufw allow 443
    
    print_success "Firewall configured"
}

test_deployment() {
    print_status "Testing deployment..."
    
    # Wait for application to start
    sleep 10
    
    # Check PM2 status
    pm2_status=$(pm2 list | grep tgp-dues | grep online || echo "not running")
    if [[ $pm2_status == *"online"* ]]; then
        print_success "Application is running with PM2"
    else
        print_error "Application failed to start with PM2"
        print_status "Checking PM2 logs..."
        pm2 logs tgp-dues --lines 10
        return 1
    fi
    
    # Test HTTP response
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:$APP_PORT | grep -q "200\|302"; then
        print_success "Application is responding on port $APP_PORT"
    else
        print_warning "Application may not be responding correctly"
    fi
    
    # Test database connection
    if PGPASSWORD=$DB_PASSWORD psql -U $DB_USER -d $DB_NAME -h localhost -c "\q" 2>/dev/null; then
        print_success "Database connection successful"
    else
        print_error "Database connection failed"
        return 1
    fi
}

show_completion_info() {
    SERVER_IP=$(curl -s ifconfig.me)
    
    echo ""
    echo -e "${GREEN}============================================${NC}"
    echo -e "${GREEN}  TGP Dues Management System Deployed!${NC}"
    echo -e "${GREEN}============================================${NC}"
    echo ""
    echo -e "${BLUE}Application URL:${NC} http://$SERVER_IP"
    echo -e "${BLUE}Application Directory:${NC} $APP_DIR"
    echo ""
    echo -e "${BLUE}Admin Login:${NC}"
    echo -e "  Username: treasurer"
    echo -e "  Password: password123"
    echo ""
    echo -e "${BLUE}Member Login Examples:${NC}"
    echo -e "  Username: juan.delacruz, mark.santos, paolo.rodriguez"
    echo -e "  Password: member123"
    echo ""
    echo -e "${BLUE}Database Credentials:${NC}"
    echo -e "  Database: $DB_NAME"
    echo -e "  Username: $DB_USER"
    echo -e "  Password: $DB_PASSWORD"
    echo ""
    echo -e "${BLUE}Management Commands:${NC}"
    echo -e "  View logs: ${YELLOW}pm2 logs tgp-dues${NC}"
    echo -e "  Restart app: ${YELLOW}pm2 restart tgp-dues${NC}"
    echo -e "  Check status: ${YELLOW}pm2 status${NC}"
    echo ""
}

main() {
    echo -e "${BLUE}"
    echo "=========================================="
    echo "  TGP Rahugan CBC Dues Management System"
    echo "  Ubuntu VPS Deployment (Root Version)"
    echo "=========================================="
    echo -e "${NC}"
    
    check_root
    
    print_status "Starting deployment from $(pwd)..."
    
    update_system
    install_nodejs
    install_postgresql
    setup_database
    install_pm2
    install_nginx
    setup_application
    setup_pm2_config
    setup_nginx
    setup_firewall
    test_deployment
    
    show_completion_info
    
    print_success "Deployment completed successfully!"
}

# Handle script interruption
trap 'print_error "Script interrupted"; exit 1' INT TERM

# Run main function
main "$@"