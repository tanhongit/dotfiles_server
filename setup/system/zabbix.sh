#!/bin/bash

# ======================== Zabbix Setup ========================
# Setup Zabbix Server or Zabbix Agent
# Usage:
#   ./zabbix.sh server   # Install Zabbix Server
#   ./zabbix.sh client   # Install Zabbix Agent

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

    # Install MySQL
    print_info "Installing MySQL server..."
    apt-get install -y mysql-server
    systemctl start mysql
    systemctl enable mysql
    print_success "MySQL installed and started"

    # Install Zabbix server, frontend, agent
    print_info "Installing Zabbix Server, Frontend, Agent..."
    apt-get install -y zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent

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
    echo '📌 Access Zabbix Web Interface:'
    echo "   http://$(hostname -I | awk '{print $1}')/zabbix"
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
    if [ "$WEB_SERVER" = "nginx" ]; then
        echo '📌 Nginx configuration: /etc/zabbix/nginx.conf'
        echo ''
    fi
}

# Install Zabbix Agent
install_zabbix_agent() {
    echo '=========================================='
    echo '🔧 Installing Zabbix Agent'
    echo '=========================================='
    echo ''

    # Get Zabbix server address from user
    read -p "Enter Zabbix Server IP address: " ZABBIX_SERVER_IP

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
    echo "Usage: $0 [server|client]"
    echo ""
    echo "Options:"
    echo "  server    Install Zabbix Server with web interface"
    echo "  client    Install Zabbix Agent (client)"
    echo ""
    echo "Examples:"
    echo "  $0 server    # Install Zabbix Server"
    echo "  $0 client    # Install Zabbix Agent"
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

