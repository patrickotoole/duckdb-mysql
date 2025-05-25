#!/bin/bash

set -e

echo "Setting up DuckDB MySQL Extension development environment..."

# Update package list
sudo apt-get update

# Install build dependencies
echo "Installing build dependencies..."
sudo apt-get install -y \
    ninja-build \
    cmake \
    build-essential \
    make \
    ccache \
    curl \
    zip \
    unzip \
    tar \
    pkg-config \
    autoconf \
    autoconf-archive \
    automake \
    libtool \
    git \
    wget

# Install MySQL server and client development libraries
echo "Installing MySQL server and development libraries..."
sudo apt-get install -y \
    mysql-server \
    mysql-client \
    libmysqlclient-dev \
    default-libmysqlclient-dev

# Configure MySQL for development/testing
echo "Configuring MySQL..."
sudo systemctl enable mysql
sudo systemctl start mysql

# Set up MySQL with no password for root (development environment)
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '';"
sudo mysql -e "FLUSH PRIVILEGES;"

# Create test database
sudo mysql -e "CREATE DATABASE IF NOT EXISTS mysqlscanner;"
sudo mysql -e "CREATE DATABASE IF NOT EXISTS mysql;"

# Install vcpkg if not already present
if [ ! -d "/usr/local/share/vcpkg" ]; then
    echo "Installing vcpkg..."
    sudo git clone https://github.com/Microsoft/vcpkg.git /usr/local/share/vcpkg
    sudo chown -R vscode:vscode /usr/local/share/vcpkg
    cd /usr/local/share/vcpkg
    ./bootstrap-vcpkg.sh
    
    # Make vcpkg available globally
    echo 'export VCPKG_ROOT=/usr/local/share/vcpkg' >> ~/.bashrc
    echo 'export VCPKG_TOOLCHAIN_PATH=/usr/local/share/vcpkg/scripts/buildsystems/vcpkg.cmake' >> ~/.bashrc
    echo 'export PATH=$VCPKG_ROOT:$PATH' >> ~/.bashrc
else
    echo "vcpkg already installed, updating..."
    cd /usr/local/share/vcpkg
    git pull
fi

# Set up environment variables for current session
export VCPKG_ROOT=/usr/local/share/vcpkg
export VCPKG_TOOLCHAIN_PATH=/usr/local/share/vcpkg/scripts/buildsystems/vcpkg.cmake
export PATH=$VCPKG_ROOT:$PATH

# Install additional development tools
echo "Installing additional development tools..."
sudo apt-get install -y \
    gdb \
    valgrind \
    clang-format \
    clang-tidy \
    doxygen

# Clean up
sudo apt-get autoremove -y
sudo apt-get autoclean

echo "Development environment setup complete!"
echo ""
echo "To build the extension, run:"
echo "  make"
echo ""
echo "To run tests, run:"
echo "  make test"
echo ""
echo "MySQL server is running on localhost:3306"
echo "Root user has no password (development setup)" 