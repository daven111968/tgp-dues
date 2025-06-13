# Tau Gamma Phi CBC Chapter Management System

A comprehensive web-based dues management system designed to streamline financial tracking and member engagement for Tau Gamma Phi Rahugan CBC Chapter.

## Features

- **Member Management**: Complete member database with status tracking (active, inactive, suspended, expelled)
- **Payment Tracking**: Monthly dues collection with payment status monitoring
- **Activity Contributions**: Track member contributions to chapter activities
- **Financial Reports**: Comprehensive reporting with PDF export capabilities
- **Dual Authentication**: Separate admin and member portals
- **Mobile Responsive**: PWA-enabled design for mobile access
- **Offline Support**: Works without internet connection

## Technology Stack

- **Frontend**: React with TypeScript, Tailwind CSS, Shadcn UI
- **Backend**: Express.js with TypeScript
- **Database**: PostgreSQL with Drizzle ORM
- **Process Management**: PM2
- **Web Server**: Nginx
- **State Management**: React Query

## Quick Deployment

Deploy to Ubuntu VPS in under 10 minutes:

```bash
# Download and run the quick deployment script
wget https://raw.githubusercontent.com/your-repo/quick-deploy.sh
chmod +x quick-deploy.sh
sudo ./quick-deploy.sh
```

The script automatically:
- Installs Node.js, PostgreSQL, Nginx, PM2
- Creates secure database and user accounts
- Configures web server with security headers
- Sets up firewall and SSL-ready environment
- Creates management and backup scripts

## Default Credentials

**Admin Access:**
- Username: `treasurer`
- Password: `password123`

**Sample Member Access:**
- Username: `juan.delacruz`
- Password: `member123`

⚠️ Change all default passwords after first login.

## Project Structure

```
├── client/             # React frontend
├── server/             # Express backend
├── shared/             # Shared types and schemas
├── quick-deploy.sh     # Ubuntu VPS deployment script
├── ecosystem.config.js # PM2 configuration
└── init-database.sql   # Database initialization
```

## Local Development

```bash
# Install dependencies
npm install

# Start development server
npm run dev

# Build for production
npm run build

# Database operations
npm run db:push
npm run db:generate
```

## Management Commands

After deployment, use these commands on your server:

```bash
# Deploy updates
/opt/tgp-chapter/deploy.sh

# Backup database
/opt/tgp-chapter/backup.sh

# View application logs
pm2 logs tgp-chapter-management

# Restart application
pm2 restart tgp-chapter-management

# Check application status
pm2 status
```

## Documentation

- **[QUICK-DEPLOY-TUTORIAL.md](QUICK-DEPLOY-TUTORIAL.md)**: Complete deployment walkthrough
- **[DEPLOYMENT.md](DEPLOYMENT.md)**: Alternative deployment methods
- **[init-database.sql](init-database.sql)**: Database setup reference

## Features Overview

### Admin Dashboard
- Complete member management (CRUD operations)
- Payment processing and tracking
- Activity management and contribution tracking
- Financial reporting with PDF export
- Chapter information management

### Member Portal
- Personal payment history
- Chapter transparency (view all member payments)
- Activity contribution tracking
- Financial summary and statistics

### Technical Features
- **Security**: Rate limiting, CORS protection, secure session management
- **Performance**: Optimized queries, caching, compression
- **Monitoring**: Comprehensive logging, PM2 process monitoring
- **Backup**: Automated daily database backups
- **SSL Ready**: Certbot integration for HTTPS

## Currency and Localization

- Uses Philippine Peso (₱) currency formatting
- Variable dues structure: ₱100 for local members, ₱200 for out-of-town workers
- Date formatting in Philippine locale

## Member Classification

- **Pure Blooded**: Original fraternity members
- **Welcome**: New members with welcoming ceremony
- **Status Options**: Active, Inactive, Suspended, Expelled

## Browser Support

- Chrome 90+
- Firefox 88+
- Safari 14+
- Edge 90+

## Security Features

- HTTPS/SSL support
- Secure password hashing
- Rate limiting on login attempts
- CSRF protection
- XSS protection headers
- Firewall configuration

## Performance

- Optimized for mobile devices
- Progressive Web App (PWA) capabilities
- Efficient database queries with proper indexing
- Gzip compression enabled
- Static asset caching

## Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For deployment issues or questions:
1. Check application logs: `pm2 logs tgp-chapter-management`
2. Review deployment documentation
3. Verify system requirements
4. Contact system administrator

---

**Tau Gamma Phi Rahugan CBC Chapter**  
*Advancing Brotherhood Through Technology*