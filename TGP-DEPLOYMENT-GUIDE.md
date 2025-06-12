# TGP Rahugan CBC Chapter - Complete Deployment Guide

## Overview
Single-script deployment solution for the Tau Gamma Phi Rahugan CBC Chapter Dues Management System on Ubuntu VPS.

## Prerequisites
- Ubuntu 18.04+ VPS with root access
- Minimum 2GB RAM, 20GB storage
- Internet connection

## Quick Deployment

### One-Command Installation
```bash
sudo bash deploy-tgp.sh
```

### What the Script Does
1. **System Setup**: Updates Ubuntu, installs Node.js (fixing dependency conflicts), PostgreSQL, Nginx
2. **Database Configuration**: Creates PostgreSQL database with proper schema and default accounts
3. **Application Setup**: Creates optimized Node.js server with authentication system
4. **Web Interface**: Deploys TGP-branded login interface with modern design
5. **Security Configuration**: Sets up firewall, reverse proxy, and security headers
6. **Testing**: Validates all components and authentication systems

## Access Information

### Web Interface
```
URL: http://your-server-ip
```

### Login Credentials

**Administrator Access:**
- Username: `treasurer`
- Password: `password123`
- Features: Full system management, financial reports, member administration

**Member Portal Access:**
- Username: `juan.delacruz` / Password: `member123` (Local Member)
- Username: `mark.santos` / Password: `member123` (Local Member)
- Username: `paolo.rodriguez` / Password: `member123` (Welcome Member)
- Features: Personal payment history, profile management

## System Management

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

# Start application
pm2 start tgp-dues
```

### Database Management
```bash
# Connect to database
PGPASSWORD=rahugan2018 psql -U rahuganmkc -d tgp_dues_db

# View admin accounts
psql -U rahuganmkc -d tgp_dues_db -c "SELECT username, name, account_type FROM users;"

# View member accounts
psql -U rahuganmkc -d tgp_dues_db -c "SELECT username, name, member_type FROM members WHERE username IS NOT NULL;"

# Backup database
pg_dump -U rahuganmkc -h localhost tgp_dues_db > backup_$(date +%Y%m%d).sql
```

### System Services
```bash
# Check all services
systemctl status nginx postgresql

# Restart services
systemctl restart nginx
systemctl restart postgresql

# View service logs
journalctl -u nginx -f
journalctl -u postgresql -f
```

## Adding Admin Accounts

### Method 1: Database Direct
```bash
PGPASSWORD=rahugan2018 psql -U rahuganmkc -d tgp_dues_db -c "
INSERT INTO users (username, name, password, position, account_type) 
VALUES ('newadmin', 'Admin Name', 'securepassword', 'Position', 'admin');"
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

PGPASSWORD=rahugan2018 psql -U rahuganmkc -d tgp_dues_db -c "
INSERT INTO users (username, name, password, position, account_type) 
VALUES ('$username', '$name', '$password', '$position', 'admin');"

echo "Admin account '$username' created successfully"
EOF

chmod +x add-admin.sh
./add-admin.sh
```

## Adding Member Accounts

### Database Method
```bash
PGPASSWORD=rahugan2018 psql -U rahuganmkc -d tgp_dues_db -c "
INSERT INTO members (name, address, initiation_date, member_type, username, password, batch_number)
VALUES ('Member Name', 'Address', '2024-01-01', 'pure_blooded', 'username', 'password', 'BATCH-###');"
```

## SSL Certificate Setup (Optional)

### Install Certbot
```bash
apt install certbot python3-certbot-nginx
```

### Get SSL Certificate
```bash
# Replace yourdomain.com with your actual domain
certbot --nginx -d yourdomain.com

# Setup auto-renewal
echo "0 12 * * * /usr/bin/certbot renew --quiet" | crontab -
```

### Update Domain Configuration
```bash
# Update Nginx configuration for your domain
nano /etc/nginx/sites-available/tgp-dues

# Change server_name from _ to your domain
# server_name yourdomain.com www.yourdomain.com;
```

## Backup and Maintenance

### Automated Backup Script
```bash
cat > /root/backup-tgp.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/root/backups"
mkdir -p $BACKUP_DIR

# Database backup
pg_dump -U rahuganmkc -h localhost tgp_dues_db > $BACKUP_DIR/db_$DATE.sql

# Application backup
tar -czf $BACKUP_DIR/app_$DATE.tar.gz /root/tgp-dues

# Clean old backups (keep 30 days)
find $BACKUP_DIR -name "*.sql" -mtime +30 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +30 -delete

echo "Backup completed: $DATE"
EOF

chmod +x /root/backup-tgp.sh

# Schedule daily backups at 2 AM
echo "0 2 * * * /root/backup-tgp.sh" | crontab -
```

### System Updates
```bash
# Update system packages
apt update && apt upgrade -y

# Update Node.js dependencies
cd /root/tgp-dues
npm update

# Restart application after updates
pm2 restart tgp-dues
```

## Monitoring and Logs

### Application Monitoring
```bash
# Real-time logs
pm2 logs tgp-dues --lines 50 -f

# Application metrics
pm2 monit

# System resources
htop
```

### Log Locations
- Application: `pm2 logs tgp-dues`
- Nginx: `/var/log/nginx/access.log` and `/var/log/nginx/error.log`
- PostgreSQL: `/var/log/postgresql/`
- System: `journalctl -u tgp-dues`

## Troubleshooting

### Common Issues

**Application Not Starting:**
```bash
# Check PM2 status
pm2 status

# Check logs for errors
pm2 logs tgp-dues --lines 20

# Restart application
pm2 restart tgp-dues
```

**Database Connection Issues:**
```bash
# Test database connection
PGPASSWORD=rahugan2018 psql -U rahuganmkc -d tgp_dues_db -c "SELECT version();"

# Restart PostgreSQL
systemctl restart postgresql

# Check PostgreSQL status
systemctl status postgresql
```

**Nginx/Web Server Issues:**
```bash
# Test Nginx configuration
nginx -t

# Restart Nginx
systemctl restart nginx

# Check port availability
ss -tlnp | grep :80
```

**Port 5000 Not Accessible:**
```bash
# Check if application is listening
ss -tlnp | grep :5000

# Check firewall rules
ufw status

# Restart application
pm2 restart tgp-dues
```

### Performance Optimization

**Database Optimization:**
```bash
# Connect to database
PGPASSWORD=rahugan2018 psql -U rahuganmkc -d tgp_dues_db

# Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_members_username ON members(username);
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_payments_member_id ON payments(member_id);
CREATE INDEX IF NOT EXISTS idx_payments_date ON payments(payment_date);
```

**Application Optimization:**
```bash
# Increase PM2 memory limit if needed
pm2 restart tgp-dues --max-memory-restart 2G

# Enable PM2 cluster mode for better performance
pm2 delete tgp-dues
pm2 start server.js --name "tgp-dues" -i max
```

## Security Recommendations

### Change Default Passwords
```bash
# Update admin password
PGPASSWORD=rahugan2018 psql -U rahuganmkc -d tgp_dues_db -c "
UPDATE users SET password = 'new_secure_password' WHERE username = 'treasurer';"

# Update database password
sudo -u postgres psql -c "ALTER USER rahuganmkc WITH PASSWORD 'new_db_password';"
```

### Firewall Configuration
```bash
# View current rules
ufw status numbered

# Allow specific IPs only (optional)
ufw allow from YOUR_OFFICE_IP to any port 22
ufw allow from YOUR_OFFICE_IP to any port 80

# Remove default SSH access (if using IP restriction)
ufw delete allow ssh
```

### Regular Security Updates
```bash
# Weekly security updates
apt update && apt list --upgradable
apt upgrade -y

# Monthly full system update
apt full-upgrade -y
apt autoremove -y
```

## Support and Maintenance

### System Health Check
```bash
# Create health check script
cat > /root/health-check.sh << 'EOF'
#!/bin/bash
echo "=== TGP System Health Check ==="
echo "Date: $(date)"
echo ""

echo "PM2 Status:"
pm2 list

echo ""
echo "Database Connection:"
PGPASSWORD=rahugan2018 psql -U rahuganmkc -d tgp_dues_db -c "SELECT 'Database OK' as status;" 2>/dev/null || echo "Database Error"

echo ""
echo "Web Server:"
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost:5000

echo ""
echo "Disk Usage:"
df -h /

echo ""
echo "Memory Usage:"
free -h

echo ""
echo "System Load:"
uptime
EOF

chmod +x /root/health-check.sh
./health-check.sh
```

### Contact and Support
- Technical Issues: Check application logs and system status
- Access Problems: Verify credentials and network connectivity
- Feature Requests: Contact Chapter MKC
- System Administration: Refer to this guide and standard Ubuntu documentation

---

**Deployment Complete**: The TGP Rahugan CBC Chapter Dues Management System is production-ready with secure authentication, modern interface, and comprehensive management tools.