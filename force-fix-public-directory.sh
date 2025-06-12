#!/bin/bash

echo "=== Force Fix Public Directory and Start Application ==="

# Stop application
pm2 stop tgp-dues 2>/dev/null || true
pm2 delete tgp-dues 2>/dev/null || true

# Navigate to app directory
cd /var/www/tgp-dues

# Force create the server/public directory
echo "Creating server/public directory structure..."
mkdir -p server/public

# Create complete HTML application files
echo "Creating login pages..."

# Main admin login page
cat > server/public/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>TGP Rahugan CBC - Dues Management System</title>
    <link rel="icon" type="image/png" href="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
            background: linear-gradient(135deg, #1a1a1a 0%, #2d2d2d 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .container { 
            background: white; 
            padding: 40px; 
            border-radius: 12px; 
            box-shadow: 0 10px 40px rgba(0,0,0,0.3);
            width: 100%;
            max-width: 450px;
        }
        .header { 
            text-align: center; 
            margin-bottom: 40px; 
        }
        .logo { 
            color: #d4af37; 
            font-size: 3em; 
            font-weight: bold; 
            margin-bottom: 10px;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.1);
        }
        .title { 
            color: #333; 
            font-size: 1.3em; 
            margin-bottom: 10px;
            font-weight: 600;
        }
        .subtitle {
            color: #666;
            font-size: 0.9em;
        }
        .login-form { 
            margin-bottom: 30px; 
        }
        .form-group { 
            margin-bottom: 20px; 
        }
        label { 
            display: block; 
            margin-bottom: 8px; 
            font-weight: 600; 
            color: #333; 
        }
        input { 
            width: 100%; 
            padding: 14px; 
            border: 2px solid #e0e0e0; 
            border-radius: 8px; 
            font-size: 16px; 
            transition: border-color 0.3s ease;
        }
        input:focus {
            outline: none;
            border-color: #d4af37;
        }
        .btn { 
            background: linear-gradient(135deg, #d4af37 0%, #b8941f 100%); 
            color: white; 
            padding: 14px 24px; 
            border: none; 
            border-radius: 8px; 
            cursor: pointer; 
            font-size: 16px; 
            font-weight: 600;
            width: 100%;
            transition: transform 0.2s ease;
        }
        .btn:hover { 
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(212, 175, 55, 0.3);
        }
        .info { 
            background: #f8f9fa; 
            padding: 20px; 
            border-radius: 8px; 
            margin-bottom: 25px;
            border-left: 4px solid #d4af37;
        }
        .info h3 {
            color: #333;
            margin-bottom: 10px;
            font-size: 1.1em;
        }
        .info p {
            color: #666;
            margin-bottom: 8px;
            font-size: 0.95em;
        }
        .member-link { 
            text-align: center; 
            margin-top: 25px; 
            padding-top: 25px;
            border-top: 1px solid #e0e0e0;
        }
        .member-link a { 
            color: #d4af37; 
            text-decoration: none; 
            font-weight: 600;
            transition: color 0.3s ease;
        }
        .member-link a:hover {
            color: #b8941f;
            text-decoration: underline;
        }
        .error {
            background: #fee;
            color: #c33;
            padding: 12px;
            border-radius: 6px;
            margin-bottom: 20px;
            border: 1px solid #fcc;
            display: none;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="logo">ΤΓΦ</div>
            <h1 class="title">Rahugan CBC Chapter</h1>
            <p class="subtitle">Dues Management System</p>
        </div>
        
        <div class="info">
            <h3>Administrator Access</h3>
            <p><strong>Default Username:</strong> treasurer</p>
            <p><strong>Default Password:</strong> password123</p>
        </div>

        <div id="error-message" class="error"></div>
        
        <form class="login-form" id="loginForm">
            <div class="form-group">
                <label for="username">Username:</label>
                <input type="text" id="username" name="username" required autocomplete="username">
            </div>
            <div class="form-group">
                <label for="password">Password:</label>
                <input type="password" id="password" name="password" required autocomplete="current-password">
            </div>
            <button type="submit" class="btn">Login as Administrator</button>
        </form>
        
        <div class="member-link">
            <a href="/member-login.html">Member Portal Login</a>
        </div>
    </div>

    <script>
        document.getElementById('loginForm').addEventListener('submit', async function(e) {
            e.preventDefault();
            
            const username = document.getElementById('username').value;
            const password = document.getElementById('password').value;
            const errorDiv = document.getElementById('error-message');
            
            try {
                const response = await fetch('/api/auth/login', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({ username, password })
                });
                
                if (response.ok) {
                    window.location.href = '/dashboard';
                } else {
                    const error = await response.json();
                    errorDiv.textContent = error.message || 'Login failed';
                    errorDiv.style.display = 'block';
                }
            } catch (error) {
                errorDiv.textContent = 'Connection error. Please try again.';
                errorDiv.style.display = 'block';
            }
        });
    </script>
</body>
</html>
EOF

# Member login page
cat > server/public/member-login.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Member Portal - TGP Rahugan CBC</title>
    <link rel="icon" type="image/png" href="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
            background: linear-gradient(135deg, #1a1a1a 0%, #2d2d2d 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .container { 
            background: white; 
            padding: 40px; 
            border-radius: 12px; 
            box-shadow: 0 10px 40px rgba(0,0,0,0.3);
            width: 100%;
            max-width: 450px;
        }
        .header { 
            text-align: center; 
            margin-bottom: 40px; 
        }
        .logo { 
            color: #d4af37; 
            font-size: 3em; 
            font-weight: bold; 
            margin-bottom: 10px;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.1);
        }
        .title { 
            color: #333; 
            font-size: 1.3em; 
            margin-bottom: 10px;
            font-weight: 600;
        }
        .subtitle {
            color: #666;
            font-size: 0.9em;
        }
        .login-form { 
            margin-bottom: 30px; 
        }
        .form-group { 
            margin-bottom: 20px; 
        }
        label { 
            display: block; 
            margin-bottom: 8px; 
            font-weight: 600; 
            color: #333; 
        }
        input { 
            width: 100%; 
            padding: 14px; 
            border: 2px solid #e0e0e0; 
            border-radius: 8px; 
            font-size: 16px; 
            transition: border-color 0.3s ease;
        }
        input:focus {
            outline: none;
            border-color: #d4af37;
        }
        .btn { 
            background: linear-gradient(135deg, #d4af37 0%, #b8941f 100%); 
            color: white; 
            padding: 14px 24px; 
            border: none; 
            border-radius: 8px; 
            cursor: pointer; 
            font-size: 16px; 
            font-weight: 600;
            width: 100%;
            transition: transform 0.2s ease;
        }
        .btn:hover { 
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(212, 175, 55, 0.3);
        }
        .info { 
            background: #f8f9fa; 
            padding: 20px; 
            border-radius: 8px; 
            margin-bottom: 25px;
            border-left: 4px solid #d4af37;
        }
        .info h3 {
            color: #333;
            margin-bottom: 10px;
            font-size: 1.1em;
        }
        .info p {
            color: #666;
            margin-bottom: 8px;
            font-size: 0.95em;
        }
        .admin-link { 
            text-align: center; 
            margin-top: 25px; 
            padding-top: 25px;
            border-top: 1px solid #e0e0e0;
        }
        .admin-link a { 
            color: #d4af37; 
            text-decoration: none; 
            font-weight: 600;
            transition: color 0.3s ease;
        }
        .admin-link a:hover {
            color: #b8941f;
            text-decoration: underline;
        }
        .error {
            background: #fee;
            color: #c33;
            padding: 12px;
            border-radius: 6px;
            margin-bottom: 20px;
            border: 1px solid #fcc;
            display: none;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="logo">ΤΓΦ</div>
            <h1 class="title">Member Portal</h1>
            <p class="subtitle">Rahugan CBC Chapter</p>
        </div>
        
        <div class="info">
            <h3>Member Access</h3>
            <p><strong>Sample Username:</strong> juan.delacruz</p>
            <p><strong>Sample Password:</strong> member123</p>
        </div>

        <div id="error-message" class="error"></div>
        
        <form class="login-form" id="memberLoginForm">
            <div class="form-group">
                <label for="username">Username:</label>
                <input type="text" id="username" name="username" required autocomplete="username">
            </div>
            <div class="form-group">
                <label for="password">Password:</label>
                <input type="password" id="password" name="password" required autocomplete="current-password">
            </div>
            <button type="submit" class="btn">Login to Member Portal</button>
        </form>
        
        <div class="admin-link">
            <a href="/">Administrator Login</a>
        </div>
    </div>

    <script>
        document.getElementById('memberLoginForm').addEventListener('submit', async function(e) {
            e.preventDefault();
            
            const username = document.getElementById('username').value;
            const password = document.getElementById('password').value;
            const errorDiv = document.getElementById('error-message');
            
            try {
                const response = await fetch('/api/member/login', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({ username, password })
                });
                
                if (response.ok) {
                    window.location.href = '/member-portal';
                } else {
                    const error = await response.json();
                    errorDiv.textContent = error.message || 'Login failed';
                    errorDiv.style.display = 'block';
                }
            } catch (error) {
                errorDiv.textContent = 'Connection error. Please try again.';
                errorDiv.style.display = 'block';
            }
        });
    </script>
</body>
</html>
EOF

# Create basic dashboard page
cat > server/public/dashboard.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard - TGP Rahugan CBC</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: #f5f5f5; }
        .header { background: #1a1a1a; color: white; padding: 20px; }
        .header h1 { color: #d4af37; }
        .container { padding: 40px; max-width: 1200px; margin: 0 auto; }
        .card { background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); margin-bottom: 20px; }
        .btn { background: #d4af37; color: white; padding: 10px 20px; border: none; border-radius: 4px; cursor: pointer; text-decoration: none; display: inline-block; }
        .btn:hover { background: #b8941f; }
        .logout { float: right; }
    </style>
</head>
<body>
    <div class="header">
        <h1>ΤΓΦ Rahugan CBC - Admin Dashboard</h1>
        <a href="/api/auth/logout" class="btn logout">Logout</a>
    </div>
    <div class="container">
        <div class="card">
            <h2>Welcome to the TGP Dues Management System</h2>
            <p>This is a basic dashboard. The full React application will load here once the build is complete.</p>
            <p>Current features available:</p>
            <ul>
                <li>Member Management</li>
                <li>Payment Tracking</li>
                <li>Financial Reports</li>
                <li>Chapter Settings</li>
            </ul>
        </div>
    </div>
</body>
</html>
EOF

echo "✓ Created server/public directory with login pages"

# Verify files exist
ls -la server/public/

echo "Setting up environment and database..."

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
SESSION_SECRET=tgp-rahugan-secret-key-2024
EOF

chmod 600 .env

# Setup database with default accounts
PGPASSWORD=rahugan2018 psql -U rahuganmkc -d tgp_dues_db -h localhost << 'EOF'
-- Ensure users table exists
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(100),
    password VARCHAR(255) NOT NULL,
    position VARCHAR(100),
    account_type VARCHAR(20) DEFAULT 'member'
);

-- Insert admin accounts
INSERT INTO users (username, name, password, position, account_type) 
VALUES 
    ('treasurer', 'Chapter Treasurer', 'password123', 'Treasurer', 'admin'),
    ('admin', 'System Administrator', 'admin123', 'Administrator', 'admin')
ON CONFLICT (username) DO UPDATE SET
    password = EXCLUDED.password,
    account_type = EXCLUDED.account_type;

-- Verify admin accounts
SELECT username, name, position, account_type FROM users WHERE account_type = 'admin';
EOF

echo "Starting application..."

# Start application with explicit environment
DATABASE_URL="postgresql://rahuganmkc:rahugan2018@localhost:5432/tgp_dues_db" \
NODE_ENV="production" \
PORT="5000" \
pm2 start "npx tsx server/index.ts" \
    --name "tgp-dues" \
    --max-memory-restart 1G

pm2 save

sleep 8

# Check status
pm2 status

if ss -tlnp | grep -q :5000; then
    echo "✓ Application is running on port 5000"
    
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5000 || echo "000")
    echo "HTTP response: $HTTP_CODE"
    
    SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo "localhost")
    echo ""
    echo "=== SUCCESS ==="
    echo "TGP Dues Management System is accessible at:"
    echo "http://$SERVER_IP"
    echo ""
    echo "Admin Login: treasurer / password123"
    echo "Member Login: juan.delacruz / member123"
else
    echo "Port 5000 not listening. Check logs:"
    pm2 logs tgp-dues --lines 10
fi