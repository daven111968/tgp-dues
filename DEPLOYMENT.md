# TGP Rahugan CBC Chapter - Dues Management System Deployment

## Quick Deployment on Ubuntu VPS

### Prerequisites
- Ubuntu 20.04 or 22.04 VPS
- Root or sudo access
- At least 2GB RAM and 20GB storage

### One-Click Installation

1. **Upload files to your VPS**:
```bash
# Option 1: Using git (if repository is available)
git clone <your-repository-url>
cd <repository-name>

# Option 2: Upload files manually via SCP
scp -r /path/to/your/project user@your-vps-ip:/home/user/tgp-dues
cd /home/user/tgp-dues
```

2. **Make installer executable and run**:
```bash
chmod +x deploy.sh
./deploy.sh
```

The script will automatically:
- Update system packages
- Install Node.js 20, PostgreSQL, PM2, and Nginx
- Create database `tgp_dues_db` with user `rahuganmkc`
- Configure and start the application
- Set up reverse proxy with Nginx
- Configure firewall rules

### Default Credentials

**Admin Access:**
- Username: `treasurer`
- Password: `password123`

**Sample Member Accounts:**
- Username: `juan.delacruz`, `mark.santos`, `paolo.rodriguez`
- Password: `member123`

**Database:**
- Database: `tgp_dues_db`
- Username: `rahuganmkc`
- Password: `rahugan2018`

### Access Your Application

After successful deployment, access your application at:
```
http://your-vps-ip
```

### Post-Deployment Setup

1. **Configure Domain (Optional)**:
```bash
sudo nano /etc/nginx/sites-available/tgp-dues
# Replace server_name with your domain
sudo systemctl reload nginx
```

2. **SSL Certificate (Recommended)**:
```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com
```

### Management Commands

```bash
# View application logs
pm2 logs tgp-dues

# Restart application
pm2 restart tgp-dues

# Check application status
pm2 status

# Update application (if using git)
cd /var/www/tgp-dues
git pull
pm2 restart tgp-dues
```

### Troubleshooting

**If deployment fails:**
1. Check logs: `pm2 logs tgp-dues`
2. Verify database connection: `sudo -u postgres psql -c "\l"`
3. Check Nginx status: `sudo systemctl status nginx`
4. Test application port: `curl localhost:5000`

**Common Issues:**
- Permission errors: Ensure script is run as non-root user with sudo privileges
- Database connection: Verify PostgreSQL is running and credentials are correct
- Port conflicts: Check if port 5000 is available

### Security Notes

- Change default passwords immediately after deployment
- Consider setting up fail2ban for SSH protection
- Regular database backups are recommended
- Keep system packages updated

### Support

For issues or customization needs, refer to the application documentation or contact system administrator.