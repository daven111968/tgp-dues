#!/bin/bash

# ============================================================================
# TGP Rahugan CBC Chapter - Dues Management System
# Production Deployment Script for Ubuntu VPS
# Version: 1.0 Final
# ============================================================================

set -e

# Colors and formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Configuration
DB_NAME="tgp_dues_db"
DB_USER="rahuganmkc"
DB_PASSWORD="rahugan2018"
APP_DIR="/var/www/tgp-dues"
APP_PORT="5000"
APP_NAME="tgp-dues"

# Logging functions
log_header() {
    echo -e "${WHITE}$1${NC}"
}

log_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Error handler
handle_error() {
    log_error "Deployment failed at line $1"
    log_error "Command: $2"
    log_error "Exit code: $3"
    echo ""
    log_info "Troubleshooting steps:"
    echo "1. Check the error message above"
    echo "2. Verify you're running as root or with sudo"
    echo "3. Ensure all project files are in the current directory"
    echo "4. Check system resources (disk space, memory)"
    echo ""
    exit 1
}

trap 'handle_error $LINENO "$BASH_COMMAND" $?' ERR

# Pre-flight checks
preflight_checks() {
    log_header "============================================================================"
    log_header "  TGP RAHUGAN CBC CHAPTER - DUES MANAGEMENT SYSTEM"
    log_header "  Production Deployment Script"
    log_header "============================================================================"
    echo ""
    
    log_step "Running pre-flight checks..."
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root or with sudo privileges"
        exit 1
    fi
    
    # Check Ubuntu version
    if ! grep -q "Ubuntu" /etc/os-release; then
        log_warning "This script is designed for Ubuntu. Proceeding anyway..."
    fi
    
    # Check essential files
    CURRENT_DIR=$(pwd)
    log_info "Current directory: $CURRENT_DIR"
    
    if [ ! -f "package.json" ]; then
        log_error "package.json not found. Run this script from the project root directory."
        exit 1
    fi
    
    if [ ! -d "server" ]; then
        log_error "server directory not found. Ensure all project files are present."
        exit 1
    fi
    
    if [ ! -d "client" ]; then
        log_error "client directory not found. Ensure all project files are present."
        exit 1
    fi
    
    # Check disk space (minimum 2GB free)
    AVAILABLE_SPACE=$(df / | awk 'NR==2 {print $4}')
    if [ $AVAILABLE_SPACE -lt 2097152 ]; then
        log_warning "Low disk space detected. At least 2GB free space recommended."
    fi
    
    log_success "Pre-flight checks completed"
    echo ""
}

# System update
update_system() {
    log_step "Updating system packages..."
    export DEBIAN_FRONTEND=noninteractive
    apt update -qq
    apt upgrade -y -qq
    apt install -y curl wget gnupg2 software-properties-common apt-transport-https ca-certificates
    log_success "System updated successfully"
}

# Install Node.js
install_nodejs() {
    log_step "Installing Node.js 20..."
    
    # Remove existing Node.js installations
    apt remove -y nodejs npm 2>/dev/null || true
    
    # Install Node.js 20
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt install -y nodejs
    
    # Verify installation
    NODE_VERSION=$(node --version 2>/dev/null || echo "failed")
    NPM_VERSION=$(npm --version 2>/dev/null || echo "failed")
    
    if [[ $NODE_VERSION == "failed" ]] || [[ $NPM_VERSION == "failed" ]]; then
        log_error "Node.js installation failed"
        exit 1
    fi
    
    log_success "Node.js $NODE_VERSION and npm $NPM_VERSION installed"
}

# Install PostgreSQL
install_postgresql() {
    log_step "Installing PostgreSQL..."
    
    apt install -y postgresql postgresql-contrib
    systemctl start postgresql
    systemctl enable postgresql
    
    # Wait for PostgreSQL to be ready
    sleep 5
    
    # Check if PostgreSQL is running
    if ! systemctl is-active --quiet postgresql; then
        log_error "PostgreSQL failed to start"
        exit 1
    fi
    
    log_success "PostgreSQL installed and running"
}

# Setup database
setup_database() {
    log_step "Setting up database..."
    
    # Change to PostgreSQL directory to avoid permission issues
    cd /tmp
    
    # Drop database if exists and recreate
    sudo -u postgres psql -c "DROP DATABASE IF EXISTS $DB_NAME;" 2>/dev/null || true
    sudo -u postgres psql -c "DROP USER IF EXISTS $DB_USER;" 2>/dev/null || true
    
    # Create database and user
    sudo -u postgres createdb $DB_NAME
    sudo -u postgres psql -c "CREATE USER $DB_USER WITH ENCRYPTED PASSWORD '$DB_PASSWORD';"
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"
    sudo -u postgres psql -c "ALTER USER $DB_USER CREATEDB;"
    sudo -u postgres psql -c "ALTER DATABASE $DB_NAME OWNER TO $DB_USER;"
    
    log_success "Database created: $DB_NAME"
    log_success "Database user created: $DB_USER"
}

# Configure PostgreSQL authentication
configure_postgresql() {
    log_step "Configuring PostgreSQL authentication..."
    
    # Find PostgreSQL configuration file
    PG_CONFIG=""
    for version in $(ls /etc/postgresql/ 2>/dev/null); do
        if [ -f "/etc/postgresql/$version/main/pg_hba.conf" ]; then
            PG_CONFIG="/etc/postgresql/$version/main/pg_hba.conf"
            break
        fi
    done
    
    if [ -z "$PG_CONFIG" ]; then
        PG_CONFIG=$(find /etc/postgresql -name "pg_hba.conf" 2>/dev/null | head -1)
    fi
    
    if [ -f "$PG_CONFIG" ]; then
        log_info "Found PostgreSQL config: $PG_CONFIG"
        cp "$PG_CONFIG" "$PG_CONFIG.backup.$(date +%Y%m%d_%H%M%S)"
        
        # Update authentication method for local connections
        sed -i 's/^local[[:space:]]\+all[[:space:]]\+all[[:space:]]\+peer$/local   all             all                                     md5/' "$PG_CONFIG"
        sed -i 's/^local[[:space:]]\+all[[:space:]]\+all[[:space:]]\+ident$/local   all             all                                     md5/' "$PG_CONFIG"
        
        systemctl restart postgresql
        sleep 3
        
        log_success "PostgreSQL authentication configured"
    else
        log_warning "PostgreSQL config file not found, using default settings"
    fi
    
    # Test database connection
    if PGPASSWORD=$DB_PASSWORD psql -U $DB_USER -d $DB_NAME -h localhost -c '\q' 2>/dev/null; then
        log_success "Database connection test successful"
    else
        log_warning "Database connection test failed, but continuing..."
    fi
}

# Install PM2
install_pm2() {
    log_step "Installing PM2 process manager..."
    npm install -g pm2@latest
    
    # Verify PM2 installation
    if ! command -v pm2 &> /dev/null; then
        log_error "PM2 installation failed"
        exit 1
    fi
    
    log_success "PM2 installed successfully"
}

# Setup application
setup_application() {
    log_step "Setting up application..."
    
    # Create application directory
    mkdir -p $APP_DIR
    log_info "Created directory: $APP_DIR"
    
    # Copy application files
    log_info "Copying application files..."
    rsync -av --exclude='node_modules' --exclude='.git' --exclude='*.log' . $APP_DIR/
    
    cd $APP_DIR
    
    # Set proper permissions
    chown -R root:root $APP_DIR
    chmod -R 755 $APP_DIR
    
    # Install dependencies
    log_info "Installing application dependencies..."
    npm ci --only=production
    
    log_success "Application files copied and dependencies installed"
}

# Create environment configuration
create_environment() {
    log_step "Creating environment configuration..."
    
    cd $APP_DIR
    
    cat > .env << EOF
# Database Configuration
DATABASE_URL=postgresql://$DB_USER:$DB_PASSWORD@localhost:5432/$DB_NAME
PGHOST=localhost
PGPORT=5432
PGUSER=$DB_USER
PGPASSWORD=$DB_PASSWORD
PGDATABASE=$DB_NAME

# Application Configuration
NODE_ENV=production
PORT=$APP_PORT

# Security
SESSION_SECRET=$(openssl rand -hex 32)
EOF
    
    chmod 600 .env
    log_success "Environment configuration created"
}

# Setup PM2 application
setup_pm2_app() {
    log_step "Setting up PM2 application..."
    
    cd $APP_DIR
    
    # Stop and delete existing processes
    pm2 stop $APP_NAME 2>/dev/null || true
    pm2 delete $APP_NAME 2>/dev/null || true
    
    # Start application with PM2
    pm2 start "npx tsx server/index.ts" \
        --name "$APP_NAME" \
        --max-memory-restart 1G \
        --restart-delay 3000 \
        --exp-backoff-restart-delay 100 \
        --max-restarts 10
    
    # Wait for application to start
    sleep 5
    
    # Check if application started successfully
    if pm2 list | grep -q "$APP_NAME.*online"; then
        log_success "Application started successfully with PM2"
    else
        log_error "Application failed to start"
        pm2 logs $APP_NAME --lines 20
        exit 1
    fi
    
    # Save PM2 configuration
    pm2 save
    
    # Setup PM2 startup script
    pm2 startup systemd -u root --hp /root
    
    log_success "PM2 configuration completed"
}

# Install and configure Nginx
setup_nginx() {
    log_step "Installing and configuring Nginx..."
    
    apt install -y nginx
    systemctl start nginx
    systemctl enable nginx
    
    # Get server IP
    SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "localhost")
    
    # Create Nginx configuration
    cat > /etc/nginx/sites-available/$APP_NAME << EOF
server {
    listen 80;
    server_name $SERVER_IP _;
    
    # Security headers
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options DENY;
    add_header X-XSS-Protection "1; mode=block";
    add_header Referrer-Policy "strict-origin-when-cross-origin";
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
    
    # Rate limiting
    limit_req_zone \$binary_remote_addr zone=app:10m rate=10r/s;
    
    location / {
        limit_req zone=app burst=20 nodelay;
        
        proxy_pass http://localhost:$APP_PORT;
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
        
        # Buffer settings
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
        proxy_busy_buffers_size 8k;
    }
    
    # Static file caching
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        proxy_pass http://localhost:$APP_PORT;
    }
}
EOF
    
    # Enable site and disable default
    ln -sf /etc/nginx/sites-available/$APP_NAME /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    
    # Test Nginx configuration
    if nginx -t; then
        systemctl reload nginx
        log_success "Nginx configured and reloaded"
    else
        log_error "Nginx configuration test failed"
        exit 1
    fi
}

# Configure firewall
setup_firewall() {
    log_step "Configuring firewall..."
    
    # Install and configure UFW
    apt install -y ufw
    
    # Reset UFW to defaults
    ufw --force reset
    
    # Set default policies
    ufw default deny incoming
    ufw default allow outgoing
    
    # Allow specific services
    ufw allow ssh
    ufw allow 80/tcp
    ufw allow 443/tcp
    
    # Enable firewall
    ufw --force enable
    
    log_success "Firewall configured"
}

# Run deployment tests
run_tests() {
    log_step "Running deployment tests..."
    
    # Test 1: PM2 Status
    if pm2 list | grep -q "$APP_NAME.*online"; then
        log_success "✓ PM2 application is running"
        PM2_STATUS="✓ Online"
    else
        log_error "✗ PM2 application not running"
        PM2_STATUS="✗ Failed"
    fi
    
    # Test 2: Application HTTP Response
    sleep 5
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$APP_PORT || echo "000")
    if [[ $HTTP_CODE =~ ^(200|302|301)$ ]]; then
        log_success "✓ Application responding (HTTP $HTTP_CODE)"
        HTTP_STATUS="✓ Responding"
    else
        log_warning "⚠ Application response code: $HTTP_CODE"
        HTTP_STATUS="⚠ Check logs"
    fi
    
    # Test 3: Database Connection
    if PGPASSWORD=$DB_PASSWORD psql -U $DB_USER -d $DB_NAME -h localhost -c '\q' 2>/dev/null; then
        log_success "✓ Database connection successful"
        DB_STATUS="✓ Connected"
    else
        log_warning "⚠ Database connection failed"
        DB_STATUS="⚠ Check config"
    fi
    
    # Test 4: Nginx Status
    if systemctl is-active --quiet nginx; then
        log_success "✓ Nginx is running"
        NGINX_STATUS="✓ Running"
    else
        log_error "✗ Nginx not running"
        NGINX_STATUS="✗ Failed"
    fi
    
    # Test 5: Port Availability
    if ss -tlnp | grep -q ":$APP_PORT "; then
        log_success "✓ Application port $APP_PORT is listening"
        PORT_STATUS="✓ Listening"
    else
        log_warning "⚠ Port $APP_PORT not listening"
        PORT_STATUS="⚠ Not available"
    fi
}

# Display final information
show_deployment_summary() {
    echo ""
    log_header "============================================================================"
    log_header "  DEPLOYMENT COMPLETED SUCCESSFULLY!"
    log_header "============================================================================"
    echo ""
    
    echo -e "${WHITE}Application Information:${NC}"
    echo -e "  URL: ${GREEN}http://$SERVER_IP${NC}"
    echo -e "  Directory: ${CYAN}$APP_DIR${NC}"
    echo -e "  Port: ${CYAN}$APP_PORT${NC}"
    echo ""
    
    echo -e "${WHITE}System Status:${NC}"
    echo -e "  PM2 Application: $PM2_STATUS"
    echo -e "  HTTP Response: $HTTP_STATUS"
    echo -e "  Database: $DB_STATUS"
    echo -e "  Nginx: $NGINX_STATUS"
    echo -e "  Port Status: $PORT_STATUS"
    echo ""
    
    echo -e "${WHITE}Login Credentials:${NC}"
    echo -e "  ${GREEN}Administrator Account:${NC}"
    echo -e "    Username: ${YELLOW}treasurer${NC}"
    echo -e "    Password: ${YELLOW}password123${NC}"
    echo ""
    echo -e "  ${GREEN}Sample Member Accounts:${NC}"
    echo -e "    Usernames: ${YELLOW}juan.delacruz${NC}, ${YELLOW}mark.santos${NC}, ${YELLOW}paolo.rodriguez${NC}"
    echo -e "    Password: ${YELLOW}member123${NC}"
    echo ""
    
    echo -e "${WHITE}Database Information:${NC}"
    echo -e "  Database: ${CYAN}$DB_NAME${NC}"
    echo -e "  Username: ${CYAN}$DB_USER${NC}"
    echo -e "  Password: ${CYAN}$DB_PASSWORD${NC}"
    echo ""
    
    echo -e "${WHITE}Management Commands:${NC}"
    echo -e "  Check application status: ${YELLOW}pm2 status${NC}"
    echo -e "  View application logs: ${YELLOW}pm2 logs $APP_NAME${NC}"
    echo -e "  Restart application: ${YELLOW}pm2 restart $APP_NAME${NC}"
    echo -e "  Stop application: ${YELLOW}pm2 stop $APP_NAME${NC}"
    echo -e "  View Nginx logs: ${YELLOW}tail -f /var/log/nginx/access.log${NC}"
    echo -e "  Check database: ${YELLOW}PGPASSWORD=$DB_PASSWORD psql -U $DB_USER -d $DB_NAME -h localhost${NC}"
    echo ""
    
    echo -e "${WHITE}Next Steps:${NC}"
    echo -e "  1. Access your application at: ${GREEN}http://$SERVER_IP${NC}"
    echo -e "  2. Login with administrator credentials"
    echo -e "  3. Configure chapter information in settings"
    echo -e "  4. Add member accounts and payment records"
    echo -e "  5. Consider setting up SSL certificate for production use"
    echo ""
    
    log_header "Deployment completed at $(date)"
    log_header "============================================================================"
}

# Main deployment function
main() {
    preflight_checks
    update_system
    install_nodejs
    install_postgresql
    setup_database
    configure_postgresql
    install_pm2
    setup_application
    create_environment
    setup_pm2_app
    setup_nginx
    setup_firewall
    run_tests
    show_deployment_summary
}

# Handle script interruption
trap 'log_error "Deployment interrupted by user"; exit 1' INT TERM

# Execute main deployment
main "$@"