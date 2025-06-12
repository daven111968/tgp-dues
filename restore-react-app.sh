#!/bin/bash

echo "=== Restoring Original React Login Page ==="

cd /var/www/tgp-dues

# Stop application
pm2 stop tgp-dues 2>/dev/null || true

# Remove the HTML fallback files
rm -rf server/public
mkdir -p server/public

# Build the React application properly
echo "Building React application..."
npm install
npm run build

# Copy built files to server/public
if [ -d "dist/public" ]; then
    cp -r dist/public/* server/public/
    echo "✓ React build copied to server/public"
elif [ -d "dist" ]; then
    cp -r dist/* server/public/
    echo "✓ Build files copied to server/public"
else
    echo "Build failed - React files not generated"
    exit 1
fi

# Fix the authentication route to work with React
cat > server/auth-routes-fix.ts << 'EOF'
import type { Express } from "express";
import { storage } from "./storage";
import { z } from "zod";

const loginSchema = z.object({
  username: z.string(),
  password: z.string(),
  accountType: z.enum(['admin', 'member']).optional().default('admin'),
});

export function setupAuthRoutes(app: Express) {
  app.post("/api/auth/login", async (req, res) => {
    try {
      const { username, password, accountType } = loginSchema.parse(req.body);
      
      if (accountType === 'admin') {
        const user = await storage.getUserByUsername(username);
        
        if (!user || user.password !== password || user.accountType !== 'admin') {
          return res.status(401).json({ message: "Invalid credentials" });
        }
        
        res.json({ 
          user: { 
            id: user.id, 
            username: user.username, 
            name: user.name, 
            position: user.position,
            accountType: 'admin'
          } 
        });
      } else {
        const member = await storage.getMemberByUsername(username);
        
        if (!member || !member.password || member.password !== password) {
          return res.status(401).json({ message: "Invalid credentials" });
        }
        
        res.json({ 
          user: { 
            id: member.id, 
            username: member.username || username, 
            name: `${member.firstName} ${member.lastName}`,
            accountType: 'member'
          } 
        });
      }
    } catch (error) {
      console.error('Login error:', error);
      res.status(400).json({ message: "Invalid request" });
    }
  });

  app.post("/api/auth/logout", (req, res) => {
    res.json({ success: true });
  });
}
EOF

# Update routes to use fixed authentication
cat > patch-routes.js << 'EOF'
const fs = require('fs');

const routesContent = fs.readFileSync('server/routes.ts', 'utf8');

// Remove existing auth route and add import
let updatedContent = routesContent;

// Add import if not present
if (!updatedContent.includes('setupAuthRoutes')) {
  updatedContent = updatedContent.replace(
    /import.*from.*storage.*\n/,
    `import { storage } from "./storage";\nimport { setupAuthRoutes } from "./auth-routes-fix";\n`
  );
}

// Replace existing login route
updatedContent = updatedContent.replace(
  /app\.post\("\/api\/auth\/login"[\s\S]*?\}\s*\}\);/,
  '// Auth routes handled by setupAuthRoutes'
);

// Add setupAuthRoutes call at the beginning of registerRoutes
updatedContent = updatedContent.replace(
  /export async function registerRoutes\(app: Express\): Promise<Server> \{/,
  `export async function registerRoutes(app: Express): Promise<Server> {
  // Setup authentication routes
  setupAuthRoutes(app);`
);

fs.writeFileSync('server/routes.ts', updatedContent);
console.log('Routes updated for React authentication');
EOF

node patch-routes.js
rm patch-routes.js

# Ensure database has correct admin accounts
PGPASSWORD=rahugan2018 psql -U rahuganmkc -d tgp_dues_db -h localhost << 'EOF'
-- Ensure admin accounts exist with correct accountType
UPDATE users SET account_type = 'admin' WHERE username IN ('treasurer', 'admin');

INSERT INTO users (username, name, password, position, account_type) 
VALUES ('treasurer', 'Chapter Treasurer', 'password123', 'Treasurer', 'admin')
ON CONFLICT (username) DO UPDATE SET
    password = 'password123',
    account_type = 'admin';

-- Verify admin account
SELECT username, name, account_type FROM users WHERE username = 'treasurer';
EOF

# Start application
echo "Starting application with React interface..."
DATABASE_URL="postgresql://rahuganmkc:rahugan2018@localhost:5432/tgp_dues_db" \
NODE_ENV="production" \
PORT="5000" \
pm2 start "npx tsx server/index.ts" \
    --name "tgp-dues" \
    --max-memory-restart 1G

sleep 10

# Check status
if ss -tlnp | grep -q :5000; then
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5000 || echo "000")
    
    if [[ $HTTP_CODE =~ ^(200|302)$ ]]; then
        SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo "localhost")
        echo ""
        echo "=== React Application Restored ==="
        echo "Access URL: http://$SERVER_IP"
        echo "Login: treasurer / password123"
        echo ""
        echo "Original React login page is now active"
    else
        echo "Application started but HTTP response: $HTTP_CODE"
        pm2 logs tgp-dues --lines 10
    fi
else
    echo "Application not responding on port 5000"
    pm2 logs tgp-dues --lines 15
fi