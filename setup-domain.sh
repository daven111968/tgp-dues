#!/bin/bash

# Domain Configuration Script for TGP Dues Management System

echo "=== Domain Setup for TGP Dues Management System ==="

# Check if domain argument is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <your-domain.com> [with-ssl]"
    echo ""
    echo "Examples:"
    echo "  $0 tgp-rahugan.com"
    echo "  $0 dues.tgp-rahugan.org with-ssl"
    echo ""
    exit 1
fi

DOMAIN="$1"
SETUP_SSL="$2"

echo "Setting up domain: $DOMAIN"

# Backup current Nginx configuration
cp /etc/nginx/sites-available/tgp-dues /etc/nginx/sites-available/tgp-dues.backup.$(date +%Y%m%d_%H%M%S)

# Create new Nginx configuration with domain
echo "Updating Nginx configuration..."
cat > /etc/nginx/sites-available/tgp-dues << EOF
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN www.$DOMAIN;

    # Security headers
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options DENY;
    add_header X-XSS-Protection "1; mode=block";
    add_header Referrer-Policy "strict-origin-when-cross-origin";

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

    # Main application proxy
    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;

        # Timeout settings
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\\n";
        add_header Content-Type text/plain;
    }

    # Security.txt for responsible disclosure
    location /.well-known/security.txt {
        return 200 "Contact: treasurer@tgp-rahugan.org\\nPreferred-Languages: en\\n";
        add_header Content-Type text/plain;
    }
}
EOF

# Test Nginx configuration
echo "Testing Nginx configuration..."
if nginx -t; then
    echo "✓ Nginx configuration is valid"
    
    # Reload Nginx
    systemctl reload nginx
    echo "✓ Nginx reloaded with new domain configuration"
else
    echo "✗ Nginx configuration test failed"
    echo "Restoring backup configuration..."
    cp /etc/nginx/sites-available/tgp-dues.backup.$(date +%Y%m%d_%H%M%S) /etc/nginx/sites-available/tgp-dues
    systemctl reload nginx
    exit 1
fi

# Check if SSL setup is requested
if [ "$SETUP_SSL" = "with-ssl" ]; then
    echo ""
    echo "Setting up SSL certificate with Let's Encrypt..."
    
    # Install certbot if not present
    if ! command -v certbot &> /dev/null; then
        echo "Installing certbot..."
        apt update
        apt install -y certbot python3-certbot-nginx
    fi
    
    # Get SSL certificate
    echo "Obtaining SSL certificate for $DOMAIN..."
    certbot --nginx -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos --email admin@$DOMAIN
    
    if [ $? -eq 0 ]; then
        echo "✓ SSL certificate installed successfully"
        
        # Setup auto-renewal
        echo "Setting up auto-renewal..."
        (crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -
        echo "✓ Auto-renewal configured"
    else
        echo "✗ SSL certificate installation failed"
        echo "Make sure:"
        echo "1. Domain $DOMAIN points to this server's IP"
        echo "2. Ports 80 and 443 are open"
        echo "3. Domain is properly configured in DNS"
    fi
fi

echo ""
echo "=== Domain Configuration Complete ==="
echo ""
echo "Domain: $DOMAIN"
if [ "$SETUP_SSL" = "with-ssl" ]; then
    echo "Access URL: https://$DOMAIN"
    echo "HTTP redirect: http://$DOMAIN -> https://$DOMAIN"
else
    echo "Access URL: http://$DOMAIN"
fi
echo ""
echo "Login Credentials:"
echo "Admin: treasurer / password123"
echo "Member: juan.delacruz / member123"
echo ""
echo "Next steps:"
echo "1. Update DNS records to point $DOMAIN to this server's IP"
echo "2. Test domain access in browser"
if [ "$SETUP_SSL" != "with-ssl" ]; then
    echo "3. Consider adding SSL: $0 $DOMAIN with-ssl"
fi
echo ""
EOF