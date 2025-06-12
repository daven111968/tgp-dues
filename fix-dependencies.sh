#!/bin/bash

# Quick fix for missing dependencies
echo "Fixing missing dependencies..."

# Stop the application
pm2 stop tgp-dues

# Navigate to application directory
cd /var/www/tgp-dues

# Install all dependencies (including dev dependencies needed for vite)
echo "Installing all dependencies..."
npm install

# Restart the application
echo "Restarting application..."
pm2 restart tgp-dues

# Check status
echo "Checking application status..."
sleep 5
pm2 status

echo "Fix completed. Check application logs:"
echo "pm2 logs tgp-dues"