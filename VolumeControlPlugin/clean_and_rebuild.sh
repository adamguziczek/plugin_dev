#!/bin/bash
# clean_and_rebuild.sh - Clean build directories and rebuild with proper architecture settings
# 
# This script provides a clean slate for building the VolumeControlPlugin for Windows
# using Microsoft's Visual C++ compiler with consistent architecture settings

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

# Current script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
ROOT_DIR="${SCRIPT_DIR}"

# Make sure environment variables are available
info "Checking environment variables..."

# Source bashrc to ensure environment variables are loaded
if [ -f ~/.bashrc ]; then
    source ~/.bashrc
    info "Sourced ~/.bashrc to load environment variables"
fi

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

# Set WSL detection override if needed
export WSL_DETECTED=1
info "Set WSL detection override to ensure cross-compilation works"

# Clean up previous build directories
info "Cleaning previous build artifacts..."

if [ -d "${ROOT_DIR}/build_windows_msvc" ]; then
    rm -rf "${ROOT_DIR}/build_windows_msvc"
    success "Removed build_windows_msvc directory"
fi

if [ -d "${ROOT_DIR}/build_windows" ]; then
    rm -rf "${ROOT_DIR}/build_windows"
    success "Removed build_windows directory"
fi

# Create fresh build directory
mkdir -p "${ROOT_DIR}/build_windows_msvc"
success "Created fresh build_windows_msvc directory"

# Run CMake configuration with explicit architecture settings
info "Running CMake configuration with proper architecture settings..."

cd "${ROOT_DIR}/build_windows_msvc"

CMAKE_COMMAND=(
    cmake
    -DCMAKE_TOOLCHAIN_FILE="../msvc-toolchain.cmake"
    -DCMAKE_BUILD_TYPE=Release
    -DJUCE_WINDOWS=TRUE
    -DJUCE_DIR="${ROOT_DIR}/../JUCE"
    -DCMAKE_VERBOSE_MAKEFILE=ON
    -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY
    -DJUCE_TARGET_ARCHITECTURE=x86_64
    -DVST3_ARCHITECTURE=x86_64
    -DJUCE_DISABLE_RUNTIME_ARCH_DETECTION=ON
    ..
)

info "Running: ${CMAKE_COMMAND[*]}"

if "${CMAKE_COMMAND[@]}"; then
    success "CMake configuration completed successfully!"
    
    # Build the project
    info "Building the project..."
    
    if cmake --build . --config Release; then
        success "Build completed successfully!"
        
        # Find VST3 path
        VST3_PATH=$(find . -name "*.vst3" -type d | head -n 1)
        
        if [ -n "$VST3_PATH" ]; then
            success "VST3 plugin built successfully at:"
            echo "$VST3_PATH"
            echo "Windows path: $(wslpath -w "$VST3_PATH")"
        else
            warning "Could not find built VST3 plugin. This may indicate a successful build with an unexpected output location."
        fi
    else
        error "Build failed"
        exit 1
    fi
else
    error "CMake configuration failed"
    exit 1
fi

info "Clean and rebuild process completed."
echo "If you want to run the standard build script, you can use './build_windows_msvc.sh'"