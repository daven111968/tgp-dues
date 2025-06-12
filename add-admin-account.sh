#!/bin/bash

# Script to add admin accounts to TGP Dues Management System

echo "=== Add Admin Account to TGP Dues Management System ==="

# Check if username and password are provided
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: $0 <username> <password> [name] [position]"
    echo ""
    echo "Examples:"
    echo "  $0 admin123 mypassword 'John Doe' 'Chapter President'"
    echo "  $0 secretary pass123 'Jane Smith' 'Secretary'"
    echo ""
    exit 1
fi

USERNAME="$1"
PASSWORD="$2"
NAME="${3:-$USERNAME}"
POSITION="${4:-Administrator}"

echo "Adding admin account:"
echo "Username: $USERNAME"
echo "Name: $NAME"
echo "Position: $POSITION"
echo ""

# Connect to database and add user
PGPASSWORD=rahugan2018 psql -U rahuganmkc -d tgp_dues_db -h localhost << EOF
-- Insert new admin user
INSERT INTO users (username, name, password, position, account_type) 
VALUES ('$USERNAME', '$NAME', '$PASSWORD', '$POSITION', 'admin')
ON CONFLICT (username) DO UPDATE SET
    name = EXCLUDED.name,
    password = EXCLUDED.password,
    position = EXCLUDED.position,
    account_type = EXCLUDED.account_type;

-- Verify the user was added
SELECT id, username, name, position, account_type 
FROM users 
WHERE username = '$USERNAME';
EOF

if [ $? -eq 0 ]; then
    echo "✓ Admin account added successfully"
    echo ""
    echo "Login credentials:"
    echo "Username: $USERNAME"
    echo "Password: $PASSWORD"
    echo "Account Type: Administrator"
    echo ""
    echo "The new admin can now login at your application URL"
else
    echo "✗ Failed to add admin account"
    echo "Check database connection and try again"
fi