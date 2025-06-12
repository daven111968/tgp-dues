#!/bin/bash

# Tau Gamma Phi Rahugan CBC Chapter - Dues Management System Installer
# Ubuntu VPS Deployment Script

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
        print_error "This script should not be run as root. Please run as a regular user with sudo privileges."
        exit 1
    fi
}

update_system() {
    print_status "Updating system packages..."
    sudo apt update && sudo apt upgrade -y
    print_success "System updated successfully"
}

install_nodejs() {
    print_status "Installing Node.js 20..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y nodejs
    
    # Verify installation
    node_version=$(node --version)
    npm_version=$(npm --version)
    print_success "Node.js $node_version and npm $npm_version installed"
}

install_postgresql() {
    print_status "Installing PostgreSQL..."
    sudo apt install postgresql postgresql-contrib -y
    sudo systemctl start postgresql
    sudo systemctl enable postgresql
    print_success "PostgreSQL installed and started"
}

setup_database() {
    print_status "Setting up database..."
    
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
    PG_VERSION=$(sudo -u postgres psql -t -c "SELECT version();" | grep -oP '\d+\.\d+' | head -1)
    PG_CONFIG="/etc/postgresql/$PG_VERSION/main/pg_hba.conf"
    
    # Backup original config
    sudo cp $PG_CONFIG $PG_CONFIG.backup
    
    # Update authentication method
    sudo sed -i "s/local   all             all                                     peer/local   all             all                                     md5/" $PG_CONFIG
    
    # Restart PostgreSQL
    sudo systemctl restart postgresql
    
    print_success "Database setup completed"
}

install_pm2() {
    print_status "Installing PM2 process manager..."
    sudo npm install -g pm2
    print_success "PM2 installed"
}

install_nginx() {
    print_status "Installing Nginx..."
    sudo apt install nginx -y
    sudo systemctl start nginx
    sudo systemctl enable nginx
    print_success "Nginx installed and started"
}

setup_application() {
    print_status "Setting up application directory..."
    
    # Create app directory
    sudo mkdir -p $APP_DIR
    sudo chown $USER:$USER $APP_DIR
    
    # Copy application files to the directory
    print_status "Copying application files..."
    cp -r . $APP_DIR/
    
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
    pm2 startup | grep "sudo env" | bash
    
    print_success "PM2 configuration completed"
}

setup_nginx() {
    print_status "Configuring Nginx reverse proxy..."
    
    # Get server IP or ask for domain
    SERVER_IP=$(curl -s ifconfig.me)
    
    # Create Nginx configuration
    sudo tee /etc/nginx/sites-available/tgp-dues << EOF
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
    sudo ln -sf /etc/nginx/sites-available/tgp-dues /etc/nginx/sites-enabled/
    
    # Remove default site
    sudo rm -f /etc/nginx/sites-enabled/default
    
    # Test Nginx configuration
    sudo nginx -t
    
    # Restart Nginx
    sudo systemctl restart nginx
    
    print_success "Nginx configuration completed"
}

setup_firewall() {
    print_status "Configuring firewall..."
    
    # Enable UFW firewall
    sudo ufw --force enable
    
    # Allow SSH, HTTP, and HTTPS
    sudo ufw allow ssh
    sudo ufw allow 80
    sudo ufw allow 443
    
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
        return 1
    fi
    
    # Test HTTP response
    SERVER_IP=$(curl -s ifconfig.me)
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

cleanup() {
    print_status "Cleaning up..."
    sudo apt autoremove -y
    sudo apt autoclean
}

show_completion_info() {
    SERVER_IP=$(curl -s ifconfig.me)
    
    echo ""
    echo -e "${GREEN}============================================${NC}"
    echo -e "${GREEN}  TGP Dues Management System Deployed!${NC}"
    echo -e "${GREEN}============================================${NC}"
    echo ""
    echo -e "${BLUE}Application URL:${NC} http://$SERVER_IP"
    echo -e "${BLUE}Admin Login:${NC}"
    echo -e "  Username: treasurer"
    echo -e "  Password: password123"
    echo ""
    echo -e "${BLUE}Member Login Examples:${NC}"
    echo -e "  Username: juan.delacruz"
    echo -e "  Username: mark.santos"
    echo -e "  Username: paolo.rodriguez"
    echo -e "  Password: member123"
    echo ""
    echo -e "${BLUE}Database Credentials:${NC}"
    echo -e "  Database: $DB_NAME"
    echo -e "  Username: $DB_USER"
    echo -e "  Password: $DB_PASSWORD"
    echo ""
    echo -e "${BLUE}Useful Commands:${NC}"
    echo -e "  View logs: ${YELLOW}pm2 logs tgp-dues${NC}"
    echo -e "  Restart app: ${YELLOW}pm2 restart tgp-dues${NC}"
    echo -e "  Check status: ${YELLOW}pm2 status${NC}"
    echo ""
    echo -e "${YELLOW}Note: If you have a domain, update the Nginx configuration${NC}"
    echo -e "${YELLOW}in /etc/nginx/sites-available/tgp-dues${NC}"
    echo ""
}

main() {
    echo -e "${BLUE}"
    echo "=========================================="
    echo "  TGP Rahugan CBC Dues Management System"
    echo "  Ubuntu VPS Deployment Installer"
    echo "=========================================="
    echo -e "${NC}"
    
    check_root
    
    print_status "Starting deployment process..."
    
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
    cleanup
    
    show_completion_info
    
    print_success "Deployment completed successfully!"
}

# Handle script interruption
trap 'print_error "Script interrupted"; exit 1' INT TERM

# Run main function
main "$@"