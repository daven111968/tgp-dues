#!/bin/bash

# Fix 404 errors in TGP deployment
# This script ensures proper static file serving

echo "=== Fixing 404 Static File Issues ==="

APP_DIR="/root/tgp-dues"
cd $APP_DIR

# Stop application
pm2 stop tgp-dues 2>/dev/null || true

# Create proper build structure
echo "Creating build directories..."
mkdir -p server/public dist/public

# Build React application
echo "Building React application..."
npm run build

# Copy build files to correct locations
if [ -d "dist/public" ]; then
    cp -r dist/public/* server/public/
    echo "✓ Copied from dist/public to server/public"
elif [ -d "dist" ]; then
    cp -r dist/* server/public/
    echo "✓ Copied from dist to server/public"
fi

# Ensure index.html exists
if [ ! -f "server/public/index.html" ]; then
    echo "Creating fallback index.html..."
    cat > server/public/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>TGP Rahugan CBC Chapter - Dues Management</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: linear-gradient(135deg, #B8860B 0%, #DAA520 100%); min-height: 100vh; display: flex; align-items: center; justify-content: center; }
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
        button:disabled { opacity: 0.7; cursor: not-allowed; }
        .error, .success { padding: 10px; border-radius: 5px; margin-top: 1rem; display: none; }
        .error { background: #fee; border: 1px solid #fcc; color: #c33; }
        .success { background: #efe; border: 1px solid #cfc; color: #363; }
        .member-link { text-align: center; margin-top: 1.5rem; padding-top: 1.5rem; border-top: 1px solid #eee; }
        .member-link a { color: #B8860B; text-decoration: none; font-weight: 600; }
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
                <input type="text" id="username" placeholder="Enter your officer ID" required>
            </div>
            
            <div class="form-group">
                <label for="password">Password</label>
                <input type="password" id="password" placeholder="Enter your password" required>
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
                    body: JSON.stringify({ username, password, accountType: 'admin' })
                });
                
                const data = await response.json();
                
                if (response.ok) {
                    successDiv.textContent = 'Welcome ' + data.user.name + '! Authentication successful.';
                    successDiv.style.display = 'block';
                } else {
                    errorDiv.textContent = data.message || 'Authentication failed';
                    errorDiv.style.display = 'block';
                }
            } catch (error) {
                errorDiv.textContent = 'Connection error. Please check network.';
                errorDiv.style.display = 'block';
            }
            
            submitBtn.textContent = 'Sign In';
            submitBtn.disabled = false;
        });
        
        function showMemberInfo() {
            alert('Member Portal Access:\\n\\nSample Credentials:\\n• juan.delacruz / member123\\n• mark.santos / member123\\n\\nContact Chapter MKC for personal credentials.');
        }
    </script>
</body>
</html>
EOF
fi

# Update server to handle production static files correctly
cat > fix-server-static.js << 'EOF'
const fs = require('fs');
const path = require('path');

// Read current server/index.ts
let serverContent = fs.readFileSync('server/index.ts', 'utf8');

// Add fallback static serving for production
const staticFix = `
// Production static file fallback
if (process.env.NODE_ENV === 'production') {
  const staticPath = path.join(__dirname, 'public');
  app.use(express.static(staticPath));
  
  app.get('*', (req, res) => {
    if (req.path.startsWith('/api')) return;
    res.sendFile(path.join(staticPath, 'index.html'));
  });
}
`;

// Insert before the routes registration
serverContent = serverContent.replace(
  '(async () => {',
  `${staticFix}\n\n(async () => {`
);

fs.writeFileSync('server/index.ts', serverContent);
console.log('Server static file handling updated');
EOF

node fix-server-static.js
rm fix-server-static.js

# Set proper permissions
chmod -R 755 server/public/

# Start application with production environment
echo "Starting application..."
NODE_ENV=production \
DATABASE_URL="postgresql://rahuganmkc:rahugan2018@localhost:5432/tgp_dues_db" \
pm2 start "npx tsx server/index.ts" \
    --name "tgp-dues" \
    --max-memory-restart 1G

pm2 save

# Test deployment
sleep 5
echo "Testing static file serving..."

if pm2 list | grep -q "tgp-dues.*online"; then
    echo "✓ PM2 process running"
else
    echo "✗ PM2 process failed"
    pm2 logs tgp-dues --lines 5
fi

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5000 2>/dev/null || echo "000")
if [[ $HTTP_CODE == "200" ]]; then
    echo "✓ HTTP server responding (200)"
else
    echo "✗ HTTP server error ($HTTP_CODE)"
fi

# Test authentication
AUTH_TEST=$(curl -s -X POST http://localhost:5000/api/auth/login \
    -H "Content-Type: application/json" \
    -d '{"username":"treasurer","password":"password123","accountType":"admin"}' || echo "error")

if [[ $AUTH_TEST == *"user"* ]]; then
    echo "✓ Authentication working"
else
    echo "✗ Authentication failed"
fi

echo ""
echo "=== 404 Fix Complete ==="
echo "Static files: server/public/index.html"
echo "Server mode: Production with static fallback"
echo "Access: http://your-server-ip"
echo ""