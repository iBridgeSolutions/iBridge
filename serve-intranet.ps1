# iBridge Intranet Server Script
# This script runs a local server for the intranet site on port 8090

Write-Host "Starting iBridge Intranet Server on port 8090..."
Write-Host "==============================================="
Write-Host "Access the intranet at: http://localhost:8090/index.html"
Write-Host "Press Ctrl+C to stop the server"
Write-Host "==============================================="

# Change to the intranet directory
Set-Location -Path "$PSScriptRoot\intranet"

# Open browser automatically to login page
Start-Process "http://localhost:8090/index.html"

# Start the server
http-server -p 8090 -c-1 --cors
