#!/bin/bash

echo "Fixing environment configuration and restarting application..."

# Stop the application
pm2 stop tgp-dues

# Navigate to application directory
cd /var/www/tgp-dues

# Create proper environment file
echo "Creating environment file..."
cat > .env << EOF
# Database Configuration
DATABASE_URL=postgresql://rahuganmkc:rahugan2018@localhost:5432/tgp_dues_db
PGHOST=localhost
PGPORT=5432
PGUSER=rahuganmkc
PGPASSWORD=rahugan2018
PGDATABASE=tgp_dues_db

# Application Configuration
NODE_ENV=production
PORT=5000

# Security
SESSION_SECRET=$(openssl rand -hex 32)
EOF

# Set proper permissions for env file
chmod 600 .env

echo "Environment file created:"
cat .env

# Install all dependencies if not already done
echo "Installing dependencies..."
npm install

# Test database connection
echo "Testing database connection..."
if PGPASSWORD=rahugan2018 psql -U rahuganmkc -d tgp_dues_db -h localhost -c '\q' 2>/dev/null; then
    echo "✓ Database connection successful"
else
    echo "✗ Database connection failed - checking PostgreSQL status..."
    systemctl status postgresql --no-pager
    echo ""
    echo "Attempting to restart PostgreSQL..."
    systemctl restart postgresql
    sleep 3
fi

# Restart the application
echo "Restarting application with PM2..."
pm2 restart tgp-dues

# Wait and check status
sleep 5
echo "Application status:"
pm2 status

echo ""
echo "Checking application logs (last 10 lines):"
pm2 logs tgp-dues --lines 10

echo ""
echo "If still having issues, check full logs with: pm2 logs tgp-dues"