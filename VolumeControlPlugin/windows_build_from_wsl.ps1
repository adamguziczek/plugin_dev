# Volume Control Plugin - WSL to Windows Build Helper
# This script copies files from WSL to a Windows directory and runs the build script
# Run with: PowerShell -ExecutionPolicy Bypass -File windows_build_from_wsl.ps1

param(
    [string]$BuildType = "Release",  # Default to Release if not specified
    [string]$WindowsDestination = "C:\Temp\VolumeControlPlugin",  # Default Windows destination
    [switch]$SkipCopy = $false  # Option to skip copying if files already exist
)

$ErrorActionPreference = "Stop"  # Stop on first error

# Function to find Visual Studio installation
function Find-VisualStudio {
    $vsYears = @(2022, 2019, 2017)  # Visual Studio versions to check in order
    $vsInstallations = @()
    
    # Try to find Visual Studio installations using vswhere if available
    $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $vswhere) {
        $vsInstallations = & $vswhere -prerelease -legacy -format json | ConvertFrom-Json
    }
    
    # If vswhere didn't work, try known paths
    if ($vsInstallations.Count -eq 0) {
        foreach ($year in $vsYears) {
            $paths = @(
                "${env:ProgramFiles(x86)}\Microsoft Visual Studio\$year\Enterprise",
                "${env:ProgramFiles(x86)}\Microsoft Visual Studio\$year\Professional",
                "${env:ProgramFiles(x86)}\Microsoft Visual Studio\$year\Community",
                "${env:ProgramFiles}\Microsoft Visual Studio\$year\Enterprise",
                "${env:ProgramFiles}\Microsoft Visual Studio\$year\Professional",
                "${env:ProgramFiles}\Microsoft Visual Studio\$year\Community"
            )
            
            foreach ($path in $paths) {
                if (Test-Path $path) {
                    $vsInstallations += [PSCustomObject]@{
                        installationPath = $path
                        installationVersion = "$year.0.0.0"
                    }
                }
            }
        }
    }
    
    return $vsInstallations
}

# Display header
Write-Host ""
Write-Host "===== VOLUME CONTROL PLUGIN - WSL TO WINDOWS BUILD HELPER =====" -ForegroundColor Cyan
Write-Host "This script will copy your project from WSL to a Windows directory"
Write-Host "and then build it using Visual Studio tools."
Write-Host ""

# Get current directory
$currentPath = Get-Location
$isWslPath = $currentPath -like "\\wsl.localhost\*" -or $currentPath -like "\\wsl$\*"

# Default source path is the current directory
$sourcePath = $currentPath

if (-not $isWslPath) {
    Write-Host "You're not running from a WSL path. Using current directory as source." -ForegroundColor Yellow
    $sourcePath = $currentPath
}

# Output configuration
Write-Host "Configuration:" -ForegroundColor White
Write-Host "- Source path: $sourcePath" -ForegroundColor Gray
Write-Host "- Destination path: $WindowsDestination" -ForegroundColor Gray
Write-Host "- Build type: $BuildType" -ForegroundColor Gray
Write-Host "- Skip copy: $SkipCopy" -ForegroundColor Gray
Write-Host ""

# Check if destination exists
if (Test-Path $WindowsDestination) {
    if (-not $SkipCopy) {
        Write-Host "Destination directory exists. Do you want to overwrite it? (y/n)" -ForegroundColor Yellow
        $confirm = Read-Host
        
        if ($confirm -eq "y" -or $confirm -eq "Y") {
            Write-Host "Removing existing directory..." -ForegroundColor Yellow
            Remove-Item -Path $WindowsDestination -Recurse -Force
            Write-Host "Directory removed successfully" -ForegroundColor Green
        } else {
            Write-Host "Using existing directory (will only update changed files)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Skip copy enabled. Using existing directory..." -ForegroundColor Yellow
    }
} else {
    Write-Host "Creating destination directory..." -ForegroundColor Yellow
    New-Item -Path $WindowsDestination -ItemType Directory -Force | Out-Null
    Write-Host "Directory created successfully" -ForegroundColor Green
}

# Copy files if not skipped
if (-not $SkipCopy) {
    Write-Host ""
    Write-Host "===== Copying Files to Windows Directory =====" -ForegroundColor Cyan
    Write-Host "Copying files from $sourcePath to $WindowsDestination"
    Write-Host "This may take a moment..." -ForegroundColor Yellow
    
    try {
        # Copy the project files
        Copy-Item -Path "$sourcePath\*" -Destination $WindowsDestination -Recurse -Force -Exclude "build_vs"
        
        # Copy the JUCE directory if it exists at the same level
        $juceSourcePath = "$sourcePath\..\JUCE"
        $juceDestPath = "$WindowsDestination\..\JUCE"
        
        if (Test-Path $juceSourcePath) {
            Write-Host "JUCE directory found. Checking if it needs to be copied..." -ForegroundColor Yellow
            
            if (-not (Test-Path $juceDestPath)) {
                Write-Host "Copying JUCE directory to $juceDestPath" -ForegroundColor Yellow
                New-Item -Path $juceDestPath -ItemType Directory -Force | Out-Null
                Copy-Item -Path "$juceSourcePath\*" -Destination $juceDestPath -Recurse -Force
                Write-Host "JUCE directory copied successfully" -ForegroundColor Green
            } else {
                Write-Host "JUCE directory already exists at destination. Skipping copy." -ForegroundColor Yellow
            }
        } else {
            Write-Host "JUCE directory not found at $juceSourcePath. Make sure it exists." -ForegroundColor Red
            exit 1
        }
        
        Write-Host "All files copied successfully" -ForegroundColor Green
    } catch {
        Write-Host "ERROR: Failed to copy files: $_" -ForegroundColor Red
        exit 1
    }
}

# Change to the Windows directory
Write-Host ""
Write-Host "===== Setting Up Build Environment =====" -ForegroundColor Cyan
Write-Host "Changing to Windows directory: $WindowsDestination"
Set-Location -Path $WindowsDestination

# Check for Visual Studio and Windows SDK
Write-Host "Checking for Visual Studio and Windows SDK..." -ForegroundColor Yellow

# Find Visual Studio
$vsInstallations = Find-VisualStudio
if ($vsInstallations.Count -eq 0) {
    Write-Host "ERROR: Visual Studio not found. Please install Visual Studio with C++ workload" -ForegroundColor Red
    exit 1
}

# Select the newest Visual Studio version
$vs = $vsInstallations | Sort-Object -Property installationVersion -Descending | Select-Object -First 1
$vsVersion = $vs.installationVersion.Split('.')[0]
Write-Host "Visual Studio $vsVersion found at: $($vs.installationPath)" -ForegroundColor Green

# Determine Visual Studio year and CMake generator
$cmakeGenerator = "Visual Studio 16 2019"  # Default
if ($vsVersion -eq "2022") {
    $cmakeGenerator = "Visual Studio 17 2022"
    $vsYear = "2022"
} elseif ($vsVersion -eq "2019") {
    $cmakeGenerator = "Visual Studio 16 2019"
    $vsYear = "2019"
} elseif ($vsVersion -eq "2017") {
    $cmakeGenerator = "Visual Studio 15 2017"
    $vsYear = "2017"
}

# Find vcvarsall.bat
$vcvarsPath = ""
$possiblePaths = @(
    "$($vs.installationPath)\VC\Auxiliary\Build\vcvarsall.bat",
    "$($vs.installationPath)\VC\vcvarsall.bat"
)

foreach ($path in $possiblePaths) {
    if (Test-Path $path) {
        $vcvarsPath = $path
        break
    }
}

if ([string]::IsNullOrEmpty($vcvarsPath)) {
    Write-Host "ERROR: Could not find vcvarsall.bat for Visual Studio" -ForegroundColor Red
    exit 1
}

Write-Host "Found vcvarsall.bat at: $vcvarsPath" -ForegroundColor Green

# Check for Windows 10 SDK
$windowsSdkPath = ""
$possibleSdkPaths = @(
    "C:\Program Files (x86)\Windows Kits\10",
    "C:\Program Files\Windows Kits\10"
)

foreach ($path in $possibleSdkPaths) {
    if (Test-Path $path) {
        $windowsSdkPath = $path
        break
    }
}

$sdkVersion = ""
if (![string]::IsNullOrEmpty($windowsSdkPath)) {
    $sdkIncludePath = Join-Path $windowsSdkPath "Include"
    if (Test-Path $sdkIncludePath) {
        $sdkVersions = Get-ChildItem -Path $sdkIncludePath -Directory | Sort-Object -Property Name -Descending
        if ($sdkVersions.Count -gt 0) {
            $sdkVersion = $sdkVersions[0].Name
            Write-Host "Found Windows 10 SDK version $sdkVersion" -ForegroundColor Green
        } else {
            Write-Host "WARNING: Windows 10 SDK found but no versions detected" -ForegroundColor Yellow
        }
    } else {
        Write-Host "WARNING: Windows 10 SDK found but missing Include directory" -ForegroundColor Yellow
        Write-Host "Please install Windows 10 SDK through Visual Studio Installer" -ForegroundColor Yellow
    }
} else {
    Write-Host "WARNING: Windows 10 SDK not found" -ForegroundColor Yellow
    Write-Host "Please install Windows 10 SDK through Visual Studio Installer" -ForegroundColor Yellow
}

# Create build directory
$buildDir = "build_vs"
if (!(Test-Path $buildDir)) {
    New-Item -ItemType Directory -Path $buildDir | Out-Null
    Write-Host "Created build directory: $buildDir" -ForegroundColor Green
} else {
    Write-Host "Using existing build directory: $buildDir" -ForegroundColor Yellow
}

# Create direct batch file for Visual Studio build
$buildBatchPath = Join-Path $WindowsDestination "win_cmake_build.bat"

@"
@echo off
setlocal enabledelayedexpansion

echo Setting up Visual Studio environment...
call "$vcvarsPath" x64
if %ERRORLEVEL% NEQ 0 (
    echo Failed to set up Visual Studio environment
    exit /b 1
)

echo --------- Environment Info ---------
echo Visual Studio Path: $($vs.installationPath)
echo Windows SDK Version: $sdkVersion
echo Current Directory: %CD%
echo ----------------------------------

cd $buildDir
if %ERRORLEVEL% NEQ 0 (
    echo Failed to change to build directory
    exit /b 1
)

echo Running CMake configuration...
cmake -G "$cmakeGenerator" -A x64 ..
if %ERRORLEVEL% NEQ 0 (
    echo CMake configuration failed
    exit /b 1
)

echo Building project...
cmake --build . --config $BuildType
if %ERRORLEVEL% NEQ 0 (
    echo Build failed
    exit /b 1
)

echo Build completed successfully
exit /b 0
"@ | Out-File -FilePath $buildBatchPath -Encoding ASCII

# Execute the batch file
Write-Host ""
Write-Host "===== Building Project =====" -ForegroundColor Cyan
Write-Host "Running build with Visual Studio $vsYear and $BuildType configuration"
try {
    $process = Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$buildBatchPath`"" -NoNewWindow -Wait -PassThru
    
    if ($process.ExitCode -ne 0) {
        Write-Host "Build failed with exit code $($process.ExitCode)" -ForegroundColor Red
        
        # Try another approach with environment variables
        Write-Host ""
        Write-Host "Trying alternative build approach..." -ForegroundColor Yellow
        
        $fallbackBatchPath = Join-Path $WindowsDestination "win_fallback_build.bat"
        
        @"
@echo off
setlocal enabledelayedexpansion

echo Setting up Visual Studio environment...
call "$vcvarsPath" x64
if %ERRORLEVEL% NEQ 0 (
    echo Failed to set up Visual Studio environment
    exit /b 1
)

echo Setting extra environment variables to help compiler detection...
set CC=cl.exe
set CXX=cl.exe

cd $buildDir
if %ERRORLEVEL% NEQ 0 (
    echo Failed to change to build directory
    exit /b 1
)

echo Cleaning CMake cache...
if exist CMakeCache.txt (
    del /f /q CMakeCache.txt
)
if exist CMakeFiles (
    rd /s /q CMakeFiles
)

echo Running simplified CMake configuration...
cmake -G "$cmakeGenerator" -A x64 ..
if %ERRORLEVEL% NEQ 0 (
    echo CMake configuration failed
    exit /b 1
)

echo Building project...
cmake --build . --config $BuildType
if %ERRORLEVEL% NEQ 0 (
    echo Build failed
    exit /b 1
)

echo Build completed successfully
exit /b 0
"@ | Out-File -FilePath $fallbackBatchPath -Encoding ASCII
        
        $fallbackProcess = Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$fallbackBatchPath`"" -NoNewWindow -Wait -PassThru
        
        if ($fallbackProcess.ExitCode -ne 0) {
            Write-Host "Alternative build approach also failed." -ForegroundColor Red
            Write-Host ""
            Write-Host "Troubleshooting Suggestions:" -ForegroundColor Yellow
            Write-Host "1. Make sure Visual Studio is installed with 'Desktop development with C++' workload" -ForegroundColor White
            Write-Host "2. Install the latest Windows 10 SDK from Visual Studio Installer" -ForegroundColor White
            Write-Host "3. Try building directly from a Windows path instead of from WSL:" -ForegroundColor White
            Write-Host "   - Clone the repository to C:\Dev\VolumeControlPlugin" -ForegroundColor White
            Write-Host "   - Run the build scripts from there" -ForegroundColor White
            exit 1
        } else {
            Write-Host "Build completed successfully using alternative approach!" -ForegroundColor Green
        }
    } else {
        Write-Host "Build completed successfully!" -ForegroundColor Green
    }
} catch {
    Write-Host "ERROR: Failed to run build process: $_" -ForegroundColor Red
    exit 1
} finally {
    # Clean up temp files
    Remove-Item $buildBatchPath -ErrorAction SilentlyContinue
    Remove-Item $fallbackBatchPath -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "===== Build Complete =====" -ForegroundColor Cyan
Write-Host "You can find the built plugin at:" -ForegroundColor White
Write-Host "$WindowsDestination\build_vs\VolumeControlPlugin_artefacts\$BuildType\VST3\VolumeControlPlugin.vst3" -ForegroundColor Gray
Write-Host ""
Write-Host "To install the plugin, copy it to your VST3 directory:" -ForegroundColor White
Write-Host "C:\Program Files\Common Files\VST3\" -ForegroundColor Gray
Write-Host ""

# Info on using the plugin and next steps
Write-Host "For future builds after making changes in WSL:" -ForegroundColor Yellow
Write-Host "1. For faster builds (skips copying files): " -ForegroundColor White
Write-Host "   .\windows_build_from_wsl.ps1 -SkipCopy" -ForegroundColor Gray
Write-Host "2. To clean the build: " -ForegroundColor White
Write-Host "   cd $WindowsDestination && .\clean.ps1" -ForegroundColor Gray
Write-Host ""