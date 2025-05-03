#!/bin/bash
# build_windows.sh - Build script for creating Windows-compatible VST3 plugins using MinGW cross-compiler
# 
# This script builds the VolumeControlPlugin for Windows using MinGW-w64 cross-compilation from WSL or Linux

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

# Check MinGW prerequisites
check_prerequisites() {
    info "Checking prerequisites for Windows cross-compilation..."
    
    # Check if MinGW compiler is installed
    if ! command -v x86_64-w64-mingw32-gcc &> /dev/null; then
        error "MinGW-w64 cross-compiler not found. Please install it using:"
        echo "sudo apt-get install mingw-w64"
        exit 1
    fi
    
    # Check if CMake is installed
    if ! command -v cmake &> /dev/null; then
        error "CMake not found. Please install it using:"
        echo "sudo apt-get install cmake"
        exit 1
    fi
    
    # Check CMake version
    local cmake_version=$(cmake --version | grep -oP "(?<=version )[0-9]+\.[0-9]+")
    local cmake_major=$(echo $cmake_version | cut -d. -f1)
    local cmake_minor=$(echo $cmake_version | cut -d. -f2)
    
    if [ "$cmake_major" -lt 3 ] || ([ "$cmake_major" -eq 3 ] && [ "$cmake_minor" -lt 15 ]); then
        error "CMake version 3.15 or higher is required. Found version $cmake_version."
        exit 1
    fi
    
    info "Using CMake version $cmake_version"
    success "All prerequisites satisfied!"
}

# Create build directory
create_build_directory() {
    info "Creating Windows build directory..."
    
    if [ ! -d "build_windows" ]; then
        mkdir -p build_windows
        success "Windows build directory created."
    else
        info "Windows build directory already exists."
    fi
}

# Run CMake configuration
run_cmake_config() {
    info "Running CMake to configure the Windows project..."
    
    cd build_windows
    
    if cmake -DCMAKE_TOOLCHAIN_FILE=../mingw-w64-toolchain.cmake -DCMAKE_BUILD_TYPE=Release ..; then
        success "CMake configuration completed successfully."
    else
        error "CMake configuration failed."
        exit 1
    fi
    
    cd ..
}

# Build the plugin
build_plugin() {
    info "Building the Windows plugin..."
    
    info "Building with $(nproc) parallel jobs"
    
    cd build_windows
    
    if cmake --build . --config Release --parallel $(nproc); then
        success "Build completed successfully."
    else
        error "Build failed."
        exit 1
    fi
    
    cd ..
}

# Display build results
display_results() {
    info "Windows VST3 plugin build completed."
    
    # Find VST3 path
    local vst3_path=$(find build_windows -name "*.vst3" -type d | head -n 1)
    
    if [ -n "$vst3_path" ]; then
        success "Windows VST3 plugin built successfully at:"
        echo "$vst3_path"
        
        # Further instructions for use in Windows
        echo ""
        info "To use this plugin in FL Studio on Windows:"
        echo "1. Copy the entire .vst3 folder to your Windows VST3 directory"
        echo "   (typically C:\\Program Files\\Common Files\\VST3)"
        echo "2. Open FL Studio and scan for new plugins"
    else
        warning "Could not find built VST3 plugin. Check the build output for errors."
    fi
}

# Main build process
main() {
    echo -e "${BLUE}=============================================${NC}"
    echo -e "${BLUE}  VolumeControlPlugin Windows Build Script   ${NC}"
    echo -e "${BLUE}=============================================${NC}"
    
    check_prerequisites
    create_build_directory
    run_cmake_config
    build_plugin
    display_results
    
    echo -e "\n${GREEN}Build process completed.${NC}"
}

# Run the main function
main