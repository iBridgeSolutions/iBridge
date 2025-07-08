# Extract-Files-Data.ps1
# This script extracts files data from Microsoft 365 and mirrors it locally

param (
    [switch]$UseRealData = $false,
    [switch]$UseDevMode = $false
)

# Set paths
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$IntranetRootPath = Join-Path $scriptPath "intranet"
$dataBasePath = Join-Path $IntranetRootPath "data\mirrored\files"
$metadataFile = Join-Path $IntranetRootPath "data\mirrored\files\file-metadata.json"

function Extract-FilesData {
    param (
        [switch]$UseRealData = $false,
        [switch]$UseDevMode = $false
    )

    Write-Host "=========================================="
    Write-Host "      EXTRACTING FILES DATA"
    Write-Host "=========================================="

    # Create directory if it doesn't exist
    if (-not (Test-Path $dataBasePath)) {
        New-Item -ItemType Directory -Path $dataBasePath -Force | Out-Null
        Write-Host "Created directory: $dataBasePath" -ForegroundColor Green
    }

    # Create subdirectories
    $subDirs = @("documents", "presentations", "spreadsheets", "images", "other")
    foreach ($dir in $subDirs) {
        $path = Join-Path $dataBasePath $dir
        if (-not (Test-Path $path)) {
            New-Item -ItemType Directory -Path $path -Force | Out-Null
            Write-Host "Created directory: $path" -ForegroundColor Green
        }
    }

    if ($UseRealData) {
        try {
            # Using Microsoft Graph to fetch files from OneDrive/SharePoint
            # This would require authentication and the Microsoft.Graph module
            Write-Host "Feature not implemented: Real data extraction requires Microsoft Graph SDK" -ForegroundColor Yellow
            Write-Host "Creating sample file data instead..." -ForegroundColor Yellow
            Create-SampleFilesData
        }
        catch {
            Write-Host "Error fetching files from Microsoft 365: $_" -ForegroundColor Red
            Write-Host "Creating sample file data instead..." -ForegroundColor Yellow
            Create-SampleFilesData
        }
    }
    else {
        Write-Host "Creating sample file data..." -ForegroundColor Yellow
        Create-SampleFilesData
    }
}

function Create-SampleFilesData {
    # Sample documents
    $documentFiles = @(
        @{
            name = "Company Handbook.docx"
            type = "document"
            size = 2345678
            created = (Get-Date).AddMonths(-6).ToString("o")
            modified = (Get-Date).AddDays(-5).ToString("o")
            createdBy = "HR Department"
            modifiedBy = "Lwandile Gasela"
            folder = "documents"
            content = "Sample company handbook content"
            path = "documents/Company Handbook.docx"
            webUrl = "#"
            tags = @("handbook", "policies", "guidelines")
        },
        @{
            name = "Project Proposal.docx"
            type = "document"
            size = 567890
            created = (Get-Date).AddMonths(-2).ToString("o")
            modified = (Get-Date).AddDays(-1).ToString("o")
            createdBy = "Business Development"
            modifiedBy = "Lisa van Wyk"
            folder = "documents"
            content = "Sample project proposal content"
            path = "documents/Project Proposal.docx"
            webUrl = "#"
            tags = @("proposal", "project", "business")
        },
        @{
            name = "Meeting Minutes.docx"
            type = "document"
            size = 345678
            created = (Get-Date).AddDays(-14).ToString("o")
            modified = (Get-Date).AddDays(-14).ToString("o")
            createdBy = "Executive Office"
            modifiedBy = "Executive Office"
            folder = "documents"
            content = "Sample meeting minutes content"
            path = "documents/Meeting Minutes.docx"
            webUrl = "#"
            tags = @("meeting", "minutes", "executive")
        }
    )

    # Sample presentations
    $presentationFiles = @(
        @{
            name = "Quarterly Results.pptx"
            type = "presentation"
            size = 4567890
            created = (Get-Date).AddMonths(-3).ToString("o")
            modified = (Get-Date).AddDays(-45).ToString("o")
            createdBy = "Finance Department"
            modifiedBy = "John Smith"
            folder = "presentations"
            content = "Sample quarterly results presentation"
            path = "presentations/Quarterly Results.pptx"
            webUrl = "#"
            tags = @("results", "quarterly", "finance")
        },
        @{
            name = "New Product Launch.pptx"
            type = "presentation"
            size = 3456789
            created = (Get-Date).AddDays(-30).ToString("o")
            modified = (Get-Date).AddDays(-2).ToString("o")
            createdBy = "Marketing Department"
            modifiedBy = "Marketing Department"
            folder = "presentations"
            content = "Sample product launch presentation"
            path = "presentations/New Product Launch.pptx"
            webUrl = "#"
            tags = @("product", "launch", "marketing")
        }
    )

    # Sample spreadsheets
    $spreadsheetFiles = @(
        @{
            name = "Budget 2025.xlsx"
            type = "spreadsheet"
            size = 2345678
            created = (Get-Date).AddMonths(-2).ToString("o")
            modified = (Get-Date).AddDays(-3).ToString("o")
            createdBy = "Finance Department"
            modifiedBy = "Finance Department"
            folder = "spreadsheets"
            content = "Sample budget spreadsheet"
            path = "spreadsheets/Budget 2025.xlsx"
            webUrl = "#"
            tags = @("budget", "finance", "2025")
        },
        @{
            name = "Sales Forecast.xlsx"
            type = "spreadsheet"
            size = 1234567
            created = (Get-Date).AddMonths(-1).ToString("o")
            modified = (Get-Date).AddDays(-7).ToString("o")
            createdBy = "Sales Department"
            modifiedBy = "Lisa van Wyk"
            folder = "spreadsheets"
            content = "Sample sales forecast spreadsheet"
            path = "spreadsheets/Sales Forecast.xlsx"
            webUrl = "#"
            tags = @("sales", "forecast", "revenue")
        }
    )

    # Sample images
    $imageFiles = @(
        @{
            name = "Company Logo.png"
            type = "image"
            size = 456789
            created = (Get-Date).AddMonths(-12).ToString("o")
            modified = (Get-Date).AddMonths(-12).ToString("o")
            createdBy = "Design Team"
            modifiedBy = "Design Team"
            folder = "images"
            content = "Binary image content"
            path = "images/Company Logo.png"
            webUrl = "#"
            tags = @("logo", "branding", "design")
        },
        @{
            name = "Team Photo.jpg"
            type = "image"
            size = 2345678
            created = (Get-Date).AddMonths(-3).ToString("o")
            modified = (Get-Date).AddMonths(-3).ToString("o")
            createdBy = "HR Department"
            modifiedBy = "HR Department"
            folder = "images"
            content = "Binary image content"
            path = "images/Team Photo.jpg"
            webUrl = "#"
            tags = @("photo", "team", "staff")
        }
    )

    # Sample other files
    $otherFiles = @(
        @{
            name = "Product Manual.pdf"
            type = "pdf"
            size = 5678901
            created = (Get-Date).AddMonths(-5).ToString("o")
            modified = (Get-Date).AddMonths(-5).ToString("o")
            createdBy = "Product Team"
            modifiedBy = "Product Team"
            folder = "other"
            content = "Binary PDF content"
            path = "other/Product Manual.pdf"
            webUrl = "#"
            tags = @("manual", "product", "documentation")
        }
    )

    # Combine all files into one array
    $allFiles = $documentFiles + $presentationFiles + $spreadsheetFiles + $imageFiles + $otherFiles

    # Create file metadata JSON
    $metadata = @{
        files = $allFiles
        totalCount = $allFiles.Count
        totalSize = ($allFiles | Measure-Object -Property size -Sum).Sum
        lastUpdated = (Get-Date).ToString("o")
    }

    # Save metadata to JSON file
    $metadata | ConvertTo-Json -Depth 5 | Out-File $metadataFile -Encoding utf8
    Write-Host "Created file metadata at: $metadataFile" -ForegroundColor Green

    # Create placeholder files with minimal content
    foreach ($file in $allFiles) {
        $filePath = Join-Path $dataBasePath $file.path
        $fileDir = Split-Path -Parent $filePath
        
        # Create directory if needed
        if (-not (Test-Path $fileDir)) {
            New-Item -ItemType Directory -Path $fileDir -Force | Out-Null
        }

        # Create file with sample content
        $content = "This is a sample file: $($file.name)`r`n"
        $content += "Created by: $($file.createdBy)`r`n"
        $content += "Modified by: $($file.modifiedBy)`r`n"
        $content += "Created on: $($file.created)`r`n"
        $content += "Modified on: $($file.modified)`r`n"
        $content += "Tags: $($file.tags -join ', ')`r`n`r`n"
        $content += $file.content
        
        Set-Content -Path $filePath -Value $content
    }

    Write-Host "Created $($allFiles.Count) sample files in mirrored directory structure." -ForegroundColor Green
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

# Extract files data
Extract-FilesData -UseRealData:$UseRealData -UseDevMode:$UseDevMode

Write-Host "Files data extraction complete!" -ForegroundColor Green
