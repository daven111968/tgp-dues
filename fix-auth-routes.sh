#!/bin/bash

echo "=== Fixing Authentication Routes ==="

cd /var/www/tgp-dues

# Stop application
pm2 stop tgp-dues 2>/dev/null || true

# Create fixed authentication routes
cat > server/auth-fix.ts << 'EOF'
import type { Express } from "express";
import { storage } from "./storage";
import { z } from "zod";

// Simplified login schema - no accountType required
const loginSchema = z.object({
  username: z.string().min(1),
  password: z.string().min(1),
});

export function setupAuthRoutes(app: Express) {
  // Admin login endpoint
  app.post("/api/auth/login", async (req, res) => {
    try {
      console.log('Admin login attempt:', req.body);
      
      const { username, password } = loginSchema.parse(req.body);
      
      // Try to find admin user
      const user = await storage.getUserByUsername(username);
      
      if (!user || user.password !== password || user.accountType !== 'admin') {
        console.log('Admin login failed for:', username);
        return res.status(401).json({ message: "Invalid admin credentials" });
      }
      
      console.log('Admin login successful for:', username);
      res.json({ 
        success: true,
        user: { 
          id: user.id, 
          username: user.username, 
          name: user.name, 
          position: user.position,
          accountType: 'admin'
        } 
      });
    } catch (error) {
      console.error('Admin login error:', error);
      res.status(400).json({ message: "Invalid request format" });
    }
  });

  // Member login endpoint
  app.post("/api/member/login", async (req, res) => {
    try {
      console.log('Member login attempt:', req.body);
      
      const { username, password } = loginSchema.parse(req.body);
      
      // Try to find member
      const member = await storage.getMemberByUsername(username);
      
      if (!member || !member.password || member.password !== password) {
        console.log('Member login failed for:', username);
        return res.status(401).json({ message: "Invalid member credentials" });
      }
      
      console.log('Member login successful for:', username);
      res.json({ 
        success: true,
        user: { 
          id: member.id, 
          username: member.username || username, 
          name: `${member.firstName} ${member.lastName}`,
          accountType: 'member'
        } 
      });
    } catch (error) {
      console.error('Member login error:', error);
      res.status(400).json({ message: "Invalid request format" });
    }
  });

  // Logout endpoint
  app.post("/api/auth/logout", (req, res) => {
    res.json({ success: true, message: "Logged out" });
  });

  // Health check
  app.get("/api/health", (req, res) => {
    res.json({ status: "healthy", timestamp: new Date().toISOString() });
  });
}
EOF

# Update the main routes file to use the new auth routes
cat > temp_routes_patch.js << 'EOF'
const fs = require('fs');

// Read the current routes file
const routesContent = fs.readFileSync('server/routes.ts', 'utf8');

// Replace the auth login section
const updatedContent = routesContent.replace(
  /app\.post\("\/api\/auth\/login"[\s\S]*?\}\s*\}\);/,
  `// Auth routes moved to separate file - will be added via setupAuthRoutes`
);

// Write back to file
fs.writeFileSync('server/routes.ts', updatedContent);

console.log('Routes file updated');
EOF

node temp_routes_patch.js
rm temp_routes_patch.js

# Update server/index.ts to include the auth routes
cat > temp_index_patch.js << 'EOF'
const fs = require('fs');

// Read the current index file
const indexContent = fs.readFileSync('server/index.ts', 'utf8');

// Add import for auth routes
let updatedContent = indexContent;

if (!updatedContent.includes('setupAuthRoutes')) {
  // Add import at the top
  updatedContent = updatedContent.replace(
    /import.*from.*routes.*\n/,
    `import { registerRoutes } from "./routes";\nimport { setupAuthRoutes } from "./auth-fix";\n`
  );
  
  // Add setupAuthRoutes call before registerRoutes
  updatedContent = updatedContent.replace(
    /const server = await registerRoutes\(app\);/,
    `setupAuthRoutes(app);\n  const server = await registerRoutes(app);`
  );
}

// Write back to file
fs.writeFileSync('server/index.ts', updatedContent);

console.log('Index file updated with auth routes');
EOF

node temp_index_patch.js
rm temp_index_patch.js

# Ensure database has the required data
echo "Setting up database with proper admin accounts..."
PGPASSWORD=rahugan2018 psql -U rahuganmkc -d tgp_dues_db -h localhost << 'EOF'
-- Ensure proper table structure
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(100),
    password VARCHAR(255) NOT NULL,
    position VARCHAR(100),
    account_type VARCHAR(20) DEFAULT 'member',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

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
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Clear and insert admin accounts
DELETE FROM users WHERE username IN ('treasurer', 'admin');
INSERT INTO users (username, name, password, position, account_type) 
VALUES 
    ('treasurer', 'Chapter Treasurer', 'password123', 'Treasurer', 'admin'),
    ('admin', 'System Administrator', 'admin123', 'Administrator', 'admin');

-- Clear and insert member accounts
DELETE FROM members WHERE username IN ('juan.delacruz', 'mark.santos', 'paolo.rodriguez');
INSERT INTO members (batch_number, username, password, first_name, last_name, email, member_type)
VALUES 
    ('2020-001', 'juan.delacruz', 'member123', 'Juan', 'Dela Cruz', 'juan@tgp.com', 'local'),
    ('2020-002', 'mark.santos', 'member123', 'Mark', 'Santos', 'mark@tgp.com', 'local'),
    ('2020-003', 'paolo.rodriguez', 'member123', 'Paolo', 'Rodriguez', 'paolo@tgp.com', 'out_of_town');

-- Verify accounts
SELECT 'Admin Accounts:' as info;
SELECT id, username, name, position, account_type FROM users WHERE account_type = 'admin';

SELECT 'Member Accounts:' as info;
SELECT id, username, first_name, last_name, member_type FROM members;
EOF

echo "Starting application with fixed authentication..."

# Start application
DATABASE_URL="postgresql://rahuganmkc:rahugan2018@localhost:5432/tgp_dues_db" \
NODE_ENV="production" \
PORT="5000" \
pm2 start "npx tsx server/index.ts" \
    --name "tgp-dues" \
    --max-memory-restart 1G

sleep 8

# Test the login endpoints
echo "Testing authentication endpoints..."

# Test admin login
echo "Testing admin login..."
ADMIN_RESPONSE=$(curl -s -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"treasurer","password":"password123"}')
echo "Admin login response: $ADMIN_RESPONSE"

# Test member login  
echo "Testing member login..."
MEMBER_RESPONSE=$(curl -s -X POST http://localhost:5000/api/member/login \
  -H "Content-Type: application/json" \
  -d '{"username":"juan.delacruz","password":"member123"}')
echo "Member login response: $MEMBER_RESPONSE"

# Check application status
pm2 status

SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo "localhost")
echo ""
echo "=== Authentication Fixed ==="
echo "Access your application at: http://$SERVER_IP"
echo ""
echo "Admin Login: treasurer / password123"
echo "Member Login: juan.delacruz / member123"
echo ""
echo "Check application logs: pm2 logs tgp-dues"