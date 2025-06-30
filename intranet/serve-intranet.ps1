# iBridge Intranet Server Script
# This script runs a local server for the intranet site on port 8090

Write-Host "Starting iBridge Intranet Server on port 8090..."
Write-Host "==============================================="
Write-Host "Access the intranet at: http://localhost:8090"
Write-Host "Press Ctrl+C to stop the server"
Write-Host "==============================================="

# Change to the current directory
Set-Location -Path $PSScriptRoot

# Install http-server if not already installed
if (-not (Get-Command http-server -ErrorAction SilentlyContinue)) {
    Write-Host "Installing http-server..."
    npm install -g http-server
}

# Open browser automatically to login page
Start-Process "http://localhost:8090/intranet/login.html"

# Start the server from the parent directory so we can access /intranet routes
Set-Location -Path (Split-Path -Parent $PSScriptRoot)
Write-Host "Serving from directory: $(Get-Location)"
http-server -p 8090 -c-1 --cors
