# Deployment Instructions for iBridge Website

This document provides instructions for deploying the consolidated iBridge website to a traditional web server.

> **Note:** For GitHub Pages deployment, please refer to the separate `github-deployment-guide.md` file.

## Local Testing

To test the website locally before deployment:

1. Open the project in Visual Studio Code
2. Use the Live Server extension (install it if not already installed)
3. Right-click on `index.html` and select "Open with Live Server"
4. Verify that all pages, images, styles, and navigation work correctly

## Deployment to Web Server

### Option 1: Manual File Copy

1. Copy the entire `iBridge-consolidated` folder to your web server's document root
2. Rename the folder to your preferred name (e.g., `ibridge` or `www`)
3. Ensure proper permissions are set (typically 755 for folders and 644 for files)

### Option 2: Using FTP

1. Connect to your web hosting using an FTP client (e.g., FileZilla)
2. Upload the entire `iBridge-consolidated` folder to your web server's document root
3. Rename the folder as needed on the server

### Option 3: Using PowerShell Script (Windows)

For automated deployment, you can use the provided PowerShell script:

```powershell
# Usage: .\deploy-website.ps1 -SourcePath "C:\path\to\iBridge-consolidated" -DestinationPath "C:\path\to\webserver\root"
param(
    [Parameter(Mandatory=$true)]
    [string]$SourcePath,
    
    [Parameter(Mandatory=$true)]
    [string]$DestinationPath
)

Write-Host "Starting deployment of iBridge website..." -ForegroundColor Green

# Create destination folder if it doesn't exist
if (-not (Test-Path -Path $DestinationPath)) {
    New-Item -ItemType Directory -Path $DestinationPath -Force
    Write-Host "Created destination directory: $DestinationPath" -ForegroundColor Yellow
}

# Copy all files from source to destination
Copy-Item -Path "$SourcePath\*" -Destination $DestinationPath -Recurse -Force
Write-Host "Files copied successfully to $DestinationPath" -ForegroundColor Green

Write-Host "Deployment completed!" -ForegroundColor Green
```

Execute this script from PowerShell to deploy the website.

## Post-Deployment Verification

After deployment, verify that:

1. All pages load correctly without 404 errors
2. All images display properly
3. CSS styling is applied correctly
4. JavaScript functionality works (dynamic header/footer loading, navigation, etc.)
5. All internal links work properly
6. The site looks correct on different devices and browsers

## Troubleshooting

If you encounter any issues after deployment:

1. **Missing images or styles**: Verify path references in HTML files
2. **JavaScript errors**: Check browser console for error messages
3. **Header/footer not loading**: Ensure the server allows fetch requests to local files
4. **404 errors**: Check file paths and case sensitivity (some servers are case-sensitive)
