# get-calendar-events.ps1
# This script retrieves all calendar events from the JSON file

# Set up paths
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$dataPath = Join-Path $scriptPath "intranet\data"
$eventsFilePath = Join-Path $dataPath "user-events.json"

# Check if the file exists
if (Test-Path $eventsFilePath) {
    # Read and return the events
    $eventsJson = Get-Content -Path $eventsFilePath -Raw
    if ($eventsJson) {
        try {
            # Validate JSON by attempting to convert it
            $null = $eventsJson | ConvertFrom-Json
            return $eventsJson
        } catch {
            Write-Error "Error parsing events: $_"
            return "[]"
        }
    } else {
        return "[]"
    }
} else {
    # Create an empty file
    "[]" | Out-File -FilePath $eventsFilePath -Encoding utf8
    return "[]"
}
