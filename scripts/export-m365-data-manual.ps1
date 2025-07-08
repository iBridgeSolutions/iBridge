# Script to manually export M365 data without Graph API
param(
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = ".\intranet\data\mirrored"
)

# Ensure output directory exists
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force
}

# Connect to Exchange Online
try {
    Write-Host "Connecting to Exchange Online..."
    $null = Connect-ExchangeOnline -ShowBanner:$false

    # Export calendar data
    Write-Host "Exporting calendar data..."
    $startDate = (Get-Date).AddDays(-30)
    $endDate = (Get-Date).AddDays(90)
    
    $calendarEvents = Get-CalendarView -StartDate $startDate -EndDate $endDate |
        Select-Object Subject, Start, End, Location, Organizer, @{
            Name='Attendees';
            Expression={($_.RequiredAttendees + $_.OptionalAttendees) -join ';'}
        }

    # Convert to the format expected by the calendar
    $formattedEvents = $calendarEvents | ForEach-Object {
        @{
            title = $_.Subject
            startDateTime = $_.Start.ToString('yyyy-MM-ddTHH:mm:ss')
            endDateTime = $_.End.ToString('yyyy-MM-ddTHH:mm:ss')
            location = $_.Location
            organizer = $_.Organizer
            attendees = $_.Attendees -split ';' | Where-Object { $_ }
            type = 'meeting'
            isAllDay = $_.Start.Date -eq $_.Start -and $_.End.Date -eq $_.End
        }
    }

    # Save to JSON
    $calendarPath = Join-Path $OutputPath "calendar-events.json"
    $formattedEvents | ConvertTo-Json -Depth 10 | Set-Content $calendarPath -Force
    Write-Host "Calendar data exported to: $calendarPath"

    # Export user directory data
    Write-Host "Exporting directory data..."
    $users = Get-User -ResultSize Unlimited | 
        Select-Object DisplayName, Title, Department, Office, WindowsEmailAddress, 
            @{Name='Manager';Expression={(Get-User $_.Manager).DisplayName}},
            @{Name='EmployeeId';Expression={$_.CustomAttribute1}} |
        Where-Object { $_.WindowsEmailAddress -like "*@ibridge.co.za" } |
        Sort-Object DisplayName

    # Save user directory to JSON
    $usersPath = Join-Path $OutputPath "directory-users.json"
    $users | ConvertTo-Json -Depth 10 | Set-Content $usersPath -Force
    Write-Host "Directory data exported to: $usersPath"

    # Export shared mailboxes and resources
    Write-Host "Exporting shared resources..."
    $sharedResources = Get-Mailbox -RecipientTypeDetails SharedMailbox,RoomMailbox |
        Select-Object DisplayName, PrimarySmtpAddress, RecipientTypeDetails |
        Sort-Object RecipientTypeDetails, DisplayName

    $resourcesPath = Join-Path $OutputPath "shared-resources.json"
    $sharedResources | ConvertTo-Json -Depth 10 | Set-Content $resourcesPath -Force
    Write-Host "Shared resources exported to: $resourcesPath"

    # Export distribution groups
    Write-Host "Exporting distribution groups..."
    $groups = Get-DistributionGroup |
        Select-Object DisplayName, PrimarySmtpAddress, 
            @{Name='Members';Expression={(Get-DistributionGroupMember $_.Identity).DisplayName}} |
        Sort-Object DisplayName

    $groupsPath = Join-Path $OutputPath "distribution-groups.json"
    $groups | ConvertTo-Json -Depth 10 | Set-Content $groupsPath -Force
    Write-Host "Distribution groups exported to: $groupsPath"
        Where-Object { $_.DisplayName }

    $directoryPath = Join-Path $OutputPath "directory-data.json"
    $users | ConvertTo-Json -Depth 10 | Set-Content $directoryPath -Force
    Write-Host "Directory data exported to: $directoryPath"

    # Disconnect from Exchange Online
    Disconnect-ExchangeOnline -Confirm:$false
    Write-Host "Export completed successfully!"

} catch {
    Write-Error "Error during export: $_"
    exit 1
}
