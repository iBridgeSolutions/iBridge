# Deploy to iBridgeSolutions/iBridge Repository
# This script will update the repository with fixed files to resolve the /lander redirect issue

# Configuration
$repoURL = "https://github.com/iBridgeSolutions/iBridge.git"
$repoName = "iBridge"
$orgName = "iBridgeSolutions"
$branchName = "main"
$customDomain = "ibridgesolutions.co.za"

# Get the current location
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$sourceFilesPath = Join-Path $scriptPath "iBridge-main\iBridge-main" 
$localRepoPath = Join-Path $scriptPath "temp-repo"

# Introduction
Write-Host "=== iBridge Website Deployment Tool ===" -ForegroundColor Cyan
Write-Host "This script will deploy the fixed website to $repoURL" -ForegroundColor Cyan
Write-Host

# Check if Git is installed
try {
    $gitVersion = git --version
    Write-Host "Git is installed: $gitVersion" -ForegroundColor Green
}
catch {
    Write-Host "Error: Git is not installed or not in your PATH" -ForegroundColor Red
    Write-Host "Please install Git from https://git-scm.com/downloads" -ForegroundColor Yellow
    exit
}

# Create temporary directory for the repository
if (Test-Path $localRepoPath) {
    Write-Host "Removing existing temporary repository..." -ForegroundColor Yellow
    Remove-Item -Path $localRepoPath -Recurse -Force
}

# Clone the repository
Write-Host "Cloning repository from $repoURL..." -ForegroundColor Yellow
git clone $repoURL $localRepoPath

# Check if clone was successful
if (-not (Test-Path "$localRepoPath\.git")) {
    Write-Host "Error: Failed to clone the repository" -ForegroundColor Red
    Write-Host "Please check the repository URL and your internet connection" -ForegroundColor Yellow
    exit
}

# Navigate to the repository
Push-Location $localRepoPath

try {
    # Copy fixed files
    Write-Host "`nUpdating files to fix the redirect issue..." -ForegroundColor Yellow
    
    # 1. Update index.html with the fixed version
    $fixedIndexPath = Join-Path $scriptPath "fixed-index.html"
    if (Test-Path $fixedIndexPath) {
        Copy-Item -Path $fixedIndexPath -Destination "index.html" -Force
        Write-Host "- Updated index.html with fixed version" -ForegroundColor Green
    } else {
        Write-Host "Warning: fixed-index.html not found at $fixedIndexPath" -ForegroundColor Yellow
        
        # Create simple index.html as fallback
        @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>iBridge Solutions</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; }
        .container { background-color: #f5f5f5; padding: 20px; border-radius: 5px; }
        h1 { color: #0066cc; }
    </style>
</head>
<body>
    <div class="container">
        <h1>iBridge Solutions</h1>
        <p>Welcome to iBridge Solutions. Our website is currently being updated.</p>
        <p>Please check back shortly.</p>
        
        <script>
            // Anti-redirect script
            if (window.location.pathname.includes('/lander')) {
                var newPath = window.location.pathname.replace('/lander', '');
                window.history.replaceState({}, document.title, newPath);
                console.log("Prevented redirect to /lander");
            }
        </script>
    </div>
</body>
</html>
"@ | Out-File -FilePath "index.html" -Encoding utf8
        Write-Host "- Created a simple index.html with anti-redirect code" -ForegroundColor Green
    }
    
    # 2. Create or update .nojekyll file
    "" | Out-File -FilePath ".nojekyll" -Encoding utf8
    Write-Host "- Added .nojekyll file" -ForegroundColor Green
    
    # 3. Update CNAME file
    $customDomain | Out-File -FilePath "CNAME" -Encoding utf8
    Write-Host "- Updated CNAME file with domain: $customDomain" -ForegroundColor Green
    
    # Add all files to Git
    git add index.html .nojekyll CNAME
    
    # Commit changes
    Write-Host "`nCommitting changes..." -ForegroundColor Yellow
    git commit -m "Fix: Resolve redirect to /lander issue and update website files"
    
    # Push changes
    Write-Host "`nPushing changes to $repoURL..." -ForegroundColor Yellow
    git push origin $branchName
    
    Write-Host "`nSuccess! The website has been updated." -ForegroundColor Green
    Write-Host "The changes should be live at https://$customDomain in a few minutes." -ForegroundColor Green
    
    # Provide additional information
    Write-Host "`nAdditional steps:" -ForegroundColor Cyan
    Write-Host "1. Check GitHub Pages settings at: https://github.com/$orgName/$repoName/settings/pages" -ForegroundColor White
    Write-Host "2. Ensure the custom domain is set to: $customDomain" -ForegroundColor White
    Write-Host "3. Check 'Enforce HTTPS' once the domain is verified" -ForegroundColor White
    Write-Host "4. If using GoDaddy, make sure to follow the guide in GoDaddy-Redirect-Fix.md" -ForegroundColor White
}
catch {
    Write-Host "Error during deployment: $_" -ForegroundColor Red
}
finally {
    # Return to original directory
    Pop-Location
}

# Ask if the user wants to clean up the temporary repository
$cleanUp = Read-Host "`nDo you want to remove the temporary repository? (y/n)"
if ($cleanUp -eq "y") {
    Remove-Item -Path $localRepoPath -Recurse -Force
    Write-Host "Temporary repository removed" -ForegroundColor Green
}

Write-Host "`nDeployment process completed!" -ForegroundColor Cyan
