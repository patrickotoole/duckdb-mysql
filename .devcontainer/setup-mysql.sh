#!/bin/bash

set -e

echo "Setting up MySQL for development..."

# Function to wait for MySQL to be ready with better error handling
wait_for_mysql() {
    echo "Waiting for MySQL to be ready..."
    local max_attempts=60  # Increased from 30 to 60 attempts (2 minutes)
    
    for i in $(seq 1 $max_attempts); do
        # Try multiple connection methods
        if mysqladmin ping -h localhost --silent 2>/dev/null || \
           mysqladmin ping -h 127.0.0.1 --silent 2>/dev/null || \
           mysql -u root -e "SELECT 1;" 2>/dev/null >/dev/null; then
            echo "MySQL is ready!"
            return 0
        fi
        
        if [ $i -eq 15 ] || [ $i -eq 30 ] || [ $i -eq 45 ]; then
            echo "MySQL still initializing... (attempt $i/$max_attempts)"
            echo "Checking MySQL status and logs..."
            sudo service mysql status || true
            echo "Recent MySQL error log:"
            sudo tail -10 /var/log/mysql/error.log 2>/dev/null || echo "No error log available"
        else
            echo "Waiting for MySQL... (attempt $i/$max_attempts)"
        fi
        
        sleep 2
    done
    
    echo "MySQL failed to become ready after $((max_attempts * 2)) seconds"
    echo "Final MySQL status check:"
    sudo service mysql status || true
    echo "MySQL error log:"
    sudo tail -20 /var/log/mysql/error.log 2>/dev/null || echo "No error log available"
    echo "MySQL process check:"
    ps aux | grep mysql || true
    return 1
}

# Function to initialize MySQL if needed
initialize_mysql() {
    echo "Checking if MySQL needs initialization..."
    
    # Check if MySQL data directory exists and has content
    if [ ! -d "/var/lib/mysql/mysql" ]; then
        echo "MySQL data directory not found, initializing..."
        sudo mysql_install_db --user=mysql --datadir=/var/lib/mysql || true
    fi
}

# Initialize MySQL if needed
initialize_mysql

# Start MySQL service
echo "Starting MySQL service..."
if sudo service mysql start; then
    echo "MySQL service started successfully"
elif sudo service mysql restart; then
    echo "MySQL service restarted successfully"
else
    echo "Failed to start MySQL service with service command, trying mysqld_safe..."
    sudo mysqld_safe --user=mysql --datadir=/var/lib/mysql --skip-grant-tables &
    sleep 10
fi

# Wait for MySQL to be ready
if ! wait_for_mysql; then
    echo "Error: MySQL is not responding"
    echo "Attempting one more restart..."
    sudo service mysql restart || true
    sleep 10
    
    if ! wait_for_mysql; then
        echo "Final attempt failed. MySQL may need manual configuration."
        exit 1
    fi
fi

# Configure MySQL
echo "Configuring MySQL for development..."

# Try to connect and configure with different approaches
configure_mysql() {
    # Method 1: Try connecting as root without password
    if mysql -u root -e "SELECT 1;" 2>/dev/null; then
        echo "MySQL root access already available"
        return 0
    fi
    
    # Method 2: Try using sudo mysql
    if sudo mysql -e "SELECT 1;" 2>/dev/null; then
        echo "Configuring MySQL root user with sudo mysql..."
        sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '';" || true
        sudo mysql -e "FLUSH PRIVILEGES;" || true
        return 0
    fi
    
    # Method 3: Try connecting to socket directly
    if mysql -u root -S /var/run/mysqld/mysqld.sock -e "SELECT 1;" 2>/dev/null; then
        echo "Configuring MySQL root user via socket..."
        mysql -u root -S /var/run/mysqld/mysqld.sock -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '';" || true
        mysql -u root -S /var/run/mysqld/mysqld.sock -e "FLUSH PRIVILEGES;" || true
        return 0
    fi
    
    echo "Note: MySQL root configuration may need manual setup"
    return 1
}

configure_mysql

# Ensure root can connect without password (try multiple times)
for attempt in 1 2 3; do
    mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '';" 2>/dev/null && break
    sleep 1
done

mysql -u root -e "FLUSH PRIVILEGES;" 2>/dev/null || true

# Create test databases
echo "Creating test databases..."
mysql -u root -e "CREATE DATABASE IF NOT EXISTS mysqlscanner;" 2>/dev/null || echo "Warning: Could not create mysqlscanner database"
mysql -u root -e "CREATE DATABASE IF NOT EXISTS mysql;" 2>/dev/null || echo "Note: mysql database already exists"

# Verify setup
echo "Verifying MySQL setup..."
if mysql -u root -e "SHOW DATABASES;" > /dev/null 2>&1; then
    echo "✓ MySQL is working correctly"
    echo "Available databases:"
    mysql -u root -e "SHOW DATABASES;"
else
    echo "⚠ Warning: MySQL may not be fully configured"
    echo "You may need to run: sudo mysql and configure manually"
fi

echo "MySQL setup complete!" 