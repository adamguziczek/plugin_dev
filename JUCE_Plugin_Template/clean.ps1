# JUCE Plugin - Windows Clean Script
# This script cleans the build directories created by PowerShell build scripts
# Run with: PowerShell -ExecutionPolicy Bypass -File clean.ps1

# Print header
Write-Host ""
Write-Host "===== JUCE PLUGIN - CLEAN SCRIPT =====" -ForegroundColor Cyan
Write-Host "This script will clean all build directories" -ForegroundColor White

# Check if running from a system directory
$currentPath = Get-Location
$isSystemDir = $currentPath -like "C:\Windows\*" -or $currentPath -like "C:\Program Files\*" -or $currentPath -like "C:\Program Files (x86)\*"

if ($isSystemDir) {
    Write-Host "WARNING: You're running from a system directory: $currentPath" -ForegroundColor Yellow
    Write-Host "This may cause permission issues or other unexpected behavior." -ForegroundColor Yellow
    Write-Host "It's recommended to move your project to a non-system location like:" -ForegroundColor Yellow
    Write-Host "  - C:\Dev\JUCEPlugin" -ForegroundColor White
    Write-Host "  - C:\Projects\JUCEPlugin" -ForegroundColor White
    Write-Host "  - C:\Users\YourUsername\Projects\JUCEPlugin" -ForegroundColor White
    Write-Host ""
    
    # Ask for confirmation before proceeding
    Write-Host "Do you want to continue anyway? (y/n)" -ForegroundColor White
    $confirm = Read-Host
    
    if ($confirm -ne "y" -and $confirm -ne "Y") {
        Write-Host "Clean operation aborted. Please move your project to a non-system directory." -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Proceeding with clean in system directory..." -ForegroundColor Yellow
    Write-Host ""
}

# Check if running from WSL path
$isWslPath = $currentPath -like "\\wsl.localhost\*" -or $currentPath -like "\\wsl$\*"

if ($isWslPath) {
    Write-Host "WSL PATH DETECTED: $currentPath" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "ERROR: Cannot run clean script directly from WSL path." -ForegroundColor Red
    Write-Host "Windows CMD doesn't support UNC paths as current directories." -ForegroundColor Red
    Write-Host ""
    Write-Host "Please use one of these alternatives:" -ForegroundColor Cyan
    Write-Host "1. Clone the repository to a Windows path (recommended):" -ForegroundColor White
    Write-Host "   git clone <your-repo-url> C:\Dev\JUCEPlugin" -ForegroundColor Gray
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
                # Using temporary batch file to avoid path issues
                $batchFile = Join-Path $PWD "temp_clean.bat"
                
                @"
@echo off
rd /s /q "$fullPath"
"@ | Out-File -FilePath $batchFile -Encoding ASCII
                
                # Run the batch file
                $process = Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$batchFile`"" -NoNewWindow -Wait -PassThru
                
                # Clean up the temporary batch file
                if (Test-Path $batchFile) {
                    Remove-Item $batchFile
                }
                
                if ($process.ExitCode -eq 0) {
                    Write-Host "Directory $dir removed successfully" -ForegroundColor Green
                    $anyCleaned = $true
                } else {
                    Write-Host "Error removing directory with exit code $($process.ExitCode)" -ForegroundColor Red
                }
            }
            catch {
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