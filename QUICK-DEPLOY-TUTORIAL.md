# TGP CBC Chapter Management System - Complete Deployment Tutorial

## 🚀 One-Click Deployment Guide

This tutorial provides complete step-by-step instructions for deploying the Tau Gamma Phi CBC Chapter Management System on any Ubuntu VPS.

## Prerequisites

- **Ubuntu VPS**: 20.04 or 22.04 LTS
- **Minimum specs**: 1GB RAM, 1 CPU core, 20GB storage
- **Root access**: SSH access with sudo privileges
- **Domain (optional)**: For SSL and professional URL

## Quick Start (5 Minutes)

### Step 1: Connect to Your Server
```bash
ssh root@your-server-ip
```

### Step 2: Download and Run Quick Deploy
```bash
# Download the deployment script
wget https://raw.githubusercontent.com/your-repo/quick-deploy.sh

# Make it executable
chmod +x quick-deploy.sh

# Run the deployment
./quick-deploy.sh
```

### Step 3: Upload Your Application
```bash
# Upload your application files (from your local machine)
scp -r ./your-app-folder/* root@your-server-ip:/opt/tgp-chapter/

# Set proper ownership on the server
chown -R tgpchapter:tgpchapter /opt/tgp-chapter/
```

### Step 4: Start the Application
```bash
# Switch to application directory
cd /opt/tgp-chapter

# Run the setup script
sudo -u tgpchapter ./setup-app.sh
```

### Step 5: Access Your Application
Open your web browser and go to:
- `http://your-server-ip` (if using IP)
- `http://your-domain.com` (if using domain)

**Default login credentials:**
- Username: `treasurer`
- Password: `password123`

⚠️ **IMPORTANT**: Change the default password immediately after first login!

---

## Detailed Deployment Walkthrough

### What the Quick Deploy Script Does

The `quick-deploy.sh` script performs a complete automated setup:

1. **System Updates**
   - Updates all Ubuntu packages
   - Installs security updates

2. **Software Installation**
   - Node.js 20.x (latest LTS)
   - PostgreSQL database server
   - Nginx web server
   - PM2 process manager
   - SSL certificate tools (Certbot)

3. **Database Setup**
   - Creates `tgp_chapter_db` database
   - Creates `tgp_user` with secure password
   - Configures proper permissions

4. **Application Environment**
   - Creates `tgpchapter` system user
   - Sets up `/opt/tgp-chapter` directory
   - Generates secure environment variables

5. **Web Server Configuration**
   - Configures Nginx as reverse proxy
   - Sets up security headers
   - Enables gzip compression
   - Rate limiting for login attempts

6. **Security Setup**
   - Configures UFW firewall
   - Opens only necessary ports (SSH, HTTP, HTTPS)
   - Applies security best practices

7. **Management Tools**
   - Creates deployment scripts
   - Sets up automatic database backups
   - Configures system monitoring

### Manual Verification Steps

After running the quick deploy script, verify the installation:

```bash
# Check system services
systemctl status nginx
systemctl status postgresql

# Check application user
id tgpchapter

# Check application directory
ls -la /opt/tgp-chapter/

# Check database
sudo -u postgres psql -l | grep tgp_chapter_db

# Check firewall
ufw status

# Check Node.js installation
node --version
npm --version
```

## Application File Structure

Your application should have this structure in `/opt/tgp-chapter/`:

```
/opt/tgp-chapter/
├── client/                 # Frontend files
├── server/                 # Backend files
├── shared/                 # Shared utilities
├── package.json           # Dependencies
├── .env                   # Environment variables
├── ecosystem.config.js    # PM2 configuration
├── logs/                  # Application logs
├── backups/               # Database backups
├── deploy.sh             # Deployment script
├── backup.sh             # Backup script
├── setup-app.sh          # Initial setup script
└── server-info.txt       # Server information
```

## Configuration Details

### Environment Variables (.env)
```bash
# Database
DATABASE_URL=postgresql://tgp_user:password@localhost:5432/tgp_chapter_db
PGHOST=localhost
PGPORT=5432
PGUSER=tgp_user
PGPASSWORD=auto-generated-secure-password
PGDATABASE=tgp_chapter_db

# Application
NODE_ENV=production
PORT=3000

# Security
SESSION_SECRET=auto-generated-64-char-secret
```

### PM2 Configuration (ecosystem.config.js)
```javascript
module.exports = {
  apps: [{
    name: 'tgp-chapter-management',
    script: 'npm',
    args: 'start',
    cwd: '/opt/tgp-chapter',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    instances: 1,
    autorestart: true,
    max_memory_restart: '1G'
  }]
};
```

### Nginx Configuration
```nginx
server {
    listen 80;
    server_name your-domain.com;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;

    # Reverse proxy to Node.js app
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Static file caching
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

## Domain and SSL Setup

### Step 1: Configure DNS
Point your domain to your server IP:
```
Type: A
Name: @
Value: your-server-ip
TTL: 3600
```

### Step 2: Update Nginx Configuration
```bash
# Edit Nginx configuration
nano /etc/nginx/sites-available/tgp-chapter

# Change server_name from IP to your domain
server_name your-domain.com;

# Test and reload
nginx -t
systemctl reload nginx
```

### Step 3: Install SSL Certificate
```bash
# Install SSL certificate with Certbot
certbot --nginx -d your-domain.com

# Verify auto-renewal
certbot renew --dry-run
```

## Management and Maintenance

### Daily Operations

**Check Application Status:**
```bash
pm2 status
pm2 logs tgp-chapter-management
```

**Monitor System Resources:**
```bash
htop                    # CPU and memory usage
df -h                   # Disk usage
systemctl status nginx  # Web server status
systemctl status postgresql  # Database status
```

**View Application Logs:**
```bash
# Real-time logs
pm2 logs tgp-chapter-management --lines 100

# Error logs only
pm2 logs tgp-chapter-management --err

# Access logs
tail -f /var/log/nginx/access.log
```

### Backup and Restore

**Manual Backup:**
```bash
cd /opt/tgp-chapter
./backup.sh
```

**Automatic Backups:**
Backups run daily at 2:00 AM and are stored in `/opt/tgp-chapter/backups/`

**Restore from Backup:**
```bash
# List available backups
ls -la /opt/tgp-chapter/backups/

# Restore specific backup
gunzip backup_file.sql.gz
PGPASSWORD=password psql -h localhost -U tgp_user -d tgp_chapter_db < backup_file.sql
```

### Application Updates

**Deploy New Version:**
```bash
cd /opt/tgp-chapter
./deploy.sh
```

**Manual Update Process:**
```bash
# Stop application
pm2 stop tgp-chapter-management

# Update files (upload new version)
# Set ownership
chown -R tgpchapter:tgpchapter /opt/tgp-chapter/

# Install dependencies
sudo -u tgpchapter npm install

# Build application
sudo -u tgpchapter npm run build

# Update database schema
sudo -u tgpchapter npm run db:push

# Start application
pm2 start tgp-chapter-management
```

## Troubleshooting Guide

### Common Issues and Solutions

**Issue: Application won't start**
```bash
# Check PM2 logs
pm2 logs tgp-chapter-management

# Check if port 3000 is in use
netstat -tlnp | grep :3000

# Restart PM2
pm2 restart tgp-chapter-management
```

**Issue: Database connection failed**
```bash
# Check PostgreSQL status
systemctl status postgresql

# Test database connection
PGPASSWORD=password psql -h localhost -U tgp_user -d tgp_chapter_db

# Check database exists
sudo -u postgres psql -l | grep tgp_chapter
```

**Issue: Nginx 502 Bad Gateway**
```bash
# Check if Node.js app is running
pm2 status

# Check Nginx configuration
nginx -t

# Check Nginx error logs
tail -f /var/log/nginx/error.log

# Restart services
systemctl restart nginx
pm2 restart tgp-chapter-management
```

**Issue: SSL certificate problems**
```bash
# Check certificate status
certbot certificates

# Renew certificate
certbot renew

# Test renewal
certbot renew --dry-run
```

**Issue: High memory usage**
```bash
# Check memory usage
free -h
pm2 monit

# Restart application to clear memory leaks
pm2 restart tgp-chapter-management
```

### Performance Optimization

**Database Optimization:**
```sql
-- Connect to database
PGPASSWORD=password psql -h localhost -U tgp_user -d tgp_chapter_db

-- Check database size
SELECT pg_size_pretty(pg_database_size('tgp_chapter_db'));

-- Analyze tables
ANALYZE;

-- Vacuum tables
VACUUM;
```

**Application Optimization:**
```bash
# Enable PM2 monitoring
pm2 install pm2-server-monit

# Check application metrics
pm2 show tgp-chapter-management
```

**Nginx Optimization:**
Add to Nginx configuration:
```nginx
# Increase worker connections
events {
    worker_connections 1024;
}

# Enable additional compression
gzip_comp_level 6;
gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
```

## Security Best Practices

### Post-Deployment Security

1. **Change Default Passwords**
   - Application admin password
   - Server user passwords
   - Database passwords (if needed)

2. **Setup SSH Key Authentication**
```bash
# Generate SSH key (on your local machine)
ssh-keygen -t rsa -b 4096

# Copy public key to server
ssh-copy-id root@your-server-ip

# Disable password authentication
nano /etc/ssh/sshd_config
# Set: PasswordAuthentication no
systemctl restart ssh
```

3. **Configure Fail2Ban**
```bash
apt install fail2ban

# Configure Fail2Ban for SSH and Nginx
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
nano /etc/fail2ban/jail.local

systemctl enable fail2ban
systemctl start fail2ban
```

4. **Regular Security Updates**
```bash
# Setup automatic security updates
apt install unattended-upgrades
dpkg-reconfigure -plow unattended-upgrades
```

### Monitoring and Alerts

**Setup System Monitoring:**
```bash
# Install monitoring tools
apt install htop iotop nethogs

# Monitor disk space
df -h
du -sh /opt/tgp-chapter/*

# Monitor network connections
netstat -tulnp
```

**Log Monitoring:**
```bash
# Setup log rotation
nano /etc/logrotate.d/tgp-chapter

# Content:
/opt/tgp-chapter/logs/*.log {
    daily
    missingok
    rotate 30
    compress
    notifempty
    create 644 tgpchapter tgpchapter
}
```

## Support and Maintenance

### Regular Maintenance Schedule

**Daily:**
- Check application status
- Monitor system resources
- Review error logs

**Weekly:**
- Update system packages: `apt update && apt upgrade`
- Check backup integrity
- Review security logs

**Monthly:**
- Review and rotate logs
- Check SSL certificate expiry
- Performance analysis
- Security audit

### Getting Help

**Log Locations:**
- Application logs: `/opt/tgp-chapter/logs/`
- Nginx logs: `/var/log/nginx/`
- System logs: `/var/log/syslog`
- PostgreSQL logs: `/var/log/postgresql/`

**Useful Commands:**
```bash
# System information
cat /opt/tgp-chapter/server-info.txt

# Application status
pm2 status
pm2 show tgp-chapter-management

# Database status
sudo -u postgres psql -c "\l"

# Web server status
nginx -t
systemctl status nginx
```

## Conclusion

Your Tau Gamma Phi CBC Chapter Management System is now deployed and ready for production use. The quick deploy script has configured a secure, scalable environment with automatic backups, monitoring, and management tools.

**Key URLs:**
- Application: `http://your-domain.com`
- Admin login: Username `treasurer`, Password `password123`

**Important Notes:**
- Change default passwords immediately
- Configure your domain DNS properly
- Setup SSL certificates for security
- Monitor logs regularly
- Keep the system updated

For additional support or advanced configuration, refer to the troubleshooting section or contact your system administrator.

---

**Tau Gamma Phi Rahugan CBC Chapter Management System**  
*Streamlining chapter finances and member management*