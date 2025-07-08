# Extract-Calendar-Data.ps1
# This script extracts calendar events from Microsoft 365 and saves them locally

param (
    [switch]$UseRealData = $false,
    [switch]$UseDevMode = $false
)

# Set up paths directly without relying on external scripts
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$IntranetRootPath = Join-Path $scriptPath "intranet"

function Extract-CalendarEvents {
    param (
        [switch]$UseRealData = $false,
        [switch]$UseDevMode = $false
    )

    Write-Host "=========================================="
    Write-Host "      EXTRACTING CALENDAR DATA"
    Write-Host "=========================================="

    # Create directory if it doesn't exist
    $dataDir = Join-Path $IntranetRootPath "data\mirrored"
    if (-not (Test-Path $dataDir)) {
        New-Item -ItemType Directory -Path $dataDir -Force | Out-Null
    }

    $outputFile = Join-Path $dataDir "calendar-events.json"

    if ($UseRealData) {
        try {
            # Using Microsoft Graph to fetch calendar events
            # First, ensure we're connected to Microsoft Graph
            Connect-ToMicrosoftGraph

            Write-Host "Fetching calendar events from Microsoft 365..." -ForegroundColor Yellow

            # Get events for the next 6 months
            $startDate = Get-Date
            $endDate = $startDate.AddMonths(6)
            
            $calendarView = Get-MgUserCalendarView -UserId $global:CurrentUserEmail `
                -StartDateTime $startDate.ToString("o") `
                -EndDateTime $endDate.ToString("o") `
                -Top 100 `
                -All

            if ($calendarView) {
                $events = $calendarView | ForEach-Object {
                    # Determine event type based on categories or other properties
                    $eventType = "other"
                    if ($_.Categories) {
                        # Map categories to our event types
                        if ($_.Categories -contains "Holiday" -or $_.Categories -contains "Out of Office") {
                            $eventType = "holiday"
                        }
                        elseif ($_.Categories -contains "Training") {
                            $eventType = "training"
                        }
                        elseif ($_.Categories -contains "Meeting") {
                            $eventType = "meeting"
                        }
                        elseif ($_.Categories -contains "Deadline") {
                            $eventType = "deadline"
                        }
                        elseif ($_.Categories -contains "Company") {
                            $eventType = "company"
                        }
                        elseif ($_.Categories -contains "Team") {
                            $eventType = "team"
                        }
                        elseif ($_.Categories -contains "Personal") {
                            $eventType = "personal"
                        }
                    }
                    
                    # Generate attendee list
                    $attendees = @()
                    if ($_.Attendees) {
                        $attendees = $_.Attendees | ForEach-Object {
                            if ($_.EmailAddress.Name) { 
                                $_.EmailAddress.Name 
                            } 
                            elseif ($_.EmailAddress.Address) { 
                                $_.EmailAddress.Address 
                            }
                        }
                    }

                    # Create event object
                    @{
                        title = $_.Subject
                        startDateTime = $_.Start.DateTime
                        endDateTime = $_.End.DateTime
                        isAllDay = $_.IsAllDay
                        location = if ($_.Location.DisplayName) { $_.Location.DisplayName } else { "No location" }
                        organizer = if ($_.Organizer.EmailAddress.Name) { $_.Organizer.EmailAddress.Name } else { $_.Organizer.EmailAddress.Address }
                        description = $_.BodyPreview
                        type = $eventType
                        attendees = $attendees
                    }
                }

                # Save events to JSON file
                $events | ConvertTo-Json -Depth 5 | Out-File $outputFile -Encoding utf8
                
                Write-Host "Successfully extracted and saved $($events.Count) calendar events to $outputFile" -ForegroundColor Green
            }
            else {
                Write-Warning "No calendar events found. Creating sample data instead."
                Create-SampleCalendarEvents
            }
        }
        catch {
            Write-Host "Error fetching calendar events from Microsoft 365: $_" -ForegroundColor Red
            Write-Host "Creating sample calendar events instead..." -ForegroundColor Yellow
            Create-SampleCalendarEvents
        }
    }
    else {
        Write-Host "Creating sample calendar events..." -ForegroundColor Yellow
        Create-SampleCalendarEvents
    }
}

function Create-SampleCalendarEvents {
    # Create sample calendar events for testing
    $currentYear = (Get-Date).Year
    $currentMonth = (Get-Date).Month
    $nextMonth = if ($currentMonth -eq 12) { 1 } else { $currentMonth + 1 }
    $nextYear = if ($currentMonth -eq 12) { $currentYear + 1 } else { $currentYear }
    
    $sampleEvents = @(
        @{
            title = "All Staff Meeting"
            startDateTime = "$currentYear-$($currentMonth.ToString('00'))-15T09:00:00"
            endDateTime = "$currentYear-$($currentMonth.ToString('00'))-15T10:30:00"
            isAllDay = $false
            location = "Main Conference Room"
            organizer = "John Smith, CEO"
            description = "Quarterly company update meeting for all staff members. Updates on company performance, new initiatives, and Q&A session."
            type = "company"
            attendees = @("All Staff")
        },
        @{
            title = "Sales Team Review"
            startDateTime = "$currentYear-$($currentMonth.ToString('00'))-22T14:00:00"
            endDateTime = "$currentYear-$($currentMonth.ToString('00'))-22T15:30:00"
            isAllDay = $false
            location = "Meeting Room 2"
            organizer = "Lisa van Wyk, Sales Manager"
            description = "Monthly sales team performance review and goal setting for the next month."
            type = "team"
            attendees = @("Sales Team")
        },
        @{
            title = "Customer Experience Workshop"
            startDateTime = "$currentYear-$($currentMonth.ToString('00'))-25T09:00:00"
            endDateTime = "$currentYear-$($currentMonth.ToString('00'))-25T17:00:00"
            isAllDay = $false
            location = "Training Center"
            organizer = "Thandi Mkhize, HR Manager"
            description = "Full-day workshop focused on improving customer experience strategies and implementing best practices."
            type = "training"
            attendees = @("Contact Center Team", "Sales Team", "Operations Team")
        },
        @{
            title = "Youth Day"
            startDateTime = "$currentYear-06-16T00:00:00"
            endDateTime = "$currentYear-06-16T23:59:59"
            isAllDay = $true
            location = "Public Holiday"
            organizer = "Government of South Africa"
            description = "South African public holiday commemorating the Soweto Uprising. Office closed."
            type = "holiday"
            attendees = @("All Staff")
        },
        @{
            title = "Project Deadline: Q3 Campaign"
            startDateTime = "$currentYear-$($nextMonth.ToString('00'))-10T17:00:00"
            endDateTime = "$currentYear-$($nextMonth.ToString('00'))-10T17:00:00"
            isAllDay = $false
            location = "N/A"
            organizer = "Marketing Department"
            description = "Final submission deadline for all Q3 campaign materials and strategy documents."
            type = "deadline"
            attendees = @("Marketing Team", "Design Team")
        },
        @{
            title = "IT System Maintenance"
            startDateTime = "$nextYear-$($nextMonth.ToString('00'))-05T22:00:00"
            endDateTime = "$nextYear-$($nextMonth.ToString('00'))-06T02:00:00"
            isAllDay = $false
            location = "Server Room"
            organizer = "IT Department"
            description = "Scheduled maintenance window for system updates and security patches. Some services may be unavailable during this time."
            type = "company"
            attendees = @("IT Team")
        },
        @{
            title = "Team Building: Outdoor Adventure"
            startDateTime = "$nextYear-$($nextMonth.ToString('00'))-15T08:00:00"
            endDateTime = "$nextYear-$($nextMonth.ToString('00'))-15T16:00:00"
            isAllDay = $true
            location = "Adventure Outdoors, Sandton"
            organizer = "HR Department"
            description = "Annual team building event featuring outdoor activities, team challenges, and a catered lunch."
            type = "team"
            attendees = @("All Staff")
        }
    )

    # Save sample events to JSON file
    $dataDir = Join-Path $IntranetRootPath "data\mirrored"
    if (-not (Test-Path $dataDir)) {
        New-Item -ItemType Directory -Path $dataDir -Force | Out-Null
    }
    
    $outputFile = Join-Path $dataDir "calendar-events.json"
    $sampleEvents | ConvertTo-Json -Depth 5 | Out-File $outputFile -Encoding utf8
    
    Write-Host "Created sample calendar events in $outputFile" -ForegroundColor Green
}

# Main execution
if ($UseRealData) {
    Write-Host "Using real data from Microsoft 365..." -ForegroundColor Cyan
}
else {
    Write-Host "Using sample data (no Microsoft 365 connection)..." -ForegroundColor Cyan
}

if ($UseDevMode) {
    Write-Host "Running in development mode..." -ForegroundColor Magenta
}

# Extract calendar events
Extract-CalendarEvents -UseRealData:$UseRealData -UseDevMode:$UseDevMode

Write-Host "Calendar data extraction complete!" -ForegroundColor Green
