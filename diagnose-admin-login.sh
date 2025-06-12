#!/bin/bash

echo "=== Diagnosing Admin Login Issues ==="

# Check if application is running
echo "1. Checking application status:"
pm2 status

echo ""
echo "2. Checking if port 5000 is accessible:"
curl -I http://localhost:5000 2>/dev/null || echo "Cannot connect to application"

echo ""
echo "3. Checking database connection:"
if PGPASSWORD=rahugan2018 psql -U rahuganmkc -d tgp_dues_db -h localhost -c '\q' 2>/dev/null; then
    echo "✓ Database connection successful"
else
    echo "✗ Database connection failed"
    exit 1
fi

echo ""
echo "4. Checking users table structure:"
PGPASSWORD=rahugan2018 psql -U rahuganmkc -d tgp_dues_db -h localhost -c "\d users"

echo ""
echo "5. Checking current users in database:"
PGPASSWORD=rahugan2018 psql -U rahuganmkc -d tgp_dues_db -h localhost -c "SELECT id, username, name, position, account_type FROM users;"

echo ""
echo "6. Looking for default treasurer account:"
PGPASSWORD=rahugan2018 psql -U rahuganmkc -d tgp_dues_db -h localhost -c "SELECT * FROM users WHERE username = 'treasurer';"

echo ""
echo "7. Checking application logs for authentication errors:"
pm2 logs tgp-dues --lines 20

echo ""
echo "=== Creating/Fixing Default Admin Account ==="

# Create or update the default admin account
PGPASSWORD=rahugan2018 psql -U rahuganmkc -d tgp_dues_db -h localhost << 'EOF'
-- Create default admin account if it doesn't exist
INSERT INTO users (username, name, password, position, account_type) 
VALUES ('treasurer', 'Chapter Treasurer', 'password123', 'Treasurer', 'admin')
ON CONFLICT (username) DO UPDATE SET
    password = 'password123',
    account_type = 'admin',
    position = 'Treasurer',
    name = 'Chapter Treasurer';

-- Verify the account exists
SELECT id, username, name, position, account_type FROM users WHERE username = 'treasurer';
EOF

echo ""
echo "8. Creating additional test admin accounts:"
PGPASSWORD=rahugan2018 psql -U rahuganmkc -d tgp_dues_db -h localhost << 'EOF'
-- Create backup admin accounts
INSERT INTO users (username, name, password, position, account_type) 
VALUES 
    ('admin', 'System Administrator', 'admin123', 'Administrator', 'admin'),
    ('president', 'Chapter President', 'president123', 'President', 'admin')
ON CONFLICT (username) DO UPDATE SET
    account_type = EXCLUDED.account_type,
    position = EXCLUDED.position;
EOF

echo ""
echo "9. Final verification - All admin accounts:"
PGPASSWORD=rahugan2018 psql -U rahuganmkc -d tgp_dues_db -h localhost -c "SELECT id, username, name, position, account_type FROM users WHERE account_type = 'admin';"

echo ""
echo "=== Login Test ==="
echo "Try these admin accounts:"
echo ""
echo "1. Username: treasurer"
echo "   Password: password123"
echo ""
echo "2. Username: admin"
echo "   Password: admin123"
echo ""
echo "3. Username: president"
echo "   Password: president123"
echo ""

# Test the login endpoint if possible
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo "localhost")
echo "Access your application at:"
echo "http://$SERVER_IP"
echo ""

# Restart application to ensure latest database state is loaded
echo "Restarting application to refresh database connection..."
pm2 restart tgp-dues

sleep 5
echo "Application restarted. Check status:"
pm2 status