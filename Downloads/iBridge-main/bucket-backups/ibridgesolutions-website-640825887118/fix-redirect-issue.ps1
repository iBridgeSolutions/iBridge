# Fix Redirect Issue Script for iBridge Website

# Get the current location
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$tempIndexPath = Join-Path $scriptPath "temp-index.html"
$repoPath = Join-Path $scriptPath "iBridge-main\iBridge-main"

# IMPORTANT: Fix the repository path if needed
if (-not (Test-Path $repoPath)) {
    $repoPath = Join-Path $scriptPath "iBridge-main"
    if (-not (Test-Path $repoPath)) {
        # Try one more path
        $repoPath = $scriptPath
        Write-Host "Using current directory as repository path" -ForegroundColor Yellow
    } else {
        Write-Host "Using path: $repoPath" -ForegroundColor Yellow
    }
}

# Check if temporary index file exists
if (-not (Test-Path $tempIndexPath)) {
    Write-Host "Error: temp-index.html not found at $tempIndexPath" -ForegroundColor Red
    exit
}

# Copy temporary index to repository
Write-Host "Copying temporary index.html to repository..." -ForegroundColor Yellow
Copy-Item $tempIndexPath -Destination "$repoPath\index.html" -Force

# Now commit and push to GitHub
Push-Location $repoPath

# Check if this is a git repository
if (-not (Test-Path "$repoPath\.git")) {
    # Try to find the git repository
    Write-Host "Searching for Git repository..." -ForegroundColor Yellow
    
    # Try iBridge-main path
    if (Test-Path "$scriptPath\iBridge-main\.git") {
        $repoPath = "$scriptPath\iBridge-main"
        Write-Host "Found Git repository at: $repoPath" -ForegroundColor Green
        Pop-Location
        Push-Location $repoPath
    } 
    # Try iBridge-main\iBridge-main path
    elseif (Test-Path "$scriptPath\iBridge-main\iBridge-main\.git") {
        $repoPath = "$scriptPath\iBridge-main\iBridge-main"
        Write-Host "Found Git repository at: $repoPath" -ForegroundColor Green
        Pop-Location
        Push-Location $repoPath
    }
    else {
        Write-Host "Error: Could not find a Git repository" -ForegroundColor Red
        Write-Host "Please navigate to your Git repository directory and copy the temp-index.html file manually" -ForegroundColor Yellow
        Write-Host "Source file: $tempIndexPath" -ForegroundColor Yellow
        Pop-Location
        exit
    }
}

# Git operations
try {
    Write-Host "Committing fix for redirect issue..." -ForegroundColor Yellow
    git add index.html
    git commit -m "Fix: Replace index.html to resolve redirection to /lander issue"
    
    Write-Host "Pushing changes to GitHub..." -ForegroundColor Yellow
    git push origin main
    
    Write-Host "Success! The fix has been pushed to GitHub." -ForegroundColor Green
    Write-Host "The website should update within a few minutes." -ForegroundColor Green
    Write-Host "Please check https://ibridgesolutions.co.za in about 5-10 minutes." -ForegroundColor Green
}
catch {
    Write-Host "Error during Git operations: $_" -ForegroundColor Red
}
finally {
    Pop-Location
}

# Optional: Check if additional domains need to be fixed
$addRedirectFix = Read-Host "Do you also want to add a redirect fix for the www subdomain? (y/n)"
if ($addRedirectFix -eq 'y') {
    # Create a CNAME file for the www subdomain
    Write-Host "Adding redirect fix for www subdomain..." -ForegroundColor Yellow
    
    # Create a simple HTML file that redirects www to apex domain
    $redirectHtml = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Redirecting...</title>
    <meta http-equiv="refresh" content="0; URL=https://ibridgesolutions.co.za">
    <link rel="canonical" href="https://ibridgesolutions.co.za">
</head>
<body>
    <h1>Redirecting...</h1>
    <p>You are being redirected to <a href="https://ibridgesolutions.co.za">https://ibridgesolutions.co.za</a></p>
    <script>
        window.location.href = "https://ibridgesolutions.co.za" + window.location.pathname;
    </script>
</body>
</html>
"@
    
    $redirectPath = Join-Path $repoPath "redirect.html"
    $redirectHtml | Out-File -FilePath $redirectPath -Encoding utf8
    
    Push-Location $repoPath
    try {
        git add redirect.html
        git commit -m "Add: Redirect file for www subdomain"
        git push origin main
        Write-Host "Redirect fix for www subdomain has been added." -ForegroundColor Green
    }
    catch {
        Write-Host "Error adding www redirect: $_" -ForegroundColor Red
    }
    finally {
        Pop-Location
    }
}

Write-Host "`nDone! These changes should fix the redirection issue." -ForegroundColor Cyan
Write-Host "After GitHub Pages updates (usually 5-10 minutes), visit:" -ForegroundColor Cyan
Write-Host "https://ibridgesolutions.co.za" -ForegroundColor Green
