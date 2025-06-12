import express, { type Express } from "express";
import path from "path";
import fs from "fs";

export function setupStaticFiles(app: Express) {
  // Define possible static file locations
  const staticPaths = [
    path.join(process.cwd(), "server/public"),
    path.join(process.cwd(), "dist/public"),
    path.join(process.cwd(), "public"),
    path.join(import.meta.dirname, "public")
  ];

  // Find the first existing static directory
  let staticDir = null;
  for (const testPath of staticPaths) {
    if (fs.existsSync(testPath)) {
      staticDir = testPath;
      break;
    }
  }

  if (staticDir) {
    console.log(`Serving static files from: ${staticDir}`);
    app.use(express.static(staticDir));
    
    // Fallback to index.html for SPA routing
    app.get('*', (req, res, next) => {
      // Skip API routes
      if (req.path.startsWith('/api')) {
        return next();
      }
      
      const indexPath = path.join(staticDir, 'index.html');
      if (fs.existsSync(indexPath)) {
        res.sendFile(indexPath);
      } else {
        res.status(404).send('Static files not found');
      }
    });
  } else {
    console.warn('No static directory found, serving basic HTML');
    
    // Serve a basic HTML page if no static files exist
    app.get('*', (req, res, next) => {
      if (req.path.startsWith('/api')) {
        return next();
      }
      
      res.send(`<!DOCTYPE html>
<html>
<head>
    <title>TGP Rahugan CBC Chapter</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; padding: 50px; background: #f5f5f5; }
        .container { max-width: 500px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; }
        h1 { color: #B8860B; }
    </style>
</head>
<body>
    <div class="container">
        <h1>TGP Rahugan CBC Chapter</h1>
        <p>Dues Management System</p>
        <p>Static files are loading...</p>
        <script>
            setTimeout(() => {
                window.location.reload();
            }, 3000);
        </script>
    </div>
</body>
</html>`);
    });
  }
}