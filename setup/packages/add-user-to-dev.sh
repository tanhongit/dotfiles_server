#!/bin/bash

# Add user(s) to developers group for NVM/NPM/Yarn access

echo "================================"
echo "Add Users to Developers Group"
echo "================================"
echo ""

# Create developers group if it doesn't exist
if ! getent group developers > /dev/null 2>&1; then
    echo "Creating 'developers' group..."
    sudo groupadd developers
    echo "✓ Group 'developers' created"
fi

# Function to add user to developers group
add_user_to_group() {
    local username="$1"

    # Check if user exists
    if ! id "$username" &>/dev/null; then
        echo "❌ Error: User '$username' does not exist"
        return 1
    fi

    # Check if user is already in developers group
    if groups "$username" | grep -q "\bdevelopers\b"; then
        echo "✓ User '$username' is already in developers group"
        return 0
    fi

    # Add user to developers group
    echo "→ Adding user '$username' to developers group..."
    sudo usermod -aG developers "$username"
    echo "✓ User '$username' added to developers group"

    return 0
}

# If no arguments, show usage
if [ $# -eq 0 ]; then
    echo "Usage: $0 <username> [username2] [username3] ..."
    echo "   or: $0 --all    (add all non-system users)"
    echo ""
    echo "Examples:"
    echo "  $0 john"
    echo "  $0 john mary bob"
    echo "  $0 --all"
    echo ""
    exit 1
fi

# Handle --all flag
if [ "$1" = "--all" ] || [ "$1" = "-a" ]; then
    echo "Adding all non-system users to developers group..."
    echo ""

    added_count=0
    while IFS=: read -r username _ uid _ _ home shell; do
        # Skip if UID < 1000 (system users) or if home doesn't exist
        if [ "$uid" -ge 1000 ] && [ -d "$home" ]; then
            if add_user_to_group "$username"; then
                ((added_count++))
            fi
        fi
    done < /etc/passwd

    echo ""
    echo "✓ Processed $added_count user(s)"
else
    # Add specified users
    success_count=0
    fail_count=0

    for username in "$@"; do
        if add_user_to_group "$username"; then
            ((success_count++))
        else
            ((fail_count++))
        fi
    done

    echo ""
    echo "✓ Successfully added $success_count user(s)"
    [ $fail_count -gt 0 ] && echo "❌ Failed to add $fail_count user(s)"
fi

echo ""
echo "================================"
echo "📌 Important Notes:"
echo "================================"
echo ""
echo "Users must logout and login again (or run 'newgrp developers')"
echo "to apply the new group membership."
echo ""
echo "After that, they can:"
echo "  • Install Node.js versions: nvm install 22"
echo "  • Install npm packages globally: npm install -g <package>"
echo "  • Install yarn packages globally: yarn global add <package>"
echo ""

