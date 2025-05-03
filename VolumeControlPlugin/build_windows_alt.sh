#!/bin/bash
# build_windows_alt.sh - Alternative build script for Windows using specialized CMake config
# 
# This script uses Windows-MSVC-WSL.cmake which is specifically designed for
# cross-compiling from WSL to Windows with proper path translation and flag handling

# Set up colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Current script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
ROOT_DIR="${SCRIPT_DIR}"
JUCE_DIR="${ROOT_DIR}/../JUCE"
BUILD_DIR="${ROOT_DIR}/build_windows_alt"

# Create log file with timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="${ROOT_DIR}/build_windows_alt_${TIMESTAMP}.log"

# Initialize log file
touch "$LOG_FILE"
echo "VolumeControlPlugin Windows Alt Build Log (${TIMESTAMP})" > "$LOG_FILE"
echo "====================================================" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

# Log function that outputs to both console and log file
log_output() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

# Print a message with a colored prefix
info() {
    log_output "${BLUE}[INFO]${NC} $1"
}

success() {
    log_output "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    log_output "${YELLOW}[WARNING]${NC} $1"
}

error() {
    log_output "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    info "Checking prerequisites for Windows cross-compilation..."
    
    # Force WSL detection override
    export WSL_DETECTED=1
    info "WSL detection override enabled"
    
    # Check for MSVC_BASE_PATH environment variable
    if [ -z "$MSVC_BASE_PATH" ]; then
        error "MSVC_BASE_PATH environment variable is not set."
        echo "Please run './set_msvc_paths.sh' first, or manually set the environment variables:"
        echo "export MSVC_BASE_PATH=\"/mnt/c/Program Files (x86)/Microsoft Visual Studio/2019/Community/VC/Tools/MSVC/YOUR_VERSION\""
        exit 1
    fi
    
    # Check for WINDOWS_KITS_BASE_PATH environment variable
    if [ -z "$WINDOWS_KITS_BASE_PATH" ]; then
        error "WINDOWS_KITS_BASE_PATH environment variable is not set."
        echo "Please run './set_msvc_paths.sh' first, or manually set the environment variables:"
        echo "export WINDOWS_KITS_BASE_PATH=\"/mnt/c/Program Files (x86)/Windows Kits/10\""
        exit 1
    fi
    
    # Check if MSVC directories exist
    if [ ! -d "$MSVC_BASE_PATH" ]; then
        error "MSVC directory not found at $MSVC_BASE_PATH"
        echo "Please check your MSVC_BASE_PATH environment variable."
        exit 1
    fi
    
    if [ ! -d "$WINDOWS_KITS_BASE_PATH" ]; then
        error "Windows Kits directory not found at $WINDOWS_KITS_BASE_PATH"
        echo "Please check your WINDOWS_KITS_BASE_PATH environment variable."
        exit 1
    fi
    
    # Check for cl.exe (MSVC compiler)
    if [ ! -f "${MSVC_BASE_PATH}/bin/Hostx64/x64/cl.exe" ]; then
        error "MSVC compiler (cl.exe) not found at ${MSVC_BASE_PATH}/bin/Hostx64/x64/cl.exe"
        echo "Please check your MSVC_BASE_PATH environment variable."
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
    
    # Check if JUCE directory exists
    if [ ! -d "$JUCE_DIR" ]; then
        error "JUCE directory not found at $JUCE_DIR"
        info "Check that JUCE is located at $JUCE_DIR, or modify this script to point to its location."
        exit 1
    fi
    
    # Check if specialized CMake config exists
    if [ ! -f "${ROOT_DIR}/Windows-MSVC-WSL.cmake" ]; then
        error "Specialized Windows-MSVC-WSL.cmake file not found."
        echo "This file is required for the alternative build approach."
        exit 1
    fi
    
    info "Using CMake version $cmake_version"
    success "All prerequisites satisfied!"
}

# Clean build directory
clean_build_directory() {
    info "Cleaning build directory..."
    
    if [ -d "$BUILD_DIR" ]; then
        rm -rf "$BUILD_DIR"
        success "Removed existing build directory"
    fi
    
    mkdir -p "$BUILD_DIR"
    success "Created fresh build directory at $BUILD_DIR"
}

# Run CMake configuration
run_cmake_config() {
    info "Running CMake configuration with specialized Windows settings..."
    
    cd "$BUILD_DIR"
    
    # Create a clean environment with minimal Linux influences
    cmake_command=(
        cmake
        -DCMAKE_TOOLCHAIN_FILE="${ROOT_DIR}/Windows-MSVC-WSL.cmake"
        -DCMAKE_BUILD_TYPE=Release
        -DJUCE_DIR="${JUCE_DIR}"
        -DCMAKE_VERBOSE_MAKEFILE=ON
        -DJUCE_TARGET_ARCHITECTURE=x86_64
        -DVST3_ARCHITECTURE=x86_64
        -DJUCE_DISABLE_RUNTIME_ARCH_DETECTION=ON
        -DCMAKE_INSTALL_PREFIX="${BUILD_DIR}/install"
        ..
    )
    
    info "Running: ${cmake_command[*]}"
    
    if "${cmake_command[@]}"; then
        success "CMake configuration completed successfully!"
    else
        error "CMake configuration failed."
        exit 1
    fi
    
    cd "$ROOT_DIR"
}

# Build the plugin
build_plugin() {
    info "Building Windows VST3 plugin..."
    
    cd "$BUILD_DIR"
    
    # Use fewer parallel jobs to avoid overwhelming WSL
    local num_jobs=$(nproc 2>/dev/null || echo 2)
    if [ $num_jobs -gt 4 ]; then
        num_jobs=4
    fi
    
    info "Building with $num_jobs parallel jobs"
    
    if cmake --build . --config Release --parallel "$num_jobs"; then
        success "Build completed successfully!"
    else
        error "Build failed."
        exit 1
    fi
    
    cd "$ROOT_DIR"
}

# Display build results
display_results() {
    info "Windows VST3 plugin build process completed."
    
    # Find VST3 path
    local vst3_path=$(find "$BUILD_DIR" -name "*.vst3" -type d | head -n 1)
    
    if [ -n "$vst3_path" ]; then
        success "Windows VST3 plugin built successfully at:"
        echo "  $vst3_path"
        echo "  Windows path: $(wslpath -w "$vst3_path")"
        
        echo ""
        info "To use this plugin in FL Studio on Windows:"
        echo "1. Copy the entire .vst3 folder to your Windows VST3 directory"
        echo "   (typically C:\\Program Files\\Common Files\\VST3)"
        echo "2. Open FL Studio and scan for new plugins"
        echo "3. Look for \"Volume Control Plugin\" in the plugin browser"
    else
        warning "Could not find built VST3 plugin. Check the build output for errors."
    fi
}

# Main build process
main() {
    log_output "${BLUE}=============================================${NC}"
    log_output "${BLUE}  VolumeControlPlugin Windows Alt Build Script   ${NC}"
    log_output "${BLUE}=============================================${NC}"
    
    check_prerequisites
    clean_build_directory
    run_cmake_config
    build_plugin
    display_results
    
    log_output "\n${GREEN}Alternative build process completed.${NC}"
    log_output "\n${BLUE}[INFO]${NC} Complete build log saved to: ${LOG_FILE}"
}

# Redirect all command output to log file as well
exec > >(tee -a "$LOG_FILE") 2>&1

# Run the main function
main

# Final message about log file location
echo ""
echo -e "${BLUE}[INFO]${NC} Full build log available at: ${LOG_FILE}"