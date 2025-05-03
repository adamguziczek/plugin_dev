# build_plugin.ps1 - Automated JUCE Plugin Build Script for Windows
# Save this file as build_plugin.ps1 and run it in PowerShell
# 
# Usage:
#   .\build_plugin.ps1 [Release|Debug]
#   
# Example:
#   .\build_plugin.ps1 Release

param(
    [string]$BuildType = "Release"  # Default to Release if not specified
)

# Configuration
$ErrorActionPreference = "Stop"  # Stop on first error
$ProgressPreference = "Continue" # Show progress bars
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$BuildDir = Join-Path $ScriptPath "build_vs"
$JuceDir = Join-Path (Split-Path -Parent $ScriptPath) "JUCE"
$CopyToVstDir = $false  # Set to $true to automatically copy to VST directory
$VstDirectory = "C:\Program Files\Common Files\VST3"  # Standard VST3 directory

# Colorful output functions
function Write-Title {
    param([string]$Message)
    Write-Host "`n=============================================" -ForegroundColor Cyan
    Write-Host " $Message" -ForegroundColor Cyan
    Write-Host "=============================================" -ForegroundColor Cyan
}

function Write-Step {
    param([string]$Message)
    Write-Host "`n→ $Message" -ForegroundColor Yellow
}

function Write-Success {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "ERROR: $Message" -ForegroundColor Red
}

# Check prerequisites
function Check-Prerequisites {
    Write-Step "Checking prerequisites..."
    
    # Check if Visual Studio 2019 is installed
    $VsPath = "C:\Program Files (x86)\Microsoft Visual Studio\2019"
    if (-not (Test-Path $VsPath)) {
        Write-Error "Visual Studio 2019 not found at $VsPath"
        Write-Host "Please install Visual Studio 2019 with C++ workload" -ForegroundColor Yellow
        exit 1
    } 
    else {
        Write-Host "✓ Visual Studio 2019 found" -ForegroundColor Green
    }
    
    # Check if CMake is installed
    try {
        $CMakeVersion = (cmake --version) | Select-Object -First 1
        Write-Host "✓ $CMakeVersion" -ForegroundColor Green
    } 
    catch {
        Write-Error "CMake not found. Please install CMake and add it to your PATH"
        Write-Host "Download from: https://cmake.org/download/" -ForegroundColor Yellow
        exit 1
    }
    
    # Check if JUCE is available
    if (-not (Test-Path $JuceDir)) {
        Write-Error "JUCE not found at expected location: $JuceDir"
        Write-Host "Please make sure JUCE is at the correct location or update the script's JuceDir variable" -ForegroundColor Yellow
        exit 1
    } 
    else {
        Write-Host "✓ JUCE found at $JuceDir" -ForegroundColor Green
    }
    
    Write-Success "All prerequisites satisfied!"
}

# Create build directory
function Create-BuildDirectory {
    Write-Step "Creating build directory..."
    
    if (Test-Path $BuildDir) {
        Write-Host "Build directory already exists. Cleaning previous build artifacts..." -ForegroundColor Yellow
        Remove-Item -Path "$BuildDir\*" -Recurse -Force -ErrorAction SilentlyContinue
    } 
    else {
        New-Item -Path $BuildDir -ItemType Directory -Force | Out-Null
    }
    
    Write-Success "Build directory ready at $BuildDir"
}

# Run CMake to generate Visual Studio project files
function Run-CMake {
    Write-Step "Running CMake to generate Visual Studio project files..."
    
    Push-Location $BuildDir
    
    try {
        $CMakeArgs = @(
            "-G", "Visual Studio 16 2019",
            "-A", "x64",
            "-DCMAKE_BUILD_TYPE=$BuildType",
            "-DJUCE_DIR=$JuceDir",
            ".."
        )
        
        Write-Host "Executing: cmake $CMakeArgs" -ForegroundColor DarkGray
        & cmake $CMakeArgs
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error "CMake configuration failed with exit code $LASTEXITCODE"
            exit 1
        }
        
        Write-Success "CMake configuration completed successfully!"
    } 
    finally {
        Pop-Location
    }
}

# Build the project
function Build-Project {
    Write-Step "Building the project - $BuildType configuration..."
    
    Push-Location $BuildDir
    
    try {
        Write-Host "Executing: cmake --build . --config $BuildType" -ForegroundColor DarkGray
        & cmake --build . --config $BuildType
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Build failed with exit code $LASTEXITCODE"
            exit 1
        }
        
        Write-Success "Build completed successfully!"
    } 
    finally {
        Pop-Location
    }
}

# Copy to VST directory if requested
function Copy-ToVstDirectory {
    if (-not $CopyToVstDir) {
        return
    }
    
    Write-Step "Copying plugin to VST3 directory..."
    
    $PluginDir = Join-Path $BuildDir "VolumeControlPlugin_artefacts\$BuildType\VST3\VolumeControlPlugin.vst3"
    
    if (-not (Test-Path $PluginDir)) {
        Write-Error "Cannot find built plugin at $PluginDir"
        return
    }
    
    if (-not (Test-Path $VstDirectory)) {
        Write-Host "VST3 directory not found at $VstDirectory. Creating it..." -ForegroundColor Yellow
        New-Item -Path $VstDirectory -ItemType Directory -Force | Out-Null
    }
    
    try {
        Copy-Item -Path $PluginDir -Destination $VstDirectory -Recurse -Force
        Write-Success "Plugin copied to $VstDirectory"
    } 
    catch {
        Write-Error "Failed to copy plugin to VST3 directory: $_"
        Write-Host "You may need to run this script as Administrator to copy to Program Files" -ForegroundColor Yellow
    }
}

# Display results
function Show-BuildResults {
    Write-Step "Build results:"
    
    $PluginPath = Join-Path $BuildDir "VolumeControlPlugin_artefacts\$BuildType\VST3\VolumeControlPlugin.vst3"
    $StandalonePath = Join-Path $BuildDir "VolumeControlPlugin_artefacts\$BuildType\Standalone\VolumeControlPlugin.exe"
    
    if (Test-Path $PluginPath) {
        Write-Success "VST3 Plugin: $PluginPath"
    } 
    else {
        Write-Error "VST3 Plugin not found! Build may have failed."
    }
    
    if (Test-Path $StandalonePath) {
        Write-Success "Standalone App: $StandalonePath"
    } 
    else {
        Write-Error "Standalone application not found! Build may have failed."
    }
    
    Write-Host "`nTo load the plugin in your DAW:" -ForegroundColor White
    Write-Host "1. Copy the .vst3 folder to your VST3 directory" -ForegroundColor White
    Write-Host "2. Rescan for plugins in your DAW" -ForegroundColor White
    Write-Host "3. Look for 'Volume Control Plugin' in the effects list" -ForegroundColor White
}

# Main function
function Main {
    $StartTime = Get-Date
    
    Write-Title "JUCE Plugin Build Script for Windows"
    
    try {
        Check-Prerequisites
        Create-BuildDirectory
        Run-CMake
        Build-Project
        Copy-ToVstDirectory
        Show-BuildResults
        
        $EndTime = Get-Date
        $Duration = ($EndTime - $StartTime).TotalSeconds
        
        Write-Title "Build Completed Successfully in $([Math]::Round($Duration, 2)) seconds"
    } 
    catch {
        Write-Error "Build failed: $_"
        exit 1
    }
}

# Run the main function
Main