# Zabbix Setup Guide

Complete guide for installing and configuring Zabbix monitoring system.

## Features

### ✨ Zabbix Server
- Auto-detects existing web server (Nginx or Apache)
- Lets you choose if no web server is installed
- Automatic MySQL database setup
- Secure random password generation
- Automatic firewall configuration
- Support for Ubuntu 20.04, 22.04, 24.04

### ✨ Zabbix Agent (Client)
- Simple installation process
- Interactive configuration
- Automatic firewall rules
- Ready to connect to Zabbix Server

## Installation

### Install Zabbix Server

**Method 1: Using install.sh**
```bash
sudo bash install.sh zabbix_server
# or short command
sudo bash install.sh zs
```

**Method 2: Direct script**
```bash
sudo bash setup/system/zabbix.sh server
```

**Method 3: Through main setup**
```bash
bash install.sh setup
# Then choose "server" when prompted for Zabbix installation
```

### Install Zabbix Agent (Client)

**Method 1: Using install.sh**
```bash
sudo bash install.sh zabbix_client
# or short command
sudo bash install.sh zc
```

**Method 2: Direct script**
```bash
sudo bash setup/system/zabbix.sh client
```

**Method 3: Through main setup**
```bash
bash install.sh setup
# Then choose "client" when prompted for Zabbix installation
```

## What Gets Installed

### Zabbix Server Installation Includes:
1. **Zabbix Server 6.5** - Main monitoring server
2. **MySQL Database** - For storing monitoring data
3. **Web Interface** - Frontend for Zabbix
4. **Web Server** - Nginx or Apache (auto-detected or user choice)
5. **Zabbix Agent** - For monitoring the server itself
6. **PHP-FPM** - For Nginx installations

### Zabbix Agent Installation Includes:
1. **Zabbix Agent 6.5** - Client agent for monitoring

## Configuration

### Automatic Configuration

The script automatically:
- ✅ Creates MySQL database and user
- ✅ Generates secure random passwords
- ✅ Configures Zabbix Server
- ✅ Configures web server (Nginx or Apache)
- ✅ Opens firewall ports
- ✅ Starts and enables all services

### Credentials Storage

After installation, credentials are saved in:
- `/root/.zabbix_db_password` - Zabbix database password
- `/root/.mysql_root_password` - MySQL root password (if set)

**View credentials:**
```bash
sudo cat /root/.zabbix_db_password
sudo cat /root/.mysql_root_password
```

## Access Zabbix Web Interface

After installation, access the web interface:

```
http://YOUR_SERVER_IP/zabbix
```

**Default credentials:**
- Username: `Admin`
- Password: `zabbix`

⚠️ **IMPORTANT:** Change the default password immediately after first login!

## Web Server Selection

### Automatic Detection

The script automatically detects:
1. If Nginx is running → uses Nginx
2. If Apache is running → uses Apache
3. If neither is running → asks you to choose

### Manual Selection

If prompted, you can choose:
```
No web server detected. Please choose:
  1) Nginx (recommended, lightweight)
  2) Apache (traditional)
Enter choice [1-2]:
```

**Recommendation:** Choose Nginx for better performance with PHP-FPM.

## Firewall Ports

### Zabbix Server
- Port 80 (HTTP) - Web interface
- Port 443 (HTTPS) - Secure web interface (if configured)
- Port 10051 (TCP) - Zabbix Server port

### Zabbix Agent
- Port 10050 (TCP) - Zabbix Agent port (only from Zabbix Server IP)

## Adding Hosts to Monitor

### Step 1: Install Zabbix Agent on Client

```bash
# On client machine
sudo bash install.sh zabbix_client
# Enter Zabbix Server IP when prompted
```

### Step 2: Add Host in Zabbix Web Interface

1. Login to Zabbix web interface
2. Go to **Configuration** → **Hosts**
3. Click **Create host**
4. Fill in:
   - **Host name:** Your client hostname
   - **Groups:** Select appropriate groups
   - **Interfaces:** Add Agent interface with client IP
5. Go to **Templates** tab
6. Add templates (e.g., "Linux by Zabbix agent")
7. Click **Add**

### Step 3: Verify Connection

```bash
# On client machine
sudo systemctl status zabbix-agent

# Check if agent is listening
sudo ss -tlnp | grep 10050
```

## Troubleshooting

### Check Service Status

```bash
# Zabbix Server
sudo systemctl status zabbix-server

# Zabbix Agent
sudo systemctl status zabbix-agent

# Web Server
sudo systemctl status nginx    # or apache2
```

### View Logs

```bash
# Zabbix Server logs
sudo tail -f /var/log/zabbix/zabbix_server.log

# Zabbix Agent logs
sudo tail -f /var/log/zabbix/zabbix_agentd.log

# Web server logs
sudo tail -f /var/log/nginx/error.log    # for Nginx
sudo tail -f /var/log/apache2/error.log  # for Apache
```

### Common Issues

#### 1. Cannot access web interface

**Check web server:**
```bash
sudo systemctl status nginx  # or apache2
sudo nginx -t                # test Nginx config
```

**Check firewall:**
```bash
sudo ufw status
sudo ufw allow 80/tcp
sudo ufw reload
```

#### 2. Database connection error

**Check MySQL:**
```bash
sudo systemctl status mysql
```

**Test connection:**
```bash
mysql -uzabbix -p < /root/.zabbix_db_password zabbix
```

#### 3. Agent not connecting

**Check agent configuration:**
```bash
sudo cat /etc/zabbix/zabbix_agentd.conf | grep -E "^Server="
```

**Test from server:**
```bash
# On Zabbix Server
zabbix_get -s CLIENT_IP -k agent.ping
```

**Check firewall on client:**
```bash
sudo ufw status
sudo ufw allow from SERVER_IP to any port 10050
```

## Uninstallation

### Remove Zabbix Server

```bash
sudo systemctl stop zabbix-server zabbix-agent
sudo apt-get remove --purge zabbix-server-mysql zabbix-frontend-php zabbix-agent
sudo rm -rf /etc/zabbix
sudo rm -f /root/.zabbix_db_password

# Optionally remove database
sudo mysql -u root -e "DROP DATABASE zabbix; DROP USER 'zabbix'@'localhost';"
```

### Remove Zabbix Agent

```bash
sudo systemctl stop zabbix-agent
sudo apt-get remove --purge zabbix-agent
sudo rm -rf /etc/zabbix
```

## Advanced Configuration

### Enable HTTPS

**For Nginx:**
```bash
# Install certbot
sudo apt-get install certbot python3-certbot-nginx

# Get SSL certificate
sudo certbot --nginx -d your-domain.com

# Certbot will automatically configure Nginx
```

**For Apache:**
```bash
# Install certbot
sudo apt-get install certbot python3-certbot-apache

# Get SSL certificate
sudo certbot --apache -d your-domain.com
```

### Change Zabbix Server Port

Edit `/etc/zabbix/zabbix_server.conf`:
```bash
sudo nano /etc/zabbix/zabbix_server.conf

# Find and change:
# ListenPort=10051
ListenPort=NEW_PORT

# Restart
sudo systemctl restart zabbix-server
```

### Backup Zabbix

**Backup database:**
```bash
mysqldump -uzabbix -p zabbix > zabbix_backup_$(date +%Y%m%d).sql
```

**Backup configuration:**
```bash
sudo tar -czf zabbix_config_backup.tar.gz /etc/zabbix/
```

## References

- [Zabbix Official Documentation](https://www.zabbix.com/documentation/current/)
- [Zabbix Templates](https://www.zabbix.com/integrations)
- [Zabbix Community](https://www.zabbix.com/forum)

## Support

For issues and questions:
1. Check the [Troubleshooting](#troubleshooting) section
2. Review Zabbix logs
3. Visit [Zabbix Documentation](https://www.zabbix.com/documentation/current/)

