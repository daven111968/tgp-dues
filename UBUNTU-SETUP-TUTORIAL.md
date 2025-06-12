# Complete Ubuntu VPS Setup Tutorial
## TGP Rahugan CBC Chapter - Dues Management System

### Prerequisites
- Ubuntu VPS (18.04 or newer)
- Root access or sudo privileges
- Basic terminal knowledge

---

## Step 1: Connect to Your Ubuntu VPS

### Using SSH (Windows/Mac/Linux)
```bash
# Replace YOUR_SERVER_IP with your actual server IP
ssh root@YOUR_SERVER_IP

# If using a non-root user with sudo privileges:
ssh username@YOUR_SERVER_IP
```

### Using PuTTY (Windows)
1. Download PuTTY from https://putty.org/
2. Enter your server IP in "Host Name"
3. Port: 22
4. Connection type: SSH
5. Click "Open"
6. Login with root credentials

---

## Step 2: Update Your Ubuntu System

### Essential System Updates
```bash
# Update package lists
apt update

# Upgrade all packages
apt upgrade -y

# Install essential tools
apt install -y curl wget git nano htop unzip
```

---

## Step 3: Get the Deployment Files

### Method 1: Download from GitHub/Server
```bash
# Navigate to root directory
cd /root

# Download the deployment script (replace URL with actual location)
wget https://your-server.com/deploy-tgp.sh

# Download the guide
wget https://your-server.com/TGP-DEPLOYMENT-GUIDE.md

# Make script executable
chmod +x deploy-tgp.sh
```

### Method 2: Create Files Manually
```bash
# Navigate to root directory
cd /root

# Create the deployment script
nano deploy-tgp.sh
```

**Copy and paste the entire deploy-tgp.sh content, then save with:**
- Press `Ctrl + O` to save
- Press `Enter` to confirm filename
- Press `Ctrl + X` to exit

```bash
# Make script executable
chmod +x deploy-tgp.sh

# Create the guide file
nano TGP-DEPLOYMENT-GUIDE.md
```

**Copy and paste the guide content, then save the same way.**

### Method 3: Transfer from Local Computer

#### Using SCP (Secure Copy)
```bash
# From your local computer, copy files to VPS
scp deploy-tgp.sh root@YOUR_SERVER_IP:/root/
scp TGP-DEPLOYMENT-GUIDE.md root@YOUR_SERVER_IP:/root/

# Then on VPS, make executable
ssh root@YOUR_SERVER_IP
cd /root
chmod +x deploy-tgp.sh
```

#### Using SFTP
```bash
# Connect via SFTP
sftp root@YOUR_SERVER_IP

# Navigate to root directory
cd /root

# Upload files
put deploy-tgp.sh
put TGP-DEPLOYMENT-GUIDE.md

# Exit SFTP
exit

# SSH back in and make executable
ssh root@YOUR_SERVER_IP
chmod +x /root/deploy-tgp.sh
```

---

## Step 4: Verify Files and Setup

### Check File Locations
```bash
# Confirm you're in the right directory
pwd
# Should show: /root

# List files to verify they exist
ls -la *.sh *.md

# Should see:
# -rwxr-xr-x 1 root root [size] [date] deploy-tgp.sh
# -rw-r--r-- 1 root root [size] [date] TGP-DEPLOYMENT-GUIDE.md
```

### Verify Script Contents
```bash
# Check first few lines of script
head -20 deploy-tgp.sh

# Should see script header and configuration
```

---

## Step 5: Run the Deployment

### Execute the Installation
```bash
# Make sure you're in /root directory
cd /root

# Run the deployment script
./deploy-tgp.sh

# Alternative method:
bash deploy-tgp.sh
```

### What Happens During Installation
The script will automatically:
1. **System Setup** (5-10 minutes)
   - Update Ubuntu packages
   - Install Node.js, PostgreSQL, Nginx
   - Configure services

2. **Database Creation** (2-3 minutes)
   - Create PostgreSQL database
   - Set up schema and tables
   - Insert default accounts

3. **Application Deployment** (3-5 minutes)
   - Create TGP application
   - Install dependencies
   - Configure environment

4. **Web Server Setup** (1-2 minutes)
   - Configure Nginx reverse proxy
   - Set up firewall rules
   - Start all services

5. **Testing and Validation** (1-2 minutes)
   - Test HTTP responses
   - Verify authentication
   - Confirm system status

### Total Installation Time: 12-22 minutes

---

## Step 6: Post-Installation Verification

### Check System Status
```bash
# Verify PM2 application status
pm2 status

# Should show: tgp-dues | online

# Check web server
systemctl status nginx

# Check database
systemctl status postgresql

# View application logs
pm2 logs tgp-dues --lines 10
```

### Test Web Access
```bash
# Get your server IP
curl ifconfig.me

# Test local access
curl http://localhost:5000

# Should return HTML content
```

---

## Step 7: Access Your System

### Web Interface
1. Open browser
2. Navigate to: `http://YOUR_SERVER_IP`
3. You should see the TGP login page

### Test Login Credentials

**Administrator Access:**
- Username: `treasurer`
- Password: `password123`

**Member Access:**
- Username: `juan.delacruz`
- Password: `member123`

---

## Step 8: Directory Structure Overview

### Important Directories
```bash
/root/tgp-dues/          # Main application directory
├── server.js            # Node.js server file
├── package.json         # Dependencies
├── public/              # Static web files
│   └── index.html       # Main web interface
├── .env                 # Environment variables
└── node_modules/        # Installed packages

/etc/nginx/sites-available/tgp-dues    # Nginx configuration
/var/log/nginx/                        # Nginx logs
/var/log/postgresql/                   # Database logs
```

### File Permissions
```bash
# Application directory
drwxr-xr-x root root /root/tgp-dues/

# Script files
-rwxr-xr-x root root /root/deploy-tgp.sh
-rw-r--r-- root root /root/TGP-DEPLOYMENT-GUIDE.md
```

---

## Step 9: Basic Management Commands

### Application Management
```bash
# Check application status
pm2 status

# Restart application
pm2 restart tgp-dues

# View real-time logs
pm2 logs tgp-dues -f

# Stop application
pm2 stop tgp-dues

# Start application
pm2 start tgp-dues
```

### System Services
```bash
# Restart web server
systemctl restart nginx

# Restart database
systemctl restart postgresql

# Check all service status
systemctl status nginx postgresql
```

### Database Access
```bash
# Connect to database
PGPASSWORD=rahugan2018 psql -U rahuganmkc -d tgp_dues_db

# View admin accounts
PGPASSWORD=rahugan2018 psql -U rahuganmkc -d tgp_dues_db -c "SELECT username, name FROM users;"

# Exit database
\q
```

---

## Troubleshooting Common Issues

### Issue 1: Permission Denied
```bash
# If you get permission denied errors:
sudo su -
cd /root
chmod +x deploy-tgp.sh
./deploy-tgp.sh
```

### Issue 2: Script Not Found
```bash
# Verify file location
ls -la /root/deploy-tgp.sh

# If missing, re-download or recreate:
cd /root
nano deploy-tgp.sh
# Paste content and save
chmod +x deploy-tgp.sh
```

### Issue 3: Network Issues During Installation
```bash
# Check internet connectivity
ping google.com

# Check DNS resolution
nslookup google.com

# If issues, try changing DNS:
echo "nameserver 8.8.8.8" > /etc/resolv.conf
```

### Issue 4: Service Start Failures
```bash
# Check system logs
journalctl -xe

# Check specific service
systemctl status nginx
systemctl status postgresql

# Restart services
systemctl restart nginx postgresql
```

### Issue 5: Port Already in Use
```bash
# Check what's using port 5000
ss -tlnp | grep :5000

# Kill conflicting processes
sudo fuser -k 5000/tcp

# Restart application
pm2 restart tgp-dues
```

---

## Security Notes

### Change Default Passwords
```bash
# After installation, change the default admin password:
PGPASSWORD=rahugan2018 psql -U rahuganmkc -d tgp_dues_db -c "
UPDATE users SET password = 'YOUR_NEW_SECURE_PASSWORD' WHERE username = 'treasurer';"
```

### Firewall Status
```bash
# Check firewall rules
ufw status

# Should show:
# Status: active
# To                         Action      From
# --                         ------      ----
# 22/tcp                     ALLOW       Anywhere
# 80/tcp                     ALLOW       Anywhere
# 443/tcp                    ALLOW       Anywhere
```

---

## Next Steps

### 1. Domain Setup (Optional)
If you have a domain name:
```bash
# Update Nginx configuration
nano /etc/nginx/sites-available/tgp-dues

# Change server_name from _ to your domain
# server_name yourdomain.com www.yourdomain.com;

# Reload Nginx
systemctl reload nginx
```

### 2. SSL Certificate (Recommended)
```bash
# Install Certbot
apt install certbot python3-certbot-nginx

# Get SSL certificate
certbot --nginx -d yourdomain.com
```

### 3. Regular Backups
```bash
# Create backup script
nano /root/backup-daily.sh

# Add backup commands (see TGP-DEPLOYMENT-GUIDE.md)
chmod +x /root/backup-daily.sh

# Schedule daily backups
crontab -e
# Add: 0 2 * * * /root/backup-daily.sh
```

---

## Summary

You have successfully:
- ✅ Connected to Ubuntu VPS
- ✅ Downloaded/created deployment files in `/root/`
- ✅ Executed the installation script
- ✅ Deployed TGP Dues Management System
- ✅ Configured web server and database
- ✅ Tested authentication system

Your TGP Rahugan CBC Chapter Dues Management System is now live at `http://YOUR_SERVER_IP`

For ongoing management and advanced features, refer to the TGP-DEPLOYMENT-GUIDE.md file.