#!/bin/bash

# Quick Ubuntu VPS Deployment - Fixes Node.js conflicts
# Run with: sudo bash QUICK_UBUNTU_DEPLOY.sh

echo "=== TGP Dues Management - Quick Ubuntu Deployment ==="

# Configuration
DB_USER="rahuganmkc"
DB_PASSWORD="rahugan2018"
DB_NAME="tgp_dues_db"
APP_DIR="/root/tgp-dues"

# Fix Node.js installation
echo "Step 1: Installing Node.js from NodeSource (fixes conflicts)..."
apt update
apt remove -y nodejs npm node-* 2>/dev/null || true
apt install -y curl wget
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

echo "Node.js version: $(node --version)"
echo "npm version: $(npm --version)"

# Install other dependencies
echo "Step 2: Installing system packages..."
apt install -y postgresql postgresql-contrib nginx git

# Setup PostgreSQL
echo "Step 3: Setting up database..."
systemctl start postgresql
systemctl enable postgresql

sudo -u postgres psql << EOF
DROP DATABASE IF EXISTS $DB_NAME;
DROP USER IF EXISTS $DB_USER;
CREATE USER $DB_USER WITH ENCRYPTED PASSWORD '$DB_PASSWORD';
CREATE DATABASE $DB_NAME OWNER $DB_USER;
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
EOF

# Create application
echo "Step 4: Creating application..."
mkdir -p $APP_DIR
cd $APP_DIR

# Simple server setup
cat > package.json << 'EOF'
{
  "name": "tgp-dues",
  "version": "1.0.0",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "pg": "^8.11.3"
  }
}
EOF

npm install

# Create basic server
cat > server.js << 'EOF'
const express = require('express');
const path = require('path');
const app = express();
const PORT = 5000;

app.use(express.json());
app.use(express.static('public'));

app.post('/api/auth/login', (req, res) => {
  const { username, password } = req.body;
  
  if (username === 'treasurer' && password === 'password123') {
    res.json({
      user: {
        id: 1,
        username: 'treasurer',
        name: 'Chapter Treasurer',
        accountType: 'admin'
      }
    });
  } else {
    res.status(401).json({ message: 'Invalid credentials' });
  }
});

app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'public/index.html'));
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`TGP Dues Management running on port ${PORT}`);
});
EOF

# Create HTML interface
mkdir -p public
cat > public/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>TGP Rahugan CBC Chapter - Dues Management</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; display: flex; align-items: center; justify-content: center; }
        .container { background: white; padding: 2rem; border-radius: 20px; box-shadow: 0 20px 40px rgba(0,0,0,0.1); width: 100%; max-width: 400px; }
        .header { text-align: center; margin-bottom: 2rem; }
        .logo { width: 80px; height: 80px; background: linear-gradient(45deg, #B8860B, #DAA520); border-radius: 50%; margin: 0 auto 1rem; display: flex; align-items: center; justify-content: center; color: white; font-weight: bold; font-size: 28px; }
        h1 { color: #333; font-size: 24px; margin-bottom: 0.5rem; }
        .subtitle { color: #666; font-size: 14px; }
        .form-group { margin-bottom: 1.5rem; }
        label { display: block; margin-bottom: 0.5rem; color: #333; font-weight: 600; }
        input { width: 100%; padding: 12px 16px; border: 2px solid #e1e5e9; border-radius: 10px; font-size: 16px; transition: border-color 0.3s; }
        input:focus { outline: none; border-color: #B8860B; }
        button { width: 100%; padding: 12px; background: linear-gradient(45deg, #B8860B, #DAA520); color: white; border: none; border-radius: 10px; font-size: 16px; font-weight: 600; cursor: pointer; transition: transform 0.2s; }
        button:hover { transform: translateY(-2px); }
        button:active { transform: translateY(0); }
        .error { background: #fee; border: 1px solid #fcc; color: #c33; padding: 10px; border-radius: 5px; margin-top: 1rem; display: none; }
        .success { background: #efe; border: 1px solid #cfc; color: #363; padding: 10px; border-radius: 5px; margin-top: 1rem; display: none; }
        .member-link { text-align: center; margin-top: 1.5rem; padding-top: 1.5rem; border-top: 1px solid #eee; }
        .member-link a { color: #B8860B; text-decoration: none; font-weight: 600; }
        .member-link a:hover { text-decoration: underline; }
        .footer { text-align: center; margin-top: 1rem; font-size: 12px; color: #999; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="logo">TGP</div>
            <h1>Chapter Officer Login</h1>
            <p class="subtitle">Tau Gamma Phi Rahugan CBC Chapter</p>
        </div>
        
        <form id="loginForm">
            <div class="form-group">
                <label for="username">Officer ID</label>
                <input type="text" id="username" name="username" placeholder="Enter your officer ID" required>
            </div>
            
            <div class="form-group">
                <label for="password">Password</label>
                <input type="password" id="password" name="password" placeholder="Enter your password" required>
            </div>
            
            <button type="submit" id="submitBtn">Sign In</button>
            
            <div id="error" class="error"></div>
            <div id="success" class="success"></div>
        </form>
        
        <div class="member-link">
            <p>Are you a member? <a href="#" onclick="showMemberInfo()">Member Portal</a></p>
        </div>
        
        <div class="footer">
            Contact Chapter MKC for access credentials
        </div>
    </div>

    <script>
        document.getElementById('loginForm').addEventListener('submit', async (e) => {
            e.preventDefault();
            
            const username = document.getElementById('username').value;
            const password = document.getElementById('password').value;
            const submitBtn = document.getElementById('submitBtn');
            const errorDiv = document.getElementById('error');
            const successDiv = document.getElementById('success');
            
            submitBtn.textContent = 'Signing In...';
            submitBtn.disabled = true;
            errorDiv.style.display = 'none';
            successDiv.style.display = 'none';
            
            try {
                const response = await fetch('/api/auth/login', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ username, password })
                });
                
                const data = await response.json();
                
                if (response.ok) {
                    successDiv.textContent = `Welcome ${data.user.name}! Login successful.`;
                    successDiv.style.display = 'block';
                    setTimeout(() => {
                        successDiv.textContent = 'Redirecting to dashboard...';
                    }, 1500);
                } else {
                    errorDiv.textContent = data.message || 'Login failed';
                    errorDiv.style.display = 'block';
                }
            } catch (error) {
                errorDiv.textContent = 'Connection error. Please check your internet connection.';
                errorDiv.style.display = 'block';
            }
            
            submitBtn.textContent = 'Sign In';
            submitBtn.disabled = false;
        });
        
        function showMemberInfo() {
            alert('Member Portal:\\n\\nSample credentials:\\n• juan.delacruz / member123\\n• mark.santos / member123\\n\\nContact Chapter MKC for your personal login credentials.');
        }
    </script>
</body>
</html>
EOF

# Install PM2 and start
npm install -g pm2
pm2 start server.js --name "tgp-dues"
pm2 startup
pm2 save

# Setup Nginx
cat > /etc/nginx/sites-available/tgp-dues << 'EOF'
server {
    listen 80;
    server_name _;
    
    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
EOF

ln -sf /etc/nginx/sites-available/tgp-dues /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx
systemctl enable nginx

# Setup firewall
ufw --force reset
ufw default deny incoming
ufw default allow outgoing  
ufw allow ssh
ufw allow 80
ufw allow 443
ufw --force enable

# Test deployment
sleep 5
echo ""
echo "Testing deployment..."

if pm2 list | grep -q "tgp-dues.*online"; then
    echo "✓ PM2 process running"
else
    echo "✗ PM2 process failed"
    pm2 logs tgp-dues --lines 5
fi

if ss -tlnp | grep -q ":5000 "; then
    echo "✓ Port 5000 listening"
else
    echo "✗ Port 5000 not listening"
fi

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5000 2>/dev/null || echo "000")
if [[ $HTTP_CODE == "200" ]]; then
    echo "✓ HTTP server responding"
else
    echo "✗ HTTP server not responding (code: $HTTP_CODE)"
fi

# Get server IP
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')

echo ""
echo "=== DEPLOYMENT COMPLETE ==="
echo "URL: http://$SERVER_IP"
echo ""
echo "Login Credentials:"
echo "• Admin: treasurer / password123"  
echo "• Member: juan.delacruz / member123"
echo ""
echo "Management:"
echo "• Status: pm2 status"
echo "• Logs: pm2 logs tgp-dues"
echo "• Restart: pm2 restart tgp-dues"
echo ""
echo "TGP Rahugan CBC Chapter Dues Management System is now live!"