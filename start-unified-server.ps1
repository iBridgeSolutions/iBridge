# iBridge Unified Server Script
# This script runs a unified server for both main website and intranet on port 8090

# Configuration
$PORT = 8090
$SERVER_ROOT = $PSScriptRoot  # Serve from the root directory

Write-Host "Starting iBridge Unified Server on port $PORT..." -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Yellow
Write-Host "Server Information:" -ForegroundColor Cyan
Write-Host " - Port: $PORT" -ForegroundColor White
Write-Host " - Root directory: $SERVER_ROOT" -ForegroundColor White
Write-Host " - Main website: http://localhost:$PORT/" -ForegroundColor White
Write-Host " - Intranet: http://localhost:$PORT/intranet/" -ForegroundColor White
Write-Host "===============================================" -ForegroundColor Yellow

# Ensure http-server is installed
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

# Kill any existing node processes that might be using the port
$portInUse = Get-NetTCPConnection -LocalPort $PORT -ErrorAction SilentlyContinue
if ($portInUse) {
    Write-Host "Port $PORT is in use. Attempting to free it..." -ForegroundColor Yellow
    $process = Get-Process -Id $portInUse.OwningProcess -ErrorAction SilentlyContinue
    if ($process) {
        Write-Host "Found process using port ${PORT}: $($process.ProcessName) (ID: $($process.Id))" -ForegroundColor Cyan
        try {
            Stop-Process -Id $portInUse.OwningProcess -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
            Write-Host "Process stopped" -ForegroundColor Green
        } catch {
            Write-Host "Could not stop process. You may need to close it manually." -ForegroundColor Red
        }
    }
}

# Set location to the server root
Set-Location -Path $SERVER_ROOT

# Open browser automatically to intranet page
$startUrl = "http://localhost:$PORT/intranet/"
Write-Host "Opening browser to: $startUrl" -ForegroundColor Cyan
Start-Process $startUrl

# Start the server with CORS enabled and no caching
Write-Host "Starting server from: $(Get-Location)" -ForegroundColor Magenta
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Red
Write-Host "===============================================" -ForegroundColor Yellow

http-server -p $PORT -c-1 --cors
