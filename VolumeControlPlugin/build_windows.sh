#!/bin/bash
# build_windows.sh - Warning script about MinGW compatibility

# Set up colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${RED}[ERROR] MinGW cross-compilation is not supported for JUCE projects${NC}"
echo -e ""
echo -e "${YELLOW}JUCE does not officially support MinGW and this approach will not work reliably.${NC}"
echo -e "Please use one of the following recommended approaches instead:"
echo -e ""
echo -e "1. ${GREEN}MSVC Cross-Compilation from WSL${NC}"
echo -e "   Use the build_windows_msvc.sh script:"
echo -e "   ./build_windows_msvc.sh"
echo -e ""
echo -e "2. ${GREEN}Native Windows Build with Visual Studio${NC}"
echo -e "   Build directly on Windows using Visual Studio and CMake"
echo -e ""
echo -e "For detailed instructions, see:"
echo -e "${BLUE}WINDOWS_BUILD_OPTIONS.md${NC}"
echo -e ""
echo -e "To set up the MSVC cross-compilation environment:"
echo -e "   ./setup_scripts.sh"
echo -e ""
exit 1