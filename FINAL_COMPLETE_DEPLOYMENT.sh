#!/bin/bash

# ============================================================================
# TGP Rahugan CBC Chapter - Dues Management System
# COMPLETE DEPLOYMENT SCRIPT - ALL ISSUES RESOLVED
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
APP_DIR="/root/tgp-dues"
APP_PORT="5000"
APP_NAME="tgp-dues"

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
    echo "                        COMPLETE DEPLOYMENT - ALL ISSUES RESOLVED"
    echo "                              CBC Chapter - Ubuntu VPS"
    echo "============================================================================"
    echo -e "${NC}"
}

log_step() {
    echo -e "${CYAN}[STEP]${NC} ${BOLD}$1${NC}"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Error handler
handle_error() {
    echo ""
    log_error "Deployment failed at: $1"
    echo "Check logs and try again"
    exit 1
}

trap 'handle_error "$BASH_COMMAND"' ERR

# System dependencies
install_dependencies() {
    log_step "Installing system dependencies"
    
    # Update system
    apt update
    apt upgrade -y
    
    # Install required packages
    apt install -y curl wget git nodejs npm postgresql postgresql-contrib nginx htop
    
    # Install PM2 globally
    npm install -g pm2
    
    # Enable PostgreSQL
    systemctl enable postgresql
    systemctl start postgresql
    
    log_success "System dependencies installed"
}

# Database setup
setup_database() {
    log_step "Setting up PostgreSQL database"
    
    # Create database user and database
    sudo -u postgres psql << EOF
CREATE USER $DB_USER WITH ENCRYPTED PASSWORD '$DB_PASSWORD';
CREATE DATABASE $DB_NAME OWNER $DB_USER;
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
ALTER USER $DB_USER CREATEDB;
EOF

    # Test connection
    PGPASSWORD=$DB_PASSWORD psql -U $DB_USER -d $DB_NAME -h localhost -c "SELECT version();"
    
    log_success "Database setup completed"
}

# Application setup
setup_application() {
    log_step "Setting up application directory"
    
    # Create application directory
    mkdir -p $APP_DIR
    cd $APP_DIR
    
    # Setup environment
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
    log_success "Application environment configured"
}

# Database schema
create_database_schema() {
    log_step "Creating database schema"
    
    PGPASSWORD=$DB_PASSWORD psql -U $DB_USER -d $DB_NAME -h localhost << 'EOF'
-- Users table for admin accounts
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    password VARCHAR(255) NOT NULL,
    position VARCHAR(100) NOT NULL,
    account_type VARCHAR(20) DEFAULT 'admin',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Members table
CREATE TABLE IF NOT EXISTS members (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    alexis_name VARCHAR(100),
    address TEXT NOT NULL,
    batch_number VARCHAR(50) UNIQUE,
    batch_name VARCHAR(100),
    initiation_date TIMESTAMP NOT NULL,
    member_type VARCHAR(20) DEFAULT 'pure_blooded',
    welcoming_date TIMESTAMP,
    status VARCHAR(20) DEFAULT 'active',
    username VARCHAR(50) UNIQUE,
    password VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Payments table
CREATE TABLE IF NOT EXISTS payments (
    id SERIAL PRIMARY KEY,
    member_id INTEGER REFERENCES members(id),
    amount DECIMAL(10,2) NOT NULL,
    payment_date TIMESTAMP NOT NULL,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Chapter info table
CREATE TABLE IF NOT EXISTS chapter_info (
    id SERIAL PRIMARY KEY,
    chapter_name VARCHAR(200) NOT NULL,
    chapter_address TEXT NOT NULL,
    contact_email VARCHAR(100) NOT NULL,
    contact_phone VARCHAR(20) NOT NULL,
    treasurer_name VARCHAR(100) NOT NULL,
    treasurer_email VARCHAR(100) NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Activities table
CREATE TABLE IF NOT EXISTS activities (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    target_amount DECIMAL(10,2),
    activity_date TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Contributions table
CREATE TABLE IF NOT EXISTS contributions (
    id SERIAL PRIMARY KEY,
    activity_id INTEGER REFERENCES activities(id),
    member_id INTEGER REFERENCES members(id),
    amount DECIMAL(10,2) NOT NULL,
    contribution_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert default admin account
INSERT INTO users (username, name, password, position, account_type) 
VALUES ('treasurer', 'Chapter Treasurer', 'password123', 'Treasurer', 'admin')
ON CONFLICT (username) DO UPDATE SET
    password = 'password123',
    account_type = 'admin';

-- Insert sample member accounts
INSERT INTO members (name, address, initiation_date, member_type, username, password, batch_number)
VALUES 
    ('Juan Dela Cruz', '123 Main St, Manila', '2020-01-01', 'pure_blooded', 'juan.delacruz', 'member123', '2020-001'),
    ('Mark Santos', '456 Oak Ave, Quezon City', '2020-02-01', 'pure_blooded', 'mark.santos', 'member123', '2020-002'),
    ('Paolo Rodriguez', '789 Pine St, Makati', '2020-03-01', 'welcome', 'paolo.rodriguez', 'member123', '2020-003')
ON CONFLICT (username) DO UPDATE SET password = 'member123';

-- Insert default chapter info
INSERT INTO chapter_info (chapter_name, chapter_address, contact_email, contact_phone, treasurer_name, treasurer_email)
VALUES ('Tau Gamma Phi Rahugan CBC Chapter', 'CBC Building, Philippines', 'treasurer@tgp-rahugan.org', '+63 912 345 6789', 'Chapter Treasurer', 'treasurer@tgp-rahugan.org')
ON CONFLICT DO NOTHING;

-- Verify setup
SELECT 'Admin Accounts:' as info;
SELECT username, name, account_type FROM users;
SELECT 'Member Accounts:' as info;
SELECT username, name, member_type FROM members WHERE username IS NOT NULL;
EOF

    log_success "Database schema created"
}

# Build application
build_application() {
    log_step "Building React application"
    
    cd $APP_DIR
    
    # Install dependencies
    npm install
    
    # Build the application
    npm run build
    
    # Setup public directory
    rm -rf server/public
    mkdir -p server/public
    
    # Copy build files
    if [ -d "dist/public" ]; then
        cp -r dist/public/* server/public/
    elif [ -d "dist" ]; then
        cp -r dist/* server/public/
    else
        log_error "Build failed - no dist directory found"
        exit 1
    fi
    
    # Verify critical files
    if [ ! -f "server/public/index.html" ]; then
        log_error "index.html not found in build output"
        exit 1
    fi
    
    log_success "Application built successfully"
}

# Start application
start_application() {
    log_step "Starting application with PM2"
    
    cd $APP_DIR
    
    # Stop any existing instance
    pm2 stop $APP_NAME 2>/dev/null || true
    pm2 delete $APP_NAME 2>/dev/null || true
    
    # Start application
    DATABASE_URL="postgresql://$DB_USER:$DB_PASSWORD@localhost:5432/$DB_NAME" \
    NODE_ENV="production" \
    PORT="$APP_PORT" \
    PGHOST="localhost" \
    PGPORT="5432" \
    PGUSER="$DB_USER" \
    PGPASSWORD="$DB_PASSWORD" \
    PGDATABASE="$DB_NAME" \
    pm2 start "npx tsx server/index.ts" \
        --name "$APP_NAME" \
        --max-memory-restart 1G \
        --restart-delay 3000
    
    # Save PM2 configuration
    pm2 save
    pm2 startup
    
    log_success "Application started"
}

# Configure Nginx
setup_nginx() {
    log_step "Configuring Nginx reverse proxy"
    
    cat > /etc/nginx/sites-available/tgp-dues << EOF
server {
    listen 80;
    server_name _;
    
    location / {
        proxy_pass http://127.0.0.1:$APP_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }
}
EOF

    # Enable site
    ln -sf /etc/nginx/sites-available/tgp-dues /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    
    # Test and reload nginx
    nginx -t
    systemctl reload nginx
    systemctl enable nginx
    
    log_success "Nginx configured"
}

# Test deployment
test_deployment() {
    log_step "Testing deployment"
    
    sleep 10
    
    # Test PM2 status
    if ! pm2 list | grep -q "$APP_NAME.*online"; then
        log_error "Application not running in PM2"
        pm2 logs $APP_NAME --lines 20
        exit 1
    fi
    
    # Test port
    if ! ss -tlnp | grep -q ":$APP_PORT "; then
        log_error "Application port not listening"
        exit 1
    fi
    
    # Test HTTP response
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$APP_PORT || echo "000")
    if [[ ! $HTTP_CODE =~ ^(200|302)$ ]]; then
        log_error "HTTP response code: $HTTP_CODE"
        exit 1
    fi
    
    # Test admin authentication
    ADMIN_TEST=$(curl -s -X POST http://localhost:$APP_PORT/api/auth/login \
        -H "Content-Type: application/json" \
        -d '{"username":"treasurer","password":"password123","accountType":"admin"}' || echo "error")
    
    if [[ $ADMIN_TEST == *"user"* && $ADMIN_TEST == *"treasurer"* ]]; then
        log_success "Admin authentication working"
    else
        log_error "Admin authentication failed: $ADMIN_TEST"
        exit 1
    fi
    
    # Test member authentication
    MEMBER_TEST=$(curl -s -X POST http://localhost:$APP_PORT/api/auth/login \
        -H "Content-Type: application/json" \
        -d '{"username":"juan.delacruz","password":"member123","accountType":"member"}' || echo "error")
    
    if [[ $MEMBER_TEST == *"user"* && $MEMBER_TEST == *"Juan"* ]]; then
        log_success "Member authentication working"
    else
        log_error "Member authentication failed: $MEMBER_TEST"
        exit 1
    fi
    
    log_success "All tests passed"
}

# Display results
show_completion() {
    SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo "localhost")
    
    clear
    print_banner
    
    echo -e "${GREEN}${BOLD}"
    echo "============================================================================"
    echo "                        DEPLOYMENT COMPLETED SUCCESSFULLY!"
    echo "============================================================================"
    echo -e "${NC}"
    
    echo -e "${WHITE}${BOLD}🌐 ACCESS INFORMATION${NC}"
    echo -e "${CYAN}┌─────────────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC} Application URL: ${GREEN}${BOLD}http://$SERVER_IP${NC}                                    ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} Direct Port: ${GREEN}${BOLD}http://$SERVER_IP:$APP_PORT${NC}                               ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} Status: ${GREEN}✓ FULLY OPERATIONAL${NC}                                   ${CYAN}│${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    echo -e "${WHITE}${BOLD}👤 LOGIN CREDENTIALS${NC}"
    echo -e "${CYAN}┌─────────────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC} ${GREEN}${BOLD}ADMINISTRATOR ACCESS${NC}                                            ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}   Username: ${YELLOW}treasurer${NC}                                           ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}   Password: ${YELLOW}password123${NC}                                        ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}                                                                       ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} ${GREEN}${BOLD}MEMBER PORTAL ACCESS${NC}                                             ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}   Sample: ${YELLOW}juan.delacruz${NC} / ${YELLOW}member123${NC}                              ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}   Sample: ${YELLOW}mark.santos${NC} / ${YELLOW}member123${NC}                                ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}   Sample: ${YELLOW}paolo.rodriguez${NC} / ${YELLOW}member123${NC}                           ${CYAN}│${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    echo -e "${WHITE}${BOLD}⚙️  SYSTEM STATUS${NC}"
    echo -e "${CYAN}┌─────────────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC} Authentication: ${GREEN}✅ FIXED & TESTED${NC}                              ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} React Interface: ${GREEN}✅ ACTIVE${NC}                                    ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} Database: ${GREEN}✅ CONNECTED${NC}                                        ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} PM2 Process: ${GREEN}✅ RUNNING${NC}                                       ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} Nginx Proxy: ${GREEN}✅ CONFIGURED${NC}                                   ${CYAN}│${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    echo -e "${WHITE}${BOLD}🛠️  MANAGEMENT COMMANDS${NC}"
    echo -e "${CYAN}┌─────────────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC} Application Status: ${YELLOW}pm2 status${NC}                                    ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} View Logs: ${YELLOW}pm2 logs $APP_NAME${NC}                                     ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} Restart App: ${YELLOW}pm2 restart $APP_NAME${NC}                                ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} Database Access: ${YELLOW}PGPASSWORD=$DB_PASSWORD psql -U $DB_USER -d $DB_NAME${NC}         ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} Nginx Status: ${YELLOW}systemctl status nginx${NC}                            ${CYAN}│${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    echo -e "${GREEN}${BOLD}🎉 TGP Rahugan CBC Chapter Dues Management System is now LIVE!${NC}"
    echo -e "${WHITE}All authentication issues resolved. Production ready.${NC}"
    echo ""
}

# Main execution
main() {
    print_banner
    sleep 3
    
    install_dependencies
    setup_database
    setup_application
    create_database_schema
    build_application
    start_application
    setup_nginx
    test_deployment
    show_completion
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (use sudo)" 
   exit 1
fi

# Run deployment
main "$@"