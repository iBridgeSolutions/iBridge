# iBridge Intranet Server Script - Fixed Version
# This script runs a local server specifically for the intranet site on port 8090

Write-Host "Starting iBridge Intranet Server on port 8090..." -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Yellow
Write-Host "Access the intranet at: http://localhost:8090/" -ForegroundColor Cyan
Write-Host "Direct links:" -ForegroundColor Cyan
Write-Host " - Dashboard: http://localhost:8090/index.html" -ForegroundColor White
Write-Host " - Company Profile: http://localhost:8090/company.html" -ForegroundColor White
Write-Host " - Directory: http://localhost:8090/directory.html" -ForegroundColor White
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Red
Write-Host "===============================================" -ForegroundColor Yellow

# Ensure http-server is installed globally
try {
    $httpServerVersion = npm list -g http-server
    if (-not $httpServerVersion.Contains("http-server")) {
        Write-Host "Installing http-server..." -ForegroundColor Yellow
        npm install -g http-server
    }
} catch {
    Write-Host "Installing http-server..." -ForegroundColor Yellow
    npm install -g http-server
}

# Change to the intranet directory
Set-Location -Path "$PSScriptRoot\intranet"
Write-Host "Server root directory: $(Get-Location)" -ForegroundColor Magenta

# Open browser automatically to intranet home page
Start-Process "http://localhost:8090/index.html"

# Start the server with CORS enabled and no caching
Write-Host "Starting server..." -ForegroundColor Green
http-server -p 8090 -c-1 --cors
