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
    error_file: './logs/err.log',
    out_file: './logs/out.log',
    log_file: './logs/combined.log',
    time: true,
    // Application-specific environment variables
    env_production: {
      NODE_ENV: 'production',
      PORT: 3000
    }
  }]
};