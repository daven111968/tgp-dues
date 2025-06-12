#!/bin/bash

echo "=== Diagnosing 502 Bad Gateway Error ==="
echo ""

# Check if application is running
echo "1. Checking PM2 application status:"
pm2 status

echo ""
echo "2. Checking if port 5000 is listening:"
ss -tlnp | grep :5000 || echo "Port 5000 is NOT listening"

echo ""
echo "3. Checking recent application logs:"
pm2 logs tgp-dues --lines 15

echo ""
echo "4. Testing local connection to application:"
curl -I http://localhost:5000 2>/dev/null || echo "Cannot connect to localhost:5000"

echo ""
echo "5. Checking Nginx status:"
systemctl status nginx --no-pager

echo ""
echo "6. Checking Nginx error logs:"
tail -10 /var/log/nginx/error.log

echo ""
echo "=== Attempting Fix ==="

# Stop application
echo "Stopping application..."
pm2 stop tgp-dues 2>/dev/null || true
pm2 delete tgp-dues 2>/dev/null || true

# Navigate to app directory
cd /var/www/tgp-dues

# Ensure environment file exists
echo "Checking environment file..."
if [ ! -f ".env" ]; then
    echo "Creating environment file..."
    cat > .env << EOF
DATABASE_URL=postgresql://rahuganmkc:rahugan2018@localhost:5432/tgp_dues_db
NODE_ENV=production
PORT=5000
PGHOST=localhost
PGPORT=5432
PGUSER=rahuganmkc
PGPASSWORD=rahugan2018
PGDATABASE=tgp_dues_db
SESSION_SECRET=$(openssl rand -hex 32)
EOF
    chmod 600 .env
fi

# Install dependencies
echo "Installing dependencies..."
npm install

# Test database connection
echo "Testing database connection..."
if PGPASSWORD=rahugan2018 psql -U rahuganmkc -d tgp_dues_db -h localhost -c '\q' 2>/dev/null; then
    echo "✓ Database connection OK"
else
    echo "✗ Database connection failed - fixing..."
    systemctl restart postgresql
    sleep 3
fi

# Start application with explicit environment
echo "Starting application with explicit environment..."
pm2 start "npx tsx server/index.ts" \
    --name "tgp-dues" \
    --env production \
    --max-memory-restart 1G \
    --restart-delay 3000

# Wait for startup
sleep 10

# Check if application started
echo ""
echo "Checking application status after restart:"
pm2 status

# Test local connection
echo ""
echo "Testing local connection:"
sleep 5
if curl -s http://localhost:5000 >/dev/null; then
    echo "✓ Application responding on localhost:5000"
else
    echo "✗ Application not responding - checking logs:"
    pm2 logs tgp-dues --lines 10
fi

# Check if port is listening
echo ""
echo "Port status:"
ss -tlnp | grep :5000 && echo "✓ Port 5000 is listening" || echo "✗ Port 5000 not listening"

# Restart Nginx
echo ""
echo "Restarting Nginx..."
nginx -t && systemctl restart nginx

echo ""
echo "=== Final Status Check ==="
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo "localhost")
echo "Try accessing: http://$SERVER_IP"
echo ""
echo "If still getting 502, check:"
echo "1. pm2 logs tgp-dues"
echo "2. tail -f /var/log/nginx/error.log"
echo "3. ss -tlnp | grep :5000"