#!/bin/bash
# set_msvc_paths.sh - Helper script to set MSVC paths for Visual Studio 2019 Community Edition

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

# Get the highest version directory in the MSVC path
find_msvc_version() {
    local msvc_path="$1"
    local highest_version=""
    
    if [ -d "$msvc_path" ]; then
        for version in "$msvc_path"/*; do
            if [ -d "$version" ]; then
                highest_version=$(basename "$version")
            fi
        done
    fi
    
    echo "$highest_version"
}

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}  MSVC Path Setup for Visual Studio 2019 ${NC}"
echo -e "${BLUE}=========================================${NC}"

# Set paths based on user's Visual Studio 2019 Community installation
VS_BASE="/mnt/c/Program Files (x86)/Microsoft Visual Studio/2019/Community"
VC_TOOLS_PATH="$VS_BASE/VC/Tools/MSVC"
WINDOWS_KITS_PATH="/mnt/c/Program Files (x86)/Windows Kits/10"

# Check if paths exist
if [ ! -d "$VS_BASE" ]; then
    error "Visual Studio path not found at: $VS_BASE"
    echo "Please verify your Visual Studio installation and adjust this script if needed."
    exit 1
fi

if [ ! -d "$VC_TOOLS_PATH" ]; then
    error "MSVC Tools path not found at: $VC_TOOLS_PATH"
    echo "Please verify your Visual Studio installation and adjust this script if needed."
    exit 1
fi

# Find MSVC version
MSVC_VERSION=$(find_msvc_version "$VC_TOOLS_PATH")

if [ -z "$MSVC_VERSION" ]; then
    error "Could not find any MSVC version in $VC_TOOLS_PATH"
    echo "Please verify your Visual Studio installation."
    exit 1
fi

# Set the full MSVC path
MSVC_BASE_PATH="$VC_TOOLS_PATH/$MSVC_VERSION"

if [ ! -d "$MSVC_BASE_PATH" ]; then
    error "MSVC version path not found at: $MSVC_BASE_PATH"
    echo "Please verify your Visual Studio installation."
    exit 1
fi

# Check for cl.exe to confirm this is a valid MSVC path
if [ ! -f "$MSVC_BASE_PATH/bin/Hostx64/x64/cl.exe" ]; then
    error "Could not find cl.exe at $MSVC_BASE_PATH/bin/Hostx64/x64/cl.exe"
    echo "This does not appear to be a valid MSVC installation. Please check your paths."
    exit 1
fi

# Display the detected paths
info "Detected MSVC paths:"
echo "Visual Studio: $VS_BASE"
echo "MSVC Version: $MSVC_VERSION"
echo "MSVC Path: $MSVC_BASE_PATH"
echo "Windows SDK: $WINDOWS_KITS_PATH"

# Confirm with user
echo ""
read -p "Are these paths correct? (y/n): " confirm

if [[ $confirm != [yY]* ]]; then
    warning "Setup cancelled by user."
    echo "You can modify this script with the correct paths and run it again."
    exit 1
fi

# Set environment variables for the current session
export MSVC_BASE_PATH="$MSVC_BASE_PATH"
export WINDOWS_KITS_BASE_PATH="$WINDOWS_KITS_PATH"

# Add to .bashrc for persistence
if grep -q "export MSVC_BASE_PATH=" ~/.bashrc; then
    # Update existing entries
    sed -i "s|export MSVC_BASE_PATH=.*|export MSVC_BASE_PATH=\"$MSVC_BASE_PATH\"|" ~/.bashrc
    success "Updated MSVC_BASE_PATH in ~/.bashrc"
else
    # Add new entries
    echo "export MSVC_BASE_PATH=\"$MSVC_BASE_PATH\"" >> ~/.bashrc
    success "Added MSVC_BASE_PATH to ~/.bashrc"
fi

if grep -q "export WINDOWS_KITS_BASE_PATH=" ~/.bashrc; then
    # Update existing entries
    sed -i "s|export WINDOWS_KITS_BASE_PATH=.*|export WINDOWS_KITS_BASE_PATH=\"$WINDOWS_KITS_PATH\"|" ~/.bashrc
    success "Updated WINDOWS_KITS_BASE_PATH in ~/.bashrc"
else
    # Add new entries
    echo "export WINDOWS_KITS_BASE_PATH=\"$WINDOWS_KITS_PATH\"" >> ~/.bashrc
    success "Added WINDOWS_KITS_BASE_PATH to ~/.bashrc"
fi

# Print instructions
echo ""
success "MSVC paths have been set up for this session and saved to your ~/.bashrc"
echo "Current session variables:"
echo "  MSVC_BASE_PATH=$MSVC_BASE_PATH"
echo "  WINDOWS_KITS_BASE_PATH=$WINDOWS_KITS_PATH"
echo ""
info "You can now build your plugin using:"
echo "  ./build_windows_msvc.sh"
echo ""
info "If you open a new terminal, the paths will be automatically loaded from your ~/.bashrc."
echo "If you need to update these paths later, you can run this script again."

exit 0