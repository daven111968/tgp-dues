#!/bin/bash

echo "=== Fixing Authentication in Current Environment ==="

# Check current database schema and fix if needed
echo "Checking database schema..."
PGPASSWORD=$PGPASSWORD psql -d $PGDATABASE -h $PGHOST -p $PGPORT -U $PGUSER << 'EOF'
-- Add account_type column to users table if it doesn't exist
ALTER TABLE users ADD COLUMN IF NOT EXISTS account_type VARCHAR(20) DEFAULT 'admin';

-- Update existing users to be admin type
UPDATE users SET account_type = 'admin' WHERE account_type IS NULL;

-- Ensure we have test accounts
INSERT INTO users (username, name, password, position, account_type) 
VALUES ('treasurer', 'Chapter Treasurer', 'password123', 'Treasurer', 'admin')
ON CONFLICT (username) DO UPDATE SET
    password = 'password123',
    account_type = 'admin';

-- Ensure we have test member accounts
INSERT INTO members (name, address, initiation_date, member_type, username, password)
VALUES 
    ('Juan Dela Cruz', '123 Main St', '2020-01-01', 'pure_blooded', 'juan.delacruz', 'member123'),
    ('Mark Santos', '456 Oak Ave', '2020-02-01', 'pure_blooded', 'mark.santos', 'member123')
ON CONFLICT (username) DO UPDATE SET
    password = 'member123';

-- Verify accounts
SELECT 'Users:' as info, username, name, account_type FROM users;
SELECT 'Members:' as info, username, name FROM members WHERE username IS NOT NULL;
EOF

echo "Database setup completed"
echo ""
echo "Authentication system is now ready to test"
echo ""
echo "Admin Login: treasurer / password123"
echo "Member Login: juan.delacruz / member123"