# Alternative server script for iBridge website using port 3000
# This will serve the entire website folder on port 3000

Write-Host "Starting iBridge Website Server on port 3000..."
Write-Host "==============================================="
Write-Host "Access the website at: http://localhost:3000"
Write-Host "Access the intranet at: http://localhost:3000/intranet/"
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

# Start the server with log output
Write-Host "Starting server from: $(Get-Location)"
Write-Host "==============================================="

# Try to use a different port
http-server -p 3000 --cors -c-1
