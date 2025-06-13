module.exports = {
  apps: [{
    name: 'tgp-chapter-management',
    script: 'npm',
    args: 'start',
    cwd: '/opt/tgp-chapter',
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
    kill_timeout: 5000,
    restart_delay: 1000,
    env_production: {
      NODE_ENV: 'production',
      PORT: 3000
    }
  }]
};