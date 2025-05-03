#!/bin/bash
# setup_scripts.sh - Setup script for VolumeControlPlugin build scripts
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
    
    # Windows cross-compilation dependencies (optional)
    WINDOWS_DEPS=(
        "mingw-w64"             # MinGW-w64 cross-compiler for building Windows plugins
        "binutils-mingw-w64"    # Binutils for MinGW
        "g++-mingw-w64"         # G++ for MinGW
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

# Check for WSL in multiple ways to improve detection reliability
check_wsl() {
    # Method 1: Check /proc/version for Microsoft
    if grep -q Microsoft /proc/version; then
        return 0
    fi
    
    # Method 2: Check for WSL environment variable
    if [[ -n "$WSL_DISTRO_NAME" ]]; then
        return 0
    fi
    
    # Method 3: Check for Windows mounts
    if [ -d "/mnt/c" ] && [ -d "/mnt/c/Windows" ]; then
        return 0
    fi
    
    # Not in WSL
    return 1
}

# Set up MSVC cross-compilation environment
setup_msvc_cross_compilation() {
    info "Setting up Windows MSVC cross-compilation environment..."
    
    # Check if we're in WSL using the improved detection
    if ! check_wsl; then
        error "MSVC cross-compilation requires Windows Subsystem for Linux (WSL)."
        echo "This approach only works when running in WSL with Visual Studio installed on Windows."
        echo ""
        warning "You appear to not be running in WSL. Please try running this script from a WSL terminal."
        echo "If you're using VS Code, try opening a WSL terminal outside of VS Code and run this script."
        echo "You can open a WSL terminal by:"
        echo "1. Open Windows Command Prompt or PowerShell"
        echo "2. Type 'wsl' and press Enter"
        echo "3. Navigate to this directory and run the script again"
        return 1
    fi
    
    # Check if we can access Windows drives
    if [ ! -d "/mnt/c" ]; then
        error "Cannot access Windows drives (/mnt/c)."
        echo "Make sure you're in WSL with proper access to the Windows file system."
        return 1
    fi
    
    success "WSL environment detected with access to Windows drives."
    
    # Look for possible Visual Studio installations
    info "Looking for Visual Studio installations on Windows..."
    VS_PATHS=(
        "/mnt/c/Program Files/Microsoft Visual Studio/2022/Community/VC/Tools/MSVC"
        "/mnt/c/Program Files/Microsoft Visual Studio/2022/Professional/VC/Tools/MSVC"
        "/mnt/c/Program Files/Microsoft Visual Studio/2022/Enterprise/VC/Tools/MSVC"
        "/mnt/c/Program Files/Microsoft Visual Studio/2019/Community/VC/Tools/MSVC"
        "/mnt/c/Program Files/Microsoft Visual Studio/2019/Professional/VC/Tools/MSVC"
        "/mnt/c/Program Files/Microsoft Visual Studio/2019/Enterprise/VC/Tools/MSVC"
    )
    
    WINDOWS_SDK_PATHS=(
        "/mnt/c/Program Files (x86)/Windows Kits/10"
    )
    
    VS_PATH=""
    VS_VERSION=""
    
    # Find Visual Studio installation
    for path in "${VS_PATHS[@]}"; do
        if [ -d "$path" ]; then
            # Find the highest version
            for version in "$path"/*; do
                if [ -d "$version" ]; then
                    VS_PATH="$path"
                    VS_VERSION=$(basename "$version")
                fi
            done
            if [ -n "$VS_PATH" ]; then
                break
            fi
        fi
    done
    
    # Find Windows SDK
    WINDOWS_SDK_PATH=""
    for path in "${WINDOWS_SDK_PATHS[@]}"; do
        if [ -d "$path" ]; then
            WINDOWS_SDK_PATH="$path"
            break
        fi
    done
    
    # Check if Visual Studio and Windows SDK were found
    if [ -z "$VS_PATH" ] || [ -z "$VS_VERSION" ]; then
        warning "Could not find Visual Studio installation in expected locations."
        echo "You will need to manually set the MSVC_BASE_PATH environment variable."
    else
        success "Found Visual Studio at: $VS_PATH/$VS_VERSION"
    fi
    
    if [ -z "$WINDOWS_SDK_PATH" ]; then
        warning "Could not find Windows SDK in expected locations."
        echo "You will need to manually set the WINDOWS_KITS_BASE_PATH environment variable."
    else
        success "Found Windows SDK at: $WINDOWS_SDK_PATH"
    fi
    
    # Set up environment variables
    echo ""
    info "Setting up MSVC environment variables..."
    
    if [ -n "$VS_PATH" ] && [ -n "$VS_VERSION" ]; then
        MSVC_PATH="$VS_PATH/$VS_VERSION"
        echo "export MSVC_BASE_PATH=\"$MSVC_PATH\"" >> ~/.bashrc
        export MSVC_BASE_PATH="$MSVC_PATH"
        success "Added MSVC_BASE_PATH to ~/.bashrc and current session"
    else
        warning "Please set MSVC_BASE_PATH manually (see instructions in WINDOWS_BUILD_OPTIONS.md)"
    fi
    
    if [ -n "$WINDOWS_SDK_PATH" ]; then
        echo "export WINDOWS_KITS_BASE_PATH=\"$WINDOWS_SDK_PATH\"" >> ~/.bashrc
        export WINDOWS_KITS_BASE_PATH="$WINDOWS_SDK_PATH"
        success "Added WINDOWS_KITS_BASE_PATH to ~/.bashrc and current session"
    else
        warning "Please set WINDOWS_KITS_BASE_PATH manually (see instructions in WINDOWS_BUILD_OPTIONS.md)"
    fi
    
    # Create msvc-toolchain.cmake if it doesn't exist
    if [ ! -f "msvc-toolchain.cmake" ]; then
        warning "msvc-toolchain.cmake not found. Make sure it exists before running build_windows_msvc.sh"
    fi
    
    # Make the build script executable
    chmod +x build_windows_msvc.sh
    success "Made build_windows_msvc.sh executable"
    
    if [ -n "$VS_PATH" ] && [ -n "$VS_VERSION" ] && [ -n "$WINDOWS_SDK_PATH" ]; then
        success "MSVC cross-compilation environment is now set up!"
        echo "You can build Windows VST3 plugins using: ./build_windows_msvc.sh"
    else
        info "Partial MSVC cross-compilation setup completed."
        echo "Review WINDOWS_BUILD_OPTIONS.md for further instructions on setting up MSVC cross-compilation."
    fi
    
    return 0
}

# Make build scripts executable
make_scripts_executable() {
    info "Making build scripts executable..."
    
    # List of scripts to make executable
    SCRIPTS=("build.sh" "build_release.sh" "build_windows_msvc.sh" "clean.sh" "setup_scripts.sh")
    
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
    echo -e "${BLUE}  VolumeControlPlugin Setup Script    ${NC}"
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
    
    # Ask if user wants to set up Windows cross-compilation
    echo -e "\nWould you like to set up MSVC cross-compilation for building Windows VST3 plugins?"
    echo ""
    echo "MSVC Cross-Compilation:"
    echo "   - Uses Microsoft's Visual C++ compiler (officially supported by JUCE)"
    echo "   - Requires Visual Studio installed on Windows"
    echo "   - Only works from WSL with access to Windows"
    echo ""
    echo "For more details, see WINDOWS_BUILD_OPTIONS.md"
    echo ""
    read -p "Would you like to set up MSVC cross-compilation? [y/N]: " setup_windows
    
    if [[ $setup_windows == [yY]* ]]; then
        setup_msvc_cross_compilation
    else
        info "Skipping Windows cross-compilation setup."
        echo "You can run this script again later to set up Windows cross-compilation."
    fi
    
    echo -e "\n${GREEN}Setup completed!${NC}"
    echo -e "You can now run:"
    echo "  - ./build.sh to build the Linux plugin"
    
    
    if [ -n "$MSVC_BASE_PATH" ] && [ -n "$WINDOWS_KITS_BASE_PATH" ]; then
        echo "  - ./build_windows_msvc.sh to build the Windows VST3 plugin using MSVC"
    fi
    
    echo ""
    echo "See WINDOWS_BUILD_OPTIONS.md for more details on Windows build options"
}

# Run the main function
main