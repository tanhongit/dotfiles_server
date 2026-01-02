#!/bin/bash

# Setup Nginx for Zabbix with Domain/Proxy support

echo "=========================================="
echo "🔧 Setup Nginx for Zabbix"
echo "=========================================="
echo ""

if [ "$EUID" -ne 0 ]; then
    echo "❌ Please run as root or with sudo"
    exit 1
fi

# Ask for domain or use IP
echo "How do you want to access Zabbix?"
echo "  1) Use domain name (e.g., zabbix.example.com)"
echo "  2) Use IP address only (e.g., 192.168.1.100)"
read -r -p "Enter choice [1-2]: " domain_choice

SERVER_NAME="_"
USE_SSL=false

if [ "$domain_choice" = "1" ]; then
    read -r -p "Enter your domain name (e.g., zabbix.example.com): " DOMAIN_NAME

    if [ -z "$DOMAIN_NAME" ]; then
        echo "❌ Domain name is required"
        exit 1
    fi

    SERVER_NAME="$DOMAIN_NAME"

    echo ""
    echo "Do you want to setup SSL/HTTPS with Let's Encrypt?"
    echo "  1) Yes - Setup SSL with certbot (recommended for production)"
    echo "  2) No - Use HTTP only"
    read -r -p "Enter choice [1-2]: " ssl_choice

    if [ "$ssl_choice" = "1" ]; then
        USE_SSL=true
        read -r -p "Enter your email for Let's Encrypt notifications: " EMAIL
    fi
else
    SERVER_NAME="_"
fi

echo ""
echo "📝 Configuration:"
echo "   Server name: $SERVER_NAME"
echo "   SSL: $USE_SSL"
echo ""

# Detect PHP-FPM version
PHP_FPM_SOCK=""
PHP_VERSION=""

echo "🔍 Detecting PHP-FPM..."
for php_ver in 8.4 8.3 8.2 8.1 8.0 7.4; do
    if [ -S "/run/php/php${php_ver}-fpm.sock" ]; then
        PHP_FPM_SOCK="/run/php/php${php_ver}-fpm.sock"
        PHP_VERSION="$php_ver"
        echo "✓ Found PHP ${php_ver} FPM"
        break
    fi
done

# Fallback to generic php-fpm
if [ -z "$PHP_FPM_SOCK" ] && [ -S "/run/php/php-fpm.sock" ]; then
    PHP_FPM_SOCK="/run/php/php-fpm.sock"
    PHP_VERSION="generic"
    echo "✓ Found generic PHP FPM"
fi

if [ -z "$PHP_FPM_SOCK" ]; then
    echo "⚠️  PHP-FPM socket not found, will use default: /run/php/php8.3-fpm.sock"
    echo "⚠️  Make sure PHP-FPM is installed and running"
    PHP_FPM_SOCK="/run/php/php8.3-fpm.sock"
fi

echo "📌 PHP-FPM socket: $PHP_FPM_SOCK"
echo ""

# Install Nginx if not installed
if ! command -v nginx &>/dev/null; then
    echo "📦 Installing Nginx..."
    apt-get update -qq
    apt-get install -y nginx
fi

# Remove default site if exists
if [ -L /etc/nginx/sites-enabled/default ]; then
    echo "🗑️  Removing default site..."
    rm -f /etc/nginx/sites-enabled/default
fi

# Create Zabbix Nginx config
echo "📝 Creating Nginx configuration..."

mkdir -p /etc/zabbix

tee /etc/zabbix/nginx.conf > /dev/null <<EOFNGINX
server {
    listen 80;
    server_name ${SERVER_NAME};

    root /usr/share/zabbix;
    index index.php;

    access_log /var/log/nginx/zabbix_access.log;
    error_log /var/log/nginx/zabbix_error.log;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    location = /favicon.ico {
        log_not_found off;
        access_log off;
    }

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php\$ {
        fastcgi_pass unix:${PHP_FPM_SOCK};
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;

        fastcgi_param PHP_VALUE "
            max_execution_time = 300
            memory_limit = 128M
            post_max_size = 16M
            upload_max_filesize = 2M
            max_input_time = 300
            date.timezone = Asia/Ho_Chi_Minh
            always_populate_raw_post_data = -1
        ";

        fastcgi_read_timeout 300;
        fastcgi_buffer_size 128k;
        fastcgi_buffers 4 256k;
        fastcgi_busy_buffers_size 256k;
    }

    location ~ /\.ht {
        deny all;
    }

    location ~ /\.(git|svn) {
        deny all;
    }
}
EOFNGINX

echo "✓ Configuration created at /etc/zabbix/nginx.conf"

# Create symlink
if [ -L /etc/nginx/sites-enabled/zabbix ]; then
    rm -f /etc/nginx/sites-enabled/zabbix
fi

ln -sf /etc/zabbix/nginx.conf /etc/nginx/sites-enabled/zabbix
echo "✓ Configuration enabled"

# Test Nginx config
echo ""
echo "🧪 Testing Nginx configuration..."
if nginx -t 2>&1; then
    echo "✓ Nginx configuration is valid"
else
    echo "❌ Nginx configuration has errors!"
    exit 1
fi

# Restart Nginx
echo ""
echo "🔄 Restarting Nginx..."
systemctl restart nginx
systemctl enable nginx

if systemctl is-active --quiet nginx; then
    echo "✓ Nginx is running"
else
    echo "❌ Nginx failed to start!"
    echo "Check logs: sudo journalctl -u nginx -n 50"
    exit 1
fi

# Setup SSL if requested
if [ "$USE_SSL" = true ]; then
    echo ""
    echo "🔒 Setting up SSL with Let's Encrypt..."

    # Install certbot
    if ! command -v certbot &>/dev/null; then
        echo "📦 Installing certbot..."
        apt-get install -y certbot python3-certbot-nginx
    fi

    # Get SSL certificate
    echo ""
    echo "📜 Obtaining SSL certificate..."
    echo "⚠️  Make sure your domain $DOMAIN_NAME points to this server IP!"
    read -r -p "Press Enter to continue or Ctrl+C to cancel..."

    if certbot --nginx -d "$DOMAIN_NAME" --non-interactive --agree-tos --email "$EMAIL" --redirect; then
        echo "✓ SSL certificate obtained successfully"
        echo "✓ HTTPS redirect enabled"
    else
        echo "⚠️  SSL setup failed. You can try manually later with:"
        echo "   sudo certbot --nginx -d $DOMAIN_NAME"
    fi
fi

# Configure firewall
echo ""
echo "🔥 Configuring firewall..."
if command -v ufw &>/dev/null && ufw status | grep -q "Status: active"; then
    ufw allow 'Nginx Full' 2>/dev/null || {
        ufw allow 80/tcp
        ufw allow 443/tcp
    }
    ufw reload
    echo "✓ Firewall configured"
else
    echo "ℹ️  Firewall (ufw) is not active"
fi

# Fix permissions
echo ""
echo "🔐 Setting file permissions..."
if [ -d /usr/share/zabbix ]; then
    chmod -R 755 /usr/share/zabbix
    chown -R www-data:www-data /usr/share/zabbix
    echo "✓ Permissions set"
fi

# Restart PHP-FPM
echo ""
echo "🔄 Restarting PHP-FPM..."

# Detect running PHP-FPM service
PHP_FPM_SERVICE=""
for php_ver in 8.4 8.3 8.2 8.1 8.0 7.4; do
    if systemctl is-active --quiet "php${php_ver}-fpm"; then
        PHP_FPM_SERVICE="php${php_ver}-fpm"
        break
    fi
done

if [ -z "$PHP_FPM_SERVICE" ] && systemctl is-active --quiet php-fpm; then
    PHP_FPM_SERVICE="php-fpm"
fi

if [ -n "$PHP_FPM_SERVICE" ]; then
    systemctl restart "$PHP_FPM_SERVICE"
    echo "✓ ${PHP_FPM_SERVICE} restarted"
else
    echo "⚠️  PHP-FPM service not found or not running"
fi

# Final summary
echo ""
echo "=========================================="
echo "✅ Nginx Setup Complete!"
echo "=========================================="
echo ""

SERVER_IP=$(hostname -I | awk '{print $1}')

if [ "$USE_SSL" = true ]; then
    echo "🌐 Access Zabbix via HTTPS:"
    echo "   https://${DOMAIN_NAME}"
    echo ""
    echo "📌 SSL Certificate:"
    echo "   Certbot will auto-renew the certificate"
    echo "   Manual renewal: sudo certbot renew"
else
    if [ "$SERVER_NAME" != "_" ]; then
        echo "🌐 Access Zabbix via HTTP:"
        echo "   http://${DOMAIN_NAME}"
        echo ""
        echo "⚠️  To enable HTTPS later, run:"
        echo "   sudo certbot --nginx -d ${DOMAIN_NAME}"
    else
        echo "🌐 Access Zabbix via IP:"
        echo "   http://${SERVER_IP}"
    fi
fi

echo ""
echo "📌 Default Zabbix credentials:"
echo "   Username: Admin"
echo "   Password: zabbix"
echo ""
echo "📝 Nginx configuration: /etc/zabbix/nginx.conf"
echo "📊 Access logs: /var/log/nginx/zabbix_access.log"
echo "❌ Error logs: /var/log/nginx/zabbix_error.log"
echo ""
echo "🔍 Check services status:"
echo "   systemctl status nginx"
echo "   systemctl status php8.3-fpm"
echo "   systemctl status zabbix-server"
echo ""

if [ "$USE_SSL" = true ]; then
    echo "🔒 SSL Info:"
    echo "   Certificate location: /etc/letsencrypt/live/${DOMAIN_NAME}/"
    echo "   Certbot auto-renewal: enabled"
    echo ""
fi

echo "=========================================="

