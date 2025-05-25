#!/bin/bash

set -e

echo "Setting up DuckDB MySQL Extension development environment..."

# Save the workspace directory for later use
WORKSPACE_DIR="$(pwd)"

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

# Install additional development tools
echo "Installing additional development tools..."
sudo apt-get install -y \
    gdb \
    valgrind \
    clang-format \
    clang-tidy \
    doxygen

# Install vcpkg - improved detection logic
echo "Setting up vcpkg..."
VCPKG_DIR="/usr/local/share/vcpkg"

# Check if vcpkg is properly installed (directory exists AND has git repo AND has vcpkg executable)
if [ -d "$VCPKG_DIR" ] && [ -d "$VCPKG_DIR/.git" ] && [ -f "$VCPKG_DIR/vcpkg" ]; then
    echo "vcpkg already installed, updating..."
    cd "$VCPKG_DIR"
    if git pull; then
        echo "vcpkg updated successfully"
    else
        echo "Warning: Failed to update vcpkg, but continuing with existing installation"
    fi
else
    echo "Installing vcpkg..."
    # Remove any existing directory that might be incomplete
    sudo rm -rf "$VCPKG_DIR"
    
    # Clone vcpkg
    sudo git clone https://github.com/Microsoft/vcpkg.git "$VCPKG_DIR"
    sudo chown -R vscode:vscode "$VCPKG_DIR"
    
    # Bootstrap vcpkg
    cd "$VCPKG_DIR"
    ./bootstrap-vcpkg.sh
    
    # Make vcpkg available globally
    echo 'export VCPKG_ROOT=/usr/local/share/vcpkg' >> ~/.bashrc
    echo 'export VCPKG_TOOLCHAIN_PATH=/usr/local/share/vcpkg/scripts/buildsystems/vcpkg.cmake' >> ~/.bashrc
    echo 'export PATH=$VCPKG_ROOT:$PATH' >> ~/.bashrc
    
    echo "vcpkg installed successfully"
fi

# Return to workspace directory
cd "$WORKSPACE_DIR"

# Set up environment variables for current session
export VCPKG_ROOT=/usr/local/share/vcpkg
export VCPKG_TOOLCHAIN_PATH=/usr/local/share/vcpkg/scripts/buildsystems/vcpkg.cmake
export PATH=$VCPKG_ROOT:$PATH

# Set up MySQL (using absolute path to script)
echo "Setting up MySQL..."
bash "$WORKSPACE_DIR/.devcontainer/setup-mysql.sh"

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
echo "MySQL server should be running on localhost:3306"
echo "Root user has no password (development setup)" 