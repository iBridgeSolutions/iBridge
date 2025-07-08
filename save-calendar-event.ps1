# save-calendar-event.ps1
# This script saves a calendar event to a JSON file

param (
    [Parameter(Mandatory=$true)]
    [string]$EventData
)

# Set up paths
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$dataPath = Join-Path $scriptPath "intranet\data"
$eventsFilePath = Join-Path $dataPath "user-events.json"

# Ensure the directory exists
if (-not (Test-Path $dataPath)) {
    New-Item -ItemType Directory -Path $dataPath -Force | Out-Null
}

# Create the file if it doesn't exist
if (-not (Test-Path $eventsFilePath)) {
    "[]" | Out-File -FilePath $eventsFilePath -Encoding utf8
}

try {
    # Convert the event data from JSON
    $calendarItem = $EventData | ConvertFrom-Json
    
    # Validate required fields
    if (-not $calendarItem.title -or -not $calendarItem.startDateTime -or -not $calendarItem.endDateTime) {
        Write-Error "Invalid event data - missing required fields"
        exit 1
    }
    
    # Read existing events
    $existingEventsJson = Get-Content -Path $eventsFilePath -Raw
    $existingEvents = @()
    
    if ($existingEventsJson) {
        $existingEvents = $existingEventsJson | ConvertFrom-Json
    }
    
    # Add ID and metadata to event
    $calendarItem | Add-Member -MemberType NoteProperty -Name "id" -Value ("evt_" + [Guid]::NewGuid().ToString("N"))
    $calendarItem | Add-Member -MemberType NoteProperty -Name "createdAt" -Value (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    
    # Add the new event to the array
    $existingEvents += $calendarItem
    
    # Save the updated events back to the file
    $existingEvents | ConvertTo-Json -Depth 5 | Out-File -FilePath $eventsFilePath -Encoding utf8
    
    Write-Host "Event saved successfully!" -ForegroundColor Green
    return $calendarItem | ConvertTo-Json
} catch {
    Write-Error "Error saving event: $_"
    exit 1
}
