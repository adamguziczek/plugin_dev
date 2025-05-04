# Volume Control Plugin - WSL to Windows Build Helper
# This script copies files from WSL to a Windows directory and runs the build script
# Run with: PowerShell -ExecutionPolicy Bypass -File windows_build_from_wsl.ps1
# Author: AI Assistant

param(
    [string]$BuildType = "Release",  # Default to Release if not specified
    [string]$WindowsDestination = "C:\Temp\VolumeControlPlugin",  # Default Windows destination
    [switch]$SkipCopy = $false  # Option to skip copying if files already exist
)

$ErrorActionPreference = "Stop"  # Stop on first error

# Display header
Write-Host ""
Write-Host "===== VOLUME CONTROL PLUGIN - WSL TO WINDOWS BUILD HELPER =====" -ForegroundColor Cyan
Write-Host "This script will copy your project from WSL to a Windows directory"
Write-Host "and then build it using the build_simple.ps1 script."
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
Write-Host "===== Running Build Script =====" -ForegroundColor Cyan
Write-Host "Changing to Windows directory: $WindowsDestination"
Set-Location -Path $WindowsDestination

# Run the build script
Write-Host "Running build_simple.ps1 with build type: $BuildType"
try {
    # Check if build_simple.ps1 exists
    if (Test-Path "build_simple.ps1") {
        # Run the build script
        & ".\build_simple.ps1" $BuildType
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Build completed successfully" -ForegroundColor Green
        } else {
            Write-Host "Build failed with exit code $LASTEXITCODE" -ForegroundColor Red
            exit $LASTEXITCODE
        }
    } else {
        Write-Host "ERROR: build_simple.ps1 not found in $WindowsDestination" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "ERROR: Failed to run build script: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "===== Build Complete =====" -ForegroundColor Cyan
Write-Host "You can find the built plugin at:" -ForegroundColor White
Write-Host "$WindowsDestination\build_vs\VolumeControlPlugin_artefacts\$BuildType\VST3\VolumeControlPlugin.vst3" -ForegroundColor Gray
Write-Host ""
Write-Host "To install the plugin, copy it to your VST3 directory:" -ForegroundColor White
Write-Host "C:\Program Files\Common Files\VST3\" -ForegroundColor Gray
Write-Host ""
Write-Host "Need to clean the build directory? Run clean.ps1 from the Windows directory:" -ForegroundColor White
Write-Host "cd $WindowsDestination" -ForegroundColor Gray
Write-Host ".\clean.ps1" -ForegroundColor Gray
Write-Host ""
Write-Host "For future builds, you can use the -SkipCopy switch to skip copying files if they haven't changed:" -ForegroundColor White
Write-Host ".\windows_build_from_wsl.ps1 -SkipCopy" -ForegroundColor Gray
Write-Host ""