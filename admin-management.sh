#!/bin/bash

# Complete Admin Account Management Script

echo "=== TGP Dues Management System - Admin Account Manager ==="
echo ""

show_menu() {
    echo "Select an option:"
    echo "1. Add new admin account"
    echo "2. List all admin accounts"
    echo "3. Change admin password"
    echo "4. Remove admin account"
    echo "5. Show current admin accounts"
    echo "6. Exit"
    echo ""
    read -p "Enter choice [1-6]: " choice
}

add_admin() {
    echo ""
    echo "=== Add New Admin Account ==="
    read -p "Username: " username
    read -s -p "Password: " password
    echo ""
    read -p "Full Name: " name
    read -p "Position (e.g., President, Secretary, Treasurer): " position
    
    if [ -z "$username" ] || [ -z "$password" ]; then
        echo "Username and password are required"
        return
    fi
    
    # Add to database
    PGPASSWORD=rahugan2018 psql -U rahuganmkc -d tgp_dues_db -h localhost << EOF
INSERT INTO users (username, name, password, position, account_type) 
VALUES ('$username', '${name:-$username}', '$password', '${position:-Administrator}', 'admin')
ON CONFLICT (username) DO UPDATE SET
    name = EXCLUDED.name,
    password = EXCLUDED.password,
    position = EXCLUDED.position,
    account_type = EXCLUDED.account_type;
EOF
    
    if [ $? -eq 0 ]; then
        echo "✓ Admin account '$username' added successfully"
    else
        echo "✗ Failed to add admin account"
    fi
}

list_admins() {
    echo ""
    echo "=== Current Admin Accounts ==="
    PGPASSWORD=rahugan2018 psql -U rahuganmkc -d tgp_dues_db -h localhost -c "
    SELECT id, username, name, position, account_type 
    FROM users 
    WHERE account_type = 'admin' 
    ORDER BY id;"
}

change_password() {
    echo ""
    echo "=== Change Admin Password ==="
    read -p "Username: " username
    read -s -p "New Password: " password
    echo ""
    
    if [ -z "$username" ] || [ -z "$password" ]; then
        echo "Username and password are required"
        return
    fi
    
    PGPASSWORD=rahugan2018 psql -U rahuganmkc -d tgp_dues_db -h localhost << EOF
UPDATE users 
SET password = '$password' 
WHERE username = '$username' AND account_type = 'admin';
EOF
    
    if [ $? -eq 0 ]; then
        echo "✓ Password updated for '$username'"
    else
        echo "✗ Failed to update password"
    fi
}

remove_admin() {
    echo ""
    echo "=== Remove Admin Account ==="
    read -p "Username to remove: " username
    read -p "Are you sure you want to remove '$username'? (yes/no): " confirm
    
    if [ "$confirm" = "yes" ]; then
        PGPASSWORD=rahugan2018 psql -U rahuganmkc -d tgp_dues_db -h localhost << EOF
DELETE FROM users 
WHERE username = '$username' AND account_type = 'admin';
EOF
        
        if [ $? -eq 0 ]; then
            echo "✓ Admin account '$username' removed"
        else
            echo "✗ Failed to remove admin account"
        fi
    else
        echo "Operation cancelled"
    fi
}

# Main script loop
while true; do
    show_menu
    
    case $choice in
        1)
            add_admin
            ;;
        2)
            list_admins
            ;;
        3)
            change_password
            ;;
        4)
            remove_admin
            ;;
        5)
            list_admins
            ;;
        6)
            echo "Goodbye!"
            exit 0
            ;;
        *)
            echo "Invalid option. Please try again."
            ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
    echo ""
done