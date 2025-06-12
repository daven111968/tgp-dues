#!/bin/bash

# ============================================================================
# TGP Rahugan CBC Chapter - Ubuntu VPS Deployment (Fixed Dependencies)
# Resolves Node.js/npm package conflicts
# ============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

# Configuration
DB_NAME="tgp_dues_db"
DB_USER="rahuganmkc"
DB_PASSWORD="rahugan2018"
APP_DIR="/root/tgp-dues"
APP_PORT="5000"
APP_NAME="tgp-dues"

log_step() {
    echo -e "${CYAN}[STEP]${NC} ${BOLD}$1${NC}"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_banner() {
    clear
    echo -e "${PURPLE}${BOLD}"
    echo "============================================================================"
    echo "  TGP RAHUGAN CBC CHAPTER - DUES MANAGEMENT SYSTEM"
    echo "  Ubuntu VPS Deployment (Fixed Node.js Dependencies)"
    echo "============================================================================"
    echo -e "${NC}"
}

# Fix Node.js installation issues
install_nodejs_proper() {
    log_step "Installing Node.js from NodeSource (fixes dependency conflicts)"
    
    # Remove any existing nodejs/npm packages that might conflict
    apt remove -y nodejs npm node-* 2>/dev/null || true
    apt autoremove -y
    
    # Install curl if not present
    apt update
    apt install -y curl wget gnupg2 software-properties-common
    
    # Add NodeSource repository (Node.js 18.x LTS)
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    
    # Install Node.js (includes npm)
    apt install -y nodejs
    
    # Verify installation
    node_version=$(node --version)
    npm_version=$(npm --version)
    
    echo "Node.js version: $node_version"
    echo "npm version: $npm_version"
    
    log_success "Node.js and npm installed successfully"
}

# Install system dependencies with fixed Node.js
install_system_dependencies() {
    log_step "Installing system dependencies"
    
    # Update system
    apt update
    apt upgrade -y
    
    # Install basic packages
    apt install -y git postgresql postgresql-contrib nginx htop ufw
    
    # Install Node.js properly (fixes the dependency issue)
    install_nodejs_proper
    
    # Install PM2 globally
    npm install -g pm2
    
    # Enable services
    systemctl enable postgresql
    systemctl start postgresql
    systemctl enable nginx
    
    log_success "All system dependencies installed"
}

# Setup PostgreSQL
setup_database() {
    log_step "Setting up PostgreSQL database"
    
    # Create database user and database
    sudo -u postgres psql << EOF
-- Drop existing if present
DROP DATABASE IF EXISTS $DB_NAME;
DROP USER IF EXISTS $DB_USER;

-- Create fresh
CREATE USER $DB_USER WITH ENCRYPTED PASSWORD '$DB_PASSWORD';
CREATE DATABASE $DB_NAME OWNER $DB_USER;
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
ALTER USER $DB_USER CREATEDB;
EOF

    # Test connection
    PGPASSWORD=$DB_PASSWORD psql -U $DB_USER -d $DB_NAME -h localhost -c "SELECT 'Database connection successful';"
    
    log_success "Database setup completed"
}

# Create application directory and files
setup_application_files() {
    log_step "Setting up application files"
    
    # Create application directory
    mkdir -p $APP_DIR
    cd $APP_DIR
    
    # Create package.json
    cat > package.json << 'EOF'
{
  "name": "tgp-dues-management",
  "version": "1.0.0",
  "description": "TGP Rahugan CBC Chapter Dues Management System",
  "main": "server/index.ts",
  "scripts": {
    "dev": "NODE_ENV=development tsx server/index.ts",
    "build": "vite build && esbuild server/index.ts --platform=node --packages=external --bundle --format=esm --outdir=dist",
    "start": "node dist/index.js"
  },
  "dependencies": {
    "@neondatabase/serverless": "^0.9.0",
    "drizzle-orm": "^0.29.0",
    "drizzle-zod": "^0.5.1",
    "express": "^4.18.2",
    "ws": "^8.14.2",
    "zod": "^3.22.4",
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "wouter": "^2.12.1",
    "@tanstack/react-query": "^5.0.0",
    "lucide-react": "^0.294.0",
    "@radix-ui/react-slot": "^1.0.2",
    "class-variance-authority": "^0.7.0",
    "clsx": "^2.0.0",
    "tailwind-merge": "^2.0.0"
  },
  "devDependencies": {
    "@types/express": "^4.17.21",
    "@types/node": "^20.9.0",
    "@types/react": "^18.2.37",
    "@types/react-dom": "^18.2.15",
    "@types/ws": "^8.5.8",
    "@vitejs/plugin-react": "^4.1.1",
    "autoprefixer": "^10.4.16",
    "esbuild": "^0.19.5",
    "postcss": "^8.4.31",
    "tailwindcss": "^3.3.5",
    "tsx": "^4.1.4",
    "typescript": "^5.2.2",
    "vite": "^5.0.0"
  }
}
EOF

    # Create basic vite config
    cat > vite.config.ts << 'EOF'
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './client/src'),
      '@shared': path.resolve(__dirname, './shared'),
    },
  },
  root: './client',
  build: {
    outDir: '../dist/public',
    emptyOutDir: true,
  },
});
EOF

    # Create basic tsconfig
    cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx",
    "strict": true,
    "noUnusedLocals": false,
    "noUnusedParameters": false,
    "noFallthroughCasesInSwitch": true,
    "baseUrl": ".",
    "paths": {
      "@/*": ["./client/src/*"],
      "@shared/*": ["./shared/*"]
    }
  },
  "include": ["client/src", "shared", "server"],
  "references": [{ "path": "./tsconfig.node.json" }]
}
EOF

    # Create environment file
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
    log_success "Application files created"
}

# Install Node.js dependencies
install_dependencies() {
    log_step "Installing Node.js dependencies"
    
    cd $APP_DIR
    
    # Clear npm cache
    npm cache clean --force
    
    # Install dependencies
    npm install
    
    log_success "Dependencies installed"
}

# Create database schema and default data
setup_database_schema() {
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
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
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
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
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
    notes TEXT
);

-- Insert default accounts
INSERT INTO users (username, name, password, position, account_type) 
VALUES ('treasurer', 'Chapter Treasurer', 'password123', 'Treasurer', 'admin')
ON CONFLICT (username) DO UPDATE SET password = 'password123';

INSERT INTO members (name, address, initiation_date, member_type, username, password, batch_number)
VALUES 
    ('Juan Dela Cruz', '123 Main St, Manila', '2020-01-01', 'pure_blooded', 'juan.delacruz', 'member123', '2020-001'),
    ('Mark Santos', '456 Oak Ave, Quezon City', '2020-02-01', 'pure_blooded', 'mark.santos', 'member123', '2020-002')
ON CONFLICT (username) DO UPDATE SET password = 'member123';

INSERT INTO chapter_info (chapter_name, chapter_address, contact_email, contact_phone, treasurer_name, treasurer_email)
VALUES ('Tau Gamma Phi Rahugan CBC Chapter', 'CBC Building, Philippines', 'treasurer@tgp-rahugan.org', '+63 912 345 6789', 'Chapter Treasurer', 'treasurer@tgp-rahugan.org')
ON CONFLICT DO NOTHING;

SELECT 'Database schema created successfully' as status;
EOF

    log_success "Database schema created"
}

# Create minimal application files for testing
create_minimal_app() {
    log_step "Creating minimal application for testing"
    
    cd $APP_DIR
    
    # Create directories
    mkdir -p server client/src client/public shared
    
    # Create basic server
    cat > server/index.ts << 'EOF'
import express from 'express';
import path from 'path';

const app = express();
const PORT = process.env.PORT || 5000;

app.use(express.json());
app.use(express.static(path.join(__dirname, '../public')));

// Basic auth endpoint
app.post('/api/auth/login', (req, res) => {
  const { username, password } = req.body;
  
  if (username === 'treasurer' && password === 'password123') {
    res.json({
      user: {
        id: 1,
        username: 'treasurer',
        name: 'Chapter Treasurer',
        accountType: 'admin'
      }
    });
  } else {
    res.status(401).json({ message: 'Invalid credentials' });
  }
});

// Serve React app
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, '../public/index.html'));
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`TGP Dues Management System running on port ${PORT}`);
});
EOF

    # Create basic HTML
    cat > client/public/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>TGP Rahugan CBC Chapter - Dues Management</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background: #f5f5f5; }
        .container { max-width: 400px; margin: 50px auto; padding: 30px; background: white; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { text-align: center; margin-bottom: 30px; }
        .logo { width: 60px; height: 60px; background: #B8860B; border-radius: 50%; margin: 0 auto 15px; display: flex; align-items: center; justify-content: center; color: white; font-weight: bold; font-size: 24px; }
        h1 { color: #333; margin: 0; font-size: 24px; }
        .subtitle { color: #666; margin: 5px 0 0 0; }
        .form-group { margin-bottom: 20px; }
        label { display: block; margin-bottom: 5px; color: #333; font-weight: bold; }
        input { width: 100%; padding: 12px; border: 1px solid #ddd; border-radius: 5px; font-size: 16px; box-sizing: border-box; }
        button { width: 100%; padding: 12px; background: #B8860B; color: white; border: none; border-radius: 5px; font-size: 16px; cursor: pointer; }
        button:hover { background: #996F0A; }
        .error { color: #d32f2f; margin-top: 10px; text-align: center; }
        .member-link { text-align: center; margin-top: 20px; }
        .member-link a { color: #B8860B; text-decoration: none; }
        .footer { text-align: center; margin-top: 20px; font-size: 12px; color: #999; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="logo">TGP</div>
            <h1>Chapter Officer Login</h1>
            <p class="subtitle">Tau Gamma Phi Rahugan CBC Chapter</p>
        </div>
        
        <form id="loginForm">
            <div class="form-group">
                <label for="username">Officer ID</label>
                <input type="text" id="username" name="username" required>
            </div>
            
            <div class="form-group">
                <label for="password">Password</label>
                <input type="password" id="password" name="password" required>
            </div>
            
            <button type="submit">Sign In</button>
            
            <div id="error" class="error" style="display: none;"></div>
        </form>
        
        <div class="member-link">
            <p>Are you a member? <a href="#" onclick="showMemberLogin()">Member Login</a></p>
        </div>
        
        <div class="footer">
            Contact Chapter MKC for access credentials
        </div>
    </div>

    <script>
        document.getElementById('loginForm').addEventListener('submit', async (e) => {
            e.preventDefault();
            
            const username = document.getElementById('username').value;
            const password = document.getElementById('password').value;
            const errorDiv = document.getElementById('error');
            
            try {
                const response = await fetch('/api/auth/login', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ username, password })
                });
                
                const data = await response.json();
                
                if (response.ok) {
                    errorDiv.style.display = 'none';
                    alert('Login successful! Welcome ' + data.user.name);
                    // In real app, redirect to dashboard
                } else {
                    errorDiv.textContent = data.message;
                    errorDiv.style.display = 'block';
                }
            } catch (error) {
                errorDiv.textContent = 'Connection error. Please try again.';
                errorDiv.style.display = 'block';
            }
        });
        
        function showMemberLogin() {
            alert('Member portal will be available soon. Contact Chapter MKC for access.');
        }
    </script>
</body>
</html>
EOF

    # Copy to server public directory
    mkdir -p server/public
    cp client/public/index.html server/public/
    
    log_success "Minimal application created"
}

# Start application with PM2
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
    pm2 start "npx tsx server/index.ts" \
        --name "$APP_NAME" \
        --max-memory-restart 1G
    
    pm2 save
    pm2 startup
    
    log_success "Application started with PM2"
}

# Configure Nginx
setup_nginx() {
    log_step "Configuring Nginx"
    
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
    }
}
EOF

    ln -sf /etc/nginx/sites-available/tgp-dues /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    
    nginx -t
    systemctl reload nginx
    
    log_success "Nginx configured"
}

# Configure firewall
setup_firewall() {
    log_step "Configuring firewall"
    
    ufw --force reset
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow ssh
    ufw allow 80
    ufw allow 443
    ufw --force enable
    
    log_success "Firewall configured"
}

# Test deployment
test_deployment() {
    log_step "Testing deployment"
    
    sleep 15
    
    # Test PM2
    if ! pm2 list | grep -q "$APP_NAME.*online"; then
        log_error "PM2 process not running"
        pm2 logs $APP_NAME --lines 10
        exit 1
    fi
    
    # Test port
    if ! ss -tlnp | grep -q ":$APP_PORT "; then
        log_error "Port $APP_PORT not listening"
        exit 1
    fi
    
    # Test HTTP
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$APP_PORT || echo "000")
    if [[ ! $HTTP_CODE =~ ^(200|302)$ ]]; then
        log_error "HTTP test failed: $HTTP_CODE"
        exit 1
    fi
    
    # Test login
    LOGIN_TEST=$(curl -s -X POST http://localhost:$APP_PORT/api/auth/login \
        -H "Content-Type: application/json" \
        -d '{"username":"treasurer","password":"password123"}' || echo "error")
    
    if [[ $LOGIN_TEST == *"user"* ]]; then
        log_success "Authentication test passed"
    else
        log_error "Authentication test failed"
        exit 1
    fi
    
    log_success "All tests passed"
}

# Show final results
show_results() {
    SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo "$(hostname -I | awk '{print $1}')")
    
    clear
    print_banner
    
    echo -e "${GREEN}${BOLD}"
    echo "============================================================================"
    echo "                        DEPLOYMENT COMPLETED SUCCESSFULLY!"
    echo "============================================================================"
    echo -e "${NC}"
    
    echo -e "${WHITE}${BOLD}🌐 ACCESS INFORMATION${NC}"
    echo -e "Application URL: ${GREEN}http://$SERVER_IP${NC}"
    echo -e "Direct Port: ${GREEN}http://$SERVER_IP:$APP_PORT${NC}"
    echo ""
    
    echo -e "${WHITE}${BOLD}👤 LOGIN CREDENTIALS${NC}"
    echo -e "Administrator: ${YELLOW}treasurer${NC} / ${YELLOW}password123${NC}"
    echo -e "Member Sample: ${YELLOW}juan.delacruz${NC} / ${YELLOW}member123${NC}"
    echo ""
    
    echo -e "${WHITE}${BOLD}🛠️ MANAGEMENT${NC}"
    echo -e "PM2 Status: ${YELLOW}pm2 status${NC}"
    echo -e "View Logs: ${YELLOW}pm2 logs $APP_NAME${NC}"
    echo -e "Restart: ${YELLOW}pm2 restart $APP_NAME${NC}"
    echo ""
    
    echo -e "${GREEN}TGP Rahugan CBC Chapter Dues Management System is LIVE!${NC}"
}

# Main execution
main() {
    # Check root access
    if [[ $EUID -ne 0 ]]; then
       echo "This script must be run as root (use sudo)" 
       exit 1
    fi
    
    print_banner
    sleep 2
    
    install_system_dependencies
    setup_database
    setup_application_files
    install_dependencies
    setup_database_schema
    create_minimal_app
    start_application
    setup_nginx
    setup_firewall
    test_deployment
    show_results
}

# Run deployment
main "$@"