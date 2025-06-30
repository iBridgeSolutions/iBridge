# iBridge Website Server Script
# This script runs a local server for the entire website on port 8090

Write-Host "Starting iBridge Website Server on port 8090..."
Write-Host "==============================================="
Write-Host "Access the website at: http://localhost:8090"
Write-Host "Access the intranet at: http://localhost:8090/intranet/"
Write-Host "Press Ctrl+C to stop the server"
Write-Host "==============================================="

# Use the project root directory
# Open browser automatically to intranet page
Start-Process "http://localhost:8090/intranet/index.html"

# Start the server
http-server -p 8090 -c-1 --cors
