# GoDaddy FTP Deployment Script for iBridge Website

# Configuration (REPLACE THESE VALUES WITH YOUR ACTUAL CREDENTIALS)
$ftpHost = "ftp.yourdomain.com" # Replace with your FTP hostname
$ftpUser = "your-username" # Replace with your FTP username
$ftpPass = "your-password" # Replace with your FTP password
$localFolder = $PSScriptRoot # Current directory where this script is located
$remoteFolder = "/public_html" # Replace with your remote folder path if different

Write-Host "=== iBridge Website Deployment Tool ==="
Write-Host "This script will deploy the website to GoDaddy hosting"

# Ask for confirmation
$confirmation = Read-Host "Do you want to continue with deployment? (y/n)"
if ($confirmation -ne 'y') {
    Write-Host "Deployment cancelled."
    exit
}

# Validate FTP credentials
if ($ftpHost -eq "ftp.yourdomain.com" -or $ftpUser -eq "your-username" -or $ftpPass -eq "your-password") {
    Write-Host "Error: You need to edit this script and replace the FTP credentials with your actual GoDaddy credentials."
    Write-Host "Open this script in a text editor and update the values at the top."
    exit
}

# Prepare files for deployment
Write-Host "Preparing files for deployment..."

# Check if folders exist
if (-not (Test-Path $localFolder)) {
    Write-Host "Error: Local folder does not exist: $localFolder"
    exit
}

# Get list of files to upload
$filesToUpload = Get-ChildItem -Path $localFolder -Recurse -File | 
                 Where-Object { 
                     -not $_.FullName.Contains(".git") -and 
                     -not $_.Name.EndsWith(".ps1") -and 
                     -not $_.Name -eq "README.md" -and 
                     -not $_.Name -eq "deployment-guide.md"
                 }

Write-Host "Found $($filesToUpload.Count) files to upload"

# Create WebClient for FTP upload
$webClient = New-Object System.Net.WebClient
$webClient.Credentials = New-Object System.Net.NetworkCredential($ftpUser, $ftpPass)

# Track statistics
$totalFiles = $filesToUpload.Count
$uploadedFiles = 0
$errorFiles = 0

# Upload files
foreach ($file in $filesToUpload) {
    $relativePath = $file.FullName.Substring($localFolder.Length).Replace("\", "/")
    $remotePath = "$remoteFolder$relativePath"
    $remoteUrl = "ftp://$ftpHost$remotePath"
    
    try {
        Write-Host "Uploading: $relativePath" -NoNewline
        
        # Upload file
        $webClient.UploadFile($remoteUrl, "STOR", $file.FullName)
        
        Write-Host " - Done" -ForegroundColor Green
        $uploadedFiles++
    }
    catch {
        Write-Host " - Error: $_" -ForegroundColor Red
        $errorFiles++
    }
    
    # Show progress
    $percentComplete = [int](($uploadedFiles + $errorFiles) / $totalFiles * 100)
    Write-Progress -Activity "Uploading Files" -Status "$percentComplete% Complete" -PercentComplete $percentComplete
}

Write-Host "Deployment completed:"
Write-Host "- Total files: $totalFiles"
Write-Host "- Successfully uploaded: $uploadedFiles"
Write-Host "- Errors: $errorFiles"

if ($errorFiles -gt 0) {
    Write-Host "There were some errors during deployment. Please check the logs above."
} else {
    Write-Host "Deployment successful! Your website should now be live at your GoDaddy hosted domain."
}

# Cleanup
$webClient.Dispose()
