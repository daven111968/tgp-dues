#!/bin/bash

# ============================================================================
# TGP Rahugan CBC Chapter - Complete VPS Deployment
# Single script for smooth Ubuntu VPS installation
# ============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

# Configuration
DB_NAME="tgp_dues_db"
DB_USER="rahuganmkc"
DB_PASSWORD="rahugan2018"
APP_DIR="/root/tgp-dues"
APP_PORT="5000"
APP_NAME="tgp-dues"

log_step() { echo -e "${CYAN}[STEP]${NC} ${BOLD}$1${NC}"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

print_banner() {
    clear
    echo -e "${PURPLE}${BOLD}"
    echo "============================================================================"
    echo "  ████████  ██████  ██████      ██████   █████  ██   ██ ██    ██  ██████  "
    echo "     ██    ██       ██   ██     ██   ██ ██   ██ ██   ██ ██    ██ ██       "
    echo "     ██    ██   ███ ██████      ██████  ███████ ███████ ██    ██ ██   ███ "
    echo "     ██    ██    ██ ██          ██   ██ ██   ██ ██   ██ ██    ██ ██    ██ "
    echo "     ██     ██████  ██          ██   ██ ██   ██ ██   ██  ██████   ██████  "
    echo ""
    echo "                   TGP RAHUGAN CBC CHAPTER - VPS DEPLOYMENT"
    echo "============================================================================"
    echo -e "${NC}"
}

handle_error() {
    log_error "Deployment failed: $1"
    echo "Cleaning up..."
    pm2 stop $APP_NAME 2>/dev/null || true
    pm2 delete $APP_NAME 2>/dev/null || true
    exit 1
}

trap 'handle_error "$BASH_COMMAND"' ERR

# System setup
setup_system() {
    log_step "Setting up Ubuntu system"
    
    # Update system
    apt update && apt upgrade -y
    
    # Remove conflicting Node.js packages
    apt remove -y nodejs npm node-* 2>/dev/null || true
    apt autoremove -y
    
    # Install base packages
    apt install -y curl wget git postgresql postgresql-contrib nginx ufw htop
    
    # Install Node.js from NodeSource (fixes dependency conflicts)
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt install -y nodejs
    
    # Install PM2
    npm install -g pm2
    
    # Enable services
    systemctl enable postgresql nginx
    systemctl start postgresql
    
    log_success "System setup completed"
}

# Database configuration
setup_database() {
    log_step "Configuring PostgreSQL database"
    
    # Create database and user
    sudo -u postgres psql << EOF
DROP DATABASE IF EXISTS $DB_NAME;
DROP USER IF EXISTS $DB_USER;
CREATE USER $DB_USER WITH ENCRYPTED PASSWORD '$DB_PASSWORD';
CREATE DATABASE $DB_NAME OWNER $DB_USER;
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
ALTER USER $DB_USER CREATEDB;
EOF

    # Create schema and default data
    PGPASSWORD=$DB_PASSWORD psql -U $DB_USER -d $DB_NAME -h localhost << 'EOF'
-- Users table for admin accounts
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    password VARCHAR(255) NOT NULL,
    position VARCHAR(100) NOT NULL,
    account_type VARCHAR(20) DEFAULT 'admin',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Members table
CREATE TABLE members (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    alexis_name VARCHAR(100),
    address TEXT NOT NULL,
    batch_number VARCHAR(50) UNIQUE,
    batch_name VARCHAR(100),
    initiation_date TIMESTAMP NOT NULL,
    member_type VARCHAR(20) DEFAULT 'pure_blooded',
    welcoming_date TIMESTAMP,
    status VARCHAR(20) DEFAULT 'active',
    username VARCHAR(50) UNIQUE,
    password VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Payments table
CREATE TABLE payments (
    id SERIAL PRIMARY KEY,
    member_id INTEGER REFERENCES members(id),
    amount DECIMAL(10,2) NOT NULL,
    payment_date TIMESTAMP NOT NULL,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Chapter info table
CREATE TABLE chapter_info (
    id SERIAL PRIMARY KEY,
    chapter_name VARCHAR(200) NOT NULL,
    chapter_address TEXT NOT NULL,
    contact_email VARCHAR(100) NOT NULL,
    contact_phone VARCHAR(20) NOT NULL,
    treasurer_name VARCHAR(100) NOT NULL,
    treasurer_email VARCHAR(100) NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Activities table
CREATE TABLE activities (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    target_amount DECIMAL(10,2),
    activity_date TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Contributions table
CREATE TABLE contributions (
    id SERIAL PRIMARY KEY,
    activity_id INTEGER REFERENCES activities(id),
    member_id INTEGER REFERENCES members(id),
    amount DECIMAL(10,2) NOT NULL,
    contribution_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notes TEXT
);

-- Insert default accounts
INSERT INTO users (username, name, password, position, account_type) 
VALUES ('treasurer', 'Chapter Treasurer', 'password123', 'Treasurer', 'admin');

INSERT INTO members (name, address, initiation_date, member_type, username, password, batch_number)
VALUES 
    ('Juan Dela Cruz', '123 Main St, Manila', '2020-01-01', 'pure_blooded', 'juan.delacruz', 'member123', '2020-001'),
    ('Mark Santos', '456 Oak Ave, Quezon City', '2020-02-01', 'pure_blooded', 'mark.santos', 'member123', '2020-002'),
    ('Paolo Rodriguez', '789 Pine St, Makati', '2020-03-01', 'welcome', 'paolo.rodriguez', 'member123', '2020-003');

INSERT INTO chapter_info (chapter_name, chapter_address, contact_email, contact_phone, treasurer_name, treasurer_email)
VALUES ('Tau Gamma Phi Rahugan CBC Chapter', 'CBC Building, Philippines', 'treasurer@tgp-rahugan.org', '+63 912 345 6789', 'Chapter Treasurer', 'treasurer@tgp-rahugan.org');
EOF

    log_success "Database configured successfully"
}

# Create React application structure
create_react_app() {
    # Create package.json for React app
    cat > package.json << 'EOF'
{
  "name": "tgp-dues-management",
  "version": "1.0.0",
  "description": "TGP Rahugan CBC Chapter Dues Management System",
  "main": "server.js",
  "scripts": {
    "build": "vite build",
    "dev": "vite",
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "pg": "^8.11.3",
    "cors": "^2.8.5",
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "wouter": "^2.11.0",
    "@tanstack/react-query": "^4.32.6",
    "lucide-react": "^0.263.1",
    "clsx": "^2.0.0",
    "tailwind-merge": "^1.14.0"
  },
  "devDependencies": {
    "@types/react": "^18.2.15",
    "@types/react-dom": "^18.2.7",
    "@vitejs/plugin-react": "^4.0.3",
    "vite": "^4.4.5",
    "tailwindcss": "^3.3.3",
    "autoprefixer": "^10.4.14",
    "postcss": "^8.4.27",
    "typescript": "^5.0.2"
  }
}
EOF

    # Create Vite config
    cat > vite.config.ts << 'EOF'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
    },
  },
  build: {
    outDir: 'dist',
    assetsDir: 'assets',
  },
})
EOF

    # Create Tailwind config
    cat > tailwind.config.js << 'EOF'
/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          DEFAULT: '#B8860B',
          50: '#F5F1E8',
          500: '#B8860B',
          600: '#996F0A',
        }
      }
    },
  },
  plugins: [],
}
EOF

    # Create PostCSS config
    cat > postcss.config.js << 'EOF'
export default {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
}
EOF

    # Create TypeScript config
    cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx",
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true,
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["src"],
  "references": [{ "path": "./tsconfig.node.json" }]
}
EOF

    # Create index.html
    cat > index.html << 'EOF'
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/vite.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>TGP Rahugan CBC Chapter - Dues Management</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
EOF

    # Create source directories
    mkdir -p src/components/ui src/lib src/pages src/hooks

    # Create main.tsx
    cat > src/main.tsx << 'EOF'
import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App.tsx'
import './index.css'

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
)
EOF

    # Create index.css
    cat > src/index.css << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  :root {
    --primary: 45 100% 38%;
    --primary-foreground: 0 0% 98%;
  }
}
EOF

    # Create App.tsx
    cat > src/App.tsx << 'EOF'
import { Switch, Route } from "wouter";
import { queryClient } from "./lib/queryClient";
import { QueryClientProvider } from "@tanstack/react-query";
import { AuthProvider, useAuth } from "./lib/auth";
import Login from "./pages/Login";
import Dashboard from "./pages/Dashboard";

function AuthenticatedApp() {
  const { user } = useAuth();

  if (!user) {
    return <Login />;
  }

  if (user.accountType === 'admin') {
    return (
      <div className="min-h-screen bg-gray-50">
        <Switch>
          <Route path="/" component={Dashboard} />
          <Route path="/dashboard" component={Dashboard} />
        </Switch>
      </div>
    );
  }

  return <div>Member Portal</div>;
}

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <AuthProvider>
        <AuthenticatedApp />
      </AuthProvider>
    </QueryClientProvider>
  );
}

export default App;
EOF

    # Create queryClient
    cat > src/lib/queryClient.ts << 'EOF'
import { QueryClient } from "@tanstack/react-query";

export async function apiRequest(
  method: string,
  url: string,
  data?: unknown,
): Promise<Response> {
  const res = await fetch(url, {
    method,
    headers: data ? { "Content-Type": "application/json" } : {},
    body: data ? JSON.stringify(data) : undefined,
  });

  if (!res.ok) {
    throw new Error(`${res.status}: ${res.statusText}`);
  }
  return res;
}

export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      refetchOnWindowFocus: false,
      retry: false,
    },
  },
});
EOF

    # Create auth provider
    cat > src/lib/auth.tsx << 'EOF'
import { createContext, useContext, useState, ReactNode } from "react";
import { useMutation } from "@tanstack/react-query";
import { apiRequest } from "./queryClient";

interface User {
  id: number;
  username: string;
  name: string;
  position?: string;
  accountType: 'admin' | 'member';
}

interface AuthContextType {
  user: User | null;
  login: (username: string, password: string) => Promise<void>;
  logout: () => void;
  isLoading: boolean;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);

  const loginMutation = useMutation({
    mutationFn: async ({ username, password }: { username: string; password: string }) => {
      const response = await apiRequest('POST', '/api/auth/login', { 
        username, 
        password, 
        accountType: 'admin' 
      });
      return response.json();
    },
    onSuccess: (data) => {
      setUser(data.user);
    },
  });

  const login = async (username: string, password: string) => {
    await loginMutation.mutateAsync({ username, password });
  };

  const logout = () => {
    setUser(null);
  };

  return (
    <AuthContext.Provider value={{
      user,
      login,
      logout,
      isLoading: loginMutation.isPending
    }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}
EOF

    # Create Login page
    cat > src/pages/Login.tsx << 'EOF'
import { useState } from "react";
import { useAuth } from "../lib/auth";

export default function Login() {
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const { login, isLoading } = useAuth();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError("");
    
    try {
      await login(username, password);
    } catch (err: any) {
      setError(err.message || "Invalid credentials");
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-yellow-600 to-yellow-800 flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl shadow-2xl p-8 w-full max-w-md">
        <div className="text-center mb-8">
          <div className="w-20 h-20 bg-gradient-to-br from-yellow-600 to-yellow-800 rounded-full flex items-center justify-center mx-auto mb-4">
            <span className="text-white text-3xl font-bold">TGP</span>
          </div>
          <h2 className="text-3xl font-bold text-gray-900 mb-2">Chapter Officer Login</h2>
          <p className="text-gray-600">Tau Gamma Phi Rahugan CBC Chapter</p>
          <p className="text-sm text-gray-500">Dues Management System</p>
        </div>
        
        {error && (
          <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-md text-red-700 text-sm">
            {error}
          </div>
        )}
        
        <form onSubmit={handleSubmit} className="space-y-6">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Officer ID
            </label>
            <input
              type="text"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent"
              placeholder="Enter your officer ID"
              autoComplete="username"
              required
            />
          </div>
          
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Password
            </label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent"
              placeholder="Enter your password"
              autoComplete="current-password"
              required
            />
          </div>
          
          <button
            type="submit"
            disabled={isLoading}
            className="w-full bg-gradient-to-r from-yellow-600 to-yellow-700 text-white py-3 px-4 rounded-lg font-semibold hover:from-yellow-700 hover:to-yellow-800 focus:outline-none focus:ring-2 focus:ring-yellow-500 focus:ring-offset-2 disabled:opacity-50 transition-all duration-200"
          >
            {isLoading ? "Signing In..." : "Sign In"}
          </button>
        </form>
        
        <div className="mt-6 text-center">
          <p className="text-sm text-gray-600">
            Contact Chapter MKC for access credentials
          </p>
        </div>
      </div>
    </div>
  );
}
EOF

    # Create Dashboard page
    cat > src/pages/Dashboard.tsx << 'EOF'
import { useAuth } from "../lib/auth";

export default function Dashboard() {
  const { user, logout } = useAuth();

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="bg-white shadow">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-6">
            <div>
              <h1 className="text-3xl font-bold text-gray-900">TGP Dashboard</h1>
              <p className="text-gray-600">Welcome, {user?.name}</p>
            </div>
            <button
              onClick={logout}
              className="bg-red-600 hover:bg-red-700 text-white px-4 py-2 rounded-lg transition-colors"
            >
              Logout
            </button>
          </div>
        </div>
      </div>
      
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="bg-white rounded-lg shadow p-6">
          <h2 className="text-2xl font-bold mb-4">Chapter Management System</h2>
          <p className="text-gray-600 mb-6">
            Welcome to the Tau Gamma Phi Rahugan CBC Chapter Dues Management System.
          </p>
          
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div className="bg-blue-50 p-6 rounded-lg">
              <h3 className="text-lg font-semibold text-blue-900 mb-2">Members</h3>
              <p className="text-blue-700">Manage chapter members and their information</p>
            </div>
            
            <div className="bg-green-50 p-6 rounded-lg">
              <h3 className="text-lg font-semibold text-green-900 mb-2">Payments</h3>
              <p className="text-green-700">Track monthly dues and payment status</p>
            </div>
            
            <div className="bg-purple-50 p-6 rounded-lg">
              <h3 className="text-lg font-semibold text-purple-900 mb-2">Reports</h3>
              <p className="text-purple-700">Generate financial and member reports</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
EOF
}

# Application setup
setup_application() {
    log_step "Setting up TGP application"
    
    # Create application directory
    mkdir -p $APP_DIR
    cd $APP_DIR
    
    # Clone or copy the React application files
    if [ -d "/tmp/tgp-source" ]; then
        cp -r /tmp/tgp-source/* .
    else
        # Create the React application structure
        create_react_app
    fi
    
    # Install dependencies
    npm install
    
    # Build the React application
    npm run build
    
    # Create production server
    cat > server.js << 'EOF'
const express = require('express');
const path = require('path');
const { Pool } = require('pg');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 5000;

// Database connection
const pool = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgresql://rahuganmkc:rahugan2018@localhost:5432/tgp_dues_db'
});

// Middleware
app.use(cors());
app.use(express.json());

// Serve static files from React build
app.use(express.static(path.join(__dirname, 'dist')));

// Authentication endpoint
app.post('/api/auth/login', async (req, res) => {
  try {
    const { username, password, accountType = 'admin' } = req.body;
    
    if (accountType === 'admin') {
      const result = await pool.query(
        'SELECT * FROM users WHERE username = $1 AND password = $2 AND account_type = $3',
        [username, password, 'admin']
      );
      
      if (result.rows.length > 0) {
        const user = result.rows[0];
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
        res.status(401).json({ message: 'Invalid credentials' });
      }
    } else if (accountType === 'member') {
      const result = await pool.query(
        'SELECT * FROM members WHERE username = $1 AND password = $2',
        [username, password]
      );
      
      if (result.rows.length > 0) {
        const member = result.rows[0];
        res.json({
          user: {
            id: member.id,
            username: member.username,
            name: member.name,
            accountType: 'member'
          }
        });
      } else {
        res.status(401).json({ message: 'Invalid member credentials' });
      }
    } else {
      res.status(400).json({ message: 'Invalid account type' });
    }
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

// Serve React app for all routes
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'dist/index.html'));
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`TGP Dues Management System running on port ${PORT}`);
});
EOF

    # Set environment variables
    cat > .env << EOF
DATABASE_URL=postgresql://$DB_USER:$DB_PASSWORD@localhost:5432/$DB_NAME
NODE_ENV=production
PORT=$APP_PORT
EOF

    log_success "Application setup completed"
}

# Start application
start_application() {
    log_step "Starting application with PM2"
    
    cd $APP_DIR
    
    # Stop any existing instance
    pm2 stop $APP_NAME 2>/dev/null || true
    pm2 delete $APP_NAME 2>/dev/null || true
    
    # Start with environment variables
    DATABASE_URL="postgresql://$DB_USER:$DB_PASSWORD@localhost:5432/$DB_NAME" \
    NODE_ENV="production" \
    PORT="$APP_PORT" \
    pm2 start server.js --name "$APP_NAME" --max-memory-restart 1G
    
    # Configure PM2 startup
    pm2 save
    pm2 startup systemd
    
    log_success "Application started successfully"
}

# Configure Nginx
setup_nginx() {
    log_step "Configuring Nginx reverse proxy"
    
    cat > /etc/nginx/sites-available/tgp-dues << EOF
server {
    listen 80;
    server_name _;
    
    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    
    location / {
        proxy_pass http://127.0.0.1:$APP_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }
    
    # Static file caching
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        proxy_pass http://127.0.0.1:$APP_PORT;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF

    # Enable site
    ln -sf /etc/nginx/sites-available/tgp-dues /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    
    # Test and reload
    nginx -t && systemctl reload nginx
    
    log_success "Nginx configured successfully"
}

# Configure firewall
setup_firewall() {
    log_step "Configuring UFW firewall"
    
    ufw --force reset
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow ssh
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw --force enable
    
    log_success "Firewall configured successfully"
}

# Test deployment
test_deployment() {
    log_step "Testing deployment"
    
    sleep 10
    
    # Test PM2 process
    if ! pm2 list | grep -q "$APP_NAME.*online"; then
        log_error "PM2 process not running"
        pm2 logs $APP_NAME --lines 10
        return 1
    fi
    
    # Test port
    if ! ss -tlnp | grep -q ":$APP_PORT "; then
        log_error "Port $APP_PORT not listening"
        return 1
    fi
    
    # Test HTTP response
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$APP_PORT 2>/dev/null || echo "000")
    if [[ ! $HTTP_CODE =~ ^(200|302)$ ]]; then
        log_error "HTTP test failed: $HTTP_CODE"
        return 1
    fi
    
    # Test admin authentication
    ADMIN_TEST=$(curl -s -X POST http://localhost:$APP_PORT/api/auth/login \
        -H "Content-Type: application/json" \
        -d '{"username":"treasurer","password":"password123","accountType":"admin"}' 2>/dev/null || echo "error")
    
    if [[ $ADMIN_TEST == *"user"* && $ADMIN_TEST == *"treasurer"* ]]; then
        log_success "Admin authentication working"
    else
        log_error "Admin authentication failed"
        return 1
    fi
    
    # Test member authentication
    MEMBER_TEST=$(curl -s -X POST http://localhost:$APP_PORT/api/auth/login \
        -H "Content-Type: application/json" \
        -d '{"username":"juan.delacruz","password":"member123","accountType":"member"}' 2>/dev/null || echo "error")
    
    if [[ $MEMBER_TEST == *"user"* && $MEMBER_TEST == *"Juan"* ]]; then
        log_success "Member authentication working"
    else
        log_error "Member authentication failed"
        return 1
    fi
    
    log_success "All deployment tests passed"
}

# Show completion summary
show_completion() {
    SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
    
    clear
    print_banner
    
    echo -e "${GREEN}${BOLD}"
    echo "============================================================================"
    echo "                        DEPLOYMENT COMPLETED SUCCESSFULLY!"
    echo "============================================================================"
    echo -e "${NC}"
    
    echo -e "${WHITE}${BOLD}🌐 ACCESS INFORMATION${NC}"
    echo -e "${CYAN}┌─────────────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC} Application URL: ${GREEN}${BOLD}http://$SERVER_IP${NC}                                    ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} System Status: ${GREEN}✅ FULLY OPERATIONAL${NC}                              ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} Interface: ${GREEN}✅ REACT LOGIN & DASHBOARD${NC}                         ${CYAN}│${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    echo -e "${WHITE}${BOLD}👤 LOGIN CREDENTIALS${NC}"
    echo -e "${CYAN}┌─────────────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC} ${GREEN}${BOLD}ADMINISTRATOR LOGIN${NC}                                               ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}   Username: ${YELLOW}treasurer${NC}                                           ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}   Password: ${YELLOW}password123${NC}                                        ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}                                                                       ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} ${GREEN}${BOLD}MEMBER PORTAL ACCESS${NC}                                               ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}   Sample: ${YELLOW}juan.delacruz${NC} / ${YELLOW}member123${NC}                              ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}   Sample: ${YELLOW}mark.santos${NC} / ${YELLOW}member123${NC}                                ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}   Sample: ${YELLOW}paolo.rodriguez${NC} / ${YELLOW}member123${NC}                           ${CYAN}│${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    echo -e "${WHITE}${BOLD}🛠️  MANAGEMENT COMMANDS${NC}"
    echo -e "${CYAN}┌─────────────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC} Application Status: ${YELLOW}pm2 status${NC}                                    ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} View Logs: ${YELLOW}pm2 logs $APP_NAME${NC}                                     ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} Restart App: ${YELLOW}pm2 restart $APP_NAME${NC}                                ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} Database Access: ${YELLOW}PGPASSWORD=$DB_PASSWORD psql -U $DB_USER -d $DB_NAME${NC}    ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} System Status: ${YELLOW}systemctl status nginx postgresql${NC}                 ${CYAN}│${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    echo -e "${GREEN}${BOLD}🎉 TGP Rahugan CBC Chapter Dues Management System is LIVE!${NC}"
    echo -e "${WHITE}React-based interface with modern authentication system ready for production.${NC}"
}

# Main execution
main() {
    # Check root privileges
    if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root. Use: sudo bash deploy-tgp.sh"
        exit 1
    fi
    
    print_banner
    sleep 3
    
    setup_system
    setup_database
    setup_application
    start_application
    setup_nginx
    setup_firewall
    test_deployment
    show_completion
}

# Execute deployment
main "$@"
