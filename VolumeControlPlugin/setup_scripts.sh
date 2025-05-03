#!/bin/bash
# setup_scripts.sh - Setup script for VolumeControlPlugin build scripts
# 
# This script makes the build scripts executable.
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

# Make scripts executable
make_scripts_executable() {
    info "Making build scripts executable..."
    
    # List of scripts to make executable
    SCRIPTS=("build.sh" "build_release.sh" "clean.sh" "setup_scripts.sh")
    
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
    
    make_scripts_executable
    
    echo -e "\n${GREEN}Setup completed!${NC}"
    echo -e "You can now run ./build.sh to build the plugin."
}

# Run the main function
main