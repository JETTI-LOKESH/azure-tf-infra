#!/bin/bash
# Startup script for Linux VM - Installs and starts a simple HTTPS service
# This script runs on first boot via cloud-init (custom_data)

set -euo pipefail

exec > /var/log/startup-script.log 2>&1
echo "=== Startup script began at $(date) ==="

# Update system packages
apt-get update -y
apt-get upgrade -y

# Install nginx
apt-get install -y nginx openssl

# Generate self-signed TLS certificate
mkdir -p /etc/nginx/ssl
openssl req -x509 -nodes -days 365 \
  -newkey rsa:2048 \
  -keyout /etc/nginx/ssl/server.key \
  -out /etc/nginx/ssl/server.crt \
  -subj "/C=US/ST=Texas/L=Dallas/O=InfraAssessment/CN=$(hostname)"

# Configure nginx with HTTPS
cat > /etc/nginx/sites-available/default <<'EOF'
server {
    listen 443 ssl;
    server_name _;

    ssl_certificate /etc/nginx/ssl/server.crt;
    ssl_certificate_key /etc/nginx/ssl/server.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    location / {
        default_type application/json;
        return 200 '{"status":"healthy","service":"infra-assessment","timestamp":"$time_iso8601","hostname":"$hostname"}';
    }

    location /health {
        default_type application/json;
        return 200 '{"status":"ok"}';
    }
}

server {
    listen 80;
    server_name _;
    return 301 https://$host$request_uri;
}
EOF

# Test nginx configuration
nginx -t

# Enable and start nginx
systemctl enable nginx
systemctl restart nginx

echo "=== Startup script completed at $(date) ==="
echo "HTTPS service is running on port 443"
