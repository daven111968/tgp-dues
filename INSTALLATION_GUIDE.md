# TGP Rahugan CBC Chapter - Dues Management System
## Complete Installation Guide for Ubuntu VPS

### Overview
This guide provides step-by-step instructions to deploy the Tau Gamma Phi Rahugan CBC Chapter Dues Management System on an Ubuntu VPS with a single command.

### System Requirements
- Ubuntu 18.04, 20.04, or 22.04 LTS
- Minimum 2GB RAM
- 20GB free disk space
- Root or sudo access
- Internet connection

### Features Included
- Member management with payment tracking
- Admin dashboard with financial reports
- Member portal for self-service
- Payment history and status tracking
- PDF report generation
- Mobile-responsive design
- Secure authentication system

---

## Quick Installation (5 Minutes)

### Step 1: Connect to Your VPS
```bash
ssh root@your-server-ip
```

### Step 2: Download and Run Installer
```bash
# Download the project files
wget https://github.com/your-repo/tgp-dues/archive/main.zip
unzip main.zip
cd tgp-dues-main

# Or if using git:
git clone https://github.com/your-repo/tgp-dues.git
cd tgp-dues

# Run the one-click installer
chmod +x install.sh
./install.sh
```

### Step 3: Access Your System
After installation completes (5-10 minutes), access your system at:
```
http://your-server-ip
```

---

## Manual Installation Steps

If you prefer to understand each step or need to troubleshoot:

### 1. System Preparation
```bash
# Update system
apt update && apt upgrade -y

# Install required packages
apt install -y curl wget unzip git
```

### 2. Install Node.js
```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs
```

### 3. Install PostgreSQL
```bash
apt install -y postgresql postgresql-contrib
systemctl start postgresql
systemctl enable postgresql
```

### 4. Setup Database
```bash
sudo -u postgres createdb tgp_dues_db
sudo -u postgres psql -c "CREATE USER rahuganmkc WITH ENCRYPTED PASSWORD 'rahugan2018';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE tgp_dues_db TO rahuganmkc;"
```

### 5. Install Application
```bash
# Create app directory
mkdir -p /var/www/tgp-dues
cd /var/www/tgp-dues

# Copy your project files here
# Install dependencies
npm install

# Create environment file
cat > .env << EOF
DATABASE_URL=postgresql://rahuganmkc:rahugan2018@localhost:5432/tgp_dues_db
NODE_ENV=production
PORT=5000
EOF
```

### 6. Install Process Manager
```bash
npm install -g pm2
pm2 start "npx tsx server/index.ts" --name "tgp-dues"
pm2 save
pm2 startup
```

### 7. Configure Web Server
```bash
apt install -y nginx
# Configure nginx (see configuration section below)
systemctl restart nginx
```

### 8. Setup Firewall
```bash
ufw allow ssh
ufw allow 80
ufw allow 443
ufw enable
```

---

## Default Credentials

### Administrator Access
- **URL:** `http://your-server-ip`
- **Username:** `treasurer`
- **Password:** `password123`

### Member Portal Access
- **URL:** `http://your-server-ip` (click "Member Login")
- **Sample Accounts:**
  - Username: `juan.delacruz`
  - Username: `mark.santos`
  - Username: `paolo.rodriguez`
- **Password:** `member123`

### Database Access
- **Database:** `tgp_dues_db`
- **Username:** `rahuganmkc`
- **Password:** `rahugan2018`
- **Host:** `localhost`
- **Port:** `5432`

---

## Post-Installation Configuration

### 1. Change Default Passwords
After first login, immediately change all default passwords:
- Admin password in Settings
- Member passwords individually
- Database password (optional)

### 2. Configure Chapter Information
1. Login as administrator
2. Go to Settings page
3. Update chapter information:
   - Chapter name
   - Contact details
   - Payment structure

### 3. Add Members
1. Go to Members page
2. Click "Add Member"
3. Fill in member details
4. Set member type (local/out-of-town)

### 4. Configure Payment Structure
The system supports variable dues:
- Local members: ₱100/month
- Out-of-town workers: ₱200/month

---

## Management Commands

### Application Management
```bash
# Check application status
pm2 status

# View application logs
pm2 logs tgp-dues

# Restart application
pm2 restart tgp-dues

# Stop application
pm2 stop tgp-dues
```

### Database Management
```bash
# Connect to database
PGPASSWORD=rahugan2018 psql -U rahuganmkc -d tgp_dues_db -h localhost

# Backup database
pg_dump -U rahuganmkc -h localhost tgp_dues_db > backup.sql

# Restore database
psql -U rahuganmkc -h localhost tgp_dues_db < backup.sql
```

### Web Server Management
```bash
# Check nginx status
systemctl status nginx

# Restart nginx
systemctl restart nginx

# View nginx logs
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log
```

---

## Troubleshooting

### Common Issues

**1. 502 Bad Gateway Error**
```bash
# Check if application is running
pm2 status

# Check application logs
pm2 logs tgp-dues

# Restart application
pm2 restart tgp-dues
```

**2. Database Connection Error**
```bash
# Check PostgreSQL status
systemctl status postgresql

# Test database connection
PGPASSWORD=rahugan2018 psql -U rahuganmkc -d tgp_dues_db -h localhost -c '\q'

# Restart PostgreSQL
systemctl restart postgresql
```

**3. Port Already in Use**
```bash
# Check what's using port 5000
ss -tlnp | grep :5000

# Kill process if needed
sudo kill -9 $(sudo lsof -t -i:5000)
```

### Log Locations
- Application logs: `pm2 logs tgp-dues`
- Nginx access logs: `/var/log/nginx/access.log`
- Nginx error logs: `/var/log/nginx/error.log`
- PostgreSQL logs: `/var/log/postgresql/`

---

## Security Recommendations

### 1. Firewall Configuration
```bash
# Allow only necessary ports
ufw deny incoming
ufw allow ssh
ufw allow 80
ufw allow 443
ufw enable
```

### 2. SSL Certificate (Recommended)
```bash
# Install certbot
apt install certbot python3-certbot-nginx

# Get SSL certificate
certbot --nginx -d yourdomain.com

# Auto-renewal
crontab -e
# Add: 0 12 * * * /usr/bin/certbot renew --quiet
```

### 3. Regular Updates
```bash
# Update system packages monthly
apt update && apt upgrade -y

# Update Node.js dependencies
cd /var/www/tgp-dues
npm update
```

### 4. Database Security
- Change default database password
- Regular database backups
- Restrict database access to localhost only

---

## System Architecture

```
Internet → Nginx (Port 80/443) → Application (Port 5000) → PostgreSQL (Port 5432)
                ↓
         Static Files & Reverse Proxy
```

### Components
- **Frontend:** React with TypeScript
- **Backend:** Express.js with TypeScript
- **Database:** PostgreSQL
- **Process Manager:** PM2
- **Web Server:** Nginx
- **Authentication:** Passport.js

---

## Support and Maintenance

### Regular Maintenance Tasks
1. **Weekly:** Check application logs and performance
2. **Monthly:** Update system packages and dependencies
3. **Quarterly:** Database backup and cleanup
4. **Annually:** Security audit and password changes

### Backup Strategy
```bash
# Create backup script
cat > /root/backup-tgp.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
pg_dump -U rahuganmkc -h localhost tgp_dues_db > /root/backups/tgp_backup_$DATE.sql
tar -czf /root/backups/app_backup_$DATE.tar.gz /var/www/tgp-dues
# Keep only last 30 days of backups
find /root/backups -name "*.sql" -mtime +30 -delete
find /root/backups -name "*.tar.gz" -mtime +30 -delete
EOF

chmod +x /root/backup-tgp.sh

# Schedule daily backups
crontab -e
# Add: 0 2 * * * /root/backup-tgp.sh
```

### Monitoring
- Monitor disk space usage
- Check application memory usage
- Monitor database performance
- Review access logs for unusual activity

---

## Contact Information

For technical support or customization requests:
- **System Administrator:** Contact your chapter treasurer
- **Documentation:** Refer to this guide
- **Updates:** Check repository for latest versions

---

*This installation guide ensures your TGP Rahugan CBC Chapter Dues Management System is properly deployed and secured for production use.*