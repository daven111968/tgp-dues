#!/bin/bash
set -e

echo "🔧 Setting up TGP Chapter Management Application..."

# Navigate to application directory
APP_DIR="/opt/tgp-chapter"
cd $APP_DIR

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    echo "❌ Error: package.json not found. Make sure application files are in $APP_DIR"
    exit 1
fi

echo "📦 Installing dependencies..."
npm install

echo "🏗️  Building application..."
npm run build

echo "🗄️  Setting up database schema..."
npm run db:push

echo "🚀 Starting application with PM2..."
pm2 start ecosystem.config.js

echo "💾 Saving PM2 configuration..."
pm2 save

echo "🔄 Setting up PM2 startup script..."
pm2 startup systemd -u tgpchapter --hp $APP_DIR

echo ""
echo "✅ Application setup completed successfully!"
echo ""
echo "🌐 Access your application at:"
echo "   - Local: http://localhost:3000"
echo "   - External: http://$(curl -s ifconfig.me 2>/dev/null || echo 'your-server-ip')"
echo ""
echo "🔑 Default admin credentials:"
echo "   Username: treasurer"
echo "   Password: password123"
echo ""
echo "⚠️  IMPORTANT: Change the default password after first login!"
echo ""
echo "📊 Useful commands:"
echo "   - View logs: pm2 logs tgp-chapter-management"
echo "   - Restart app: pm2 restart tgp-chapter-management"
echo "   - Check status: pm2 status"
echo "   - Stop app: pm2 stop tgp-chapter-management"
echo ""
echo "🎉 Your TGP Chapter Management System is now running!"