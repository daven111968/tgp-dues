#!/bin/bash

echo "=== Fixing Nginx Configuration ==="

# Backup current config
cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup.$(date +%Y%m%d_%H%M%S)

# Create correct Nginx configuration for TGP Dues app
cat > /etc/nginx/nginx.conf << 'EOF'
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
    worker_connections 768;
}

http {
    sendfile on;
    tcp_nopush on;
    types_hash_max_size 2048;
    server_tokens off;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Logging
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

    # Include sites
    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
EOF

# Create TGP Dues site configuration
cat > /etc/nginx/sites-available/tgp-dues << 'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    
    server_name _;

    # Security headers
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options DENY;
    add_header X-XSS-Protection "1; mode=block";
    add_header Referrer-Policy "strict-origin-when-cross-origin";

    # Main application proxy
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

    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF

# Remove old configurations
rm -f /etc/nginx/sites-enabled/default
rm -f /etc/nginx/sites-enabled/*

# Enable TGP Dues site
ln -sf /etc/nginx/sites-available/tgp-dues /etc/nginx/sites-enabled/

# Test configuration
echo "Testing Nginx configuration..."
if nginx -t; then
    echo "✓ Nginx configuration is valid"
    
    # Restart Nginx
    echo "Restarting Nginx..."
    systemctl restart nginx
    
    if systemctl is-active --quiet nginx; then
        echo "✓ Nginx restarted successfully"
    else
        echo "✗ Nginx failed to restart"
        systemctl status nginx --no-pager
        exit 1
    fi
else
    echo "✗ Nginx configuration test failed"
    nginx -t
    exit 1
fi

# Check if application is running
echo ""
echo "Checking application status..."
if pm2 list | grep -q "tgp-dues.*online"; then
    echo "✓ Application is running"
else
    echo "✗ Application not running - starting it..."
    cd /var/www/tgp-dues
    pm2 start "npx tsx server/index.ts" --name "tgp-dues"
    sleep 5
fi

# Test local connection
echo ""
echo "Testing application connection..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost:5000 | grep -q "200\|302"; then
    echo "✓ Application responding on localhost:5000"
else
    echo "✗ Application not responding"
    echo "Application logs:"
    pm2 logs tgp-dues --lines 10
fi

# Get server IP and test
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo "your-server-ip")
echo ""
echo "=== Configuration Fixed ==="
echo ""
echo "Your TGP Dues Management System should now be accessible at:"
echo "http://$SERVER_IP"
echo ""
echo "Login credentials:"
echo "Admin: treasurer / password123"
echo "Member: juan.delacruz / member123"
echo ""
EOF