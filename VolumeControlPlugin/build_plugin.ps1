# Volume Control Plugin - Comprehensive Windows Build Script
# Usage: .\build_plugin.ps1 [Debug|Release]
# Run with: PowerShell -ExecutionPolicy Bypass -File build_plugin.ps1 [Debug|Release]

param(
    [string]$BuildType = "Release"
)

# Configuration
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$BuildDir = Join-Path $ScriptDir "build_vs"
$JuceDir = Join-Path (Split-Path -Parent $ScriptDir) "JUCE"

# Helper functions
function Write-ColorText {
    param (
        [string]$Text,
        [string]$Color = "White"
    )
    Write-Host $Text -ForegroundColor $Color
}

function Write-Step {
    param ([string]$Text)
    Write-ColorText "`n→ $Text" "Yellow"
}

function Write-Success {
    param ([string]$Text)
    Write-ColorText "✓ $Text" "Green"
}

function Write-Error {
    param ([string]$Text)
    Write-ColorText "ERROR: $Text" "Red"
}

function Write-Warning {
    param ([string]$Text)
    Write-ColorText "WARNING: $Text" "Yellow"
}

# Check execution policy
$policy = Get-ExecutionPolicy -Scope Process
if ($policy -eq "Restricted" -or $policy -eq "AllSigned") {
    Write-Warning "PowerShell execution policy is set to $policy"
    Write-ColorText "If you receive a policy error, run this command first:" "Gray"
    Write-ColorText "Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process" "Gray"
}

# Print header
Write-ColorText "`n=============================================" "Cyan"
Write-ColorText " Volume Control Plugin - Windows Build Script " "Cyan"
Write-ColorText "=============================================" "Cyan"
Write-ColorText "Building in $BuildType configuration" "Cyan"

# Step 1: Check prerequisites
Write-Step "Checking prerequisites..."

# Check Visual Studio
$vsFound = $false
$vsVersion = ""
# Try Visual Studio 2022
if (Test-Path "C:\Program Files\Microsoft Visual Studio\2022") {
    $vsFound = $true
    $vsVersion = "2022"
    $vsGenerator = "Visual Studio 17 2022"
    Write-Success "Visual Studio 2022 found"
}
# Try Visual Studio 2019 if 2022 wasn't found
elseif (Test-Path "C:\Program Files (x86)\Microsoft Visual Studio\2019") {
    $vsFound = $true
    $vsVersion = "2019"
    $vsGenerator = "Visual Studio 16 2019"
    Write-Success "Visual Studio 2019 found"
}
else {
    Write-Error "Visual Studio 2019 or 2022 not found!"
    Write-ColorText "Please install Visual Studio with 'Desktop development with C++' workload."
    Write-ColorText "Download from: https://visualstudio.microsoft.com/downloads/"
    exit 1
}

# Check CMake
try {
    $cmakeVersion = (cmake --version) | Select-Object -First 1
    Write-Success "$cmakeVersion"
}
catch {
    Write-Error "CMake not found!"
    Write-ColorText "Please install CMake 3.15 or higher."
    Write-ColorText "Download from: https://cmake.org/download/"
    exit 1
}

# Check JUCE
if (-not (Test-Path $JuceDir)) {
    Write-Error "JUCE not found at $JuceDir"
    Write-ColorText "Please make sure the JUCE framework is in the parent directory of this project."
    Write-ColorText "Clone it with: git clone https://github.com/juce-framework/JUCE.git"
    exit 1
}
Write-Success "JUCE found at $JuceDir"
Write-Success "All prerequisites satisfied!"

# Step 2: Create build directory
Write-Step "Creating build directory..."
if (Test-Path $BuildDir) {
    Write-ColorText "Cleaning previous build artifacts..." "Gray"
    Remove-Item -Path "$BuildDir\*" -Recurse -Force -ErrorAction SilentlyContinue
}
else {
    New-Item -Path $BuildDir -ItemType Directory -Force | Out-Null
}
Write-Success "Build directory ready at $BuildDir"

# Step 3: Run CMake
Write-Step "Running CMake configuration..."
Push-Location $BuildDir
$cmakeArgs = @("-G", $vsGenerator, "-A", "x64", "-DCMAKE_BUILD_TYPE=$BuildType", "-DJUCE_DIR=$JuceDir", "..")
Write-ColorText "Executing: cmake $cmakeArgs" "Gray"
try {
    & cmake $cmakeArgs
    if ($LASTEXITCODE -ne 0) {
        Write-Error "CMake configuration failed with exit code $LASTEXITCODE"
        Pop-Location
        exit 1
    }
    Write-Success "CMake configuration completed successfully!"
}
catch {
    $ErrorMsg = $_.Exception.Message
    Write-Error "CMake failed: $ErrorMsg"
    Pop-Location
    exit 1
}

# Step 4: Build
$buildStepMessage = "Building project ($BuildType)"
Write-Step $buildStepMessage
$buildArgs = @("--build", ".", "--config", "$BuildType")
Write-ColorText "Executing: cmake $buildArgs" "Gray"
try {
    & cmake $buildArgs
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Build failed with exit code $LASTEXITCODE"
        Pop-Location
        exit 1
    }
    Write-Success "Build completed successfully!"
}
catch {
    $ErrorMsg = $_.Exception.Message
    Write-Error "Build failed: $ErrorMsg"
    Pop-Location
    exit 1
}
Pop-Location

# Step 5: Show results
Write-Step "Build Results:"
$PluginPath = Join-Path $BuildDir "VolumeControlPlugin_artefacts\$BuildType\VST3\VolumeControlPlugin.vst3"
$StandalonePath = Join-Path $BuildDir "VolumeControlPlugin_artefacts\$BuildType\Standalone\VolumeControlPlugin.exe"

if (Test-Path $PluginPath) {
    Write-Success "VST3 Plugin built successfully!"
    Write-ColorText "Location: $PluginPath" "White"
}
else {
    Write-Error "VST3 Plugin not found at expected location. Build may have failed."
}

if (Test-Path $StandalonePath) {
    Write-Success "Standalone App built successfully!"
    Write-ColorText "Location: $StandalonePath" "White"
}
else {
    Write-Error "Standalone application not found at expected location. Build may have failed."
}

# Step 6: Installation instructions
Write-Step "Installation Instructions:"
Write-ColorText "To load the plugin in your DAW:" "White"
Write-ColorText "1. Copy the .vst3 folder to your VST3 directory:" "White"
Write-ColorText "   C:\Program Files\Common Files\VST3" "Gray"
Write-ColorText "2. Rescan for plugins in your DAW" "White"
Write-ColorText "3. Look for 'Volume Control Plugin' in the effects list" "White"
Write-ColorText ""
Write-ColorText "To test the plugin without a DAW, run the standalone application:" "White"
Write-ColorText "   $StandalonePath" "Gray"

Write-ColorText "`n=============================================" "Cyan"
Write-ColorText " Build Completed Successfully!" "Cyan"
Write-ColorText "=============================================" "Cyan"