# Volume Control Plugin - Windows Clean Script
# This script cleans the build directories created by PowerShell build scripts
# Run with: PowerShell -ExecutionPolicy Bypass -File clean.ps1

# Print header
Write-Host ""
Write-Host "===== VOLUME CONTROL PLUGIN - CLEAN SCRIPT =====" -ForegroundColor Cyan
Write-Host "This script will clean all build directories" -ForegroundColor White

# Check if running from WSL path
$currentPath = Get-Location
$isWslPath = $currentPath -like "\\wsl.localhost\*" -or $currentPath -like "\\wsl$\*"

if ($isWslPath) {
    Write-Host "WSL PATH DETECTED: $currentPath" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "ERROR: Cannot run clean script directly from WSL path." -ForegroundColor Red
    Write-Host "Windows CMD doesn't support UNC paths as current directories." -ForegroundColor Red
    Write-Host ""
    Write-Host "Please use one of these alternatives:" -ForegroundColor Cyan
    Write-Host "1. Clone the repository to a Windows path (recommended):" -ForegroundColor White
    Write-Host "   git clone <your-repo-url> C:\Dev\VolumeControlPlugin" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Use the Linux clean script from WSL:" -ForegroundColor White
    Write-Host "   ./clean.sh" -ForegroundColor Gray
    Write-Host ""
    exit 1
}

# Define build directories to clean
$buildDirs = @(
    "build_vs"
)

# Track if any directories were cleaned
$anyCleaned = $false

foreach ($dir in $buildDirs) {
    $fullPath = Join-Path $PSScriptRoot $dir
    
    if (Test-Path $fullPath) {
        Write-Host "Found build directory: $dir" -ForegroundColor Yellow
        
        # Ask for confirmation
        Write-Host "Are you sure you want to remove the $dir directory? (y/n)" -ForegroundColor White
        $confirm = Read-Host
        
        if ($confirm -eq "y" -or $confirm -eq "Y") {
            try {
                Write-Host "Removing $dir..." -ForegroundColor Yellow
                Remove-Item -Path $fullPath -Recurse -Force
                Write-Host "Directory $dir removed successfully" -ForegroundColor Green
                $anyCleaned = $true
            }
            catch {
                # Simplify the error message to avoid string interpolation issues
                Write-Host "Error removing directory. Please try again." -ForegroundColor Red
            }
        }
        else {
            Write-Host "Skipping $dir directory" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "$dir directory does not exist, nothing to clean" -ForegroundColor Gray
    }
}

if ($anyCleaned) {
    Write-Host "Clean completed successfully" -ForegroundColor Green
}
else {
    Write-Host "No directories were cleaned" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "===== Clean Script Complete =====" -ForegroundColor Cyan