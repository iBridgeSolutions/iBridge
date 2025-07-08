# Simple script to update settings.json to use real Microsoft 365 data
# This script doesn't require Microsoft Graph authentication

Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "         iBridge Portal - Quick Switch to Real Microsoft 365 Data" -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host ""

# Settings file path
$settingsPath = ".\intranet\data\settings.json"

# Check if settings file exists
if (-not (Test-Path $settingsPath)) {
    Write-Host "❌ Error: Settings file not found at $settingsPath" -ForegroundColor Red
    exit 1
}

try {
    # Read the current settings
    $settings = Get-Content -Path $settingsPath -Raw | ConvertFrom-Json
    
    # Display current settings
    Write-Host "Current settings:" -ForegroundColor Yellow
    Write-Host "  Development Mode: $($settings.devMode ? 'Enabled ❌' : 'Disabled ✅')" -ForegroundColor $(if ($settings.devMode) { "Yellow" } else { "Green" })
    Write-Host "  Using M365 Data:  $($settings.useM365Data ? 'Yes ✅' : 'No ❌')" -ForegroundColor $(if ($settings.useM365Data) { "Green" } else { "Yellow" })
    Write-Host ""
    
    # Only update if in dev mode
    if ($settings.devMode -eq $true) {
        # Update settings to use real data
        $settings.devMode = $false
        $settings.useM365Data = $true
        $settings.dateUpdated = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        
        # Save the updated settings
        $settings | ConvertTo-Json -Depth 10 | Set-Content -Path $settingsPath -Encoding UTF8
        
        Write-Host "✅ Settings updated to use real Microsoft 365 data!" -ForegroundColor Green
        Write-Host "  Development Mode: Disabled ✅" -ForegroundColor Green
        Write-Host "  Using M365 Data:  Yes ✅" -ForegroundColor Green
    }
    else {
        Write-Host "✅ Settings already set to use real Microsoft 365 data!" -ForegroundColor Green
    }
    
    # Check Microsoft 365 configuration
    if ($null -ne $settings.microsoftConfig) {
        Write-Host ""
        Write-Host "Microsoft 365 Configuration:" -ForegroundColor Yellow
        Write-Host "  Admin Email: $($settings.microsoftConfig.adminEmail)" -ForegroundColor White
        Write-Host "  Client ID:   $($settings.microsoftConfig.clientId)" -ForegroundColor White
        Write-Host "  Tenant ID:   $($settings.microsoftConfig.tenantId)" -ForegroundColor White
        
        # Prompt to update Microsoft 365 details
        Write-Host ""
        Write-Host "Do you want to update the Microsoft 365 app registration details? (Y/N)" -ForegroundColor Yellow
        $response = Read-Host
        
        if ($response.ToLower() -eq "y") {
            Write-Host ""
            Write-Host "Enter the Client ID for your app registration:" -ForegroundColor Yellow
            $clientId = Read-Host
            
            Write-Host "Enter the Tenant ID for your Microsoft 365 tenant:" -ForegroundColor Yellow
            $tenantId = Read-Host
            
            # Only update if values provided
            if (-not [string]::IsNullOrWhiteSpace($clientId) -and -not [string]::IsNullOrWhiteSpace($tenantId)) {
                $settings.microsoftConfig.clientId = $clientId
                $settings.microsoftConfig.tenantId = $tenantId
                
                # Save the updated settings
                $settings | ConvertTo-Json -Depth 10 | Set-Content -Path $settingsPath -Encoding UTF8
                
                Write-Host "✅ Microsoft 365 configuration updated successfully!" -ForegroundColor Green
            }
            else {
                Write-Host "❌ No changes made - client ID or tenant ID was not provided." -ForegroundColor Yellow
            }
        }
    }
    
    # Final instructions
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Start the intranet server:" -ForegroundColor White
    Write-Host "   - Run: .\START-UNIFIED-SERVER.bat" -ForegroundColor Yellow
    Write-Host "2. Access the intranet at:" -ForegroundColor White
    Write-Host "   - http://localhost:8090/intranet/" -ForegroundColor Yellow
    Write-Host "3. Log in with your Microsoft 365 account:" -ForegroundColor White
    Write-Host "   - lwandile.gasela@ibridge.co.za" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "Remember: If you encounter authentication issues, you may need to:" -ForegroundColor Cyan
    Write-Host "1. Register your app in Microsoft Entra ID / Azure AD" -ForegroundColor White
    Write-Host "2. Configure redirect URIs in the app registration" -ForegroundColor White
    Write-Host "3. Grant admin consent for API permissions" -ForegroundColor White
    Write-Host ""
    Write-Host "For detailed setup, run the MANUAL-M365-EXTRACTION.bat script" -ForegroundColor White
}
catch {
    Write-Host "❌ Error updating settings: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "Press Enter to exit..." -ForegroundColor White
Read-Host
