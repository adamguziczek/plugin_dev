#!/bin/bash
# setup_scripts.sh - Setup script for JUCE plugin build scripts
# 
# This script makes the build scripts executable and installs required dependencies.
# Run this script after cloning the repository.

# Set up colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print a message with a colored prefix
info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running in WSL (Windows Subsystem for Linux)
is_wsl() {
    if grep -q Microsoft /proc/version; then
        return 0
    else
        return 1
    fi
}

# Install dependencies for Debian/Ubuntu-based systems
install_dependencies_debian() {
    info "Installing dependencies for Debian/Ubuntu-based system..."
    
    # Required dependencies based on CMake output
    DEPS=(
        "build-essential"
        "cmake"
        "pkg-config"
        "libgtk-3-dev"          # gtk+-3.0
        "libwebkit2gtk-4.1-dev" # webkit2gtk-4.1
        "libasound2-dev"        # alsa
        "libfreetype6-dev"      # freetype2
        "libfontconfig1-dev"    # fontconfig
        "libgl1-mesa-dev"       # gl
        "libcurl4-openssl-dev"  # libcurl (critical for network operations)
        "libx11-dev"            # X11 for JUCE GUI apps
    )
    
    # Check if any dependencies are already installed
    info "Checking which dependencies need to be installed..."
    DEPS_TO_INSTALL=()
    
    for dep in "${DEPS[@]}"; do
        if dpkg -l | grep -q "^ii  $dep "; then
            success "$dep is already installed."
        else
            DEPS_TO_INSTALL+=("$dep")
        fi
    done
    
    # If all dependencies are already installed
    if [ ${#DEPS_TO_INSTALL[@]} -eq 0 ]; then
        success "All dependencies are already installed!"
        return 0
    fi
    
    # Install missing dependencies
    info "Installing missing dependencies: ${DEPS_TO_INSTALL[*]}"
    
    # Ask for confirmation before proceeding with installation
    echo -e "${YELLOW}This will require sudo access to install packages.${NC}"
    read -p "Do you want to continue? (y/n): " confirm
    
    if [[ $confirm != [yY]* ]]; then
        warning "Dependency installation cancelled by user."
        echo "You'll need to install the following dependencies manually:"
        for dep in "${DEPS_TO_INSTALL[@]}"; do
            echo "  - $dep"
        done
        return 1
    fi
    
    # Install dependencies
    if sudo apt-get update && sudo apt-get install -y "${DEPS_TO_INSTALL[@]}"; then
        success "All dependencies installed successfully!"
    else
        error "Failed to install one or more dependencies."
        echo "Please try installing them manually using:"
        echo "sudo apt-get install ${DEPS_TO_INSTALL[*]}"
        return 1
    fi
    
    return 0
}

# Install dependencies for other Linux distributions
install_dependencies_other() {
    warning "Automatic dependency installation is only supported for Debian/Ubuntu-based systems."
    echo "Please install the following dependencies manually using your distribution's package manager:"
    echo "  - cmake"
    echo "  - pkg-config"
    echo "  - GTK3 development libraries (gtk+-3.0)"
    echo "  - WebKit2GTK development libraries (webkit2gtk-4.1)"
    echo "  - ALSA development libraries"
    echo "  - FreeType2 development libraries"
    echo "  - Fontconfig development libraries"
    echo "  - OpenGL development libraries"
    echo "  - libcurl development libraries"
    echo "  - X11 development libraries"
    
    return 1
}

# Install all required dependencies
install_dependencies() {
    echo -e "${BLUE}=======================================${NC}"
    echo -e "${BLUE}  Installing Required Dependencies    ${NC}"
    echo -e "${BLUE}=======================================${NC}"
    
    if is_wsl; then
        info "Detected WSL (Windows Subsystem for Linux) environment."
        echo "Note: Building audio plugins in WSL may have limitations."
        echo "      The plugins will be built for Linux, not Windows."
    fi
    
    # Check if this is a Debian/Ubuntu-based system
    if [ -f /etc/debian_version ]; then
        install_dependencies_debian
    else
        install_dependencies_other
    fi
    
    # Verify and warn about critical dependencies (especially libcurl)
    if dpkg -l | grep -q "^ii  libcurl4-openssl-dev "; then
        success "libcurl development libraries are installed."
    else
        warning "libcurl development libraries are NOT installed. This is critical for building the plugin."
        echo "Without libcurl properly installed and linked, you will encounter linker errors."
        echo "The CMakeLists.txt has been configured to properly link libcurl, but the package must be installed."
    fi
    
    # Explanation for WSL users
    if is_wsl; then
        echo -e "\n${YELLOW}[WSL NOTE]${NC} When building JUCE applications in WSL, you may encounter issues with"
        echo "library paths for GTK, WebKit2GTK, and libcurl. The CMakeLists.txt for this project"
        echo "includes explicit include and link directory configurations to address this."
        echo "If you encounter build errors related to missing headers or libraries, you"
        echo "may need to modify the paths in CMakeLists.txt to match your system."
        echo -e "\nTo diagnose path issues, you can run:"
        echo "pkg-config --cflags --libs libcurl"
        echo "pkg-config --cflags --libs gtk+-3.0"
        echo "pkg-config --cflags --libs webkit2gtk-4.1"
    fi
}

# Make build scripts executable
make_scripts_executable() {
    info "Making build scripts executable..."
    
    # List of scripts to make executable
    SCRIPTS=("build.sh" "clean.sh" "setup_scripts.sh")
    
    for script in "${SCRIPTS[@]}"; do
        if [ -f "$script" ]; then
            if chmod +x "$script"; then
                success "Made $script executable."
            else
                error "Failed to make $script executable."
                exit 1
            fi
        else
            warning "Script $script not found."
        fi
    done
}

# Main function
main() {
    echo -e "${BLUE}=======================================${NC}"
    echo -e "${BLUE}  JUCE Plugin Setup Script    ${NC}"
    echo -e "${BLUE}=======================================${NC}"
    
    # Make scripts executable
    make_scripts_executable
    
    # Ask if user wants to install dependencies
    echo -e "\nWould you like to install/check required dependencies for building the plugin?"
    read -p "This is recommended for first-time setup [Y/n]: " install_deps
    
    if [[ $install_deps != [nN]* ]]; then
        install_dependencies
    else
        info "Skipping dependency installation."
        echo "You can run this script again later if you encounter missing dependencies."
    fi
    
    echo -e "\n${GREEN}Setup completed!${NC}"
    echo -e "You can now run:"
    echo "  - ./build.sh to build the Linux plugin"
    echo ""
}

# Run the main function
main