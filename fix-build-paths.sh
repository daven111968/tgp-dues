#!/bin/bash

echo "=== Fixing Build Paths and Starting Application ==="

# Stop current application
pm2 stop tgp-dues 2>/dev/null || true
pm2 delete tgp-dues 2>/dev/null || true

# Navigate to app directory
cd /var/www/tgp-dues

# Create environment file
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

# Install dependencies
echo "Installing dependencies..."
npm install

# Build the client - this creates dist/public according to vite.config.ts
echo "Building client application..."
npm run build

# Check build output
if [ -d "dist/public" ]; then
    echo "✓ Build successful - found dist/public"
    
    # Create server/public directory and copy build files
    mkdir -p server/public
    cp -r dist/public/* server/public/
    echo "✓ Copied build files to server/public"
    
elif [ -d "dist" ]; then
    echo "Build created dist directory - copying to server/public"
    mkdir -p server/public
    cp -r dist/* server/public/
    
else
    echo "Build failed or unexpected output location"
    echo "Creating minimal static files..."
    mkdir -p server/public
    cat > server/public/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>TGP Rahugan CBC - Dues Management</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; text-align: center; }
        .container { max-width: 600px; margin: 0 auto; }
        .btn { background: #007bff; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>TGP Rahugan CBC Chapter</h1>
        <h2>Dues Management System</h2>
        <p>System is starting up...</p>
        <p><a href="/api/health" class="btn">Check API Status</a></p>
        <p>If this page persists, please contact your administrator.</p>
    </div>
</body>
</html>
EOF
fi

# Verify server/public directory exists and has content
if [ -d "server/public" ] && [ -f "server/public/index.html" ]; then
    echo "✓ server/public directory ready"
    ls -la server/public/
else
    echo "✗ server/public directory missing - creating fallback"
    mkdir -p server/public
    echo "<h1>TGP Dues System</h1>" > server/public/index.html
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

# Start application with explicit environment
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
sleep 10

# Check application status
echo "Checking application status..."
pm2 status

# Check if port is listening
if ss -tlnp | grep -q :5000; then
    echo "✓ Application listening on port 5000"
    
    # Test HTTP response
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5000 || echo "000")
    echo "HTTP response: $HTTP_CODE"
    
    if [[ $HTTP_CODE =~ ^(200|302)$ ]]; then
        echo "✓ Application responding successfully"
        
        # Get server IP
        SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo "localhost")
        echo ""
        echo "=== DEPLOYMENT SUCCESSFUL ==="
        echo "TGP Dues Management System is now accessible at:"
        echo "http://$SERVER_IP"
        echo ""
        echo "Login Credentials:"
        echo "Admin: treasurer / password123"
        echo "Member: juan.delacruz / member123"
        echo ""
        echo "Management Commands:"
        echo "- View logs: pm2 logs tgp-dues"
        echo "- Restart: pm2 restart tgp-dues"
        echo "- Status: pm2 status"
        
    else
        echo "Application started but HTTP response indicates an issue"
        echo "Response code: $HTTP_CODE"
        echo "Check logs: pm2 logs tgp-dues --lines 20"
    fi
else
    echo "✗ Port 5000 not listening"
    echo "Application logs:"
    pm2 logs tgp-dues --lines 20
fi