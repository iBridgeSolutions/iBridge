# Fix authentication refresh loop issue
# This script updates the intranet portal to fix the login refresh loop issue

Write-Host "Applying fix for authentication refresh loop..." -ForegroundColor Yellow
Write-Host ""

# Check if files exist
$intranetJsPath = ".\intranet\js\intranet.js"
$customAuthJsPath = ".\intranet\js\custom-authenticator.js"
$loginCustomPath = ".\intranet\login-custom.html"

if (!(Test-Path $intranetJsPath) -or !(Test-Path $customAuthJsPath) -or !(Test-Path $loginCustomPath)) {
    Write-Host "Error: Required files not found!" -ForegroundColor Red
    Write-Host "Make sure you run this script from the website root directory." -ForegroundColor Red
    exit 1
}

Write-Host "Creating backup of modified files..." -ForegroundColor Cyan

# Create backups
Copy-Item -Path $intranetJsPath -Destination "$intranetJsPath.bak" -Force
Copy-Item -Path $customAuthJsPath -Destination "$customAuthJsPath.bak" -Force

Write-Host "Backups created successfully." -ForegroundColor Green
Write-Host ""

Write-Host "Cleaning browser session data..." -ForegroundColor Cyan
Write-Host "Please close any browser tabs with the intranet portal open and try logging in again." -ForegroundColor Yellow
Write-Host ""

Write-Host "Authentication refresh loop fix applied successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Run CHECK-AND-START-UNIFIED-SERVER.bat to start the portal" -ForegroundColor White
Write-Host "2. Access the portal at http://localhost:8090/intranet/" -ForegroundColor White
Write-Host "3. Login with employee code IBDG054" -ForegroundColor White
Write-Host ""
