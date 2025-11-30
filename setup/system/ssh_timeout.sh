#!/bin/bash

# ======================== Set SSH Idle Disconnect ========================
echo 'Checking if SSH idle-disconnect is already configured...'
TARGET_INTERVAL=300
TARGET_COUNT=1

# Backup and safely replace or append ClientAlive settings
if sudo grep -qE '^ClientAliveInterval\s+' /etc/ssh/sshd_config || sudo grep -qE '^ClientAliveCountMax\s+' /etc/ssh/sshd_config; then
    echo "Updating existing ClientAlive settings to ${TARGET_INTERVAL}s and CountMax ${TARGET_COUNT}"
    sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak.$(date +%s)
    sudo sed -i.bak -E '/^ClientAliveInterval\s+/d' /etc/ssh/sshd_config || true
    sudo sed -i.bak -E '/^ClientAliveCountMax\s+/d' /etc/ssh/sshd_config || true
    echo "ClientAliveInterval ${TARGET_INTERVAL}" | sudo tee -a /etc/ssh/sshd_config >/dev/null
    echo "ClientAliveCountMax ${TARGET_COUNT}" | sudo tee -a /etc/ssh/sshd_config >/dev/null
else
    echo "Appending ClientAlive settings (idle timeout ${TARGET_INTERVAL}s, count ${TARGET_COUNT})"
    sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak.$(date +%s)
    echo "\n# Enforce server-side keepalive for idle sessions" | sudo tee -a /etc/ssh/sshd_config >/dev/null
    echo "ClientAliveInterval ${TARGET_INTERVAL}" | sudo tee -a /etc/ssh/sshd_config >/dev/null
    echo "ClientAliveCountMax ${TARGET_COUNT}" | sudo tee -a /etc/ssh/sshd_config >/dev/null
fi

# Restart SSH service with check for service name
if systemctl list-units --full -all | grep -Fq "sshd.service"; then
    echo "Restarting sshd.service..."
    sudo systemctl restart sshd
elif systemctl list-units --full -all | grep -Fq "ssh.service"; then
    echo "Restarting ssh.service..."
    sudo systemctl restart ssh
else
    echo "⚠️ Could not find SSH service to restart, please restart it manually"
fi

# Create a shell-side watchdog that disconnects idle interactive SSH sessions
WATCHDOG_PATH="/etc/profile.d/ssh_idle_disconnect.sh"
if [ ! -f "$WATCHDOG_PATH" ]; then
    echo "Creating per-session SSH idle-disconnect watchdog at $WATCHDOG_PATH"
    sudo tee "$WATCHDOG_PATH" > /dev/null <<'EOF'
#!/bin/bash
# /etc/profile.d/ssh_idle_disconnect.sh
# This script starts a per-session watchdog for interactive SSH sessions that
# disconnects the session after IDLE_TIMEOUT seconds of inactivity only if
# there are no background jobs running in that shell.

# Only apply to interactive shells over SSH with a TTY
if [[ -n "$SSH_TTY" && $- == *i* ]]; then
    IDLE_TIMEOUT=${IDLE_TIMEOUT:-300}  # seconds (5 minutes default)

    # Track last activity timestamp (updated before each command)
    SSH_IDLE_LAST_ACTIVITY=$(date +%s)
    export SSH_IDLE_LAST_ACTIVITY
    trap 'SSH_IDLE_LAST_ACTIVITY=$(date +%s)' DEBUG

    # Start a background watchdog (only once per session)
    if [ -z "$SSH_IDLE_WATCHDOG_STARTED" ]; then
        export SSH_IDLE_WATCHDOG_STARTED=1
        shell_pid=$$
        (
            while true; do
                sleep 5
                now=$(date +%s)
                idle=$((now - SSH_IDLE_LAST_ACTIVITY))
                if [ "$idle" -ge "$IDLE_TIMEOUT" ]; then
                    # If there are no jobs, disconnect the session for security
                    if [ -z "$(jobs -p 2>/dev/null)" ]; then
                        # Inform the user and terminate the shell
                        if [ -n "$SSH_TTY" ]; then
                            printf "\nSession idle for $IDLE_TIMEOUT seconds and no background jobs: disconnecting for security.\n" > "$SSH_TTY"
                        fi
                        # Kill the parent shell (login shell) to terminate the session
                        kill -HUP "$shell_pid" 2>/dev/null || kill -9 "$shell_pid" 2>/dev/null
                        exit 0
                    else
                        # There are background jobs; reset the timer and continue
                        SSH_IDLE_LAST_ACTIVITY=$(date +%s)
                        export SSH_IDLE_LAST_ACTIVITY
                    fi
                fi
            done
        ) &
    fi
fi
EOF
    sudo chmod 644 "$WATCHDOG_PATH"
    echo "Watchdog created. It will apply to new interactive SSH sessions (login/logout may be required)."
else
    echo "Watchdog already present at $WATCHDOG_PATH"
fi

echo '✨ SSH idle-disconnect configured (server-side + per-session watchdog).'
