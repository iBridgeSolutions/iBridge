# Run the Node.js server for iBridge website

Write-Host "Starting Node.js server for iBridge website..."
Write-Host "==============================================="
Write-Host "Access the website at: http://localhost:8090"
Write-Host "Access the intranet at: http://localhost:8090/intranet/"
Write-Host "Press Ctrl+C to stop the server"
Write-Host "==============================================="

# Kill any existing node processes that might be using the port
$nodeProcesses = Get-Process -Name "node" -ErrorAction SilentlyContinue
if ($nodeProcesses) {
    Write-Host "Stopping existing node processes..."
    Stop-Process -Name "node" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
}

# Run the Node.js server
node server.js
