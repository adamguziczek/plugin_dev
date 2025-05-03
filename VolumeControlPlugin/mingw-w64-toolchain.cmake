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

# Compiler flags to fix cross-compilation issues with JUCE
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -static-libgcc -static-libstdc++ -fpermissive")
# Disable specific warnings that cause errors in JUCE/Harfbuzz when cross-compiling
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-shift-count-overflow -Wno-narrowing")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-implicit-fallthrough -Wno-deprecated-declarations")

# Add Windows-specific defines for JUCE
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DWINDOWS=1 -D_WINDOWS=1 -DWIN32=1 -D_WIN32=1")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -D_WIN64=1 -DWIN64=1 -DJUCE_MINGW=1")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DJUCE_WINDOWS=1 -DJUCE_WASAPI=1 -DJUCE_DIRECTSOUND=1")

# Ensure JUCE uses Windows file paths
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DJUCE_WINDOWS_USE_NATIVE_FILE_PATHS=1")

# Additional linker flags
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -static-libgcc -static-libstdc++ -Wl,-Bstatic,--whole-archive -lpthread -Wl,--no-whole-archive")
set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -static-libgcc -static-libstdc++ -Wl,-Bstatic,--whole-archive -lpthread -Wl,--no-whole-archive")

# Link with Windows libraries needed by JUCE
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -lole32 -loleaut32 -lrpcrt4 -lshlwapi -luuid -lwsock32 -lws2_32 -lwininet -lversion -lwinmm")

# Ensure DLLs are created with proper extension
set(CMAKE_SHARED_LIBRARY_PREFIX "")
set(CMAKE_SHARED_LIBRARY_SUFFIX ".dll")

# Disable certain JUCE-related features that might not work well in cross-compilation
set(JUCE_BUILD_MISC_UTILITIES OFF CACHE BOOL "")
set(JUCE_USE_CURL OFF CACHE BOOL "")
set(JUCE_WEB_BROWSER OFF CACHE BOOL "")

# Optimization level
set(CMAKE_CXX_FLAGS_RELEASE "-O3")

# Define build type as Release by default
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type" FORCE)
endif()

# Use position independent code
set(CMAKE_POSITION_INDEPENDENT_CODE ON)