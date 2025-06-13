# Ubuntu VPS Deployment Guide

## Tau Gamma Phi CBC Chapter Management System

## Quick Deployment (Recommended)

Use the automated quick deploy script for complete setup:

```bash
# Download and run the quick deployment script
wget https://raw.githubusercontent.com/your-repo/quick-deploy.sh
chmod +x quick-deploy.sh
sudo ./quick-deploy.sh
```

This script will:
- Install all required software (Node.js, PostgreSQL, Nginx)
- Setup database and security
- Configure web server and firewall
- Create management scripts

For detailed step-by-step instructions, see **QUICK-DEPLOY-TUTORIAL.md**

### 2. Upload your application files

```bash
# Copy your application files to the deployment directory
sudo cp -r /path/to/your/app/* /home/tgp-chapter/tgp-chapter-management/
sudo chown -R tgp-chapter:tgp-chapter /home/tgp-chapter/tgp-chapter-management/
```

### 3. Install dependencies and build

```bash
# Switch to the application user
sudo su - tgp-chapter
cd /home/tgp-chapter/tgp-chapter-management

# Install dependencies
npm install

# Build the application
npm run build

# Setup database schema
npm run db:push
```

### 4. Start the application

```bash
# Start with PM2
pm2 start ecosystem.config.js

# Save PM2 configuration
pm2 save
pm2 startup

# Start Nginx
sudo systemctl start nginx
sudo systemctl enable nginx
```

## Manual Deployment Steps

### 1. System Setup

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Node.js 20.x
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install PostgreSQL
sudo apt install -y postgresql postgresql-contrib

# Install PM2 and Nginx
sudo npm install -g pm2
sudo apt install -y nginx
```

### 2. Database Configuration

```bash
# Switch to postgres user
sudo -u postgres psql

# Create database and user
CREATE DATABASE tgp_chapter_db;
CREATE USER tgp_user WITH ENCRYPTED PASSWORD 'your_secure_password';
GRANT ALL PRIVILEGES ON DATABASE tgp_chapter_db TO tgp_user;
ALTER USER tgp_user CREATEDB;
\q
```

### 3. Application Setup

```bash
# Create application user
sudo useradd -m -s /bin/bash tgp-chapter
sudo usermod -aG sudo tgp-chapter

# Create application directory
sudo mkdir -p /home/tgp-chapter/tgp-chapter-management
sudo chown tgp-chapter:tgp-chapter /home/tgp-chapter/tgp-chapter-management
```

### 4. Environment Configuration

Create `.env` file in the application directory:

```bash
# Database Configuration
DATABASE_URL=postgresql://tgp_user:your_secure_password@localhost:5432/tgp_chapter_db
PGHOST=localhost
PGPORT=5432
PGUSER=tgp_user
PGPASSWORD=your_secure_password
PGDATABASE=tgp_chapter_db

# Application Configuration
NODE_ENV=production
PORT=3000

# Session Configuration
SESSION_SECRET=your_very_long_random_secret_key_here
```

### 5. PM2 Configuration

Create `ecosystem.config.js`:

```javascript
module.exports = {
  apps: [{
    name: 'tgp-chapter-management',
    script: 'npm',
    args: 'run dev',
    cwd: '/home/tgp-chapter/tgp-chapter-management',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    error_file: '/home/tgp-chapter/tgp-chapter-management/logs/err.log',
    out_file: '/home/tgp-chapter/tgp-chapter-management/logs/out.log',
    log_file: '/home/tgp-chapter/tgp-chapter-management/logs/combined.log',
    time: true
  }]
};
```

### 6. Nginx Configuration

Create `/etc/nginx/sites-available/tgp-chapter`:

```nginx
server {
    listen 80;
    server_name your-domain.com;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # Static assets caching
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

Enable the site:
```bash
sudo ln -s /etc/nginx/sites-available/tgp-chapter /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx
```

## SSL Configuration

Install Certbot and setup SSL:

```bash
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com
```

## Firewall Setup

```bash
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw enable
```

## Management Commands

### Application Management

```bash
# View application logs
pm2 logs tgp-chapter-management

# Restart application
pm2 restart tgp-chapter-management

# Stop application
pm2 stop tgp-chapter-management

# View application status
pm2 status
```

### Database Management

```bash
# Create backup
PGPASSWORD=your_password pg_dump -h localhost -U tgp_user -d tgp_chapter_db > backup_$(date +%Y%m%d_%H%M%S).sql

# Restore from backup
PGPASSWORD=your_password psql -h localhost -U tgp_user -d tgp_chapter_db < backup_file.sql

# Access database
PGPASSWORD=your_password psql -h localhost -U tgp_user -d tgp_chapter_db
```

### System Monitoring

```bash
# Check system resources
htop
df -h
free -h

# Check application status
systemctl status nginx
systemctl status postgresql
pm2 status
```

## Troubleshooting

### Common Issues

1. **Application won't start**
   - Check PM2 logs: `pm2 logs tgp-chapter-management`
   - Verify environment variables in `.env`
   - Check database connection

2. **Database connection failed**
   - Verify PostgreSQL is running: `sudo systemctl status postgresql`
   - Check database credentials in `.env`
   - Verify database exists: `sudo -u postgres psql -l`

3. **Nginx errors**
   - Check Nginx logs: `sudo tail -f /var/log/nginx/error.log`
   - Verify configuration: `sudo nginx -t`
   - Check if port 3000 is accessible: `curl localhost:3000`

4. **SSL certificate issues**
   - Renew certificate: `sudo certbot renew`
   - Check certificate status: `sudo certbot certificates`

### Performance Optimization

1. **Enable compression in Nginx**
   ```nginx
   gzip on;
   gzip_vary on;
   gzip_min_length 1024;
   gzip_proxied any;
   gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss;
   ```

2. **Setup database connection pooling**
   - Modify database connection settings in the application
   - Monitor connection usage

3. **Enable PM2 monitoring**
   ```bash
   pm2 install pm2-server-monit
   ```

## Security Checklist

- [ ] Change default database passwords
- [ ] Setup firewall rules
- [ ] Enable SSL/TLS certificates
- [ ] Regular security updates
- [ ] Setup automated backups
- [ ] Configure fail2ban for SSH protection
- [ ] Use strong session secrets
- [ ] Regular security audits

## Backup Strategy

### Automated Daily Backups

Create a cron job for daily backups:

```bash
# Edit crontab
crontab -e

# Add daily backup at 2 AM
0 2 * * * /home/tgp-chapter/tgp-chapter-management/backup.sh
```

### Manual Backup

```bash
# Create full backup
./backup.sh

# Backup application files
tar -czf app_backup_$(date +%Y%m%d).tar.gz /home/tgp-chapter/tgp-chapter-management
```

## Updates and Maintenance

### Application Updates

```bash
# Pull latest changes (if using git)
git pull origin main

# Install new dependencies
npm install

# Build updated application
npm run build

# Push database schema changes
npm run db:push

# Restart application
pm2 restart tgp-chapter-management
```

### System Updates

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Update Node.js (if needed)
# Follow Node.js update procedures

# Update PM2
npm update -g pm2
```

## Support

For deployment issues or questions:
1. Check application logs first
2. Review this documentation
3. Contact the development team
4. Check GitHub issues (if applicable)

---

**Tau Gamma Phi Rahugan CBC Chapter Management System**
*Streamlining chapter finances and member management*