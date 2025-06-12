# Domain Setup Guide for TGP Dues Management System

## Quick Domain Setup

### Step 1: Configure DNS Records
Before setting up the domain, ensure your DNS records point to your server:

```
A Record: yourdomain.com → your-server-ip
A Record: www.yourdomain.com → your-server-ip
```

### Step 2: Run Domain Setup Script

**For HTTP only:**
```bash
chmod +x setup-domain.sh
./setup-domain.sh yourdomain.com
```

**For HTTPS with SSL certificate:**
```bash
./setup-domain.sh yourdomain.com with-ssl
```

---

## Manual Domain Configuration

### 1. Update Nginx Configuration

Edit the Nginx site configuration:
```bash
nano /etc/nginx/sites-available/tgp-dues
```

Replace `server_name _;` with your domain:
```nginx
server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;
    
    # Rest of configuration remains the same
}
```

### 2. Test and Reload Nginx
```bash
nginx -t
systemctl reload nginx
```

---

## SSL Certificate Setup (Recommended)

### 1. Install Certbot
```bash
apt update
apt install certbot python3-certbot-nginx
```

### 2. Obtain SSL Certificate
```bash
certbot --nginx -d yourdomain.com -d www.yourdomain.com
```

### 3. Setup Auto-Renewal
```bash
crontab -e
# Add this line:
0 12 * * * /usr/bin/certbot renew --quiet
```

---

## DNS Configuration Examples

### Using Cloudflare
1. Login to Cloudflare dashboard
2. Select your domain
3. Go to DNS management
4. Add A records:
   - Name: `@` → IP: `your-server-ip`
   - Name: `www` → IP: `your-server-ip`

### Using Namecheap
1. Login to Namecheap account
2. Go to Domain List → Manage
3. Advanced DNS tab
4. Add A records:
   - Host: `@` → Value: `your-server-ip`
   - Host: `www` → Value: `your-server-ip`

### Using GoDaddy
1. Login to GoDaddy account
2. My Products → DNS
3. Add A records:
   - Name: `@` → Points to: `your-server-ip`
   - Name: `www` → Points to: `your-server-ip`

---

## Verification Steps

### 1. Check DNS Propagation
```bash
# Check if DNS is propagated
nslookup yourdomain.com
dig yourdomain.com
```

### 2. Test Domain Access
```bash
# Test HTTP response
curl -I http://yourdomain.com

# Test HTTPS response (if SSL configured)
curl -I https://yourdomain.com
```

### 3. Browser Testing
- Visit `http://yourdomain.com`
- Login with admin credentials: treasurer / password123
- Test member portal access

---

## Troubleshooting

### Domain Not Resolving
- Check DNS propagation (can take up to 48 hours)
- Verify A records point to correct server IP
- Clear browser cache and try incognito mode

### SSL Certificate Issues
```bash
# Check certificate status
certbot certificates

# Renew certificate manually
certbot renew --dry-run

# Check Nginx SSL configuration
nginx -t
```

### 502 Bad Gateway with Domain
- Ensure application is running: `pm2 status`
- Check Nginx logs: `tail -f /var/log/nginx/error.log`
- Verify proxy_pass points to correct port

---

## Security Considerations

### 1. Force HTTPS Redirect
After SSL setup, ensure HTTP redirects to HTTPS:
```nginx
server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;
    return 301 https://$server_name$request_uri;
}
```

### 2. Security Headers
The configuration includes these security headers:
- X-Content-Type-Options: nosniff
- X-Frame-Options: DENY
- X-XSS-Protection: 1; mode=block
- Referrer-Policy: strict-origin-when-cross-origin

### 3. Firewall Configuration
Ensure necessary ports are open:
```bash
ufw allow 80/tcp
ufw allow 443/tcp
ufw reload
```

---

## Custom Domain Examples

### Subdomain Setup
For a subdomain like `dues.yourdomain.com`:

1. **DNS Record:**
   ```
   A Record: dues.yourdomain.com → your-server-ip
   ```

2. **Nginx Configuration:**
   ```nginx
   server_name dues.yourdomain.com;
   ```

3. **SSL Certificate:**
   ```bash
   certbot --nginx -d dues.yourdomain.com
   ```

### Multiple Domains
To serve multiple domains on the same system:

```nginx
server {
    listen 80;
    server_name domain1.com domain2.org dues.company.com;
    # Configuration
}
```

---

## Maintenance

### Regular Tasks
- Monitor certificate expiration
- Check DNS record accuracy
- Update domain configuration as needed
- Monitor access logs for domain-specific traffic

### Certificate Renewal
Certbot auto-renewal should handle this, but verify:
```bash
# Test renewal
certbot renew --dry-run

# Check renewal logs
journalctl -u certbot.timer
```

---

Your TGP Dues Management System will be accessible at your custom domain with proper SSL encryption and security headers configured.