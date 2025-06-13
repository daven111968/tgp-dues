# Database Setup for VPS Deployment

## Prerequisites

1. **Ubuntu VPS** with PostgreSQL installed
2. **Node.js 18+** installed
3. **Git** for cloning the repository

## Step 1: Install PostgreSQL

```bash
# Update system
sudo apt update

# Install PostgreSQL
sudo apt install postgresql postgresql-contrib

# Start and enable PostgreSQL
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

## Step 2: Create Database and User

```bash
# Switch to PostgreSQL user
sudo -u postgres psql

# In PostgreSQL prompt, run these commands:
CREATE DATABASE tgp_chapter_db;
CREATE USER tgp_user WITH ENCRYPTED PASSWORD 'your_secure_password';
GRANT ALL PRIVILEGES ON DATABASE tgp_chapter_db TO tgp_user;
ALTER USER tgp_user CREATEDB;
\q
```

## Step 3: Setup Environment Variables

Create a `.env` file in your project root:

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
PORT=5000

# Session Configuration (generate a random string)
SESSION_SECRET=your_random_session_secret_here
```

## Step 4: Deploy Your Application

```bash
# Clone or upload your project to VPS
cd /path/to/your/project

# Install dependencies
npm install

# Push database schema to PostgreSQL
npm run db:push

# Start the application
npm run dev
```

## Step 5: Verify Database Setup

```bash
# Test database connection
sudo -u postgres psql -d tgp_chapter_db -c "\dt"

# This should show your application tables
```

## Database Schema

The application will automatically create these tables:
- `users` - Admin and member user accounts
- `members` - Chapter member information
- `payments` - Payment records
- `chapter_info` - Chapter configuration
- `activities` - Chapter activities
- `contributions` - Member contributions to activities

## Default Admin Account

After running `npm run db:push`, you can login with:
- **Username**: treasurer
- **Password**: password123

**Important**: Change this password immediately after first login.

## Troubleshooting

**Connection Issues:**
```bash
# Check if PostgreSQL is running
sudo systemctl status postgresql

# Check if database exists
sudo -u postgres psql -l | grep tgp_chapter_db

# Test connection manually
psql -h localhost -U tgp_user -d tgp_chapter_db
```

**Permission Issues:**
```bash
# Grant additional permissions if needed
sudo -u postgres psql -d tgp_chapter_db -c "GRANT ALL ON SCHEMA public TO tgp_user;"
```

## Production Notes

1. Use a strong password for the database user
2. Consider setting up firewall rules to restrict database access
3. Regular database backups are recommended
4. Monitor database performance and storage usage

## Backup Command

```bash
# Create backup
pg_dump -h localhost -U tgp_user -d tgp_chapter_db > backup.sql

# Restore backup
psql -h localhost -U tgp_user -d tgp_chapter_db < backup.sql
```

That's it! Your database is now ready for the TGP Chapter Management System.