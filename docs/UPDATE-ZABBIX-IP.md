# Update Zabbix Server IP Guide

## Overview

This guide explains how to update the Zabbix Server IP address on servers that already have Zabbix Agent installed. This is useful when:
- Your Zabbix Server IP address changes
- You're migrating to a new Zabbix Server
- You need to point agents to a different monitoring server

## Prerequisites

- Zabbix Agent (or Agent2) must be already installed
- Root or sudo access on the agent server
- Network connectivity to the new Zabbix Server

## Quick Usage

### Method 1: Interactive (Prompt for IP)

```bash
sudo bash install.sh update_zabbix_ip
```

The script will:
1. Detect your installed Zabbix Agent version
2. Show current configuration
3. Prompt you for the new Zabbix Server IP
4. Ask for confirmation
5. Update the configuration
6. Restart the agent
7. Verify the connection

### Method 2: Direct IP (Non-interactive)

```bash
sudo bash install.sh update_zabbix_ip 192.168.1.200
```

Or use the short alias:

```bash
sudo bash install.sh uzi 192.168.1.200
```

## What It Does

### 1. Detection

The script automatically detects which agent is installed:
- **Zabbix Agent 2** (`zabbix_agent2`)
  - Config: `/etc/zabbix/zabbix_agent2.conf`
  - Service: `zabbix-agent2`
- **Zabbix Agent** (`zabbix_agentd`)
  - Config: `/etc/zabbix/zabbix_agentd.conf`
  - Service: `zabbix-agent`

### 2. Shows Current Configuration

```
✓ Found: Zabbix Agent 2
✓ Config file: /etc/zabbix/zabbix_agent2.conf

✓ Current Server: 192.168.1.100
✓ Current ServerActive: 192.168.1.100
```

### 3. Validates New IP

The script validates that the IP address is in correct format:
- Must be IPv4 format (e.g., 192.168.1.100)
- Each octet must be 0-255
- Rejects invalid formats

### 4. Creates Backup

Before making changes, the script creates a timestamped backup:
```
✓ Backup created: /etc/zabbix/zabbix_agent2.conf.backup.20260103_140530
```

### 5. Updates Configuration

Updates two key parameters:
- `Server=` - Passive checks (server pulls data from agent)
- `ServerActive=` - Active checks (agent pushes data to server)

### 6. Restarts Agent

Safely restarts the agent service and verifies it's running:
```
✓ Restarting Zabbix Agent 2...
✓ Zabbix Agent 2 restarted successfully
✓ Zabbix Agent 2 is running
```

### 7. Verifies Connection

Tests connection to the new server on port 10051:
```
✓ Testing connection to Zabbix Server...
✓ Connection to 192.168.1.200:10051 successful
```

## Example Session

```bash
$ sudo bash install.sh update_zabbix_ip

========================================
Update Zabbix Server IP
========================================

✓ Found: Zabbix Agent 2
✓ Config file: /etc/zabbix/zabbix_agent2.conf

✓ Current Server: 192.168.1.100
✓ Current ServerActive: 192.168.1.100

Enter new Zabbix Server IP: 192.168.1.200
✓ New Zabbix Server IP: 192.168.1.200

Update Zabbix Server IP to 192.168.1.200? (y/N): y

✓ Updating Zabbix Agent configuration...
✓ Backup created: /etc/zabbix/zabbix_agent2.conf.backup.20260103_140530
✓ Updated Server parameter
✓ Updated ServerActive parameter
✓ Restarting Zabbix Agent 2...
✓ Zabbix Agent 2 restarted successfully
✓ Zabbix Agent 2 is running

========================================
Configuration Verification
========================================

Server:       192.168.1.200
ServerActive: 192.168.1.200
Hostname:     web-server-01

✓ Testing connection to Zabbix Server...
✓ Connection to 192.168.1.200:10051 successful

========================================
Update Complete!
========================================

✓ Zabbix Server IP updated to: 192.168.1.200
✓ Backup saved to: /etc/zabbix/zabbix_agent2.conf.backup.20260103_140530

✓ Next steps on Zabbix Server:
  1. Add this host to Zabbix Server if not already added
  2. Check host status in Zabbix web interface
  3. Verify agent is reporting data
```

## Error Handling

### Agent Not Installed

```
✗ Zabbix Agent is not installed on this system

Please install Zabbix Agent first:
  sudo bash install.sh zabbix_client
```

### Invalid IP Format

```
✗ Invalid IP address format: 192.168.1.256
```

### Connection Failed

```
⚠ Cannot connect to 192.168.1.200:10051
⚠ Please check:
  1. Zabbix Server is running at 192.168.1.200
  2. Firewall allows connection to port 10051
  3. This host is added to Zabbix Server
```

### Restart Failed

If restart fails, the script automatically:
1. Shows error message
2. Restores the backup
3. Attempts to restart with old config

## Rollback

If you need to rollback to the previous configuration:

```bash
# Find the backup file
ls -la /etc/zabbix/*.backup.*

# Restore it
sudo cp /etc/zabbix/zabbix_agent2.conf.backup.20260103_140530 /etc/zabbix/zabbix_agent2.conf

# Restart agent
sudo systemctl restart zabbix-agent2
```

## Troubleshooting

### Agent Not Connecting to New Server

**Check 1: Firewall on Agent Server**
```bash
# Allow outgoing to Zabbix Server
sudo ufw allow out to 192.168.1.200 port 10051
```

**Check 2: Firewall on Zabbix Server**
```bash
# Allow incoming from agents
sudo ufw allow 10051/tcp
```

**Check 3: Agent Logs**
```bash
# For Agent 2
sudo tail -f /var/log/zabbix/zabbix_agent2.log

# For Agent 1
sudo tail -f /var/log/zabbix/zabbix_agentd.log
```

**Check 4: Configuration**
```bash
# Verify Server parameter
grep "^Server=" /etc/zabbix/zabbix_agent2.conf

# Verify ServerActive parameter
grep "^ServerActive=" /etc/zabbix/zabbix_agent2.conf
```

**Check 5: Agent Status**
```bash
sudo systemctl status zabbix-agent2
```

### Host Not Showing in Zabbix Server

1. **Add host on Zabbix Server:**
   - Go to Configuration → Hosts → Create host
   - Set Host name (must match agent's Hostname)
   - Set Groups
   - Set Interfaces (Agent interface with correct IP)
   - Link Templates
   - Click Add

2. **Check host availability:**
   - Go to Configuration → Hosts
   - Look for ZBX icon (should be green)
   - Green = Agent is reachable
   - Red = Agent is not reachable

3. **Check latest data:**
   - Click on host name
   - Go to Latest data
   - Should see metrics coming in

## Bulk Update

To update multiple servers, you can use a loop:

```bash
# List of servers
SERVERS=(
    "server1.example.com"
    "server2.example.com"
    "server3.example.com"
)

# New Zabbix Server IP
NEW_IP="192.168.1.200"

# Update each server
for server in "${SERVERS[@]}"; do
    echo "Updating $server..."
    ssh root@$server "cd /root/dotfiles_server && bash install.sh update_zabbix_ip $NEW_IP"
done
```

## Using Ansible

For Ansible automation:

```yaml
---
- name: Update Zabbix Server IP
  hosts: zabbix_agents
  become: yes
  vars:
    new_zabbix_server_ip: "192.168.1.200"
  
  tasks:
    - name: Update Zabbix Server IP
      shell: |
        cd /root/dotfiles_server
        bash install.sh update_zabbix_ip {{ new_zabbix_server_ip }}
      register: result
    
    - name: Show result
      debug:
        var: result.stdout_lines
```

## Security Considerations

### 1. Verify New Server

Before updating, ensure the new IP belongs to your legitimate Zabbix Server:
```bash
# Check if port 10051 is open
nc -zv 192.168.1.200 10051

# Check Zabbix Server version
telnet 192.168.1.200 10051
```

### 2. Backup Strategy

The script creates automatic backups, but you may want to keep them longer:
```bash
# Archive old backups
sudo mkdir -p /root/zabbix-backups
sudo cp /etc/zabbix/*.backup.* /root/zabbix-backups/
```

### 3. PSK Encryption

If using PSK encryption, make sure:
- `TLSConnect=psk` is set
- `TLSAccept=psk` is set
- `TLSPSKIdentity` matches server configuration
- `TLSPSKFile` points to correct PSK file

This script does not modify PSK settings.

## Advanced Usage

### Custom Configuration

If you need to update additional parameters:

```bash
# Edit the config file directly
sudo nano /etc/zabbix/zabbix_agent2.conf

# Then restart
sudo systemctl restart zabbix-agent2
```

### Multiple Zabbix Servers

To monitor from multiple servers (comma-separated):

```bash
# Edit config file
sudo nano /etc/zabbix/zabbix_agent2.conf

# Set multiple servers
Server=192.168.1.100,192.168.1.200
ServerActive=192.168.1.100:10051,192.168.1.200:10051

# Restart
sudo systemctl restart zabbix-agent2
```

## FAQ

**Q: Does this work with both Zabbix Agent and Agent2?**
A: Yes, it automatically detects which version is installed.

**Q: Will I lose my monitoring data?**
A: No, historical data is stored on the Zabbix Server, not the agent.

**Q: Do I need to reconfigure anything on the Zabbix Server?**
A: If the host already exists with the correct hostname, no changes needed. Otherwise, add/update the host.

**Q: Can I update hostname at the same time?**
A: No, this script only updates the server IP. To change hostname, edit the config file manually.

**Q: What if the new server is not reachable?**
A: The script will show a warning but still update the config. You can rollback if needed.

**Q: Is there a way to test without actually updating?**
A: Not directly, but you can check connectivity first:
```bash
nc -zv 192.168.1.200 10051
```

**Q: Can I use this for distributed monitoring?**
A: Yes, you can point agents to any Zabbix Server or Proxy.

## Related Commands

- Install Zabbix Agent: `sudo bash install.sh zabbix_client`
- Install Zabbix Server: `sudo bash install.sh zabbix_server`
- Check agent status: `sudo systemctl status zabbix-agent2`
- View agent logs: `sudo tail -f /var/log/zabbix/zabbix_agent2.log`

## Summary

The `update_zabbix_ip` command provides a safe and automated way to update Zabbix Server IP addresses for installed agents:

✅ **Automatic detection** of agent version
✅ **Validation** of IP address format
✅ **Backup** before changes
✅ **Safe rollback** if errors occur
✅ **Connection verification** to new server
✅ **Works with** both Agent and Agent2

For additional help or issues, check the main README or the script source code.

