# Setup-Custom-Calendar.ps1
# This script updates the calendar.html file to use the custom calendar system instead of Microsoft 365

param (
    [switch]$Force = $false
)

# Define paths
$scriptPath = Split-Path -Parent $MyInvocation.MyScriptLocation
$intranetRootPath = Join-Path $scriptPath "intranet"
$calendarHtmlPath = Join-Path $intranetRootPath "calendar.html"
$backupPath = Join-Path $intranetRootPath "calendar.html.bak"

# Ensure we have a calendar.html file to work with
if (-not (Test-Path $calendarHtmlPath)) {
    Write-Host "Error: calendar.html file not found at $calendarHtmlPath" -ForegroundColor Red
    exit 1
}

# Backup the original file if it doesn't exist already
if ((-not (Test-Path $backupPath)) -or $Force) {
    Write-Host "Creating backup of calendar.html..." -ForegroundColor Yellow
    Copy-Item -Path $calendarHtmlPath -Destination $backupPath -Force
    Write-Host "Backup created at $backupPath" -ForegroundColor Green
}

# Read the calendar.html content
$calendarHtml = Get-Content -Path $calendarHtmlPath -Raw

# Check if the file already uses the custom calendar system
if ($calendarHtml -match 'calendar-custom-loader\.js' -and -not $Force) {
    Write-Host "Calendar already uses the custom system. Use -Force to apply changes anyway." -ForegroundColor Yellow
    exit 0
}

# Remove Microsoft authentication scripts
$msalPattern = '<script src=".*msal.*\.js.*?></script>'
$calendarHtml = $calendarHtml -replace $msalPattern, ''

$graphPattern = '<script src=".*graph.*\.js.*?></script>'
$calendarHtml = $calendarHtml -replace $graphPattern, ''

$authConfigPattern = '<script src=".*auth-config\.js.*?></script>'
$calendarHtml = $calendarHtml -replace $authConfigPattern, ''

$msAuthPattern = '<script src=".*ms-auth\.js.*?></script>'
$calendarHtml = $calendarHtml -replace $msAuthPattern, ''

# Remove any Microsoft authentication UI elements
$signInButtonPattern = '<div class="[^"]*" id="sign-in-button-container".*?</div>'
$calendarHtml = $calendarHtml -replace $signInButtonPattern, ''

# Remove Microsoft Graph calendar initialization code
$graphCalendarPattern = '(?s)// Initialize MS Graph and load calendar.*?// End of MS Graph calendar initialization'
$calendarHtml = $calendarHtml -replace $graphCalendarPattern, '// Calendar initialization handled by calendar-custom-loader.js'

# Add our custom calendar loader script before the closing body tag
if (-not ($calendarHtml -match 'calendar-custom-loader\.js')) {
    $customCalendarScriptTag = '<script src="js/calendar-custom-loader.js"></script>'
    $calendarHtml = $calendarHtml -replace '</body>', "$customCalendarScriptTag`r`n</body>"
}

# Write the updated content back to the file
Set-Content -Path $calendarHtmlPath -Value $calendarHtml

Write-Host "Calendar updated to use custom calendar system!" -ForegroundColor Green
Write-Host "Original calendar.html backed up to $backupPath" -ForegroundColor Cyan
