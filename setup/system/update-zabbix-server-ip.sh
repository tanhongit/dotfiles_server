#!/bin/bash

# Update Zabbix Server IP for Zabbix Agent
# This script allows you to change the Zabbix Server IP without reinstalling the agent

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print functions
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_info() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "This script must be run as root or with sudo"
    exit 1
fi

print_header "Update Zabbix Server IP"
echo ""

# Check if Zabbix Agent is installed
if ! command -v zabbix_agent2 &>/dev/null && ! command -v zabbix_agentd &>/dev/null; then
    print_error "Zabbix Agent is not installed on this system"
    echo ""
    echo "Please install Zabbix Agent first:"
    echo "  sudo bash install.sh zabbix_client"
    exit 1
fi

# Detect which agent is installed
AGENT_CONFIG=""
AGENT_SERVICE=""
AGENT_NAME=""

if command -v zabbix_agent2 &>/dev/null; then
    AGENT_CONFIG="/etc/zabbix/zabbix_agent2.conf"
    AGENT_SERVICE="zabbix-agent2"
    AGENT_NAME="Zabbix Agent 2"
elif command -v zabbix_agentd &>/dev/null; then
    AGENT_CONFIG="/etc/zabbix/zabbix_agentd.conf"
    AGENT_SERVICE="zabbix-agent"
    AGENT_NAME="Zabbix Agent"
fi

print_info "Found: $AGENT_NAME"
print_info "Config file: $AGENT_CONFIG"
echo ""

# Get current Zabbix Server IP
CURRENT_SERVER=$(grep "^Server=" "$AGENT_CONFIG" | cut -d'=' -f2 | tr -d ' ')
CURRENT_SERVER_ACTIVE=$(grep "^ServerActive=" "$AGENT_CONFIG" | cut -d'=' -f2 | tr -d ' ')

if [ -n "$CURRENT_SERVER" ]; then
    print_info "Current Server: $CURRENT_SERVER"
fi

if [ -n "$CURRENT_SERVER_ACTIVE" ]; then
    print_info "Current ServerActive: $CURRENT_SERVER_ACTIVE"
fi

echo ""

# Get new Zabbix Server IP
if [ -n "$1" ]; then
    NEW_SERVER_IP="$1"
    print_info "Using provided IP: $NEW_SERVER_IP"
else
    read -r -p "Enter new Zabbix Server IP: " NEW_SERVER_IP
fi

# Validate IP address format
if ! [[ "$NEW_SERVER_IP" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    print_error "Invalid IP address format: $NEW_SERVER_IP"
    exit 1
fi

# Validate each octet
IFS='.' read -r -a octets <<< "$NEW_SERVER_IP"
for octet in "${octets[@]}"; do
    if [ "$octet" -lt 0 ] || [ "$octet" -gt 255 ]; then
        print_error "Invalid IP address: $NEW_SERVER_IP (octet out of range)"
        exit 1
    fi
done

print_info "New Zabbix Server IP: $NEW_SERVER_IP"
echo ""

# Confirm before proceeding
read -r -p "Update Zabbix Server IP to $NEW_SERVER_IP? (y/N): " confirm
if [[ ! $confirm =~ ^[Yy]$ ]]; then
    print_warning "Operation cancelled"
    exit 0
fi

echo ""
print_info "Updating Zabbix Agent configuration..."

# Backup current config
BACKUP_FILE="${AGENT_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)"
cp "$AGENT_CONFIG" "$BACKUP_FILE"
print_info "Backup created: $BACKUP_FILE"

# Update Server parameter
if grep -q "^Server=" "$AGENT_CONFIG"; then
    sed -i "s/^Server=.*/Server=$NEW_SERVER_IP/" "$AGENT_CONFIG"
    print_info "Updated Server parameter"
else
    echo "Server=$NEW_SERVER_IP" >> "$AGENT_CONFIG"
    print_info "Added Server parameter"
fi

# Update ServerActive parameter
if grep -q "^ServerActive=" "$AGENT_CONFIG"; then
    sed -i "s/^ServerActive=.*/ServerActive=$NEW_SERVER_IP/" "$AGENT_CONFIG"
    print_info "Updated ServerActive parameter"
else
    echo "ServerActive=$NEW_SERVER_IP" >> "$AGENT_CONFIG"
    print_info "Added ServerActive parameter"
fi

# Restart Zabbix Agent
print_info "Restarting $AGENT_NAME..."
if systemctl restart "$AGENT_SERVICE"; then
    print_info "$AGENT_NAME restarted successfully"
else
    print_error "Failed to restart $AGENT_NAME"
    print_warning "Restoring backup..."
    cp "$BACKUP_FILE" "$AGENT_CONFIG"
    systemctl restart "$AGENT_SERVICE" || true
    exit 1
fi

# Check agent status
sleep 2
if systemctl is-active --quiet "$AGENT_SERVICE"; then
    print_info "$AGENT_NAME is running"
else
    print_error "$AGENT_NAME is not running"
    systemctl status "$AGENT_SERVICE" --no-pager
    exit 1
fi

# Verify configuration
echo ""
print_header "Configuration Verification"
echo ""
echo "Server:       $(grep "^Server=" "$AGENT_CONFIG" | cut -d'=' -f2)"
echo "ServerActive: $(grep "^ServerActive=" "$AGENT_CONFIG" | cut -d'=' -f2)"
echo "Hostname:     $(grep "^Hostname=" "$AGENT_CONFIG" | cut -d'=' -f2)"
echo ""

# Test connection (optional)
print_info "Testing connection to Zabbix Server..."
if timeout 5 bash -c "echo > /dev/tcp/$NEW_SERVER_IP/10051" 2>/dev/null; then
    print_info "Connection to $NEW_SERVER_IP:10051 successful"
else
    print_warning "Cannot connect to $NEW_SERVER_IP:10051"
    print_warning "Please check:"
    echo "  1. Zabbix Server is running at $NEW_SERVER_IP"
    echo "  2. Firewall allows connection to port 10051"
    echo "  3. This host is added to Zabbix Server"
fi

echo ""
print_header "Update Complete!"
echo ""
print_info "Zabbix Server IP updated to: $NEW_SERVER_IP"
print_info "Backup saved to: $BACKUP_FILE"
echo ""
print_info "Next steps on Zabbix Server:"
echo "  1. Add this host to Zabbix Server if not already added"
echo "  2. Check host status in Zabbix web interface"
echo "  3. Verify agent is reporting data"
echo ""

