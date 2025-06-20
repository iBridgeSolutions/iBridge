# Simple Direct Update Script for iBridge Website

# Configuration
$customDomain = "ibridgesolutions.co.za"
$repoPath = "c:\Users\Lwandile Gasela\Downloads\iBridge-main\iBridge-main\iBridge-main"

# Check if the repository exists
if (-not (Test-Path $repoPath)) {
    Write-Host "Error: Repository path not found at $repoPath" -ForegroundColor Red
    exit
}

# Introduction
Write-Host "=== iBridge Website Direct Update Tool ===" -ForegroundColor Cyan
Write-Host "This script will directly update the website files to fix the redirect issue" -ForegroundColor Cyan
Write-Host

# Get script location for source files
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$fixedIndexPath = Join-Path $scriptPath "fixed-index.html"

# Navigate to the repository
Push-Location $repoPath

try {
    # 1. Update index.html with the fixed version
    Write-Host "Updating index.html..." -ForegroundColor Yellow
    if (Test-Path $fixedIndexPath) {
        Copy-Item -Path $fixedIndexPath -Destination "index.html" -Force
        Write-Host "- Updated index.html with fixed version" -ForegroundColor Green
    } else {
        Write-Host "Warning: fixed-index.html not found, creating a simple version..." -ForegroundColor Yellow
        
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
    Write-Host "Adding .nojekyll file..." -ForegroundColor Yellow
    "" | Out-File -FilePath ".nojekyll" -Encoding utf8
    Write-Host "- Added .nojekyll file" -ForegroundColor Green
    
    # 3. Verify CNAME file
    Write-Host "Checking CNAME file..." -ForegroundColor Yellow
    if (Test-Path "CNAME") {
        $currentDomain = Get-Content "CNAME" -Raw
        if ($currentDomain.Trim() -ne $customDomain) {
            Write-Host "- Updating CNAME to contain only: $customDomain" -ForegroundColor Yellow
            $customDomain | Out-File -FilePath "CNAME" -Encoding utf8
        } else {
            Write-Host "- CNAME file already correctly set to: $customDomain" -ForegroundColor Green
        }
    } else {
        Write-Host "- Creating CNAME file with domain: $customDomain" -ForegroundColor Yellow
        $customDomain | Out-File -FilePath "CNAME" -Encoding utf8
    }
    
    Write-Host "`nFiles updated successfully!" -ForegroundColor Green
    
    # Ask if the user wants to push to GitHub
    $pushToGitHub = Read-Host "`nDo you want to commit and push these changes to GitHub? (y/n)"
    if ($pushToGitHub -eq "y") {
        # Check if this is a git repository
        if (-not (Test-Path ".git")) {
            Write-Host "Error: This is not a Git repository. Cannot push changes." -ForegroundColor Red
        } else {
            # Push changes to GitHub
            Write-Host "Adding files to Git..." -ForegroundColor Yellow
            git add index.html .nojekyll CNAME
            
            Write-Host "Committing changes..." -ForegroundColor Yellow
            git commit -m "Fix: Resolve redirect to /lander issue and update website files"
            
            Write-Host "Pushing to GitHub..." -ForegroundColor Yellow
            git push origin main
            
            Write-Host "`nChanges pushed to GitHub successfully!" -ForegroundColor Green
            Write-Host "Your website should be updated at https://$customDomain in a few minutes" -ForegroundColor Green
        }
    } else {
        Write-Host "`nChanges made locally only. To complete deployment:" -ForegroundColor Yellow
        Write-Host "1. Open a terminal in $repoPath" -ForegroundColor White
        Write-Host "2. Run: git add index.html .nojekyll CNAME" -ForegroundColor White
        Write-Host "3. Run: git commit -m ""Fix: Resolve redirect to /lander issue""" -ForegroundColor White
        Write-Host "4. Run: git push origin main" -ForegroundColor White
    }
}
catch {
    Write-Host "Error: $_" -ForegroundColor Red
}
finally {
    # Return to original directory
    Pop-Location
}

Write-Host "`nImportant Note About GoDaddy:" -ForegroundColor Cyan
Write-Host "If you're using GoDaddy for your domain, you may need to disable their default landing page." -ForegroundColor White
Write-Host "Please check the GoDaddy-Redirect-Fix.md file for detailed instructions." -ForegroundColor White
