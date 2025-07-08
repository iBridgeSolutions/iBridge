# Microsoft 365 Integration Manager
# This script provides an interactive menu to manage Microsoft 365 integration with the intranet

# Function to display a menu and get user selection
function Show-Menu {
    param (
        [string]$Title = "Microsoft 365 Integration Manager"
    )
    Clear-Host
    Write-Host "=====================================================================" -ForegroundColor Cyan
    Write-Host "         iBridge $Title" -ForegroundColor Cyan
    Write-Host "=====================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1: Sync Microsoft 365 Data (Development Mode)" -ForegroundColor Yellow
    Write-Host "2: Verify Microsoft 365 Integration" -ForegroundColor Yellow
    Write-Host "3: View Data Consistency Guide" -ForegroundColor Yellow
    Write-Host "4: Start Intranet Server" -ForegroundColor Yellow
    Write-Host "5: View Current Integration Status" -ForegroundColor Yellow
    Write-Host "6: Set Up Scheduled Sync" -ForegroundColor Yellow
    Write-Host "7: Validate Intranet Data Files" -ForegroundColor Yellow
    Write-Host "8: Enrich Employee Data" -ForegroundColor Yellow
    Write-Host "Q: Quit" -ForegroundColor Red
    Write-Host ""
}

# Function to read settings.json file
function Get-IntranetSettings {
    $dataPath = ".\intranet\data\settings.json"
    if (Test-Path -Path $dataPath) {
        try {
            $settings = Get-Content -Path $dataPath -Raw | ConvertFrom-Json
            return $settings
        } catch {
            Write-Host "❌ Error reading settings.json: $_" -ForegroundColor Red
            return $null
        }
    } else {
        Write-Host "❌ settings.json file not found at $dataPath" -ForegroundColor Red
        return $null
    }
}

# Function to display current integration status
function Show-IntegrationStatus {
    $settings = Get-IntranetSettings
    
    if ($null -eq $settings) {
        Write-Host "❌ Unable to determine integration status." -ForegroundColor Red
        return
    }
    
    Write-Host "=====================================================================" -ForegroundColor Cyan
    Write-Host "         Microsoft 365 Integration Status" -ForegroundColor Cyan
    Write-Host "=====================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Display mode
    if ($settings.devMode) {
        Write-Host "Mode: DEVELOPMENT (using simulated data)" -ForegroundColor Yellow
    } else {
        Write-Host "Mode: PRODUCTION (using real Microsoft 365 data)" -ForegroundColor Green
    }
    
    # M365 Integration enabled?
    if ($settings.useM365Data) {
        Write-Host "Microsoft 365 Integration: ENABLED" -ForegroundColor Green
    } else {
        Write-Host "Microsoft 365 Integration: DISABLED" -ForegroundColor Red
    }
    
    # Check tenant ID and client ID
    if ($settings.microsoftConfig.tenantId -and $settings.microsoftConfig.clientId) {
        Write-Host "Tenant ID: $($settings.microsoftConfig.tenantId)" -ForegroundColor White
        Write-Host "Client ID: $($settings.microsoftConfig.clientId)" -ForegroundColor White
    } else {
        Write-Host "❌ Missing tenant ID or client ID" -ForegroundColor Red
    }
    
    # Display admin users
    if ($settings.adminUsers -and $settings.adminUsers.Count -gt 0) {
        Write-Host "`nAdmin Users:" -ForegroundColor Cyan
        foreach ($admin in $settings.adminUsers) {
            Write-Host "- $admin" -ForegroundColor White
        }
    }
    
    # Data files status
    Write-Host "`nData Files Status:" -ForegroundColor Cyan
    $dataPath = ".\intranet\data"
    $files = @("organization.json", "employees.json", "departments.json", "settings.json")
    
    foreach ($file in $files) {
        $filePath = Join-Path -Path $dataPath -ChildPath $file
        if (Test-Path -Path $filePath) {
            $lastModified = (Get-Item $filePath).LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
            Write-Host "✓ $file (Last Updated: $lastModified)" -ForegroundColor Green
        } else {
            Write-Host "✗ $file (Not Found)" -ForegroundColor Red
        }
    }
    
    # Profile photos status
    $profilesPath = ".\intranet\images\profiles"
    if (Test-Path -Path $profilesPath) {
        $photos = Get-ChildItem -Path $profilesPath -Filter "*.jpg"
        Write-Host "`nProfile Photos: $($photos.Count) found" -ForegroundColor Green
    } else {
        Write-Host "`n✗ Profile photos directory not found" -ForegroundColor Red
    }
    
    Write-Host "`nLast Data Update: $($settings.dateUpdated)" -ForegroundColor White
    
    Write-Host "`n=====================================================================" -ForegroundColor Cyan
    Write-Host "Press any key to return to the menu..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Function to set up a scheduled task
function Set-ScheduledSync {
    Write-Host "=====================================================================" -ForegroundColor Cyan
    Write-Host "         Set Up Scheduled Microsoft 365 Sync" -ForegroundColor Cyan
    Write-Host "=====================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "This will create a Windows scheduled task to regularly sync Microsoft 365 data." -ForegroundColor Yellow
    Write-Host ""
    
    # Ask for frequency
    Write-Host "How often should the sync run?" -ForegroundColor Cyan
    Write-Host "1: Daily" -ForegroundColor White
    Write-Host "2: Weekly (every Monday)" -ForegroundColor White
    Write-Host "3: Monthly (1st of month)" -ForegroundColor White
    Write-Host "Q: Cancel" -ForegroundColor Red
    
    $choice = Read-Host "Select option"
    
    if ($choice -eq "q" -or $choice -eq "Q") {
        return
    }
    
    # Ask for time
    $time = Read-Host "Enter time to run sync (e.g., 7am, 2pm, 22:00)"
    
    # Set trigger based on choice
    try {
        $taskName = "iBridge-M365-Sync"
        $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "sync-m365-dev-data.ps1"
        $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$scriptPath`""
        
        switch ($choice) {
            "1" { $trigger = New-ScheduledTaskTrigger -Daily -At $time }
            "2" { $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At $time }
            "3" { $trigger = New-ScheduledTaskTrigger -Monthly -DaysOfMonth 1 -At $time }
            default { 
                Write-Host "❌ Invalid option selected" -ForegroundColor Red 
                return
            }
        }
        
        # Register the task
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Description "Sync Microsoft 365 data with iBridge intranet" -RunLevel Highest -Force
        
        Write-Host "`n✅ Scheduled task '$taskName' created successfully!" -ForegroundColor Green
        
        # Show frequency message
        $freqMessage = switch ($choice) {
            "1" { "daily at $time" }
            "2" { "weekly on Mondays at $time" }
            "3" { "monthly on the 1st day at $time" }
        }
        Write-Host "   The sync will run $freqMessage" -ForegroundColor White
    } catch {
        Write-Host "`n❌ Failed to create scheduled task: $_" -ForegroundColor Red
        Write-Host "   You may need administrator privileges to create a scheduled task." -ForegroundColor Yellow
    }
    
    Write-Host "`nPress any key to return to the menu..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Main menu loop
do {
    Show-Menu
    $selection = Read-Host "Please make a selection"
    
    switch ($selection) {
        '1' {
            Clear-Host
            Write-Host "Running Microsoft 365 Sync..." -ForegroundColor Yellow
            & "$PSScriptRoot\sync-m365-dev-data.ps1"
            Write-Host "Press any key to return to the menu..." -ForegroundColor Yellow
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        '2' {
            Clear-Host
            Write-Host "Verifying Microsoft 365 Integration..." -ForegroundColor Yellow
            & "$PSScriptRoot\verify-m365-integration.ps1"
            Write-Host "Press any key to return to the menu..." -ForegroundColor Yellow
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        '3' {
            Clear-Host
            Write-Host "Displaying Data Consistency Guide..." -ForegroundColor Yellow
            & "$PSScriptRoot\m365-consistency-guide.ps1"
        }
        '4' {
            Clear-Host
            Write-Host "Starting Intranet Server..." -ForegroundColor Yellow
            Start-Process "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$PSScriptRoot\start-unified-server.ps1`"" -NoNewWindow
            Write-Host "✅ Server started. Access the intranet at http://localhost:8090/intranet/" -ForegroundColor Green
            Write-Host "Press any key to return to the menu..." -ForegroundColor Yellow
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        '5' {
            Clear-Host
            Show-IntegrationStatus
        }
        '6' {
            Clear-Host
            Set-ScheduledSync
        }
        '7' {
            Clear-Host
            Write-Host "Validating Intranet Data Files..." -ForegroundColor Yellow
            & "$PSScriptRoot\validate-intranet-data.ps1"
            Write-Host "Press any key to return to the menu..." -ForegroundColor Yellow
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        '8' {
            Clear-Host
            Write-Host "Enriching Employee Data..." -ForegroundColor Yellow
            & "$PSScriptRoot\enrich-employee-data.ps1"
            Write-Host "Press any key to return to the menu..." -ForegroundColor Yellow
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        'q' {
            return
        }
        'Q' {
            return
        }
    }
} while ($selection -ne 'q' -and $selection -ne 'Q')
