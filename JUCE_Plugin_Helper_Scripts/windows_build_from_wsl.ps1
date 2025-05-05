# JUCE Plugin - WSL to Windows Build Helper
# This script copies files from WSL to a Windows directory and runs the build script
# Run with: PowerShell -ExecutionPolicy Bypass -File windows_build_from_wsl.ps1

param(
    [string]$BuildType = "Release",  # Default to Release if not specified
    [string]$WindowsDestination = "C:\Temp\JUCEPlugin",  # Default Windows destination
    [switch]$SkipCopy = $false,  # Option to skip copying if files already exist
    [switch]$Force = $false      # Option to force overwrite without prompting
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
Write-Host "===== JUCE PLUGIN - WSL TO WINDOWS BUILD HELPER =====" -ForegroundColor Cyan
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
Write-Host "- Force: $Force" -ForegroundColor Gray
Write-Host ""

# Function to safely clean and recreate directory
function Reset-Directory {
    param (
        [string]$Path,
        [switch]$CreateIfNotExists = $true
    )
    
    if (Test-Path $Path) {
        Write-Host "Cleaning directory: $Path" -ForegroundColor Yellow
        
        # First try the simple approach
        try {
            Remove-Item -Path $Path -Recurse -Force -ErrorAction Stop
            Write-Host "Directory removed successfully" -ForegroundColor Green
        }
        catch {
            Write-Host "Standard removal failed, trying alternative approach..." -ForegroundColor Yellow
            
            # Alternative approach - remove files first, then directories
            $childItems = Get-ChildItem -Path $Path -Recurse
            
            # Remove files first
            $childItems | Where-Object { !$_.PSIsContainer } | ForEach-Object {
                Remove-Item -Path $_.FullName -Force -ErrorAction SilentlyContinue
            }
            
            # Then remove directories from deepest to shallowest
            $childItems | Where-Object { $_.PSIsContainer } | Sort-Object -Property FullName -Descending | ForEach-Object {
                Remove-Item -Path $_.FullName -Force -ErrorAction SilentlyContinue
            }
            
            # Finally, remove the root directory
            Remove-Item -Path $Path -Force -ErrorAction SilentlyContinue
            
            # Check if removal was successful
            if (Test-Path $Path) {
                Write-Host "WARNING: Could not completely remove directory. Will try to reuse it." -ForegroundColor Yellow
            } else {
                Write-Host "Directory removed successfully with alternative approach" -ForegroundColor Green
            }
        }
    }
    
    # Create the directory if it doesn't exist (or was successfully removed)
    if (-not (Test-Path $Path) -and $CreateIfNotExists) {
        try {
            New-Item -Path $Path -ItemType Directory -Force | Out-Null
            Write-Host "Directory created successfully" -ForegroundColor Green
        }
        catch {
            Write-Host "ERROR: Failed to create directory: $_" -ForegroundColor Red
            return $false
        }
    }
    
    return $true
}

# Check if destination exists
if (Test-Path $WindowsDestination) {
    if (-not $SkipCopy -and -not $Force) {
        Write-Host "Destination directory exists. Do you want to overwrite it? (y/n)" -ForegroundColor Yellow
        $confirm = Read-Host
        
        if ($confirm -eq "y" -or $confirm -eq "Y") {
            if (-not (Reset-Directory -Path $WindowsDestination)) {
                exit 1
            }
        } else {
            Write-Host "Using existing directory (will only update changed files)" -ForegroundColor Yellow
        }
    } elseif (-not $SkipCopy -and $Force) {
        # Force overwrite without asking
        if (-not (Reset-Directory -Path $WindowsDestination)) {
            exit 1
        }
    } else {
        Write-Host "Skip copy enabled. Using existing directory..." -ForegroundColor Yellow
    }
} else {
    Write-Host "Creating destination directory..." -ForegroundColor Yellow
    if (-not (Reset-Directory -Path $WindowsDestination)) {
        exit 1
    }
}

# Copy files if not skipped
if (-not $SkipCopy) {
    Write-Host ""
    Write-Host "===== Copying Files to Windows Directory =====" -ForegroundColor Cyan
    Write-Host "Copying files from $sourcePath to $WindowsDestination"
    Write-Host "This may take a moment..." -ForegroundColor Yellow
    
    try {
        # Copy project files (excluding build directory)
        $sourceItems = Get-ChildItem -Path $sourcePath -Exclude "build_vs"
        foreach ($item in $sourceItems) {
            $destinationPath = Join-Path $WindowsDestination $item.Name
            
            # If the item is a directory
            if ($item.PSIsContainer) {
                # Make sure destination directory exists
                if (-not (Test-Path $destinationPath)) {
                    New-Item -Path $destinationPath -ItemType Directory -Force | Out-Null
                }
                
                # Copy contents
                Copy-Item -Path "$($item.FullName)\*" -Destination $destinationPath -Recurse -Force
            } else {
                # It's a file, copy it directly
                Copy-Item -Path $item.FullName -Destination $destinationPath -Force
            }
        }
        
        Write-Host "Project files copied successfully" -ForegroundColor Green
        
        # Copy the JUCE directory if it exists at the same level
        $juceSourcePath = "$sourcePath\..\JUCE"
        $juceDestPath = "$WindowsDestination\..\JUCE"
        
        if (Test-Path $juceSourcePath) {
            Write-Host "JUCE directory found. Checking if it needs to be copied..." -ForegroundColor Yellow
            
            if (-not (Test-Path $juceDestPath)) {
                Write-Host "Copying JUCE directory to $juceDestPath" -ForegroundColor Yellow
                if (Reset-Directory -Path $juceDestPath) {
                    # Copy JUCE files
                    $juceSourceItems = Get-ChildItem -Path $juceSourcePath
                    foreach ($item in $juceSourceItems) {
                        $juceDestinationPath = Join-Path $juceDestPath $item.Name
                        
                        # If the item is a directory
                        if ($item.PSIsContainer) {
                            # Make sure destination directory exists
                            if (-not (Test-Path $juceDestinationPath)) {
                                New-Item -Path $juceDestinationPath -ItemType Directory -Force | Out-Null
                            }
                            
                            # Copy contents (ignore errors on some problematic files)
                            Copy-Item -Path "$($item.FullName)\*" -Destination $juceDestinationPath -Recurse -Force -ErrorAction SilentlyContinue
                        } else {
                            # It's a file, copy it directly
                            Copy-Item -Path $item.FullName -Destination $juceDestinationPath -Force -ErrorAction SilentlyContinue
                        }
                    }
                    
                    Write-Host "JUCE directory copied successfully" -ForegroundColor Green
                }
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
        
        Write-Host ""
        Write-Host "Troubleshooting Copy Error:" -ForegroundColor Yellow
        Write-Host "1. Try running with the -Force parameter: .\windows_build_from_wsl.ps1 -Force" -ForegroundColor White
        Write-Host "2. Try manually copying the files from WSL to Windows:" -ForegroundColor White
        Write-Host "   a. Create a directory: mkdir C:\Temp\JUCEPlugin" -ForegroundColor Gray
        Write-Host "   b. Copy files: copy-item -Path '\\wsl.localhost\Ubuntu\path\to\YourPlugin\*' -Destination 'C:\Temp\JUCEPlugin' -Recurse" -ForegroundColor Gray
        Write-Host "3. Try running this script from Windows PowerShell as Administrator" -ForegroundColor White
        
        # Ask if user wants to continue with existing files
        Write-Host ""
        Write-Host "Do you want to continue with existing files? (y/n)" -ForegroundColor Yellow
        $continueDespiteError = Read-Host
        
        if ($continueDespiteError -ne "y" -and $continueDespiteError -ne "Y") {
            exit 1
        } else {
            Write-Host "Continuing with existing files..." -ForegroundColor Yellow
        }
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

# More robust version detection logic
$rawVsVersion = $vs.installationVersion
$vsVersionNumber = $rawVsVersion.Split('.')[0]

# Debug output to see what's being detected
Write-Host "Detected Visual Studio version: $rawVsVersion" -ForegroundColor Green
Write-Host "Visual Studio $vsVersionNumber found at: $($vs.installationPath)" -ForegroundColor Green

# Determine Visual Studio year and CMake generator with more robust logic
# Default to VS 2022 if we're on a new version or unsure
$cmakeGenerator = "Visual Studio 17 2022"
$vsYear = "2022"

# Only override if we're sure it's an older version
if ($vsVersionNumber -eq "2019" -or $vsVersionNumber -eq "16") {
    $cmakeGenerator = "Visual Studio 16 2019"
    $vsYear = "2019"
} elseif ($vsVersionNumber -eq "2017" -or $vsVersionNumber -eq "15") {
    $cmakeGenerator = "Visual Studio 15 2017"
    $vsYear = "2017"
}

# Always print the selected generator
Write-Host "Using CMake generator: $cmakeGenerator" -ForegroundColor Green

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

# Create build directory and clean CMake cache
$buildDir = "build_vs"
if (!(Test-Path $buildDir)) {
    New-Item -ItemType Directory -Path $buildDir | Out-Null
    Write-Host "Created build directory: $buildDir" -ForegroundColor Green
} else {
    Write-Host "Using existing build directory: $buildDir" -ForegroundColor Yellow
    
    # Clean any existing CMake cache to prevent generator conflicts
    $cmakeCachePath = Join-Path $buildDir "CMakeCache.txt"
    if (Test-Path $cmakeCachePath) {
        Write-Host "Removing existing CMake cache to ensure clean configuration" -ForegroundColor Yellow
        Remove-Item $cmakeCachePath -Force
    }
    
    $cmakeFilesDir = Join-Path $buildDir "CMakeFiles"
    if (Test-Path $cmakeFilesDir) {
        Write-Host "Removing CMakeFiles directory to ensure clean configuration" -ForegroundColor Yellow
        Remove-Item $cmakeFilesDir -Recurse -Force
    }
}

# Create direct batch file for Visual Studio build
$buildBatchPath = Join-Path $WindowsDestination "win_cmake_build.bat"

# Make sure we use a fixed literal for the generator to prevent any expansion issues
$cmakeGeneratorString = $cmakeGenerator  # Store in a separate variable for clarity

$batchContent = @"
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
echo CMake Generator: $cmakeGeneratorString
echo ----------------------------------

cd $buildDir
if %ERRORLEVEL% NEQ 0 (
    echo Failed to change to build directory
    exit /b 1
)

echo Cleaning any existing CMake cache...
if exist CMakeCache.txt (
    del /f /q CMakeCache.txt
)
if exist CMakeFiles (
    rd /s /q CMakeFiles
)

echo Running CMake configuration...
cmake -G "$cmakeGeneratorString" -A x64 ..
if %ERRORLEVEL% NEQ 0 (
    echo CMake configuration failed
    exit /b 1
)
"@

$batchContent | Out-File -FilePath $buildBatchPath -Encoding ASCII

# Add building project part to batch content
$batchContent += @"

echo Building project...
cmake --build . --config $BuildType
if %ERRORLEVEL% NEQ 0 (
    echo Build failed
    exit /b 1
)

echo Build completed successfully
exit /b 0
"@

# Write batch content to file
$batchContent | Out-File -FilePath $buildBatchPath -Encoding ASCII

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
        
        $fallbackBatchContent = @"
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
echo Using generator: $cmakeGeneratorString
cmake -G "$cmakeGeneratorString" -A x64 ..
if %ERRORLEVEL% NEQ 0 (
    echo CMake configuration failed
    exit /b 1
)
"@

$fallbackBatchContent += @"


echo Building project...
cmake --build . --config $BuildType
if %ERRORLEVEL% NEQ 0 (
    echo Build failed
    exit /b 1
)

echo Build completed successfully
exit /b 0
"@

# Write fallback batch content to file
$fallbackBatchContent | Out-File -FilePath $fallbackBatchPath -Encoding ASCII
        
        $fallbackProcess = Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$fallbackBatchPath`"" -NoNewWindow -Wait -PassThru
        
        if ($fallbackProcess.ExitCode -ne 0) {
            Write-Host "Alternative build approach also failed." -ForegroundColor Red
            Write-Host ""
            Write-Host "Troubleshooting Suggestions:" -ForegroundColor Yellow
            Write-Host "1. Make sure Visual Studio is installed with 'Desktop development with C++' workload" -ForegroundColor White
            Write-Host "2. Install the latest Windows 10 SDK from Visual Studio Installer" -ForegroundColor White
            Write-Host "3. Try building directly from a Windows path instead of from WSL:" -ForegroundColor White
            Write-Host "   - Clone the repository to C:\Dev\YourPlugin" -ForegroundColor White
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
    # Clean up temp files - only if they exist
    if (Test-Path $buildBatchPath) {
        Remove-Item $buildBatchPath -ErrorAction SilentlyContinue
    }
    
    # Only try to remove fallback path if it was created
    if ($fallbackBatchPath -and (Test-Path $fallbackBatchPath)) {
        Remove-Item $fallbackBatchPath -ErrorAction SilentlyContinue
    }
}

Write-Host ""
Write-Host "===== Build Complete =====" -ForegroundColor Cyan
Write-Host "You can find the built plugin at:" -ForegroundColor White
Write-Host "$WindowsDestination\build_vs\JUCEPlugin_artefacts\$BuildType\VST3\JUCEPlugin.vst3" -ForegroundColor Gray
Write-Host ""
Write-Host "To install the plugin, copy it to your VST3 directory:" -ForegroundColor White
Write-Host "C:\Program Files\Common Files\VST3\" -ForegroundColor Gray
Write-Host ""

# Info on using the plugin and next steps
Write-Host "For future builds after making changes in WSL:" -ForegroundColor Yellow
Write-Host "1. For faster builds (skips copying files): " -ForegroundColor White
Write-Host "   .\windows_build_from_wsl.ps1 -SkipCopy" -ForegroundColor Gray
Write-Host "2. To force clean rebuild with new files: " -ForegroundColor White
Write-Host "   .\windows_build_from_wsl.ps1 -Force" -ForegroundColor Gray
Write-Host "3. To clean the build: " -ForegroundColor White
Write-Host "   cd $WindowsDestination && .\clean.ps1" -ForegroundColor Gray
Write-Host ""