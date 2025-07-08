# Simple script to disable development mode in iBridge Portal settings
# This ensures the portal uses real Microsoft 365 data

Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "         iBridge Portal - Switch to Real Microsoft 365 Data" -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host ""

# Update settings.json
$settingsPath = ".\intranet\data\settings.json"
if (Test-Path $settingsPath) {
    try {
        Write-Host "Reading current settings..." -ForegroundColor Blue
        $settings = Get-Content -Path $settingsPath -Raw | ConvertFrom-Json
        
        Write-Host "Current settings:" -ForegroundColor Yellow
        Write-Host "- Development Mode: $($settings.devMode)" -ForegroundColor $(if ($settings.devMode) { "Yellow" } else { "Green" })
        Write-Host "- Using M365 Data: $($settings.useM365Data)" -ForegroundColor $(if ($settings.useM365Data) { "Green" } else { "Yellow" })
        Write-Host "- Admin Email: $($settings.microsoftConfig.adminEmail)" -ForegroundColor White
        
        Write-Host "`nUpdating settings to use real Microsoft 365 data..." -ForegroundColor Blue
        
        # Update settings
        $settings.devMode = $false
        $settings.useM365Data = $true
        $settings.dateUpdated = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        
        # Write updated settings back to file
        $settings | ConvertTo-Json -Depth 10 | Set-Content -Path $settingsPath
        
        Write-Host "`nSettings updated successfully!" -ForegroundColor Green
        Write-Host "- Development Mode: $($settings.devMode)" -ForegroundColor $(if ($settings.devMode) { "Yellow" } else { "Green" })
        Write-Host "- Using M365 Data: $($settings.useM365Data)" -ForegroundColor $(if ($settings.useM365Data) { "Green" } else { "Yellow" })
        Write-Host "- Date Updated: $($settings.dateUpdated)" -ForegroundColor White
        
    } catch {
        Write-Host "Error updating settings: $_" -ForegroundColor Red
    }
} else {
    Write-Host "Error: Settings file not found at $settingsPath" -ForegroundColor Red
}

Write-Host "`n====================================================================" -ForegroundColor Cyan
Write-Host "         Next Steps" -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "1. Go to the Microsoft Entra ID (Azure AD) Admin Center:" -ForegroundColor White
Write-Host "   https://entra.microsoft.com/#view/Microsoft_AAD_RegisteredApps/ApplicationsListBlade" -ForegroundColor Yellow
Write-Host "2. Login with your admin account: lwandile.gasela@ibridge.co.za" -ForegroundColor White
Write-Host "3. Find and select 'iBridge Portal' in the app list" -ForegroundColor White
Write-Host "4. Under 'API permissions', add the following Microsoft Graph permissions:" -ForegroundColor White
Write-Host "   - User.Read (delegated)" -ForegroundColor Yellow
Write-Host "   - User.ReadBasic.All (delegated)" -ForegroundColor Yellow
Write-Host "   - Directory.Read.All (delegated)" -ForegroundColor Yellow
Write-Host "   - Organization.Read.All (delegated)" -ForegroundColor Yellow
Write-Host "   - Group.Read.All (delegated)" -ForegroundColor Yellow
Write-Host "5. Click 'Grant admin consent for (your organization)'" -ForegroundColor White
Write-Host "6. Under 'Authentication', ensure these redirect URIs are added:" -ForegroundColor White
Write-Host "   - http://localhost:8090/intranet/login.html" -ForegroundColor Yellow
Write-Host "   - http://localhost:8090/intranet/" -ForegroundColor Yellow
Write-Host "   - http://localhost:8090/intranet/index.html" -ForegroundColor Yellow
Write-Host "7. Make sure 'Access tokens' and 'ID tokens' are checked" -ForegroundColor White
Write-Host "8. Start the intranet server with: .\START-UNIFIED-SERVER.bat" -ForegroundColor White
Write-Host "9. Visit http://localhost:8090/intranet/ to see real Microsoft 365 data" -ForegroundColor White

Write-Host "`nPress Enter to exit..." -ForegroundColor White
Read-Host
