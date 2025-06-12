#!/bin/bash

echo "=== Diagnosing Port 5000 Issue ==="

# Check what's running on port 5000
echo "1. Checking what's using port 5000:"
ss -tlnp | grep :5000 || echo "Nothing listening on port 5000"

echo ""
echo "2. Checking PM2 status:"
pm2 status

echo ""
echo "3. Checking recent PM2 logs:"
pm2 logs tgp-dues --lines 20

echo ""
echo "4. Checking if any Node.js processes are running:"
ps aux | grep node | grep -v grep

echo ""
echo "=== Fixing the Issue ==="

# Kill any existing processes on port 5000
echo "Killing any processes on port 5000..."
sudo fuser -k 5000/tcp 2>/dev/null || echo "No processes to kill on port 5000"

# Stop PM2 processes
echo "Stopping PM2 processes..."
pm2 stop all 2>/dev/null || true
pm2 delete all 2>/dev/null || true

# Navigate to app directory
cd /var/www/tgp-dues

# Check if .env file exists and has correct content
echo "Checking environment file..."
if [ -f ".env" ]; then
    echo "Environment file exists:"
    cat .env
else
    echo "Creating environment file..."
    cat > .env << 'EOF'
DATABASE_URL=postgresql://rahuganmkc:rahugan2018@localhost:5432/tgp_dues_db
NODE_ENV=production
PORT=5000
PGHOST=localhost
PGPORT=5432
PGUSER=rahuganmkc
PGPASSWORD=rahugan2018
PGDATABASE=tgp_dues_db
EOF
    chmod 600 .env
fi

# Test database connection
echo ""
echo "Testing database connection..."
if PGPASSWORD=rahugan2018 psql -U rahuganmkc -d tgp_dues_db -h localhost -c '\q' 2>/dev/null; then
    echo "✓ Database connection successful"
else
    echo "✗ Database connection failed - restarting PostgreSQL..."
    systemctl restart postgresql
    sleep 3
    
    # Try to recreate database if needed
    sudo -u postgres psql << 'EOSQL'
CREATE DATABASE tgp_dues_db;
CREATE USER rahuganmkc WITH ENCRYPTED PASSWORD 'rahugan2018';
GRANT ALL PRIVILEGES ON DATABASE tgp_dues_db TO rahuganmkc;
ALTER USER rahuganmkc CREATEDB;
EOSQL
fi

# Install dependencies
echo ""
echo "Installing dependencies..."
npm install

# Test running the application directly first
echo ""
echo "Testing application startup directly..."
export DATABASE_URL="postgresql://rahuganmkc:rahugan2018@localhost:5432/tgp_dues_db"
export NODE_ENV="production"
export PORT="5000"

# Try to start the application directly for testing
timeout 10s npx tsx server/index.ts &
APP_PID=$!

sleep 5

# Check if it's now listening
if ss -tlnp | grep -q :5000; then
    echo "✓ Application started successfully on port 5000"
    kill $APP_PID 2>/dev/null || true
    
    # Start with PM2
    echo "Starting with PM2..."
    DATABASE_URL="postgresql://rahuganmkc:rahugan2018@localhost:5432/tgp_dues_db" \
    NODE_ENV="production" \
    PORT="5000" \
    pm2 start "npx tsx server/index.ts" --name "tgp-dues" --max-memory-restart 1G
    
    pm2 save
    
    sleep 5
    
    echo ""
    echo "Final status check:"
    pm2 status
    ss -tlnp | grep :5000 && echo "✓ Port 5000 is now listening"
    
    # Test HTTP response
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5000 || echo "000")
    echo "HTTP response: $HTTP_CODE"
    
else
    echo "✗ Application failed to start"
    kill $APP_PID 2>/dev/null || true
    echo "Check application logs for errors:"
    echo "Recent logs from direct run:"
fi

echo ""
echo "=== Troubleshooting Complete ==="