# iBridge Website Deployment Preparation Script
# This script prepares your website files for deployment to ibridgesolutions.co.za

param(
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = ".\deployment-ready"
)

Write-Host "=== iBridge Website Deployment Preparation ===" -ForegroundColor Green
Write-Host "Preparing files for deployment to ibridgesolutions.co.za" -ForegroundColor Cyan

# Create output directory
if (Test-Path $OutputPath) {
    Write-Host "Cleaning existing deployment directory..." -ForegroundColor Yellow
    Remove-Item $OutputPath -Recurse -Force
}
New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null

# Files to include in deployment
$filesToCopy = @(
    "index.html",
    "about.html", 
    "services.html",
    "contact.html",
    "contact-center.html",
    "it-support.html",
    "ai-automation.html",
    ".htaccess"
)

# Directories to copy
$directoriesToCopy = @(
    "css",
    "js", 
    "images"
)

Write-Host "Copying website files..." -ForegroundColor Yellow

# Copy HTML files
foreach ($file in $filesToCopy) {
    if (Test-Path $file) {
        Copy-Item $file $OutputPath
        Write-Host "  - Copied $file" -ForegroundColor Green
    } else {
        Write-Host "  - Missing: $file" -ForegroundColor Red
    }
}

# Copy directories
foreach ($dir in $directoriesToCopy) {
    if (Test-Path $dir) {
        Copy-Item $dir $OutputPath -Recurse
        Write-Host "  - Copied $dir directory" -ForegroundColor Green
    } else {
        Write-Host "  - Missing: $dir directory" -ForegroundColor Red
    }
}

# Check for and report file sizes
Write-Host "`nFile Size Analysis:" -ForegroundColor Cyan
$totalSize = 0
Get-ChildItem $OutputPath -Recurse -File | ForEach-Object {
    $sizeKB = [math]::Round($_.Length / 1KB, 2)
    $totalSize += $_.Length
    
    if ($sizeKB -gt 500) {
        Write-Host "  - Large file: $($_.Name) ($sizeKB KB)" -ForegroundColor Yellow
    }
}

$totalSizeMB = [math]::Round($totalSize / 1MB, 2)
Write-Host "Total deployment size: $totalSizeMB MB" -ForegroundColor Cyan

# Image optimization suggestions
Write-Host "`nImage Optimization:" -ForegroundColor Cyan
if (Test-Path "$OutputPath\images") {
    $imageFiles = Get-ChildItem "$OutputPath\images" -Include *.png,*.jpg,*.jpeg -Recurse
    foreach ($img in $imageFiles) {
        $sizeKB = [math]::Round($img.Length / 1KB, 2)
        if ($sizeKB -gt 100) {
            Write-Host "  - Consider optimizing: $($img.Name) ($sizeKB KB)" -ForegroundColor Yellow
        }
    }
}

# Validate HTML files for common issues
Write-Host "`nValidating HTML files..." -ForegroundColor Cyan
$htmlFiles = Get-ChildItem $OutputPath -Filter "*.html"
foreach ($htmlFile in $htmlFiles) {
    $content = Get-Content $htmlFile.FullName -Raw
    
    # Check for absolute paths that might break
    if ($content -match 'src="[A-Za-z]:\\' -or $content -match 'href="[A-Za-z]:\\') {
        Write-Host "  - Found absolute file paths in $($htmlFile.Name)" -ForegroundColor Red
    }
    
    # Check for localhost references
    if ($content -match 'localhost' -or $content -match '127\.0\.0\.1') {
        Write-Host "  - Found localhost references in $($htmlFile.Name)" -ForegroundColor Red
    }
    
    Write-Host "  - Validated $($htmlFile.Name)" -ForegroundColor Green
}

# Create deployment ZIP file
Write-Host "`nCreating deployment ZIP file..." -ForegroundColor Yellow
$zipPath = ".\iBridge-deployment-$(Get-Date -Format 'yyyy-MM-dd-HHmm').zip"

try {
    Compress-Archive -Path "$OutputPath\*" -DestinationPath $zipPath -CompressionLevel Optimal
    Write-Host "  - Created: $zipPath" -ForegroundColor Green
    
    $zipSize = [math]::Round((Get-Item $zipPath).Length / 1KB, 2)
    Write-Host "  - ZIP size: $zipSize KB" -ForegroundColor Cyan
} catch {
    Write-Host "  - Could not create ZIP file. Please create manually." -ForegroundColor Yellow
}

# Final deployment checklist
Write-Host "`n=== DEPLOYMENT CHECKLIST ===" -ForegroundColor Green
Write-Host "Before uploading to ibridgesolutions.co.za:" -ForegroundColor Cyan
Write-Host "  [] Backup any existing website content" -ForegroundColor White
Write-Host "  [] Test all files locally first" -ForegroundColor White  
Write-Host "  [] Upload files to public_html directory" -ForegroundColor White
Write-Host "  [] Set proper file permissions (644 for files, 755 for folders)" -ForegroundColor White
Write-Host "  [] Test website after upload" -ForegroundColor White
Write-Host "  [] Enable SSL certificate in GoDaddy panel" -ForegroundColor White
Write-Host "  [] Update .htaccess to force HTTPS (after SSL is active)" -ForegroundColor White

Write-Host "`n=== NEXT STEPS ===" -ForegroundColor Green
Write-Host "1. Log into GoDaddy hosting panel" -ForegroundColor White
Write-Host "2. Open cPanel File Manager" -ForegroundColor White
Write-Host "3. Navigate to public_html directory" -ForegroundColor White
Write-Host "4. Upload files from: $OutputPath" -ForegroundColor White
Write-Host "5. Test your website at: http://ibridgesolutions.co.za" -ForegroundColor White

Write-Host "`nDeployment preparation complete!" -ForegroundColor Green
