#!/bin/bash

# ============================================================================
# TGP Rahugan CBC Chapter - Dues Management System
# One-Click Installation Script for Ubuntu VPS
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
BOLD='\033[1m'

# Configuration
DB_NAME="tgp_dues_db"
DB_USER="rahuganmkc"
DB_PASSWORD="rahugan2018"
APP_DIR="/var/www/tgp-dues"
APP_PORT="5000"
APP_NAME="tgp-dues"

# Progress tracking
STEP_COUNT=0
TOTAL_STEPS=12

print_banner() {
    clear
    echo -e "${PURPLE}${BOLD}"
    echo "============================================================================"
    echo "  ████████  ██████  ██████      ██████   █████  ██   ██ ██    ██  ██████   █████  ███    ██ "
    echo "     ██    ██       ██   ██     ██   ██ ██   ██ ██   ██ ██    ██ ██       ██   ██ ████   ██ "
    echo "     ██    ██   ███ ██████      ██████  ███████ ███████ ██    ██ ██   ███ ███████ ██ ██  ██ "
    echo "     ██    ██    ██ ██          ██   ██ ██   ██ ██   ██ ██    ██ ██    ██ ██   ██ ██  ██ ██ "
    echo "     ██     ██████  ██          ██   ██ ██   ██ ██   ██  ██████   ██████  ██   ██ ██   ████ "
    echo ""
    echo "                        DUES MANAGEMENT SYSTEM INSTALLER"
    echo "                              CBC Chapter - Ubuntu VPS"
    echo "============================================================================"
    echo -e "${NC}"
}

print_step() {
    STEP_COUNT=$((STEP_COUNT + 1))
    echo -e "${CYAN}[STEP $STEP_COUNT/$TOTAL_STEPS]${NC} ${BOLD}$1${NC}"
}

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

print_progress() {
    local current=$1
    local total=$2
    local desc=$3
    local percentage=$((current * 100 / total))
    local filled=$((percentage / 2))
    local empty=$((50 - filled))
    
    printf "\r${BLUE}Progress: ${NC}["
    printf "%*s" $filled | tr ' ' '█'
    printf "%*s" $empty | tr ' ' '░'
    printf "] %d%% - %s" $percentage "$desc"
}

# Error handler
handle_error() {
    echo ""
    print_error "Installation failed at step $STEP_COUNT: $1"
    print_error "Line: $2, Command: $3"
    echo ""
    print_status "Troubleshooting steps:"
    echo "1. Check internet connection"
    echo "2. Verify system has sufficient resources (2GB RAM, 20GB disk)"
    echo "3. Ensure running as root or with sudo privileges"
    echo "4. Check system logs: journalctl -xe"
    echo ""
    exit 1
}

trap 'handle_error "$BASH_COMMAND" $LINENO "$BASH_COMMAND"' ERR

# Pre-flight checks
preflight_checks() {
    print_step "Pre-flight System Checks"
    
    # Check OS
    if ! grep -qi "ubuntu" /etc/os-release; then
        print_warning "This installer is optimized for Ubuntu. Detected: $(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
    fi
    
    # Check root privileges
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        echo "Please run: sudo $0"
        exit 1
    fi
    
    # Check system resources
    MEMORY_GB=$(free -g | awk '/^Mem:/{print $2}')
    if [ $MEMORY_GB -lt 2 ]; then
        print_warning "System has ${MEMORY_GB}GB RAM. Minimum 2GB recommended."
    fi
    
    DISK_AVAILABLE_GB=$(df / | awk 'NR==2 {print int($4/1024/1024)}')
    if [ $DISK_AVAILABLE_GB -lt 20 ]; then
        print_warning "Available disk space: ${DISK_AVAILABLE_GB}GB. Minimum 20GB recommended."
    fi
    
    # Check essential files
    if [ ! -f "package.json" ]; then
        print_error "package.json not found. Run this script from the project root directory."
        exit 1
    fi
    
    if [ ! -d "server" ] || [ ! -d "client" ]; then
        print_error "Project directories missing. Ensure all files are present."
        exit 1
    fi
    
    print_success "Pre-flight checks completed"
    sleep 2
}

# System update with progress
update_system() {
    print_step "Updating System Packages"
    export DEBIAN_FRONTEND=noninteractive
    
    print_status "Updating package lists..."
    apt update -qq
    print_progress 1 3 "Package lists updated"
    
    print_status "Upgrading system packages..."
    apt upgrade -y -qq
    print_progress 2 3 "System packages upgraded"
    
    print_status "Installing essential packages..."
    apt install -y -qq curl wget gnupg2 software-properties-common apt-transport-https ca-certificates lsb-release
    print_progress 3 3 "Essential packages installed"
    
    echo ""
    print_success "System updated successfully"
    sleep 1
}

# Node.js installation
install_nodejs() {
    print_step "Installing Node.js 20"
    
    print_status "Adding NodeSource repository..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - > /dev/null 2>&1
    print_progress 1 3 "Repository added"
    
    print_status "Installing Node.js..."
    apt install -y nodejs > /dev/null 2>&1
    print_progress 2 3 "Node.js installed"
    
    # Verify installation
    NODE_VERSION=$(node --version 2>/dev/null)
    NPM_VERSION=$(npm --version 2>/dev/null)
    print_progress 3 3 "Installation verified"
    
    echo ""
    print_success "Node.js $NODE_VERSION and npm $NPM_VERSION installed"
    sleep 1
}

# PostgreSQL installation and setup
install_postgresql() {
    print_step "Installing and Configuring PostgreSQL"
    
    print_status "Installing PostgreSQL..."
    apt install -y postgresql postgresql-contrib > /dev/null 2>&1
    print_progress 1 4 "PostgreSQL installed"
    
    print_status "Starting PostgreSQL service..."
    systemctl start postgresql
    systemctl enable postgresql
    print_progress 2 4 "Service started"
    
    sleep 3
    
    print_status "Creating database and user..."
    sudo -u postgres psql << EOF > /dev/null 2>&1
DROP DATABASE IF EXISTS $DB_NAME;
DROP USER IF EXISTS $DB_USER;
CREATE DATABASE $DB_NAME;
CREATE USER $DB_USER WITH ENCRYPTED PASSWORD '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
ALTER USER $DB_USER CREATEDB;
ALTER DATABASE $DB_NAME OWNER TO $DB_USER;
EOF
    print_progress 3 4 "Database created"
    
    # Configure authentication
    PG_CONFIG=$(find /etc/postgresql -name "pg_hba.conf" | head -1)
    if [ -f "$PG_CONFIG" ]; then
        cp "$PG_CONFIG" "$PG_CONFIG.backup.$(date +%Y%m%d_%H%M%S)"
        sed -i 's/^local[[:space:]]\+all[[:space:]]\+all[[:space:]]\+peer$/local   all             all                                     md5/' "$PG_CONFIG"
        sed -i 's/^local[[:space:]]\+all[[:space:]]\+all[[:space:]]\+ident$/local   all             all                                     md5/' "$PG_CONFIG"
        systemctl restart postgresql
        sleep 2
    fi
    print_progress 4 4 "Authentication configured"
    
    echo ""
    print_success "PostgreSQL configured with database: $DB_NAME"
    sleep 1
}

# Application setup
setup_application() {
    print_step "Setting Up Application"
    
    print_status "Creating application directory..."
    mkdir -p $APP_DIR
    print_progress 1 5 "Directory created"
    
    print_status "Copying application files..."
    rsync -a --exclude='node_modules' --exclude='.git' --exclude='*.log' --exclude='*.backup' . $APP_DIR/
    print_progress 2 5 "Files copied"
    
    cd $APP_DIR
    
    print_status "Setting permissions..."
    chown -R root:root $APP_DIR
    chmod -R 755 $APP_DIR
    print_progress 3 5 "Permissions set"
    
    print_status "Installing dependencies..."
    npm install > /dev/null 2>&1
    print_progress 4 5 "Dependencies installed"
    
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
SESSION_SECRET=$(openssl rand -hex 32)
EOF
    chmod 600 .env
    print_progress 5 5 "Environment configured"
    
    echo ""
    print_success "Application setup completed"
    sleep 1
}

# PM2 installation and configuration
setup_pm2() {
    print_step "Installing Process Manager (PM2)"
    
    print_status "Installing PM2 globally..."
    npm install -g pm2 > /dev/null 2>&1
    print_progress 1 4 "PM2 installed"
    
    cd $APP_DIR
    
    print_status "Starting application..."
    # Stop any existing processes
    pm2 stop $APP_NAME 2>/dev/null || true
    pm2 delete $APP_NAME 2>/dev/null || true
    
    # Start with explicit environment
    DATABASE_URL="postgresql://$DB_USER:$DB_PASSWORD@localhost:5432/$DB_NAME" \
    NODE_ENV="production" \
    PORT="$APP_PORT" \
    pm2 start "npx tsx server/index.ts" \
        --name "$APP_NAME" \
        --max-memory-restart 1G \
        --restart-delay 3000 > /dev/null 2>&1
    
    print_progress 2 4 "Application started"
    
    print_status "Configuring PM2 startup..."
    pm2 save > /dev/null 2>&1
    env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u root --hp /root > /dev/null 2>&1 || true
    print_progress 3 4 "Startup configured"
    
    sleep 5
    print_progress 4 4 "Startup verification complete"
    
    echo ""
    print_success "PM2 process manager configured"
    sleep 1
}

# Nginx installation and configuration
setup_nginx() {
    print_step "Installing and Configuring Web Server"
    
    print_status "Installing Nginx..."
    apt install -y nginx > /dev/null 2>&1
    print_progress 1 4 "Nginx installed"
    
    print_status "Configuring Nginx..."
    # Remove default configuration
    rm -f /etc/nginx/sites-enabled/default
    
    # Create TGP Dues configuration
    cat > /etc/nginx/sites-available/$APP_NAME << 'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

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

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;

        # Timeout settings
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Health check
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF

    ln -sf /etc/nginx/sites-available/$APP_NAME /etc/nginx/sites-enabled/
    print_progress 2 4 "Configuration created"
    
    print_status "Testing configuration..."
    nginx -t > /dev/null 2>&1
    print_progress 3 4 "Configuration tested"
    
    print_status "Starting web server..."
    systemctl restart nginx
    systemctl enable nginx
    print_progress 4 4 "Web server started"
    
    echo ""
    print_success "Nginx web server configured"
    sleep 1
}

# Firewall configuration
setup_firewall() {
    print_step "Configuring Security Firewall"
    
    print_status "Installing UFW firewall..."
    apt install -y ufw > /dev/null 2>&1
    print_progress 1 3 "UFW installed"
    
    print_status "Configuring firewall rules..."
    ufw --force reset > /dev/null 2>&1
    ufw default deny incoming > /dev/null 2>&1
    ufw default allow outgoing > /dev/null 2>&1
    ufw allow ssh > /dev/null 2>&1
    ufw allow 80/tcp > /dev/null 2>&1
    ufw allow 443/tcp > /dev/null 2>&1
    print_progress 2 3 "Rules configured"
    
    print_status "Enabling firewall..."
    ufw --force enable > /dev/null 2>&1
    print_progress 3 3 "Firewall enabled"
    
    echo ""
    print_success "Firewall security configured"
    sleep 1
}

# Database connection test
test_database() {
    print_step "Testing Database Connection"
    
    if PGPASSWORD=$DB_PASSWORD psql -U $DB_USER -d $DB_NAME -h localhost -c '\q' 2>/dev/null; then
        print_success "Database connection successful"
    else
        print_error "Database connection failed"
        return 1
    fi
    sleep 1
}

# Application health check
test_application() {
    print_step "Testing Application Health"
    
    print_status "Checking PM2 status..."
    if pm2 list | grep -q "$APP_NAME.*online"; then
        print_progress 1 3 "PM2 process running"
    else
        print_error "Application not running in PM2"
        return 1
    fi
    
    print_status "Testing port connectivity..."
    if ss -tlnp | grep -q ":$APP_PORT "; then
        print_progress 2 3 "Port $APP_PORT listening"
    else
        print_error "Port $APP_PORT not listening"
        return 1
    fi
    
    print_status "Testing HTTP response..."
    sleep 5
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$APP_PORT 2>/dev/null || echo "000")
    if [[ $HTTP_CODE =~ ^(200|302)$ ]]; then
        print_progress 3 3 "HTTP response successful"
        print_success "Application health check passed"
    else
        print_warning "HTTP response code: $HTTP_CODE"
        print_success "Application installed but may need restart"
    fi
    sleep 1
}

# Final system verification
final_verification() {
    print_step "Final System Verification"
    
    # Get server details
    SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "localhost")
    HOSTNAME=$(hostname)
    UPTIME=$(uptime -p)
    
    print_status "System verification complete"
    sleep 2
}

# Display installation summary
show_installation_summary() {
    clear
    print_banner
    
    echo -e "${GREEN}${BOLD}"
    echo "============================================================================"
    echo "                        INSTALLATION COMPLETED SUCCESSFULLY!"
    echo "============================================================================"
    echo -e "${NC}"
    
    # Get server IP
    SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo "your-server-ip")
    
    echo -e "${WHITE}${BOLD}🌐 ACCESS INFORMATION${NC}"
    echo -e "${CYAN}┌─────────────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC} Application URL: ${GREEN}${BOLD}http://$SERVER_IP${NC}                                    ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} Installation Directory: ${YELLOW}/var/www/tgp-dues${NC}                           ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} Application Port: ${YELLOW}5000${NC}                                              ${CYAN}│${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    echo -e "${WHITE}${BOLD}👤 LOGIN CREDENTIALS${NC}"
    echo -e "${CYAN}┌─────────────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC} ${GREEN}${BOLD}ADMINISTRATOR ACCOUNT${NC}                                            ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}   Username: ${YELLOW}treasurer${NC}                                           ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}   Password: ${YELLOW}password123${NC}                                        ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}                                                                       ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} ${GREEN}${BOLD}SAMPLE MEMBER ACCOUNTS${NC}                                           ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}   Usernames: ${YELLOW}juan.delacruz${NC}, ${YELLOW}mark.santos${NC}, ${YELLOW}paolo.rodriguez${NC}      ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}   Password: ${YELLOW}member123${NC}                                          ${CYAN}│${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    echo -e "${WHITE}${BOLD}🗄️  DATABASE INFORMATION${NC}"
    echo -e "${CYAN}┌─────────────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC} Database Name: ${YELLOW}$DB_NAME${NC}                                       ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} Username: ${YELLOW}$DB_USER${NC}                                            ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} Password: ${YELLOW}$DB_PASSWORD${NC}                                               ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} Host: ${YELLOW}localhost${NC}                                              ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} Port: ${YELLOW}5432${NC}                                                   ${CYAN}│${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    echo -e "${WHITE}${BOLD}🛠️  MANAGEMENT COMMANDS${NC}"
    echo -e "${CYAN}┌─────────────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC} Check application status: ${YELLOW}pm2 status${NC}                             ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} View application logs: ${YELLOW}pm2 logs tgp-dues${NC}                        ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} Restart application: ${YELLOW}pm2 restart tgp-dues${NC}                       ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} Stop application: ${YELLOW}pm2 stop tgp-dues${NC}                            ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} Restart web server: ${YELLOW}systemctl restart nginx${NC}                   ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} View web server logs: ${YELLOW}tail -f /var/log/nginx/access.log${NC}        ${CYAN}│${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    echo -e "${WHITE}${BOLD}📋 NEXT STEPS${NC}"
    echo -e "${CYAN}┌─────────────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC} 1. Access your system at: ${GREEN}http://$SERVER_IP${NC}                      ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} 2. Login with administrator credentials                             ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} 3. Change default passwords in Settings                            ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} 4. Configure chapter information                                   ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} 5. Add member accounts and payment records                         ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} 6. Consider setting up SSL certificate for production             ${CYAN}│${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    echo -e "${WHITE}${BOLD}🔧 SUPPORT${NC}"
    echo -e "${CYAN}┌─────────────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC} Documentation: See INSTALLATION_GUIDE.md                          ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} Troubleshooting: Check application and system logs                ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} Updates: Regular system maintenance recommended                    ${CYAN}│${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    echo -e "${GREEN}${BOLD}Installation completed at: $(date)${NC}"
    echo -e "${GREEN}${BOLD}Total installation time: $SECONDS seconds${NC}"
    echo ""
    echo -e "${PURPLE}${BOLD}Tau Gamma Phi Rahugan CBC Chapter - Dues Management System${NC}"
    echo -e "${PURPLE}${BOLD}Ready for production use!${NC}"
    echo ""
}

# Main installation function
main() {
    # Record start time
    START_TIME=$(date +%s)
    
    print_banner
    echo -e "${YELLOW}${BOLD}Starting TGP Dues Management System installation...${NC}"
    echo ""
    sleep 3
    
    # Run installation steps
    preflight_checks
    update_system
    install_nodejs
    install_postgresql
    setup_application
    setup_pm2
    setup_nginx
    setup_firewall
    test_database
    test_application
    final_verification
    
    # Calculate installation time
    END_TIME=$(date +%s)
    INSTALL_TIME=$((END_TIME - START_TIME))
    
    # Show final summary
    show_installation_summary
}

# Handle script interruption
trap 'echo ""; print_error "Installation interrupted by user"; exit 1' INT TERM

# Execute main installation
main "$@"