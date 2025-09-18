#!/bin/bash

set -e

echo "Setting up local DuckDB MySQL Extension development environment..."

# Check if we're on a supported platform
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    PLATFORM="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    PLATFORM="macos"
else
    echo "Unsupported platform: $OSTYPE"
    echo "This script supports Linux and macOS."
    echo "For other platforms, please install dependencies manually."
    exit 1
fi

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

echo "Detected platform: $PLATFORM"

# Install dependencies based on platform
if [[ "$PLATFORM" == "linux" ]]; then
    echo "Installing Linux dependencies..."
    
    # Check if apt is available
    if command_exists apt-get; then
        sudo apt-get update
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
            git
    else
        echo "apt-get not found. Please install dependencies manually:"
        echo "ninja-build cmake build-essential make ccache curl zip unzip tar pkg-config autoconf autoconf-archive git"
        exit 1
    fi

elif [[ "$PLATFORM" == "macos" ]]; then
    echo "Installing macOS dependencies..."
    
    # Check if brew is available
    if command_exists brew; then
        brew install \
            pkg-config \
            ninja \
            automake \
            autoconf \
            autoconf-archive \
            libevent
    else
        echo "Homebrew not found. Please install Homebrew first:"
        echo "/bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        exit 1
    fi
fi

# Check if cmake is installed
if ! command_exists cmake; then
    echo "CMake not found. Please install CMake."
    exit 1
fi

# Set up vcpkg if not already present
if [ ! -d "vcpkg" ]; then
    echo "Installing vcpkg..."
    git clone https://github.com/Microsoft/vcpkg.git
    cd vcpkg
    if [[ "$PLATFORM" == "linux" ]]; then
        ./bootstrap-vcpkg.sh
    elif [[ "$PLATFORM" == "macos" ]]; then
        ./bootstrap-vcpkg.sh
    fi
    cd ..
else
    echo "vcpkg already exists, updating..."
    cd vcpkg
    git pull
    cd ..
fi

# Set environment variables
export VCPKG_TOOLCHAIN_PATH="$(pwd)/vcpkg/scripts/buildsystems/vcpkg.cmake"

# Add to shell profile if not already there
SHELL_PROFILE=""
if [[ -f "$HOME/.bashrc" ]]; then
    SHELL_PROFILE="$HOME/.bashrc"
elif [[ -f "$HOME/.zshrc" ]]; then
    SHELL_PROFILE="$HOME/.zshrc"
elif [[ -f "$HOME/.profile" ]]; then
    SHELL_PROFILE="$HOME/.profile"
fi

if [[ -n "$SHELL_PROFILE" ]]; then
    if ! grep -q "VCPKG_TOOLCHAIN_PATH" "$SHELL_PROFILE"; then
        echo "" >> "$SHELL_PROFILE"
        echo "# DuckDB MySQL Extension vcpkg configuration" >> "$SHELL_PROFILE"
        echo "export VCPKG_TOOLCHAIN_PATH=\"$(pwd)/vcpkg/scripts/buildsystems/vcpkg.cmake\"" >> "$SHELL_PROFILE"
        echo "Added VCPKG_TOOLCHAIN_PATH to $SHELL_PROFILE"
    fi
fi

# Initialize git submodules
echo "Initializing git submodules..."
git submodule update --init --recursive

echo ""
echo "Development environment setup complete!"
echo ""
echo "To build the extension:"
echo "  make"
echo ""
echo "To run tests:"
echo "  make test"
echo ""
echo "Note: For testing, you may need to install and configure MySQL separately."
echo "Set MYSQL_TEST_DATABASE_AVAILABLE=1 to enable tests that require MySQL." 