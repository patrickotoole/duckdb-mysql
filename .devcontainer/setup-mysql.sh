#!/bin/bash

set -e

echo "Setting up MySQL for development..."

# Function to wait for MySQL to be ready
wait_for_mysql() {
    echo "Waiting for MySQL to be ready..."
    for i in {1..30}; do
        if mysqladmin ping -h localhost --silent; then
            echo "MySQL is ready!"
            return 0
        fi
        echo "Waiting for MySQL... (attempt $i/30)"
        sleep 2
    done
    echo "MySQL failed to become ready after 60 seconds"
    return 1
}

# Start MySQL service
echo "Starting MySQL service..."
if sudo service mysql start; then
    echo "MySQL service started successfully"
elif sudo service mysql restart; then
    echo "MySQL service restarted successfully"
else
    echo "Failed to start MySQL service, trying manual startup..."
    sudo mysqld_safe --user=mysql --datadir=/var/lib/mysql &
    sleep 5
fi

# Wait for MySQL to be ready
if ! wait_for_mysql; then
    echo "Error: MySQL is not responding"
    exit 1
fi

# Configure MySQL
echo "Configuring MySQL for development..."

# Try to connect and configure
if mysql -u root -e "SELECT 1;" 2>/dev/null; then
    echo "MySQL root access already available"
else
    echo "Configuring MySQL root user..."
    # Try different approaches to set up root access
    sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '';" 2>/dev/null || \
    sudo mysql -e "UPDATE mysql.user SET authentication_string='' WHERE User='root'; FLUSH PRIVILEGES;" 2>/dev/null || \
    echo "Note: MySQL root configuration may need manual setup"
fi

# Ensure root can connect without password
mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '';" 2>/dev/null || true
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
fi

echo "MySQL setup complete!" 