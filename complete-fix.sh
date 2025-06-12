#!/bin/bash

# Complete fix for TGP Dues Management System
set -e

echo "=== TGP Dues Management System - Complete Fix ==="
echo ""

# Configuration
DB_NAME="tgp_dues_db"
DB_USER="rahuganmkc"
DB_PASSWORD="rahugan2018"
APP_DIR="/var/www/tgp-dues"
APP_PORT="5000"

# Stop application
echo "1. Stopping application..."
pm2 stop tgp-dues 2>/dev/null || true
pm2 delete tgp-dues 2>/dev/null || true

# Navigate to app directory
cd $APP_DIR

# Fix database setup
echo "2. Ensuring database is properly configured..."
# Restart PostgreSQL to ensure it's running
systemctl restart postgresql
sleep 3

# Recreate database and user with proper permissions
sudo -u postgres psql << EOF
DROP DATABASE IF EXISTS $DB_NAME;
DROP USER IF EXISTS $DB_USER;
CREATE DATABASE $DB_NAME;
CREATE USER $DB_USER WITH ENCRYPTED PASSWORD '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
ALTER USER $DB_USER CREATEDB;
ALTER DATABASE $DB_NAME OWNER TO $DB_USER;
\q
EOF

echo "Database recreated successfully"

# Test database connection
if PGPASSWORD=$DB_PASSWORD psql -U $DB_USER -d $DB_NAME -h localhost -c '\q' 2>/dev/null; then
    echo "✓ Database connection verified"
else
    echo "✗ Database connection failed - attempting to fix PostgreSQL config..."
    
    # Find and update PostgreSQL config
    PG_CONFIG=$(find /etc/postgresql -name "pg_hba.conf" | head -1)
    if [ -f "$PG_CONFIG" ]; then
        cp "$PG_CONFIG" "$PG_CONFIG.backup"
        sed -i 's/^local[[:space:]]\+all[[:space:]]\+all[[:space:]]\+peer$/local   all             all                                     md5/' "$PG_CONFIG"
        sed -i 's/^local[[:space:]]\+all[[:space:]]\+all[[:space:]]\+ident$/local   all             all                                     md5/' "$PG_CONFIG"
        systemctl restart postgresql
        sleep 3
        echo "PostgreSQL config updated"
    fi
fi

# Create environment file
echo "3. Creating environment configuration..."
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
echo "Environment file created"

# Install dependencies
echo "4. Installing all dependencies..."
npm install

# Verify essential files
echo "5. Verifying application files..."
if [ ! -f "server/index.ts" ]; then
    echo "✗ server/index.ts not found"
    exit 1
fi

if [ ! -f "package.json" ]; then
    echo "✗ package.json not found"
    exit 1
fi

echo "✓ Application files verified"

# Start application with PM2
echo "6. Starting application..."
pm2 start "npx tsx server/index.ts" \
    --name "tgp-dues" \
    --max-memory-restart 1G \
    --restart-delay 3000 \
    --exp-backoff-restart-delay 100

# Save PM2 config
pm2 save

# Wait for startup
echo "7. Waiting for application to start..."
sleep 10

# Check status
echo "8. Checking application status..."
if pm2 list | grep -q "tgp-dues.*online"; then
    echo "✓ Application is running"
    
    # Test HTTP response
    sleep 5
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$APP_PORT || echo "000")
    if [[ $HTTP_CODE =~ ^(200|302|301)$ ]]; then
        echo "✓ Application responding (HTTP $HTTP_CODE)"
    else
        echo "⚠ Application response: $HTTP_CODE"
    fi
else
    echo "✗ Application failed to start"
    echo "Recent logs:"
    pm2 logs tgp-dues --lines 20
    exit 1
fi

# Get server IP
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo "localhost")

echo ""
echo "=== Fix Complete ==="
echo ""
echo "Application URL: http://$SERVER_IP"
echo ""
echo "Admin Login:"
echo "  Username: treasurer"
echo "  Password: password123"
echo ""
echo "Member Login:"
echo "  Username: juan.delacruz (or mark.santos, paolo.rodriguez)"
echo "  Password: member123"
echo ""
echo "Management commands:"
echo "  pm2 status"
echo "  pm2 logs tgp-dues"
echo "  pm2 restart tgp-dues"
echo ""