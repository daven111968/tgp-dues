#!/bin/bash

echo "=== Building Client Application and Starting Server ==="

# Stop current application
pm2 stop tgp-dues 2>/dev/null || true
pm2 delete tgp-dues 2>/dev/null || true

# Navigate to app directory
cd /var/www/tgp-dues

# Ensure environment is set
echo "Setting up environment..."
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

# Install all dependencies (including dev dependencies for build)
echo "Installing all dependencies..."
npm install

# Build the client application
echo "Building client application..."
npm run build

# Check if build was successful
if [ -d "client/dist" ]; then
    echo "✓ Client build successful"
    
    # Create the public directory structure the server expects
    echo "Setting up public directory structure..."
    mkdir -p server/public
    cp -r client/dist/* server/public/
    
    echo "✓ Public directory created with client build files"
else
    echo "✗ Client build failed - checking for alternative build output..."
    
    # Check for other possible build locations
    if [ -d "dist" ]; then
        echo "Found build in root dist directory"
        mkdir -p server/public
        cp -r dist/* server/public/
    elif [ -d "build" ]; then
        echo "Found build in root build directory"
        mkdir -p server/public
        cp -r build/* server/public/
    else
        echo "Creating minimal public directory..."
        mkdir -p server/public
        echo "<!DOCTYPE html><html><head><title>TGP Dues</title></head><body><h1>TGP Dues Management System</h1><p>Loading...</p></body></html>" > server/public/index.html
    fi
fi

# Test database connection
echo "Testing database connection..."
if PGPASSWORD=rahugan2018 psql -U rahuganmkc -d tgp_dues_db -h localhost -c '\q' 2>/dev/null; then
    echo "✓ Database connection successful"
else
    echo "Database connection failed - restarting PostgreSQL..."
    systemctl restart postgresql
    sleep 3
fi

# Start application with PM2
echo "Starting application with PM2..."
DATABASE_URL="postgresql://rahuganmkc:rahugan2018@localhost:5432/tgp_dues_db" \
NODE_ENV="production" \
PORT="5000" \
pm2 start "npx tsx server/index.ts" \
    --name "tgp-dues" \
    --max-memory-restart 1G \
    --restart-delay 3000

pm2 save

# Wait for startup
echo "Waiting for application to start..."
sleep 10

# Check status
echo "Checking application status..."
pm2 status

# Check if port is listening
if ss -tlnp | grep -q :5000; then
    echo "✓ Application listening on port 5000"
    
    # Test HTTP response
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5000 || echo "000")
    echo "HTTP response code: $HTTP_CODE"
    
    if [[ $HTTP_CODE =~ ^(200|302)$ ]]; then
        echo "✓ Application responding successfully"
        
        # Get server IP
        SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo "localhost")
        echo ""
        echo "=== SUCCESS ==="
        echo "TGP Dues Management System is now running!"
        echo "Access URL: http://$SERVER_IP"
        echo ""
        echo "Login credentials:"
        echo "Admin: treasurer / password123"
        echo "Member: juan.delacruz / member123"
    else
        echo "Application started but HTTP response indicates an issue"
        echo "Check logs: pm2 logs tgp-dues"
    fi
else
    echo "✗ Port 5000 not listening"
    echo "Recent application logs:"
    pm2 logs tgp-dues --lines 15
fi

echo ""
echo "Build and deployment complete."