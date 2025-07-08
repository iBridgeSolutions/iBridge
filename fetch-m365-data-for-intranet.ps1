# fetch-m365-data-for-intranet.ps1
# Script to fetch Microsoft 365 data for display on intranet site
# This script creates JSON files that can be consumed by your intranet website

param (
    [switch]$Calendar = $false,
    [switch]$SharePointNews = $false,
    [switch]$UserDirectory = $false,
    [switch]$DocumentLibraries = $false,
    [switch]$TeamSites = $false,
    [switch]$All = $false
)

# Set up paths
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$dataPath = Join-Path $scriptPath "intranet\data\m365"
$mirrorPath = Join-Path $dataPath "mirrored"

# Ensure directories exist
if (-not (Test-Path $dataPath)) {
    New-Item -ItemType Directory -Path $dataPath -Force | Out-Null
}
if (-not (Test-Path $mirrorPath)) {
    New-Item -ItemType Directory -Path $mirrorPath -Force | Out-Null
}

# Check if modules are installed
function Check-ModuleInstalled {
    param (
        [string]$ModuleName
    )
    
    if (Get-Module -ListAvailable -Name $ModuleName) {
        return $true
    } else {
        return $false
    }
}

# Install required modules if not present
function Install-RequiredModules {
    $modules = @(
        "Microsoft.Graph.Authentication",
        "Microsoft.Graph.Users",
        "Microsoft.Graph.Groups",
        "Microsoft.Graph.Sites",
        "Microsoft.Graph.Calendar",
        "Microsoft.Graph.Files"
    )

    foreach ($module in $modules) {
        if (-not (Check-ModuleInstalled -ModuleName $module)) {
            Write-Host "Installing $module module..." -ForegroundColor Cyan
            Install-Module -Name $module -Scope CurrentUser -Force
        } else {
            Write-Host "$module is already installed." -ForegroundColor Green
        }
    }
}

# Connect to Microsoft Graph with required scopes
function Connect-ToMicrosoftGraph {
    $scopes = @(
        "User.Read.All", 
        "Directory.Read.All", 
        "Group.Read.All",
        "Sites.Read.All",
        "Calendars.Read",
        "Files.Read.All"
    )
    
    try {
        Write-Host "Connecting to Microsoft Graph API..." -ForegroundColor Cyan
        Connect-MgGraph -Scopes $scopes
        
        # Check if connection was successful
        $context = Get-MgContext
        if ($null -eq $context) {
            Write-Error "Failed to connect to Microsoft Graph."
            return $false
        }
        
        Write-Host "Successfully connected to Microsoft Graph as: $($context.Account)" -ForegroundColor Green
        return $true
        
    } catch {
        Write-Error "Error connecting to Microsoft Graph: $_"
        return $false
    }
}

# Fetch calendar events for the current user
function Fetch-CalendarEvents {
    param (
        [int]$Days = 30
    )
    
    try {
        Write-Host "Fetching calendar events for the next $Days days..." -ForegroundColor Cyan
        $startDate = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
        $endDate = (Get-Date).AddDays($Days).ToString("yyyy-MM-ddTHH:mm:ss")
        
        $events = Get-MgUserCalendarView -UserId $me.Id -StartDateTime $startDate -EndDateTime $endDate -Top 100
        
        $formattedEvents = @()
        foreach ($event in $events) {
            $formattedEvents += @{
                id = $event.Id
                subject = $event.Subject
                startDateTime = $event.Start.DateTime
                endDateTime = $event.End.DateTime
                location = $event.Location.DisplayName
                organizer = $event.Organizer.EmailAddress.Name
                isAllDay = $event.IsAllDay
                sensitivity = $event.Sensitivity
                showAs = $event.ShowAs
                attendees = @($event.Attendees | ForEach-Object { $_.EmailAddress.Name })
                type = if ($event.Categories -contains "Meeting") { "meeting" } else { "event" }
            }
        }
        
        $outputPath = Join-Path $mirrorPath "calendar-events.json"
        $formattedEvents | ConvertTo-Json -Depth 5 | Out-File -FilePath $outputPath -Encoding utf8
        
        Write-Host "Calendar events saved to: $outputPath" -ForegroundColor Green
        return $formattedEvents
    } catch {
        Write-Error "Error fetching calendar events: $_"
        return @()
    }
}

# Fetch SharePoint news
function Fetch-SharePointNews {
    try {
        Write-Host "Fetching SharePoint news articles..." -ForegroundColor Cyan
        
        # Get root SharePoint site (or you could specify a specific site)
        $sites = Get-MgSite -Search "*" -Filter "SiteCollection/Root ne null"
        $newsArticles = @()
        
        foreach ($site in $sites) {
            try {
                # In a real implementation, you'd use more specific Microsoft Graph calls to get news
                # This is a simplified version
                $sitePages = Get-MgSitePage -SiteId $site.Id -Filter "Name eq 'SitePages'" -Top 20
                
                foreach ($page in $sitePages) {
                    # Check if it's a news page (in real implementation, check page properties)
                    if ($page.Name -like "News*") {
                        $newsArticles += @{
                            id = $page.Id
                            title = $page.Title
                            url = $page.WebUrl
                            site = $site.DisplayName
                            createdAt = $page.CreatedDateTime
                            modifiedAt = $page.LastModifiedDateTime
                            author = $page.LastModifiedBy.User.DisplayName
                            preview = "News article preview" # In real implementation, extract content
                        }
                    }
                }
            } catch {
                Write-Warning "Couldn't retrieve news from site $($site.DisplayName): $_"
            }
        }
        
        $outputPath = Join-Path $mirrorPath "sharepoint-news.json"
        $newsArticles | ConvertTo-Json -Depth 5 | Out-File -FilePath $outputPath -Encoding utf8
        
        Write-Host "SharePoint news saved to: $outputPath" -ForegroundColor Green
        return $newsArticles
    } catch {
        Write-Error "Error fetching SharePoint news: $_"
        return @()
    }
}

# Fetch user directory
function Fetch-UserDirectory {
    try {
        Write-Host "Fetching user directory information..." -ForegroundColor Cyan
        
        $users = Get-MgUser -Filter "AccountEnabled eq true" -Property Id, DisplayName, UserPrincipalName, Mail, JobTitle, Department, BusinessPhones, OfficeLocation, MobilePhone -Top 100
        
        $formattedUsers = @()
        foreach ($user in $users) {
            $formattedUsers += @{
                id = $user.Id
                displayName = $user.DisplayName
                email = $user.Mail
                username = $user.UserPrincipalName
                jobTitle = $user.JobTitle
                department = $user.Department
                phone = if ($user.BusinessPhones.Count -gt 0) { $user.BusinessPhones[0] } else { "" }
                mobilePhone = $user.MobilePhone
                office = $user.OfficeLocation
            }
        }
        
        $outputPath = Join-Path $mirrorPath "user-directory.json"
        $formattedUsers | ConvertTo-Json -Depth 5 | Out-File -FilePath $outputPath -Encoding utf8
        
        Write-Host "User directory saved to: $outputPath" -ForegroundColor Green
        return $formattedUsers
    } catch {
        Write-Error "Error fetching user directory: $_"
        return @()
    }
}

# Fetch document libraries
function Fetch-DocumentLibraries {
    param (
        [int]$MaxSites = 5,
        [int]$MaxDocs = 20
    )
    
    try {
        Write-Host "Fetching document libraries..." -ForegroundColor Cyan
        
        $sites = Get-MgSite -Search "*" -Top $MaxSites
        $libraries = @()
        
        foreach ($site in $sites) {
            try {
                # Get document libraries (drives) for the site
                $drives = Get-MgSiteDrive -SiteId $site.Id
                
                foreach ($drive in $drives) {
                    $driveInfo = @{
                        id = $drive.Id
                        name = $drive.Name
                        description = $drive.Description
                        siteId = $site.Id
                        siteName = $site.DisplayName
                        webUrl = $drive.WebUrl
                        documents = @()
                    }
                    
                    # Get documents in the root of each library
                    $rootItems = Get-MgDriveItem -DriveId $drive.Id -Top $MaxDocs
                    
                    foreach ($item in $rootItems) {
                        if ($item.File) {
                            $driveInfo.documents += @{
                                id = $item.Id
                                name = $item.Name
                                webUrl = $item.WebUrl
                                size = $item.Size
                                createdAt = $item.CreatedDateTime
                                modifiedAt = $item.LastModifiedDateTime
                                modifiedBy = $item.LastModifiedBy.User.DisplayName
                            }
                        }
                    }
                    
                    $libraries += $driveInfo
                }
            } catch {
                Write-Warning "Couldn't retrieve document libraries for site $($site.DisplayName): $_"
            }
        }
        
        $outputPath = Join-Path $mirrorPath "document-libraries.json"
        $libraries | ConvertTo-Json -Depth 5 | Out-File -FilePath $outputPath -Encoding utf8
        
        Write-Host "Document libraries saved to: $outputPath" -ForegroundColor Green
        return $libraries
    } catch {
        Write-Error "Error fetching document libraries: $_"
        return @()
    }
}

# Fetch team sites
function Fetch-TeamSites {
    try {
        Write-Host "Fetching team sites..." -ForegroundColor Cyan
        
        $sites = Get-MgSite -Search "*" -Filter "SiteCollection/Root ne null"
        $teamSites = @()
        
        foreach ($site in $sites) {
            # Check if it's a team site (has a connected group)
            if ($null -ne $site.Group) {
                $teamSites += @{
                    id = $site.Id
                    displayName = $site.DisplayName
                    description = $site.Description
                    webUrl = $site.WebUrl
                    createdAt = $site.CreatedDateTime
                    lastModifiedAt = $site.LastModifiedDateTime
                    groupId = $site.Group.Id
                }
            }
        }
        
        $outputPath = Join-Path $mirrorPath "team-sites.json"
        $teamSites | ConvertTo-Json -Depth 5 | Out-File -FilePath $outputPath -Encoding utf8
        
        Write-Host "Team sites saved to: $outputPath" -ForegroundColor Green
        return $teamSites
    } catch {
        Write-Error "Error fetching team sites: $_"
        return @()
    }
}

# Main execution
Clear-Host
Write-Host "Microsoft 365 Data Fetcher for Intranet" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

# Check and install required modules
Install-RequiredModules

# Connect to Microsoft Graph
$connected = Connect-ToMicrosoftGraph
if (-not $connected) {
    Write-Error "Failed to connect to Microsoft Graph. Exiting."
    exit 1
}

# Get current user
$me = Get-MgMe
Write-Host "`nFetching data for: $($me.DisplayName) ($($me.UserPrincipalName))" -ForegroundColor Cyan

# Process based on parameters
if ($Calendar -or $All) {
    Fetch-CalendarEvents -Days 30
}

if ($SharePointNews -or $All) {
    Fetch-SharePointNews
}

if ($UserDirectory -or $All) {
    Fetch-UserDirectory
}

if ($DocumentLibraries -or $All) {
    Fetch-DocumentLibraries
}

if ($TeamSites -or $All) {
    Fetch-TeamSites
}

# If no specific parameters were provided
if (-not ($Calendar -or $SharePointNews -or $UserDirectory -or $DocumentLibraries -or $TeamSites -or $All)) {
    Write-Host "`nNo specific data types selected. Use parameters to specify data to fetch:" -ForegroundColor Yellow
    Write-Host "  -Calendar            : Fetch calendar events" -ForegroundColor Gray
    Write-Host "  -SharePointNews      : Fetch SharePoint news" -ForegroundColor Gray
    Write-Host "  -UserDirectory       : Fetch user directory" -ForegroundColor Gray
    Write-Host "  -DocumentLibraries   : Fetch document libraries" -ForegroundColor Gray
    Write-Host "  -TeamSites           : Fetch team sites" -ForegroundColor Gray
    Write-Host "  -All                 : Fetch all data types" -ForegroundColor Gray
    Write-Host "`nExample: .\fetch-m365-data-for-intranet.ps1 -Calendar -UserDirectory" -ForegroundColor Gray
}

Write-Host "`nDisconnecting from Microsoft Graph..." -ForegroundColor Cyan
Disconnect-MgGraph

Write-Host "`nData fetching complete. JSON files are available in: $mirrorPath" -ForegroundColor Green
