# TGP Rahugan CBC Chapter - Complete Deployment Tutorial

## Overview
This tutorial provides complete deployment of the Tau Gamma Phi Rahugan CBC Chapter Dues Management System on Ubuntu VPS with fixed authentication and React interface.

## Quick Deployment (5 Minutes)

### Prerequisites
- Ubuntu 18.04+ VPS with root access
- Minimum 2GB RAM, 20GB storage
- Internet connection

### One-Command Installation
```bash
chmod +x FINAL_DEPLOYMENT.sh
./FINAL_DEPLOYMENT.sh
```

## What the Script Does

### 1. Environment Setup
- Creates production environment configuration
- Sets database connection parameters
- Configures session secrets

### 2. Authentication Fix
- Resolves "Invalid request" errors
- Creates dual login system (admin/member)
- Implements proper request validation
- Adds comprehensive error handling

### 3. React Application Build
- Builds the React frontend properly
- Copies files to correct server directory
- Ensures all assets are available

### 4. Database Configuration
- Creates all required tables
- Sets up admin accounts (treasurer/admin)
- Creates sample member accounts
- Configures chapter information

### 5. Application Startup
- Starts with PM2 process manager
- Sets all environment variables
- Configures automatic restart

### 6. Comprehensive Testing
- Tests PM2 process status
- Verifies port accessibility
- Tests admin login functionality
- Tests member login functionality
- Validates HTTP responses

## Access Information

### Application URL
```
http://your-server-ip
```

### Administrator Login
- **Username:** treasurer
- **Password:** password123
- **Features:** Full system access, member management, financial reports

### Member Portal Login
- **Username:** juan.delacruz, mark.santos, paolo.rodriguez
- **Password:** member123
- **Features:** Personal payment history, profile management

### Database Access
```bash
PGPASSWORD=rahugan2018 psql -U rahuganmkc -d tgp_dues_db -h localhost
```

## System Features

### Admin Dashboard
- Member management with batch tracking
- Payment processing and history
- Financial reports with PDF export
- Chapter information management
- Activity and contribution tracking

### Member Portal
- Personal payment history
- Profile information
- Due amount calculations
- Payment status tracking

### Technical Features
- Variable dues structure (₱100 local, ₱200 out-of-town)
- Dynamic date filtering
- Mobile-responsive design
- Progressive Web App capabilities
- Secure authentication system

## Management Commands

### Application Management
```bash
# Check status
pm2 status

# View logs
pm2 logs tgp-dues

# Restart application
pm2 restart tgp-dues

# Stop application
pm2 stop tgp-dues
```

### Database Operations
```bash
# Connect to database
PGPASSWORD=rahugan2018 psql -U rahuganmkc -d tgp_dues_db -h localhost

# Backup database
pg_dump -U rahuganmkc -h localhost tgp_dues_db > backup.sql

# View admin accounts
psql -U rahuganmkc -d tgp_dues_db -c "SELECT * FROM users WHERE account_type = 'admin';"
```

### System Monitoring
```bash
# Check port status
ss -tlnp | grep :5000

# Monitor server resources
htop

# View nginx logs (if configured)
tail -f /var/log/nginx/access.log
```

## Adding Domain (Optional)

### 1. Configure DNS
Point your domain to server IP:
```
A Record: yourdomain.com → your-server-ip
```

### 2. Update Nginx
```bash
# Install nginx if not present
apt install nginx

# Create domain configuration
cat > /etc/nginx/sites-available/tgp-dues << 'EOF'
server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;
    
    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
EOF

# Enable site
ln -sf /etc/nginx/sites-available/tgp-dues /etc/nginx/sites-enabled/
systemctl reload nginx
```

### 3. SSL Certificate (Recommended)
```bash
# Install certbot
apt install certbot python3-certbot-nginx

# Get certificate
certbot --nginx -d yourdomain.com

# Setup auto-renewal
echo "0 12 * * * /usr/bin/certbot renew --quiet" | crontab -
```

## Adding Admin Accounts

### Method 1: Database Direct
```bash
PGPASSWORD=rahugan2018 psql -U rahuganmkc -d tgp_dues_db -h localhost -c "
INSERT INTO users (username, name, password, position, account_type) 
VALUES ('newadmin', 'Admin Name', 'password123', 'Position', 'admin');"
```

### Method 2: Interactive Script
```bash
# Create admin management script
cat > add-admin.sh << 'EOF'
#!/bin/bash
read -p "Username: " username
read -s -p "Password: " password
echo
read -p "Full Name: " name
read -p "Position: " position

PGPASSWORD=rahugan2018 psql -U rahuganmkc -d tgp_dues_db -h localhost -c "
INSERT INTO users (username, name, password, position, account_type) 
VALUES ('$username', '$name', '$password', '$position', 'admin');"

echo "Admin account created successfully"
EOF

chmod +x add-admin.sh
./add-admin.sh
```

## Backup and Maintenance

### Automated Backup Script
```bash
cat > /root/backup-tgp.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p /root/backups

# Database backup
pg_dump -U rahuganmkc -h localhost tgp_dues_db > /root/backups/db_$DATE.sql

# Application backup
tar -czf /root/backups/app_$DATE.tar.gz /var/www/tgp-dues

# Clean old backups (keep 30 days)
find /root/backups -name "*.sql" -mtime +30 -delete
find /root/backups -name "*.tar.gz" -mtime +30 -delete

echo "Backup completed: $DATE"
EOF

chmod +x /root/backup-tgp.sh

# Schedule daily backups
echo "0 2 * * * /root/backup-tgp.sh" | crontab -
```

### Update Procedure
```bash
# Navigate to application directory
cd /var/www/tgp-dues

# Stop application
pm2 stop tgp-dues

# Pull updates (if using git)
git pull

# Install dependencies
npm install

# Rebuild application
npm run build

# Copy build files
rm -rf server/public
mkdir -p server/public
cp -r dist/public/* server/public/

# Restart application
pm2 restart tgp-dues
```

## Troubleshooting

### Common Issues

**1. Authentication "Invalid request" Error**
- Solution already implemented in FINAL_DEPLOYMENT.sh
- Verify database has admin accounts
- Check application logs: `pm2 logs tgp-dues`

**2. Build Directory Not Found**
- Solution: Script properly builds and copies React files
- Verify server/public exists with index.html

**3. Database Connection Failed**
```bash
# Restart PostgreSQL
systemctl restart postgresql

# Check connection
PGPASSWORD=rahugan2018 psql -U rahuganmkc -d tgp_dues_db -h localhost -c '\q'
```

**4. Application Not Starting**
```bash
# Check PM2 logs
pm2 logs tgp-dues

# Restart with environment variables
cd /var/www/tgp-dues
DATABASE_URL="postgresql://rahuganmkc:rahugan2018@localhost:5432/tgp_dues_db" pm2 restart tgp-dues
```

**5. Port 5000 Not Listening**
```bash
# Check what's using the port
ss -tlnp | grep :5000

# Kill conflicting processes
sudo fuser -k 5000/tcp

# Restart application
pm2 restart tgp-dues
```

### Log Locations
- Application: `pm2 logs tgp-dues`
- Database: `/var/log/postgresql/`
- System: `journalctl -u tgp-dues`

## Security Recommendations

### 1. Change Default Passwords
- Update treasurer password immediately
- Change database password in production
- Use strong passwords for all accounts

### 2. Firewall Configuration
```bash
ufw allow ssh
ufw allow 80
ufw allow 443
ufw deny 5000  # Block direct access to app port
ufw enable
```

### 3. Regular Updates
```bash
# System packages
apt update && apt upgrade

# Application dependencies
cd /var/www/tgp-dues && npm update
```

### 4. Monitoring Setup
```bash
# Install monitoring tools
apt install htop iotop nethogs

# Monitor application
watch -n 5 'pm2 status && ss -tlnp | grep :5000'
```

## Support and Contact

### System Administration
- Application logs contain detailed error information
- Database includes audit trails for all transactions
- PM2 provides process monitoring and auto-restart

### Chapter Contact
- Technical issues: Contact system administrator
- Access requests: Contact Chapter MKC
- Feature requests: Refer to development team

---

**Deployment completed successfully with all authentication issues resolved and React interface fully functional.**