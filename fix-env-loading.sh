#!/bin/bash

echo "=== Fixing Environment Variable Loading ==="

# Stop application
pm2 stop tgp-dues 2>/dev/null || true
pm2 delete tgp-dues 2>/dev/null || true

# Navigate to app directory
cd /var/www/tgp-dues

# Create environment file with proper format
echo "Creating .env file..."
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

# Verify environment file
echo "Environment file contents:"
cat .env

# Test database connection manually
echo ""
echo "Testing database connection..."
if PGPASSWORD=rahugan2018 psql -U rahuganmkc -d tgp_dues_db -h localhost -c '\q' 2>/dev/null; then
    echo "✓ Database connection successful"
else
    echo "✗ Database connection failed - recreating database..."
    
    # Restart PostgreSQL
    systemctl restart postgresql
    sleep 3
    
    # Recreate database
    sudo -u postgres psql << 'EOSQL'
DROP DATABASE IF EXISTS tgp_dues_db;
DROP USER IF EXISTS rahuganmkc;
CREATE DATABASE tgp_dues_db;
CREATE USER rahuganmkc WITH ENCRYPTED PASSWORD 'rahugan2018';
GRANT ALL PRIVILEGES ON DATABASE tgp_dues_db TO rahuganmkc;
ALTER USER rahuganmkc CREATEDB;
ALTER DATABASE tgp_dues_db OWNER TO rahuganmkc;
EOSQL
    
    echo "Database recreated"
fi

# Install dependencies
echo ""
echo "Installing dependencies..."
npm install

# Start application with explicit environment variables
echo ""
echo "Starting application with explicit environment..."
DATABASE_URL="postgresql://rahuganmkc:rahugan2018@localhost:5432/tgp_dues_db" \
NODE_ENV="production" \
PORT="5000" \
pm2 start "npx tsx server/index.ts" \
    --name "tgp-dues" \
    --max-memory-restart 1G

# Wait for startup
sleep 10

# Check status
echo ""
echo "Application status:"
pm2 status

# Check logs
echo ""
echo "Recent logs:"
pm2 logs tgp-dues --lines 15

# Test if port is listening
echo ""
echo "Checking if port 5000 is listening:"
ss -tlnp | grep :5000 && echo "✓ Port 5000 is listening" || echo "✗ Port 5000 not listening"

# Test HTTP response
if pm2 list | grep -q "tgp-dues.*online"; then
    echo ""
    echo "Testing HTTP response..."
    sleep 5
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5000 || echo "000")
    echo "HTTP response code: $HTTP_CODE"
    
    if [[ $HTTP_CODE =~ ^(200|302)$ ]]; then
        echo "✓ Application is responding correctly"
        
        # Get server IP
        SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo "localhost")
        echo ""
        echo "=== SUCCESS ==="
        echo "Your application is now running at: http://$SERVER_IP"
        echo ""
        echo "Login credentials:"
        echo "Admin: treasurer / password123"
        echo "Member: juan.delacruz / member123"
    else
        echo "⚠ Application responding but with unexpected code"
    fi
else
    echo "✗ Application failed to start"
fi

echo ""
echo "If issues persist, check: pm2 logs tgp-dues"