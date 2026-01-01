#!/bin/bash

# Fix MySQL FROZEN issue when downgrading from MariaDB to MySQL

echo "=========================================="
echo "🔧 Fixing MySQL FROZEN Issue"
echo "=========================================="
echo ""

if [ "$EUID" -ne 0 ]; then
    echo "❌ Please run as root or with sudo"
    exit 1
fi

# Check if FROZEN file exists
if [ ! -f /etc/mysql/FROZEN ]; then
    echo "✓ No FROZEN file found, MySQL is not frozen"
    exit 0
fi

echo "Found FROZEN file:"
cat /etc/mysql/FROZEN
echo ""

echo "This happens when trying to downgrade from MariaDB 11.x to MySQL 8.0"
echo ""
echo "Choose an option:"
echo "  1) Remove MySQL/MariaDB and clean everything (recommended)"
echo "  2) Just remove FROZEN file (risky, may cause data corruption)"
echo "  3) Cancel"
read -r -p "Enter choice [1-3]: " choice

case "$choice" in
    1)
        echo ""
        echo "➜ Stopping database services..."
        systemctl stop mysql 2>/dev/null || true
        systemctl stop mariadb 2>/dev/null || true

        echo "➜ Fixing broken packages..."
        dpkg --configure -a 2>/dev/null || true
        apt-get install -f -y 2>/dev/null || true

        echo "➜ Removing packages..."
        apt-get remove --purge -y mariadb-server* mariadb-client* mariadb-common* \
            mysql-server* mysql-client* mysql-common* 2>/dev/null || true

        dpkg --purge mariadb-server mariadb-client mariadb-common \
            mysql-server mysql-client mysql-common 2>/dev/null || true

        echo "➜ Cleaning up files..."
        rm -rf /etc/mysql
        rm -rf /var/lib/mysql
        rm -rf /var/log/mysql

        echo "➜ Removing auto-installed packages..."
        apt-get autoremove -y
        apt-get autoclean

        echo ""
        echo "✅ Cleanup complete!"
        echo ""
        echo "📌 Next steps:"
        echo "   1. Run: apt-get update"
        echo "   2. Install MySQL: DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server"
        echo "   3. Or run Zabbix installation again: bash install.sh zabbix_server"
        ;;
    2)
        echo ""
        echo "⚠️  Removing FROZEN file only (risky)..."
        rm -f /etc/mysql/FROZEN
        echo "✓ FROZEN file removed"
        echo ""
        echo "📌 Try to start MySQL:"
        echo "   systemctl start mysql"
        ;;
    3)
        echo "Cancelled"
        exit 0
        ;;
    *)
        echo "❌ Invalid choice"
        exit 1
        ;;
esac

