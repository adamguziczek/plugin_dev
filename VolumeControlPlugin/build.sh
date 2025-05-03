#!/bin/bash
# build.sh - Build script for VolumeControlPlugin
# 
# This script automates the build process for the VolumeControlPlugin.
# It checks prerequisites, creates a build directory, runs CMake,
# and builds the plugin.

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

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
check_prerequisites() {
    info "Checking prerequisites..."
    
    # Check if CMake is installed
    if ! command_exists cmake; then
        error "CMake is not installed. Please install CMake 3.15 or higher."
        exit 1
    fi
    
    # Check CMake version
    CMAKE_VERSION=$(cmake --version | head -n1 | awk '{print $3}')
    CMAKE_MAJOR=$(echo $CMAKE_VERSION | cut -d. -f1)
    CMAKE_MINOR=$(echo $CMAKE_VERSION | cut -d. -f2)
    
    if [ "$CMAKE_MAJOR" -lt 3 ] || ([ "$CMAKE_MAJOR" -eq 3 ] && [ "$CMAKE_MINOR" -lt 15 ]); then
        error "CMake version $CMAKE_VERSION is too old. Please install CMake 3.15 or higher."
        exit 1
    fi
    
    info "Using CMake version $CMAKE_VERSION"
    
    # Check if C++ compiler is installed
    if ! command_exists g++ && ! command_exists clang++; then
        error "No C++ compiler found. Please install g++ or clang++."
        exit 1
    fi
    
    # Check if JUCE directory exists
    if [ ! -d "../JUCE" ]; then
        error "JUCE directory not found. Please make sure the JUCE framework is in the parent directory."
        exit 1
    fi
    
    success "All prerequisites satisfied!"
}

# Create build directory
create_build_dir() {
    info "Creating build directory..."
    
    if [ ! -d "build" ]; then
        mkdir -p build
        success "Build directory created."
    else
        info "Build directory already exists."
    fi
}

# Run CMake to configure the project
run_cmake() {
    info "Running CMake to configure the project..."
    
    cd build || { error "Failed to change to build directory."; exit 1; }
    
    if ! cmake ..; then
        error "CMake configuration failed."
        exit 1
    fi
    
    success "CMake configuration completed successfully."
}

# Build the plugin
build_plugin() {
    info "Building the plugin..."
    
    # Determine the number of CPU cores for parallel build
    if command_exists nproc; then
        # Linux
        CORES=$(nproc)
    elif command_exists sysctl; then
        # macOS
        CORES=$(sysctl -n hw.ncpu)
    else
        # Default to 2 cores
        CORES=2
    fi
    
    info "Building with $CORES parallel jobs"
    
    if ! cmake --build . --parallel $CORES; then
        error "Build failed."
        exit 1
    fi
    
    success "Build completed successfully!"
}

# Show build results
show_results() {
    info "Build results:"
    
    # Find the plugin files
    echo -e "\nPlugin files:"
    find . -name "*.vst3" -o -name "*.component" -o -name "*.app" | while read -r file; do
        echo "  - $file"
    done
    
    echo -e "\nTo use the plugin, copy the appropriate files to your plugin directory."
    echo "For more information, see the README.md file."
}

# Main function
main() {
    echo -e "${BLUE}=======================================${NC}"
    echo -e "${BLUE}  VolumeControlPlugin Build Script    ${NC}"
    echo -e "${BLUE}=======================================${NC}"
    
    check_prerequisites
    create_build_dir
    run_cmake
    build_plugin
    show_results
    
    echo -e "\n${GREEN}Build process completed successfully!${NC}"
}

# Run the main function
main