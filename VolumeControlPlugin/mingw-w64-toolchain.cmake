# MinGW-w64 Toolchain file for cross-compilation from Linux to Windows
# This file enables building Windows VST3 plugins from WSL or Linux
# Improved configuration with proper library linking and compiler flags

# System information
set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_PROCESSOR x86_64)

# Set the MinGW-w64 compiler paths
set(MINGW_PREFIX "x86_64-w64-mingw32")
set(MINGW_ROOTDIR "/usr/${MINGW_PREFIX}")

# Set the required compilers
set(CMAKE_C_COMPILER ${MINGW_PREFIX}-gcc)
set(CMAKE_CXX_COMPILER ${MINGW_PREFIX}-g++)
set(CMAKE_RC_COMPILER ${MINGW_PREFIX}-windres)
set(CMAKE_AR ${MINGW_PREFIX}-ar)
set(CMAKE_RANLIB ${MINGW_PREFIX}-ranlib)

# Set the installation path
set(CMAKE_INSTALL_PREFIX ${MINGW_ROOTDIR})

# Set root paths for find operations
set(CMAKE_FIND_ROOT_PATH ${MINGW_ROOTDIR} ${CMAKE_INSTALL_PREFIX})
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# Enable shared libraries by default for VST plugins
set(BUILD_SHARED_LIBS ON)

# Ensure DLLs are created with proper extension
set(CMAKE_EXECUTABLE_SUFFIX ".exe")
set(CMAKE_SHARED_LIBRARY_PREFIX "")
set(CMAKE_SHARED_LIBRARY_SUFFIX ".dll")
set(CMAKE_STATIC_LIBRARY_PREFIX "lib")
set(CMAKE_STATIC_LIBRARY_SUFFIX ".a")
set(CMAKE_IMPORT_LIBRARY_PREFIX "lib")
set(CMAKE_IMPORT_LIBRARY_SUFFIX ".dll.a")

# Common compiler flags for both C and CXX
set(COMMON_FLAGS "-static-libgcc -static-libstdc++ -fpermissive")

# Compiler flags specifically for C
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${COMMON_FLAGS}")

# Compiler flags specifically for CXX
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${COMMON_FLAGS}")

# Disable specific warnings that cause errors in JUCE/Harfbuzz when cross-compiling
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wno-narrowing -Wno-implicit-fallthrough -Wno-deprecated-declarations")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-shift-count-overflow -Wno-narrowing -Wno-implicit-fallthrough -Wno-deprecated-declarations")

# Add Windows-specific defines for JUCE
set(WIN_DEFINES "-DWINDOWS=1 -D_WINDOWS=1 -DWIN32=1 -D_WIN32=1 -D_WIN64=1 -DWIN64=1 -DJUCE_MINGW=1 -DJUCE_WINDOWS=1 -DJUCE_WASAPI=1 -DJUCE_DIRECTSOUND=1 -DJUCE_WINDOWS_USE_NATIVE_FILE_PATHS=1")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${WIN_DEFINES}")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${WIN_DEFINES}")

# Optimization level for Release builds
set(CMAKE_C_FLAGS_RELEASE "-O3 -DNDEBUG")
set(CMAKE_CXX_FLAGS_RELEASE "-O3 -DNDEBUG")

# Specify the threading model for MinGW (important for Windows)
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -mthreads")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -mthreads")

# Properly specified linker flags
set(WIN_LIBS "-lole32 -loleaut32 -lrpcrt4 -lshlwapi -luuid -lwsock32 -lws2_32 -lwininet -lversion -lwinmm -lkernel32 -luser32 -lgdi32 -lwinspool -lshell32 -lcomdlg32 -ladvapi32")

# Fixed linker flags for both executables and shared libraries
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -static-libgcc -static-libstdc++ -Wl,--as-needed ${WIN_LIBS}")
set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -static-libgcc -static-libstdc++ -Wl,--as-needed ${WIN_LIBS}")

# Add pthread support with proper linking (fixed to avoid duplicate symbols)
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -pthread")
set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -pthread")

# Disable certain JUCE-related features that might not work well in cross-compilation
set(JUCE_BUILD_MISC_UTILITIES OFF CACHE BOOL "")
set(JUCE_USE_CURL OFF CACHE BOOL "")
set(JUCE_WEB_BROWSER OFF CACHE BOOL "")

# Define build type as Release by default
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type" FORCE)
endif()

# Use position independent code
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# Add additional search paths for header/library files
include_directories(SYSTEM ${MINGW_ROOTDIR}/include)
link_directories(${MINGW_ROOTDIR}/lib)

message(STATUS "MinGW-w64 toolchain configured for Windows cross-compilation")
message(STATUS "C compiler: ${CMAKE_C_COMPILER}")
message(STATUS "CXX compiler: ${CMAKE_CXX_COMPILER}")