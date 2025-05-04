# Volume Control Plugin - Windows Clean Script
# This script cleans the build directories created by PowerShell build scripts
# Run with: PowerShell -ExecutionPolicy Bypass -File clean.ps1

# Print header
Write-Host "`n===== VOLUME CONTROL PLUGIN - CLEAN SCRIPT =====" -ForegroundColor Cyan
Write-Host "This script will clean all build directories" -ForegroundColor White

# Define build directories to clean
$buildDirs = @(
    'build_vs'
)

# Track if any directories were cleaned
$anyCleaned = $false

foreach ($dir in $buildDirs) {
    $fullPath = Join-Path $PSScriptRoot $dir
    
    if (Test-Path $fullPath) {
        Write-Host "Found build directory: $dir" -ForegroundColor Yellow
        
        # Ask for confirmation
        $confirm = Read-Host "Are you sure you want to remove the $dir directory? (y/n)"
        
        if ($confirm -eq 'y' -or $confirm -eq 'Y') {
            try {
                Write-Host "Removing $dir..." -ForegroundColor Yellow
                Remove-Item -Path $fullPath -Recurse -Force
                Write-Host "✓ $dir directory removed successfully" -ForegroundColor Green
                $anyCleaned = $true
            }
            catch {
                $errorMessage = $_.Exception.Message
                Write-Host "Error removing directory: $errorMessage" -ForegroundColor Red
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
    Write-Host "✓ Clean completed successfully" -ForegroundColor Green
}
else {
    Write-Host "No directories were cleaned" -ForegroundColor Yellow
}

Write-Host "`n===== Clean Script Complete =====" -ForegroundColor Cyan