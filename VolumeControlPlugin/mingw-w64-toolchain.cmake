# MinGW-w64 Toolchain file for cross-compilation from Linux to Windows
# This file enables building Windows VST3 plugins from WSL

# System information
set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_PROCESSOR x86_64)

# Set the MinGW-w64 compiler paths
set(MINGW_PREFIX "x86_64-w64-mingw32")

# Set the required compilers
set(CMAKE_C_COMPILER ${MINGW_PREFIX}-gcc)
set(CMAKE_CXX_COMPILER ${MINGW_PREFIX}-g++)
set(CMAKE_RC_COMPILER ${MINGW_PREFIX}-windres)

# Set the installation path (optional)
set(CMAKE_INSTALL_PREFIX /usr/${MINGW_PREFIX})

# Set root path for find operations
set(CMAKE_FIND_ROOT_PATH /usr/${MINGW_PREFIX})
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# Enable shared libraries by default for VST plugins
set(BUILD_SHARED_LIBS ON)

# Special flags for MinGW cross-compilation
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -static-libgcc -static-libstdc++")
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -static-libgcc -static-libstdc++")
set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -static-libgcc -static-libstdc++")

# Ensure DLLs are created with proper extension
set(CMAKE_SHARED_LIBRARY_PREFIX "")
set(CMAKE_SHARED_LIBRARY_SUFFIX ".dll")

# Disable certain JUCE-related features that might not work well in cross-compilation
set(JUCE_BUILD_MISC_UTILITIES OFF CACHE BOOL "")
set(JUCE_USE_CURL OFF CACHE BOOL "")

# Define Windows platform
add_definitions(-D_WIN32)
add_definitions(-DWINDOWS=1)