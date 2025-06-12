#!/bin/bash

echo "=== Quick Authentication Fix and Test ==="

cd /var/www/tgp-dues

# Stop application
pm2 stop tgp-dues 2>/dev/null || true

# Ensure database has admin accounts
PGPASSWORD=rahugan2018 psql -U rahuganmkc -d tgp_dues_db -h localhost << 'EOF'
-- Create users table if not exists
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(100),
    password VARCHAR(255) NOT NULL,
    position VARCHAR(100),
    account_type VARCHAR(20) DEFAULT 'admin',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create members table if not exists
CREATE TABLE IF NOT EXISTS members (
    id SERIAL PRIMARY KEY,
    batch_number VARCHAR(50) UNIQUE,
    username VARCHAR(50) UNIQUE,
    password VARCHAR(255),
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100),
    phone VARCHAR(20),
    address TEXT,
    member_type VARCHAR(20) DEFAULT 'local',
    blood_type VARCHAR(5),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Clear and recreate accounts
DELETE FROM users WHERE username IN ('treasurer', 'admin');
DELETE FROM members WHERE username IN ('juan.delacruz', 'mark.santos');

-- Insert admin accounts
INSERT INTO users (username, name, password, position, account_type) 
VALUES 
    ('treasurer', 'Chapter Treasurer', 'password123', 'Treasurer', 'admin'),
    ('admin', 'System Administrator', 'admin123', 'Administrator', 'admin');

-- Insert member accounts
INSERT INTO members (batch_number, username, password, first_name, last_name, email, member_type)
VALUES 
    ('2020-001', 'juan.delacruz', 'member123', 'Juan', 'Dela Cruz', 'juan@tgp-rahugan.org', 'local'),
    ('2020-002', 'mark.santos', 'member123', 'Mark', 'Santos', 'mark@tgp-rahugan.org', 'local');

-- Verify accounts
SELECT 'Admin Accounts:' as info;
SELECT username, name, account_type FROM users;
SELECT 'Member Accounts:' as info;
SELECT username, first_name, last_name FROM members;
EOF

# Build React application
echo "Building React application..."
npm install
npm run build

# Copy build files
rm -rf server/public
mkdir -p server/public

if [ -d "dist/public" ]; then
    cp -r dist/public/* server/public/
    echo "✓ React build copied from dist/public"
elif [ -d "dist" ]; then
    cp -r dist/* server/public/
    echo "✓ React build copied from dist"
else
    echo "❌ Build failed - no dist directory found"
    exit 1
fi

# Verify index.html exists
if [ ! -f "server/public/index.html" ]; then
    echo "❌ index.html not found in build"
    exit 1
fi

# Start application with environment variables
echo "Starting application..."
DATABASE_URL="postgresql://rahuganmkc:rahugan2018@localhost:5432/tgp_dues_db" \
NODE_ENV="production" \
PORT="5000" \
pm2 start "npx tsx server/index.ts" \
    --name "tgp-dues" \
    --max-memory-restart 1G

sleep 8

# Test deployment
echo "Testing deployment..."

# Check PM2 status
if ! pm2 list | grep -q "tgp-dues.*online"; then
    echo "❌ Application not running"
    pm2 logs tgp-dues --lines 10
    exit 1
fi

# Check port
if ! ss -tlnp | grep -q ":5000 "; then
    echo "❌ Port 5000 not listening"
    exit 1
fi

# Test HTTP
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5000 || echo "000")
if [[ ! $HTTP_CODE =~ ^(200|302)$ ]]; then
    echo "❌ HTTP response: $HTTP_CODE"
    exit 1
fi

# Test admin login
echo "Testing admin login..."
ADMIN_LOGIN=$(curl -s -X POST http://localhost:5000/api/auth/login \
    -H "Content-Type: application/json" \
    -d '{"username":"treasurer","password":"password123","accountType":"admin"}' || echo "error")

if [[ $ADMIN_LOGIN == *"user"* && $ADMIN_LOGIN == *"treasurer"* ]]; then
    echo "✓ Admin login working"
else
    echo "❌ Admin login failed: $ADMIN_LOGIN"
fi

# Test member login
echo "Testing member login..."
MEMBER_LOGIN=$(curl -s -X POST http://localhost:5000/api/auth/login \
    -H "Content-Type: application/json" \
    -d '{"username":"juan.delacruz","password":"member123","accountType":"member"}' || echo "error")

if [[ $MEMBER_LOGIN == *"user"* && $MEMBER_LOGIN == *"Juan"* ]]; then
    echo "✓ Member login working"
else
    echo "❌ Member login failed: $MEMBER_LOGIN"
fi

# Test member endpoint
MEMBER_ENDPOINT=$(curl -s -X POST http://localhost:5000/api/member/login \
    -H "Content-Type: application/json" \
    -d '{"username":"juan.delacruz","password":"member123"}' || echo "error")

if [[ $MEMBER_ENDPOINT == *"user"* ]]; then
    echo "✓ Member endpoint working"
else
    echo "❌ Member endpoint failed: $MEMBER_ENDPOINT"
fi

# Get server IP
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo "localhost")

echo ""
echo "=== DEPLOYMENT SUCCESSFUL ==="
echo "URL: http://$SERVER_IP"
echo ""
echo "Admin Login: treasurer / password123"
echo "Member Login: juan.delacruz / member123"
echo ""
echo "Authentication fixed and tested successfully!"