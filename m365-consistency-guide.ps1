# Microsoft 365 Data Consistency Guide
# This document provides guidance for maintaining consistent data between Microsoft 365 and the intranet

Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "         iBridge Microsoft 365 Data Consistency Guide" -ForegroundColor Cyan
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host ""

# Display intro
Write-Host "This guide helps you maintain consistent data between Microsoft 365 and your intranet portal." -ForegroundColor White
Write-Host "Regular synchronization ensures that your employee directory, company profile, and" -ForegroundColor White
Write-Host "department information stays up-to-date across all platforms." -ForegroundColor White
Write-Host ""

# Step 1: Regular Synchronization
Write-Host "Step 1: Regular Synchronization" -ForegroundColor Green
Write-Host "-------------------------------------------------------------------------" -ForegroundColor Yellow
Write-Host "Schedule regular syncs between Microsoft 365 and your intranet using:" -ForegroundColor White
Write-Host "  • For manual sync: Run SYNC-M365-DATA.bat" -ForegroundColor White
Write-Host "  • For scheduled sync: Create a Windows Task Scheduler task to run sync-m365-dev-data.ps1" -ForegroundColor White
Write-Host ""
Write-Host "Recommended sync frequency:" -ForegroundColor White
Write-Host "  • Small organizations (< 50 employees): Weekly" -ForegroundColor White
Write-Host "  • Medium organizations (50-200 employees): Twice weekly" -ForegroundColor White
Write-Host "  • Large organizations (> 200 employees): Daily" -ForegroundColor White
Write-Host ""

# Step 2: Data Verification
Write-Host "Step 2: Data Verification" -ForegroundColor Green
Write-Host "-------------------------------------------------------------------------" -ForegroundColor Yellow
Write-Host "After each sync, verify that data is consistent using:" -ForegroundColor White
Write-Host "  • Run VERIFY-M365-INTEGRATION.bat" -ForegroundColor White
Write-Host "  • Check that employee counts match between Microsoft 365 and the intranet" -ForegroundColor White
Write-Host "  • Verify profile photos are updated" -ForegroundColor White
Write-Host ""

# Step 3: Data Formatting Standards
Write-Host "Step 3: Data Formatting Standards" -ForegroundColor Green
Write-Host "-------------------------------------------------------------------------" -ForegroundColor Yellow
Write-Host "Maintain consistent data formatting in Microsoft 365 and the intranet:" -ForegroundColor White
Write-Host ""
Write-Host "Employee Information:" -ForegroundColor Cyan
Write-Host "  • Display Names: First Last format (e.g., 'John Smith' not 'Smith, John')" -ForegroundColor White
Write-Host "  • Job Titles: Consistent capitalization (e.g., 'IT Systems Administrator')" -ForegroundColor White
Write-Host "  • Department Names: Match exactly with those in departments.json" -ForegroundColor White
Write-Host ""
Write-Host "Department Information:" -ForegroundColor Cyan
Write-Host "  • Department IDs: Use consistent format (e.g., 'IT-001', 'HR-001')" -ForegroundColor White
Write-Host "  • Each department should have:" -ForegroundColor White
Write-Host "    - Description" -ForegroundColor White
Write-Host "    - Head of Department" -ForegroundColor White
Write-Host "    - Location" -ForegroundColor White
Write-Host "    - Contact Email & Phone" -ForegroundColor White
Write-Host ""

# Step 4: Handling Data Conflicts
Write-Host "Step 4: Handling Data Conflicts" -ForegroundColor Green
Write-Host "-------------------------------------------------------------------------" -ForegroundColor Yellow
Write-Host "When conflicts occur between Microsoft 365 and intranet data:" -ForegroundColor White
Write-Host "1. Microsoft 365 data should be considered the source of truth" -ForegroundColor White
Write-Host "2. Use manual edits only for data that doesn't exist in Microsoft 365" -ForegroundColor White
Write-Host "3. Document any manual changes in the commit history" -ForegroundColor White
Write-Host ""

# Step 5: Moving from Dev Mode to Production
Write-Host "Step 5: Moving from Dev Mode to Production" -ForegroundColor Green
Write-Host "-------------------------------------------------------------------------" -ForegroundColor Yellow
Write-Host "When ready to switch from development mode to production:" -ForegroundColor White
Write-Host "1. Register an app in Microsoft Entra ID following ENTRA_INTEGRATION_STEPS.md" -ForegroundColor White
Write-Host "2. Update settings.json:" -ForegroundColor White
Write-Host "   - Set 'devMode' to false" -ForegroundColor White
Write-Host "   - Update 'clientId' and 'tenantId' with your registered app values" -ForegroundColor White
Write-Host "3. Run fetch-company-data.ps1 (not sync-m365-dev-data.ps1)" -ForegroundColor White
Write-Host ""

# Summary
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "                   Summary of Best Practices" -ForegroundColor Green
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "• Sync regularly using provided scripts" -ForegroundColor White
Write-Host "• Verify data after each sync" -ForegroundColor White
Write-Host "• Maintain consistent data formats" -ForegroundColor White
Write-Host "• Treat Microsoft 365 as the source of truth" -ForegroundColor White
Write-Host "• Document any manual changes" -ForegroundColor White
Write-Host ""
Write-Host "For more information, see the documentation in the README.md file." -ForegroundColor White
Write-Host "=====================================================================" -ForegroundColor Cyan

# Offer to create a scheduled task
Write-Host ""
Write-Host "Would you like to set up a scheduled task to automatically sync Microsoft 365 data? (y/n)" -ForegroundColor Yellow
$setupTask = Read-Host
if ($setupTask -eq "y" -or $setupTask -eq "Y") {
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "sync-m365-dev-data.ps1"
    $taskName = "iBridge-M365-Sync"
    $taskDescription = "Sync Microsoft 365 data with the iBridge intranet portal"
    
    # Create a scheduled task
    try {
        # Build the action
        $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$scriptPath`""
        
        # Build the trigger (default: run daily at 7 AM)
        $trigger = New-ScheduledTaskTrigger -Daily -At 7am
        
        # Register the task
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Description $taskDescription -RunLevel Highest
        
        Write-Host "✅ Scheduled task '$taskName' created successfully." -ForegroundColor Green
        Write-Host "   The task will run daily at 7 AM to sync Microsoft 365 data." -ForegroundColor White
    }
    catch {
        Write-Host "❌ Failed to create scheduled task: $_" -ForegroundColor Red
        Write-Host "   You can manually create a scheduled task to run sync-m365-dev-data.ps1" -ForegroundColor Yellow
    }
} else {
    Write-Host "Scheduled task setup skipped. You can manually run SYNC-M365-DATA.bat when needed." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Press Enter to exit..." -ForegroundColor White
Read-Host
