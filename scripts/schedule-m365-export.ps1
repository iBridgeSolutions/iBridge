# Schedule regular M365 data exports
param(
    [Parameter(Mandatory=$false)]
    [string]$TaskName = "iBridge_M365_DataExport",
    [Parameter(Mandatory=$false)]
    [string]$IntervalHours = 4
)

$scriptPath = Join-Path $PSScriptRoot "export-m365-data-manual.ps1"
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Hours $IntervalHours)
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType S4U -RunLevel Highest

# Create or update the scheduled task
$existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($existingTask) {
    Set-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Principal $principal
    Write-Host "Updated existing scheduled task: $TaskName"
} else {
    Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Principal $principal
    Write-Host "Created new scheduled task: $TaskName"
}

Write-Host "M365 data export scheduled to run every $IntervalHours hours"
