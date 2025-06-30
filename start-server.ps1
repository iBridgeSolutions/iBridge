# Simple server script for iBridge website
# This will serve the entire website folder on port 8090

Write-Host "Starting iBridge Website Server on port 8090..."
Write-Host "==============================================="
Write-Host "Access the website at: http://localhost:8090"
Write-Host "Access the intranet at: http://localhost:8090/intranet/"
Write-Host "Press Ctrl+C to stop the server"
Write-Host "==============================================="

# Ensure http-server is installed
try {
    $httpServerVersion = npm list -g http-server
    Write-Host "Using http-server: $httpServerVersion"
} catch {
    Write-Host "Installing http-server..."
    npm install -g http-server
}

# Kill any existing node processes that might be using the port
$nodeProcesses = Get-Process -Name "node" -ErrorAction SilentlyContinue
if ($nodeProcesses) {
    Write-Host "Stopping existing node processes..."
    Stop-Process -Name "node" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
}

Write-Host "Starting server from: $(Get-Location)"
Write-Host "==============================================="

# Start the server with log output
http-server -p 8090 --cors -c-1
