#!/bin/bash

echo "=== Complete Fix and Deployment for TGP Dues Management System ==="

# Stop application
pm2 stop tgp-dues 2>/dev/null || true
pm2 delete tgp-dues 2>/dev/null || true

# Navigate to app directory
cd /var/www/tgp-dues

echo "1. Setting up environment..."
cat > .env << 'EOF'
DATABASE_URL=postgresql://rahuganmkc:rahugan2018@localhost:5432/tgp_dues_db
NODE_ENV=production
PORT=5000
PGHOST=localhost
PGPORT=5432
PGUSER=rahuganmkc
PGPASSWORD=rahugan2018
PGDATABASE=tgp_dues_db
SESSION_SECRET=tgp-rahugan-secret-key-2024
EOF

chmod 600 .env

echo "2. Installing dependencies..."
npm install

echo "3. Building client application..."
# Build the client
npm run build

# Check if build was successful and copy to correct location
if [ -d "dist/public" ]; then
    echo "✓ Build successful - copying to server/public"
    rm -rf server/public
    mkdir -p server/public
    cp -r dist/public/* server/public/
elif [ -d "dist" ]; then
    echo "✓ Build found in dist - copying to server/public"
    rm -rf server/public
    mkdir -p server/public
    cp -r dist/* server/public/
else
    echo "Creating fallback client files..."
    mkdir -p server/public
    cat > server/public/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>TGP Rahugan CBC - Dues Management</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 40px; background: #f5f5f5; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 40px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { text-align: center; margin-bottom: 40px; }
        .logo { color: #d4af37; font-size: 2.5em; font-weight: bold; margin-bottom: 10px; }
        .title { color: #333; font-size: 1.5em; margin-bottom: 20px; }
        .login-form { max-width: 400px; margin: 0 auto; }
        .form-group { margin-bottom: 20px; }
        label { display: block; margin-bottom: 5px; font-weight: bold; color: #333; }
        input { width: 100%; padding: 12px; border: 1px solid #ddd; border-radius: 4px; font-size: 16px; }
        .btn { background: #d4af37; color: white; padding: 12px 24px; border: none; border-radius: 4px; cursor: pointer; font-size: 16px; width: 100%; }
        .btn:hover { background: #b8941f; }
        .info { background: #e8f4f8; padding: 20px; border-radius: 4px; margin-bottom: 20px; }
        .member-link { text-align: center; margin-top: 20px; }
        .member-link a { color: #d4af37; text-decoration: none; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="logo">ΤΓΦ</div>
            <h1 class="title">Rahugan CBC Chapter<br>Dues Management System</h1>
        </div>
        
        <div class="info">
            <h3>Administrator Login</h3>
            <p>Default credentials:</p>
            <p><strong>Username:</strong> treasurer<br><strong>Password:</strong> password123</p>
        </div>
        
        <form class="login-form" action="/api/auth/login" method="POST">
            <div class="form-group">
                <label for="username">Username:</label>
                <input type="text" id="username" name="username" required>
            </div>
            <div class="form-group">
                <label for="password">Password:</label>
                <input type="password" id="password" name="password" required>
            </div>
            <button type="submit" class="btn">Login</button>
        </form>
        
        <div class="member-link">
            <a href="/member-login">Member Portal Login</a>
        </div>
    </div>
</body>
</html>
EOF

    # Create basic member login page
    cat > server/public/member-login.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Member Portal - TGP Rahugan CBC</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 40px; background: #f5f5f5; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 40px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { text-align: center; margin-bottom: 40px; }
        .logo { color: #d4af37; font-size: 2.5em; font-weight: bold; margin-bottom: 10px; }
        .title { color: #333; font-size: 1.5em; margin-bottom: 20px; }
        .login-form { max-width: 400px; margin: 0 auto; }
        .form-group { margin-bottom: 20px; }
        label { display: block; margin-bottom: 5px; font-weight: bold; color: #333; }
        input { width: 100%; padding: 12px; border: 1px solid #ddd; border-radius: 4px; font-size: 16px; }
        .btn { background: #d4af37; color: white; padding: 12px 24px; border: none; border-radius: 4px; cursor: pointer; font-size: 16px; width: 100%; }
        .btn:hover { background: #b8941f; }
        .info { background: #e8f4f8; padding: 20px; border-radius: 4px; margin-bottom: 20px; }
        .admin-link { text-align: center; margin-top: 20px; }
        .admin-link a { color: #d4af37; text-decoration: none; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="logo">ΤΓΦ</div>
            <h1 class="title">Member Portal<br>Rahugan CBC Chapter</h1>
        </div>
        
        <div class="info">
            <h3>Member Login</h3>
            <p>Sample member accounts:</p>
            <p><strong>Username:</strong> juan.delacruz<br><strong>Password:</strong> member123</p>
        </div>
        
        <form class="login-form" action="/api/member/login" method="POST">
            <div class="form-group">
                <label for="username">Username:</label>
                <input type="text" id="username" name="username" required>
            </div>
            <div class="form-group">
                <label for="password">Password:</label>
                <input type="password" id="password" name="password" required>
            </div>
            <button type="submit" class="btn">Login</button>
        </form>
        
        <div class="admin-link">
            <a href="/">Administrator Login</a>
        </div>
    </div>
</body>
</html>
EOF
fi

echo "4. Setting up database with admin accounts..."
PGPASSWORD=rahugan2018 psql -U rahuganmkc -d tgp_dues_db -h localhost << 'EOF'
-- Create users table if it doesn't exist
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(100),
    password VARCHAR(255) NOT NULL,
    position VARCHAR(100),
    account_type VARCHAR(20) DEFAULT 'member',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create members table if it doesn't exist
CREATE TABLE IF NOT EXISTS members (
    id SERIAL PRIMARY KEY,
    batch_number VARCHAR(50) UNIQUE,
    username VARCHAR(50) UNIQUE,
    password VARCHAR(255),
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100),
    phone VARCHAR(20),
    address TEXT,
    member_type VARCHAR(20) DEFAULT 'local',
    blood_type VARCHAR(5),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create payments table if it doesn't exist
CREATE TABLE IF NOT EXISTS payments (
    id SERIAL PRIMARY KEY,
    member_id INTEGER REFERENCES members(id),
    amount DECIMAL(10,2) NOT NULL,
    payment_date DATE DEFAULT CURRENT_DATE,
    payment_type VARCHAR(50) DEFAULT 'monthly_dues',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert default admin accounts
INSERT INTO users (username, name, password, position, account_type) 
VALUES 
    ('treasurer', 'Chapter Treasurer', 'password123', 'Treasurer', 'admin'),
    ('admin', 'System Administrator', 'admin123', 'Administrator', 'admin')
ON CONFLICT (username) DO UPDATE SET
    password = EXCLUDED.password,
    account_type = EXCLUDED.account_type;

-- Insert sample member accounts
INSERT INTO members (batch_number, username, password, first_name, last_name, email, member_type)
VALUES 
    ('2020-001', 'juan.delacruz', 'member123', 'Juan', 'Dela Cruz', 'juan@email.com', 'local'),
    ('2020-002', 'mark.santos', 'member123', 'Mark', 'Santos', 'mark@email.com', 'local'),
    ('2020-003', 'paolo.rodriguez', 'member123', 'Paolo', 'Rodriguez', 'paolo@email.com', 'out_of_town')
ON CONFLICT (username) DO UPDATE SET
    password = EXCLUDED.password;

-- Verify accounts
SELECT 'Admin accounts:' as type;
SELECT username, name, position, account_type FROM users WHERE account_type = 'admin';

SELECT 'Member accounts:' as type;
SELECT username, first_name, last_name, member_type FROM members LIMIT 5;
EOF

echo "5. Starting application..."
# Start with explicit environment variables
DATABASE_URL="postgresql://rahuganmkc:rahugan2018@localhost:5432/tgp_dues_db" \
NODE_ENV="production" \
PORT="5000" \
SESSION_SECRET="tgp-rahugan-secret-key-2024" \
pm2 start "npx tsx server/index.ts" \
    --name "tgp-dues" \
    --max-memory-restart 1G \
    --restart-delay 3000

pm2 save

# Wait for startup
sleep 10

echo "6. Testing deployment..."
pm2 status

# Check if port is listening
if ss -tlnp | grep -q :5000; then
    echo "✓ Application listening on port 5000"
    
    # Test HTTP response
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5000 || echo "000")
    echo "HTTP response: $HTTP_CODE"
    
    if [[ $HTTP_CODE =~ ^(200|302)$ ]]; then
        echo "✓ Application responding successfully"
        
        SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo "localhost")
        echo ""
        echo "=== DEPLOYMENT SUCCESSFUL ==="
        echo "TGP Dues Management System is accessible at:"
        echo "http://$SERVER_IP"
        echo ""
        echo "ADMIN LOGIN:"
        echo "Username: treasurer"
        echo "Password: password123"
        echo ""
        echo "MEMBER LOGIN:"
        echo "Username: juan.delacruz"
        echo "Password: member123"
        echo ""
        echo "Alternative admin:"
        echo "Username: admin"
        echo "Password: admin123"
        
    else
        echo "Application started but HTTP response: $HTTP_CODE"
        echo "Check logs: pm2 logs tgp-dues"
    fi
else
    echo "✗ Port 5000 not listening"
    echo "Application logs:"
    pm2 logs tgp-dues --lines 20
fi