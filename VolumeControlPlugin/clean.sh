#!/bin/bash
# clean.sh - Clean script for VolumeControlPlugin build directories
# 
# This script cleans the build directories (build, build_release, and build_windows).

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

# Clean build directories
clean_build_directories() {
    # List of build directories to clean
    BUILD_DIRS=("build" "build_release" "build_windows")
    
    local any_cleaned=false
    
    for dir in "${BUILD_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            info "Cleaning $dir directory..."
            
            # Ask for confirmation
            read -p "Are you sure you want to remove the $dir directory? (y/n): " confirm
            
            if [[ $confirm == [yY]* ]]; then
                rm -rf "$dir"
                success "$dir directory removed successfully."
                any_cleaned=true
            else
                warning "Skipping $dir directory clean."
            fi
        else
            info "$dir directory does not exist, nothing to clean."
        fi
    done
    
    if [ "$any_cleaned" = true ]; then
        success "Clean completed."
    else
        info "No directories were cleaned."
    fi
}

# Main function
main() {
    echo -e "${BLUE}=======================================${NC}"
    echo -e "${BLUE}  VolumeControlPlugin Clean Script    ${NC}"
    echo -e "${BLUE}=======================================${NC}"
    
    clean_build_directories
    
    echo -e "\n${GREEN}Script completed.${NC}"
}

# Run the main function
main