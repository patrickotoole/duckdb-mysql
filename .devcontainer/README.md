# DuckDB MySQL Extension - Development Container

This directory contains the GitHub Codespaces / Dev Container configuration for developing the DuckDB MySQL extension.

## What's Included

The dev container provides a complete development environment with:

### Build Tools
- **CMake** - Build system generator
- **Ninja** - Fast build tool
- **Make** - Traditional build tool
- **GCC/G++** - C++ compiler toolchain
- **ccache** - Compiler cache for faster builds

### Dependencies
- **vcpkg** - C++ package manager (installed globally)
- **MySQL Server** - Local MySQL instance for testing
- **MySQL Client Libraries** - Development headers and libraries
- **Git** - Version control with submodule support

### Development Tools
- **GDB** - Debugger
- **Valgrind** - Memory debugging and profiling
- **clang-format** - Code formatter
- **clang-tidy** - Static analysis tool
- **GitHub CLI** - Command-line interface for GitHub

### VS Code Extensions
- C/C++ IntelliSense and debugging
- CMake Tools
- Makefile Tools
- GitHub Actions support

## Quick Start

1. **Open in GitHub Codespaces**: Click the "Code" button in the GitHub repository and select "Create codespace on main"

2. **Wait for setup**: The container will automatically install dependencies and configure the environment (this takes a few minutes on first run)

3. **Build the extension**:
   ```bash
   make
   ```

4. **Run tests**:
   ```bash
   make test
   ```

## Environment Variables

The following environment variables are pre-configured:

- `VCPKG_ROOT=/usr/local/share/vcpkg`
- `VCPKG_TOOLCHAIN_PATH=/usr/local/share/vcpkg/scripts/buildsystems/vcpkg.cmake`
- `MYSQL_TEST_DATABASE_AVAILABLE=1`
- `MYSQL_HOST=localhost`
- `MYSQL_USER=root`
- `MYSQL_PWD=""` (empty password for development)
- `MYSQL_DATABASE=mysqlscanner`

## MySQL Configuration

The MySQL server is automatically:
- Installed and configured
- Started on container creation
- Set up with a root user (no password for development convenience)
- Configured with test databases: `mysqlscanner` and `mysql`
- Available on port 3306 (forwarded from the container)

**MySQL Setup Script**: The container includes a separate `setup-mysql.sh` script that handles MySQL configuration robustly for container environments.

## Volume Mounts

A named volume `duckdb-mysql-vcpkg-cache` is mounted at `/usr/local/share/vcpkg` to persist vcpkg packages across container rebuilds, significantly speeding up subsequent container creation.

## Customization

To modify the development environment:

1. **Add dependencies**: Edit `.devcontainer/setup.sh`
2. **Change VS Code settings**: Edit `.devcontainer/devcontainer.json` under `customizations.vscode.settings`
3. **Add VS Code extensions**: Edit the `extensions` array in `devcontainer.json`

## Troubleshooting

### Container setup fails
- Check the output logs for specific error messages
- If MySQL setup fails, try running the MySQL setup manually: `bash .devcontainer/setup-mysql.sh`
- Try rebuilding the container: Command Palette → "Dev Containers: Rebuild Container"

### Container fails to start
- Check that Docker has sufficient resources allocated
- Try rebuilding the container: Command Palette → "Dev Containers: Rebuild Container"

### Build failures
- Ensure git submodules are initialized: `git submodule update --init --recursive`
- Try cleaning the build: `make clean` then `make`

### MySQL connection issues
- Check if MySQL is running: `sudo service mysql status`
- Restart MySQL: `sudo service mysql restart`
- Run the MySQL setup script manually: `bash .devcontainer/setup-mysql.sh`
- Verify databases exist: `mysql -u root -e "SHOW DATABASES;"`

### systemd/systemctl errors in container
- This is normal in container environments. The scripts use `service` commands instead
- If you see systemd warnings, they can be safely ignored

### vcpkg issues
- Check vcpkg installation: `vcpkg version`
- Re-bootstrap vcpkg: `cd $VCPKG_ROOT && ./bootstrap-vcpkg.sh`

## Manual MySQL Setup

If MySQL setup fails during container creation, you can run it manually:

```bash
# Run the MySQL setup script
bash .devcontainer/setup-mysql.sh

# Or manually start MySQL and configure it
sudo service mysql start
mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '';"
mysql -u root -e "FLUSH PRIVILEGES;"
mysql -u root -e "CREATE DATABASE IF NOT EXISTS mysqlscanner;"
```

## Performance Tips

- Use the volume mount for vcpkg to avoid reinstalling packages
- Consider using `ccache` for faster compilation (already installed)
- Use `ninja` instead of `make` for parallel builds: `cmake --build build --parallel` 