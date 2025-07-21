# Deployment script for iBridge website
Set-ExecutionPolicy Bypass -Scope Process -Force

# Configuration
$cpanelHost = "s41.registerdomain.net.za"
$cpanelPort = "2083"
$publicHtmlPath = "/home/public_html"

Write-Host "iBridge Website Deployment Script" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

# 1. Build process
Write-Host "`nStep 1: Preparing files for deployment..." -ForegroundColor Green

# Create dist directory if it doesn't exist
if(!(Test-Path -Path "dist")) {
    New-Item -ItemType Directory -Path "dist"
}

# Copy all required files to dist
Write-Host "Copying files to dist directory..."
Copy-Item -Path "*.html" -Destination "dist" -Recurse -Force
Copy-Item -Path "css/*" -Destination "dist/css" -Recurse -Force
Copy-Item -Path "js/*" -Destination "dist/js" -Recurse -Force
Copy-Item -Path "images/*" -Destination "dist/images" -Recurse -Force
Copy-Item -Path "favicon.ico" -Destination "dist" -Force
Copy-Item -Path ".htaccess" -Destination "dist" -Force
Copy-Item -Path "intranet/*" -Destination "dist/intranet" -Recurse -Force

# 2. Validate critical files
Write-Host "`nStep 2: Validating critical files..." -ForegroundColor Green
$requiredFiles = @(
    "dist/index.html",
    "dist/css/styles.css",
    "dist/js/main.js",
    "dist/intranet/login.html",
    "dist/.htaccess"
)

foreach($file in $requiredFiles) {
    if(Test-Path $file) {
        Write-Host "✓ Found $file" -ForegroundColor Green
    } else {
        Write-Host "✗ Missing $file" -ForegroundColor Red
        exit 1
    }
}

# 3. Prompt for deployment
Write-Host "`nStep 3: Ready for deployment" -ForegroundColor Green
Write-Host "Files will be deployed to $cpanelHost"
$confirm = Read-Host "Continue with deployment? (Y/N)"

if($confirm -ne "Y") {
    Write-Host "Deployment cancelled" -ForegroundColor Yellow
    exit 0
}

# 4. Deploy using preferred method
Write-Host "`nStep 4: Starting deployment..." -ForegroundColor Green
Write-Host "Please choose deployment method:"
Write-Host "1. File Manager (Manual)"
Write-Host "2. FTP"
Write-Host "3. Git"

$method = Read-Host "Enter number (1-3)"

switch($method) {
    "1" {
        Write-Host "`nFile Manager Instructions:" -ForegroundColor Cyan
        Write-Host "1. Log in to cPanel at https://$($cpanelHost):$cpanelPort"
        Write-Host "2. Open File Manager"
        Write-Host "3. Navigate to public_html"
        Write-Host "4. Upload all files from the 'dist' directory"
    }
    "2" {
        Write-Host "`nFTP Instructions:" -ForegroundColor Cyan
        Write-Host "Please enter your FTP credentials:"
        $ftpUser = Read-Host "Username"
        $ftpPass = Read-Host "Password" -AsSecureString
        
        # Note: In a production script, we would implement actual FTP upload here
        Write-Host "FTP upload would start here..."
    }
    "3" {
        Write-Host "`nGit Deployment Instructions:" -ForegroundColor Cyan
        Write-Host "1. Initialize Git repository (if not already done):"
        Write-Host "   git init"
        Write-Host "2. Add all files:"
        Write-Host "   git add ."
        Write-Host "3. Commit changes:"
        Write-Host "   git commit -m 'Deployment update'"
        Write-Host "4. Add cPanel remote (if not already done):"
        Write-Host "   git remote add cpanel ssh://username@$cpanelHost/home/username/repository"
        Write-Host "5. Push to cPanel:"
        Write-Host "   git push cpanel main"
    }
}

Write-Host "`nPost-Deployment Tasks:" -ForegroundColor Green
Write-Host "1. Verify domain redirection (ibridge.co.za → ibridgebpo.com)"
Write-Host "2. Test all website functionality"
Write-Host "3. Clear browser cache and verify changes"
Write-Host "4. Check SSL certificate"

Write-Host "`nDeployment script completed" -ForegroundColor Cyan
