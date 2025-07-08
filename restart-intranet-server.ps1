# iBridge Intranet Server Restart Script
# This script stops any running Node.js servers and starts a fresh intranet server

Write-Host "iBridge Intranet Server Manager" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Yellow

# Stop any running Node.js processes
$nodeProcesses = Get-Process -Name "node" -ErrorAction SilentlyContinue
if ($nodeProcesses) {
    Write-Host "Stopping existing node processes..." -ForegroundColor Yellow
    Stop-Process -Name "node" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    Write-Host "Node processes stopped" -ForegroundColor Green
} else {
    Write-Host "No node processes found running" -ForegroundColor Cyan
}

# Check if any process is using port 8090
$portInUse = Get-NetTCPConnection -LocalPort 8090 -ErrorAction SilentlyContinue
if ($portInUse) {
    Write-Host "Port 8090 is in use. Attempting to free it..." -ForegroundColor Yellow
    $process = Get-Process -Id $portInUse.OwningProcess -ErrorAction SilentlyContinue
    if ($process) {
        Write-Host "Found process using port 8090: $($process.ProcessName) (ID: $($process.Id))" -ForegroundColor Cyan
        try {
            Stop-Process -Id $portInUse.OwningProcess -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
            Write-Host "Process stopped" -ForegroundColor Green
        } catch {
            Write-Host "Could not stop process. You may need to close it manually." -ForegroundColor Red
        }
    }
}

Write-Host "Starting iBridge Intranet Server on port 8090..." -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Yellow
Write-Host "Access the intranet at: http://localhost:8090/" -ForegroundColor Cyan
Write-Host "Direct links:" -ForegroundColor Cyan
Write-Host " - Dashboard: http://localhost:8090/index.html" -ForegroundColor White
Write-Host " - Company Profile: http://localhost:8090/company.html" -ForegroundColor White
Write-Host " - Directory: http://localhost:8090/directory.html" -ForegroundColor White
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Red
Write-Host "===============================================" -ForegroundColor Yellow

# Change to the intranet directory
Set-Location -Path "$PSScriptRoot\intranet"
Write-Host "Server root directory: $(Get-Location)" -ForegroundColor Magenta

# Open browser automatically to intranet home page
Start-Process "http://localhost:8090/index.html"

# Start the server with CORS enabled and no caching
Write-Host "Starting server..." -ForegroundColor Green
http-server -p 8090 -c-1 --cors
