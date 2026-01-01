#!/bin/bash

# ======================== Zabbix Setup ========================
# Setup Zabbix Server or Zabbix Agent
# Usage:
#   ./zabbix.sh server                 # Install Zabbix Server
#   ./zabbix.sh client                 # Install Zabbix Agent (will prompt for IP)
#   ./zabbix.sh client 192.168.1.100   # Install Zabbix Agent with Server IP

set -e

ZABBIX_VERSION="7.0"
UBUNTU_VERSION=$(lsb_release -rs | cut -d. -f1)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${YELLOW}➜${NC} $1"
}

# Check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "Please run as root or with sudo"
        exit 1
    fi
}

# Install Zabbix Server
install_zabbix_server() {
    echo '=========================================='
    echo '🔧 Installing Zabbix Server'
    echo '=========================================='
    echo ''

    print_info "Updating system packages..."
    apt-get update -qq

    print_info "Installing required packages..."
    apt-get install -y wget curl gnupg2 software-properties-common apt-transport-https ca-certificates

    # Install Zabbix repository
    print_info "Adding Zabbix repository..."
    if [ "$UBUNTU_VERSION" -eq 24 ]; then
        wget -q https://repo.zabbix.com/zabbix/${ZABBIX_VERSION}/ubuntu/pool/main/z/zabbix-release/zabbix-release_${ZABBIX_VERSION}-1+ubuntu24.04_all.deb
        dpkg -i zabbix-release_${ZABBIX_VERSION}-1+ubuntu24.04_all.deb
        rm -f zabbix-release_${ZABBIX_VERSION}-1+ubuntu24.04_all.deb
    elif [ "$UBUNTU_VERSION" -eq 22 ]; then
        wget -q https://repo.zabbix.com/zabbix/${ZABBIX_VERSION}/ubuntu/pool/main/z/zabbix-release/zabbix-release_${ZABBIX_VERSION}-1+ubuntu22.04_all.deb
        dpkg -i zabbix-release_${ZABBIX_VERSION}-1+ubuntu22.04_all.deb
        rm -f zabbix-release_${ZABBIX_VERSION}-1+ubuntu22.04_all.deb
    elif [ "$UBUNTU_VERSION" -eq 20 ]; then
        wget -q https://repo.zabbix.com/zabbix/${ZABBIX_VERSION}/ubuntu/pool/main/z/zabbix-release/zabbix-release_${ZABBIX_VERSION}-1+ubuntu20.04_all.deb
        dpkg -i zabbix-release_${ZABBIX_VERSION}-1+ubuntu20.04_all.deb
        rm -f zabbix-release_${ZABBIX_VERSION}-1+ubuntu20.04_all.deb
    else
        print_error "Unsupported Ubuntu version: $UBUNTU_VERSION"
        exit 1
    fi

    apt-get update -qq
    print_success "Zabbix repository added"

    # Check for existing database installations
    print_info "Checking for existing database installations..."
    DB_INSTALLED=false
    DB_TYPE=""

    if dpkg -l | grep -q "^ii.*mariadb-server"; then
        DB_INSTALLED=true
        DB_TYPE="MariaDB"
    elif dpkg -l | grep -q "^ii.*mysql-server"; then
        DB_INSTALLED=true
        DB_TYPE="MySQL"
    fi

    if [ "$DB_INSTALLED" = true ]; then
        print_info "${DB_TYPE} is already installed"
        echo ""
        echo "Choose an option:"
        echo "  1) Use existing ${DB_TYPE} (recommended if working)"
        echo "  2) Remove ${DB_TYPE} and install fresh MySQL 8.0"
        echo "  3) Cancel installation"
        read -r -p "Enter choice [1-3]: " db_choice

        case "$db_choice" in
            1)
                print_info "Using existing ${DB_TYPE}"
                # Check if database is running
                if ! systemctl is-active --quiet mysql && ! systemctl is-active --quiet mariadb; then
                    print_info "Starting database service..."
                    systemctl start mysql 2>/dev/null || systemctl start mariadb 2>/dev/null || true
                fi
                ;;
            2)
                print_info "Removing existing ${DB_TYPE}..."
                # Stop services
                systemctl stop mysql 2>/dev/null || true
                systemctl stop mariadb 2>/dev/null || true

                # Remove frozen file if exists
                rm -f /etc/mysql/FROZEN

                # Fix broken packages first
                print_info "Fixing broken packages..."
                dpkg --configure -a 2>/dev/null || true
                apt-get install -f -y 2>/dev/null || true

                # Purge old installations completely
                print_info "Purging old database packages..."
                apt-get remove --purge -y mariadb-server* mariadb-client* mariadb-common* \
                    mysql-server* mysql-client* mysql-common* 2>/dev/null || true

                # Clean up residual config
                dpkg --purge mariadb-server mariadb-client mariadb-common \
                    mysql-server mysql-client mysql-common 2>/dev/null || true

                apt-get autoremove -y
                apt-get autoclean

                # Clean up config files and data
                print_info "Cleaning up configuration and data..."
                rm -rf /etc/mysql
                rm -rf /var/lib/mysql
                rm -rf /var/log/mysql
                rm -rf /etc/mysql/FROZEN

                print_success "Old database removed completely"

                # Update package lists
                apt-get update -qq

                # Install MySQL fresh
                print_info "Installing MySQL server..."
                DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server

                # Create default MySQL config if missing
                if [ ! -f /etc/mysql/my.cnf ]; then
                    print_info "Creating MySQL default configuration..."
                    mkdir -p /etc/mysql/conf.d /etc/mysql/mysql.conf.d
                    tee /etc/mysql/my.cnf > /dev/null <<'EOFMYSQL'
# MySQL default configuration
[client]
port = 3306
socket = /var/run/mysqld/mysqld.sock

[mysqld]
port = 3306
socket = /var/run/mysqld/mysqld.sock
pid-file = /var/run/mysqld/mysqld.pid
datadir = /var/lib/mysql
bind-address = 127.0.0.1
log-error = /var/log/mysql/error.log

!includedir /etc/mysql/conf.d/
!includedir /etc/mysql/mysql.conf.d/
EOFMYSQL
                    print_success "MySQL configuration created"
                fi

                # Initialize MySQL data directory if needed
                if [ ! -d /var/lib/mysql/mysql ]; then
                    print_info "Initializing MySQL data directory..."
                    mkdir -p /var/lib/mysql
                    chown -R mysql:mysql /var/lib/mysql
                    mysqld --initialize-insecure --user=mysql 2>/dev/null || true
                fi

                # Create log directory
                mkdir -p /var/log/mysql
                chown -R mysql:adm /var/log/mysql

                # Verify installation and start
                if dpkg -l | grep -q "^ii.*mysql-server"; then
                    print_info "Starting MySQL..."
                    systemctl start mysql
                    systemctl enable mysql

                    # Wait for MySQL to start
                    sleep 3

                    if systemctl is-active --quiet mysql; then
                        print_success "MySQL installed and started"
                    else
                        print_error "MySQL failed to start, checking logs..."
                        journalctl -u mysql -n 20 --no-pager
                    fi
                else
                    print_error "MySQL installation failed, trying to fix..."
                    apt-get install -f -y
                    dpkg --configure -a
                    systemctl start mysql 2>/dev/null || true
                fi
                ;;
            3)
                print_error "Installation cancelled"
                exit 1
                ;;
            *)
                print_error "Invalid choice"
                exit 1
                ;;
        esac
    else
        # Install MySQL - no existing database
        print_info "Installing MySQL server..."
        DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server

        # Create default MySQL config if missing
        if [ ! -f /etc/mysql/my.cnf ]; then
            print_info "Creating MySQL default configuration..."
            mkdir -p /etc/mysql/conf.d /etc/mysql/mysql.conf.d
            tee /etc/mysql/my.cnf > /dev/null <<'EOFMYSQL'
# MySQL default configuration
[client]
port = 3306
socket = /var/run/mysqld/mysqld.sock

[mysqld]
port = 3306
socket = /var/run/mysqld/mysqld.sock
pid-file = /var/run/mysqld/mysqld.pid
datadir = /var/lib/mysql
bind-address = 127.0.0.1
log-error = /var/log/mysql/error.log

!includedir /etc/mysql/conf.d/
!includedir /etc/mysql/mysql.conf.d/
EOFMYSQL
            print_success "MySQL configuration created"
        fi

        # Initialize MySQL data directory if needed
        if [ ! -d /var/lib/mysql/mysql ]; then
            print_info "Initializing MySQL data directory..."
            mkdir -p /var/lib/mysql
            chown -R mysql:mysql /var/lib/mysql
            mysqld --initialize-insecure --user=mysql 2>/dev/null || true
        fi

        # Create log directory
        mkdir -p /var/log/mysql
        chown -R mysql:adm /var/log/mysql

        systemctl start mysql
        systemctl enable mysql
        print_success "MySQL installed and started"
    fi

    # Detect or choose web server
    print_info "Detecting web server..."
    WEB_SERVER=""

    if systemctl is-active --quiet nginx; then
        WEB_SERVER="nginx"
        print_info "Nginx detected, will use Nginx"
    elif systemctl is-active --quiet apache2; then
        WEB_SERVER="apache"
        print_info "Apache detected, will use Apache"
    else
        # Ask user to choose
        echo ""
        echo "No web server detected. Please choose:"
        echo "  1) Nginx (recommended, lightweight)"
        echo "  2) Apache (traditional)"
        read -r -p "Enter choice [1-2]: " choice

        case "$choice" in
            1)
                WEB_SERVER="nginx"
                print_info "Selected: Nginx"
                ;;
            2)
                WEB_SERVER="apache"
                print_info "Selected: Apache"
                ;;
            *)
                print_error "Invalid choice"
                exit 1
                ;;
        esac
    fi

    # Install Zabbix server, frontend, agent based on web server
    print_info "Installing Zabbix Server, Frontend, Agent..."

    if [ "$WEB_SERVER" = "nginx" ]; then
        apt-get install -y zabbix-server-mysql zabbix-frontend-php zabbix-nginx-conf zabbix-sql-scripts zabbix-agent php-fpm
        print_success "Installed Zabbix with Nginx support"
    else
        apt-get install -y zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent
        print_success "Installed Zabbix with Apache support"
    fi

    # Create Zabbix database
    print_info "Setting up Zabbix database..."

    # Generate random password for MySQL root if not set
    if ! mysql -u root -e "SELECT 1" &>/dev/null; then
        MYSQL_ROOT_PASSWORD=$(openssl rand -base64 32)
        mysql -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF
        echo "MySQL root password: ${MYSQL_ROOT_PASSWORD}" > /root/.mysql_root_password
        chmod 600 /root/.mysql_root_password
        print_success "MySQL root password saved to /root/.mysql_root_password"
    fi

    # Create Zabbix database and user
    ZABBIX_DB_PASSWORD=$(openssl rand -base64 32)
    mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS zabbix CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
CREATE USER IF NOT EXISTS 'zabbix'@'localhost' IDENTIFIED BY '${ZABBIX_DB_PASSWORD}';
GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'localhost';
SET GLOBAL log_bin_trust_function_creators = 1;
FLUSH PRIVILEGES;
EOF

    # Import initial schema
    print_info "Importing Zabbix database schema..."
    zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mysql --default-character-set=utf8mb4 -uzabbix -p"${ZABBIX_DB_PASSWORD}" zabbix

    mysql -u root <<EOF
SET GLOBAL log_bin_trust_function_creators = 0;
EOF

    print_success "Zabbix database created and configured"

    # Save database credentials
    echo "Zabbix DB Password: ${ZABBIX_DB_PASSWORD}" > /root/.zabbix_db_password
    chmod 600 /root/.zabbix_db_password
    print_success "Zabbix DB password saved to /root/.zabbix_db_password"

    # Configure Zabbix server
    print_info "Configuring Zabbix server..."
    sed -i "s/# DBPassword=/DBPassword=${ZABBIX_DB_PASSWORD}/" /etc/zabbix/zabbix_server.conf

    # Configure web server
    if [ "$WEB_SERVER" = "nginx" ]; then
        print_info "Configuring Nginx..."

        # Update Nginx config for Zabbix
        sed -i 's/# listen 8080;/listen 80;/' /etc/zabbix/nginx.conf
        sed -i 's/# server_name example.com;/server_name _;/' /etc/zabbix/nginx.conf

        # Create symlink if not exists
        if [ ! -L /etc/nginx/sites-enabled/zabbix ]; then
            ln -sf /etc/zabbix/nginx.conf /etc/nginx/sites-enabled/zabbix
        fi

        # Test Nginx config
        if nginx -t 2>/dev/null; then
            print_success "Nginx configuration is valid"
        else
            print_error "Nginx configuration has errors, please check manually"
        fi

        # Start and enable services
        print_info "Starting Zabbix services..."
        systemctl restart zabbix-server zabbix-agent php8.4-fpm nginx 2>/dev/null || \
        systemctl restart zabbix-server zabbix-agent php8.3-fpm nginx 2>/dev/null || \
        systemctl restart zabbix-server zabbix-agent php8.1-fpm nginx 2>/dev/null || \
        systemctl restart zabbix-server zabbix-agent php-fpm nginx

        systemctl enable zabbix-server zabbix-agent nginx
        print_success "Zabbix services started and enabled (Nginx)"
    else
        print_info "Configuring Apache..."

        # Start and enable services
        print_info "Starting Zabbix services..."
        systemctl restart zabbix-server zabbix-agent apache2
        systemctl enable zabbix-server zabbix-agent apache2
        print_success "Zabbix services started and enabled (Apache)"
    fi

    # Configure firewall if ufw is active
    if command -v ufw &>/dev/null && ufw status | grep -q "Status: active"; then
        print_info "Configuring firewall..."
        ufw allow 80/tcp
        ufw allow 443/tcp
        ufw allow 10051/tcp
        ufw reload
        print_success "Firewall configured"
    fi

    echo ''
    echo '=========================================='
    echo '✨ Zabbix Server installed successfully!'
    echo '=========================================='
    echo ''
    echo "📌 Web Server: ${WEB_SERVER}"

    # Detect actual listening port
    if command -v ss &>/dev/null; then
        NGINX_PORT=$(ss -tlnp | grep nginx | grep -oP ':\K[0-9]+' | head -1)
        APACHE_PORT=$(ss -tlnp | grep apache | grep -oP ':\K[0-9]+' | head -1)
    else
        NGINX_PORT=$(netstat -tlnp 2>/dev/null | grep nginx | grep -oP ':\K[0-9]+' | head -1)
        APACHE_PORT=$(netstat -tlnp 2>/dev/null | grep apache | grep -oP ':\K[0-9]+' | head -1)
    fi

    if [ "$WEB_SERVER" = "nginx" ] && [ -n "$NGINX_PORT" ]; then
        echo "📌 Nginx listening on port: ${NGINX_PORT}"
    elif [ "$WEB_SERVER" = "apache" ] && [ -n "$APACHE_PORT" ]; then
        echo "📌 Apache listening on port: ${APACHE_PORT}"
    fi

    echo '📌 Access Zabbix Web Interface:'
    SERVER_IP=$(hostname -I | awk '{print $1}')

    if [ "$WEB_SERVER" = "nginx" ] && [ -n "$NGINX_PORT" ]; then
        if [ "$NGINX_PORT" = "80" ]; then
            echo "   http://${SERVER_IP}/zabbix"
        else
            echo "   http://${SERVER_IP}:${NGINX_PORT}/zabbix"
        fi
    elif [ "$WEB_SERVER" = "apache" ] && [ -n "$APACHE_PORT" ]; then
        if [ "$APACHE_PORT" = "80" ]; then
            echo "   http://${SERVER_IP}/zabbix"
        else
            echo "   http://${SERVER_IP}:${APACHE_PORT}/zabbix"
        fi
    else
        echo "   http://${SERVER_IP}/zabbix"
    fi

    echo ''
    echo '📌 Default credentials:'
    echo '   Username: Admin'
    echo '   Password: zabbix'
    echo ''
    echo '⚠️  IMPORTANT: Change the default password after first login!'
    echo ''
    echo '📌 Database credentials saved in:'
    echo '   /root/.zabbix_db_password'
    echo '   /root/.mysql_root_password'
    echo ''
    echo '📌 Zabbix root directory: /usr/share/zabbix'
    echo ''
    echo '📌 Zabbix server configuration: /etc/zabbix/zabbix_server.conf'
    echo ''
    echo '📌 Zabbix agent configuration: /etc/zabbix/zabbix_agentd.conf'
    echo ''
    if [ "$WEB_SERVER" = "nginx" ]; then
        echo '📌 Nginx configuration: /etc/zabbix/nginx.conf'
        echo ''
        echo '🔍 Check Nginx status:'
        echo '   systemctl status nginx'
        echo '   ss -tlnp | grep nginx'
        echo ''
        echo '📝 If Zabbix not accessible, check Nginx config:'
        echo '   sudo nginx -t'
        echo '   cat /etc/zabbix/nginx.conf'
        echo '   ls -la /etc/nginx/sites-enabled/ | grep zabbix'
        echo ''
    else
        echo '📌 Apache configuration: /etc/apache2/conf-enabled/zabbix.conf'
        echo ''
        echo '🔍 Check Apache status:'
        echo '   systemctl status apache2'
        echo '   ss -tlnp | grep apache'
        echo ''
    fi
    echo '=========================================='
    echo ''
}

# Install Zabbix Agent
install_zabbix_agent() {
    echo '=========================================='
    echo '🔧 Installing Zabbix Agent'
    echo '=========================================='
    echo ''

    # Get Zabbix server address from user
    read -r -p "Enter Zabbix Server IP address: " ZABBIX_SERVER_IP

    if [ -z "$ZABBIX_SERVER_IP" ]; then
        print_error "Zabbix Server IP is required"
        exit 1
    fi

    print_info "Updating system packages..."
    apt-get update -qq

    print_info "Installing required packages..."
    apt-get install -y wget curl gnupg2 software-properties-common apt-transport-https ca-certificates

    # Install Zabbix repository
    print_info "Adding Zabbix repository..."
    if [ "$UBUNTU_VERSION" -eq 24 ]; then
        wget -q https://repo.zabbix.com/zabbix/${ZABBIX_VERSION}/ubuntu/pool/main/z/zabbix-release/zabbix-release_${ZABBIX_VERSION}-1+ubuntu24.04_all.deb
        dpkg -i zabbix-release_${ZABBIX_VERSION}-1+ubuntu24.04_all.deb
        rm -f zabbix-release_${ZABBIX_VERSION}-1+ubuntu24.04_all.deb
    elif [ "$UBUNTU_VERSION" -eq 22 ]; then
        wget -q https://repo.zabbix.com/zabbix/${ZABBIX_VERSION}/ubuntu/pool/main/z/zabbix-release/zabbix-release_${ZABBIX_VERSION}-1+ubuntu22.04_all.deb
        dpkg -i zabbix-release_${ZABBIX_VERSION}-1+ubuntu22.04_all.deb
        rm -f zabbix-release_${ZABBIX_VERSION}-1+ubuntu22.04_all.deb
    elif [ "$UBUNTU_VERSION" -eq 20 ]; then
        wget -q https://repo.zabbix.com/zabbix/${ZABBIX_VERSION}/ubuntu/pool/main/z/zabbix-release/zabbix-release_${ZABBIX_VERSION}-1+ubuntu20.04_all.deb
        dpkg -i zabbix-release_${ZABBIX_VERSION}-1+ubuntu20.04_all.deb
        rm -f zabbix-release_${ZABBIX_VERSION}-1+ubuntu20.04_all.deb
    else
        print_error "Unsupported Ubuntu version: $UBUNTU_VERSION"
        exit 1
    fi

    apt-get update -qq
    print_success "Zabbix repository added"

    # Install Zabbix agent
    print_info "Installing Zabbix Agent..."
    apt-get install -y zabbix-agent

    # Configure Zabbix agent
    print_info "Configuring Zabbix Agent..."
    sed -i "s/^Server=.*/Server=${ZABBIX_SERVER_IP}/" /etc/zabbix/zabbix_agentd.conf
    sed -i "s/^ServerActive=.*/ServerActive=${ZABBIX_SERVER_IP}/" /etc/zabbix/zabbix_agentd.conf
    sed -i "s/^Hostname=.*/Hostname=$(hostname)/" /etc/zabbix/zabbix_agentd.conf

    # Start and enable Zabbix agent
    print_info "Starting Zabbix Agent..."
    systemctl restart zabbix-agent
    systemctl enable zabbix-agent
    print_success "Zabbix Agent started and enabled"

    # Configure firewall if ufw is active
    if command -v ufw &>/dev/null && ufw status | grep -q "Status: active"; then
        print_info "Configuring firewall..."
        ufw allow from "$ZABBIX_SERVER_IP" to any port 10050
        ufw reload
        print_success "Firewall configured"
    fi

    echo ''
    echo '=========================================='
    echo '✨ Zabbix Agent installed successfully!'
    echo '=========================================='
    echo ''
    echo '📌 Agent Configuration:'
    echo "   Server: ${ZABBIX_SERVER_IP}"
    echo "   Hostname: $(hostname)"
    echo '   Port: 10050'
    echo ''
    echo '📌 Next steps:'
    echo '   1. Add this host in Zabbix Server web interface'
    echo '   2. Assign templates to monitor this host'
    echo '   3. Check agent status: systemctl status zabbix-agent'
    echo ''
}

# Show usage
show_usage() {
    echo "Usage: $0 [server|client] [server_ip]"
    echo ""
    echo "Options:"
    echo "  server              Install Zabbix Server with web interface"
    echo "  client [server_ip]  Install Zabbix Agent (client)"
    echo ""
    echo "Arguments:"
    echo "  server_ip           Zabbix Server IP (optional for client)"
    echo "                      If not provided, will prompt for input"
    echo ""
    echo "Examples:"
    echo "  $0 server                    # Install Zabbix Server"
    echo "  $0 client                    # Install Agent (will ask for IP)"
    echo "  $0 client 192.168.1.100      # Install Agent with Server IP"
    echo ""
}

# Main
main() {
    check_root

    case "${1:-}" in
        server)
            install_zabbix_server
            ;;
        client)
            install_zabbix_agent
            ;;
        *)
            show_usage
            exit 1
            ;;
    esac
}

main "$@"

