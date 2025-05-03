# Simple PowerShell build script for JUCE plugin
# Run with: PowerShell -ExecutionPolicy Bypass -File build_simple.ps1

# Basic variables - modify these if needed
$BuildType = "Release"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$BuildDir = Join-Path $ScriptDir "build_vs"
$JuceDir = Join-Path (Split-Path -Parent $ScriptDir) "JUCE"

# Display header
Write-Host "JUCE Plugin Simple Build Script"
Write-Host "==============================="

# Step 1: Check prerequisites
Write-Host "Step 1: Checking prerequisites..."

# Check Visual Studio
if (-not (Test-Path "C:\Program Files (x86)\Microsoft Visual Studio\2019")) {
    Write-Host "ERROR: Visual Studio 2019 not found" -ForegroundColor Red
    exit 1
}
Write-Host "Visual Studio 2019 found" -ForegroundColor Green

# Check CMake
try {
    cmake --version | Out-Null
    Write-Host "CMake found" -ForegroundColor Green
}
catch {
    Write-Host "ERROR: CMake not found" -ForegroundColor Red
    exit 1
}

# Check JUCE
if (-not (Test-Path $JuceDir)) {
    Write-Host "ERROR: JUCE not found at $JuceDir" -ForegroundColor Red
    exit 1
}
Write-Host "JUCE found" -ForegroundColor Green

# Step 2: Create build directory
Write-Host "Step 2: Creating build directory..."
if (Test-Path $BuildDir) {
    Write-Host "Cleaning existing build directory"
    Remove-Item -Path (Join-Path $BuildDir "*") -Recurse -Force -ErrorAction SilentlyContinue
}
else {
    New-Item -Path $BuildDir -ItemType Directory -Force | Out-Null
}

# Step 3: Run CMake
Write-Host "Step 3: Running CMake..."
Set-Location $BuildDir
& cmake "-G" "Visual Studio 16 2019" "-A" "x64" "-DCMAKE_BUILD_TYPE=$BuildType" "-DJUCE_DIR=$JuceDir" ".."
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: CMake configuration failed" -ForegroundColor Red
    exit 1
}

# Step 4: Build the project
Write-Host "Step 4: Building project..."
& cmake --build . --config $BuildType
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Build failed" -ForegroundColor Red
    exit 1
}

# Step 5: Show results
Write-Host "Step 5: Checking build results..."
$PluginPath = Join-Path $BuildDir "VolumeControlPlugin_artefacts\$BuildType\VST3\VolumeControlPlugin.vst3"
$StandalonePath = Join-Path $BuildDir "VolumeControlPlugin_artefacts\$BuildType\Standalone\VolumeControlPlugin.exe"

if (Test-Path $PluginPath) {
    Write-Host "VST3 Plugin built successfully at: $PluginPath" -ForegroundColor Green
}
else {
    Write-Host "VST3 Plugin not found - build may have failed" -ForegroundColor Red
}

if (Test-Path $StandalonePath) {
    Write-Host "Standalone app built successfully at: $StandalonePath" -ForegroundColor Green
}
else {
    Write-Host "Standalone app not found - build may have failed" -ForegroundColor Red
}

Write-Host "Build process completed!"