# Direct Push to iBridgeSolutions/iBridge Repository

# Configuration
$repoURL = "https://github.com/iBridgeSolutions/iBridge.git"
$repoName = "iBridge"
$orgName = "iBridgeSolutions"
$branchName = "main"
$customDomain = "ibridgesolutions.co.za"

# Get the current location
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$fixedIndexPath = Join-Path $scriptPath "fixed-index.html"
$tempRepoPath = Join-Path $scriptPath "temp-ibridgesolutions-repo"

# Introduction
Write-Host "=== Direct Push to $repoURL ===" -ForegroundColor Cyan
Write-Host "This script will push the fixed website files to the iBridgeSolutions/iBridge repository" -ForegroundColor Cyan
Write-Host

# Check if Git is installed
try {
    $gitVersion = git --version
    Write-Host "Git is installed: $gitVersion" -ForegroundColor Green
}
catch {
    Write-Host "Error: Git is not installed or not in your PATH" -ForegroundColor Red
    exit
}

# Create temporary directory
if (Test-Path $tempRepoPath) {
    Write-Host "Removing existing temporary directory..." -ForegroundColor Yellow
    Remove-Item -Path $tempRepoPath -Recurse -Force
}
New-Item -Path $tempRepoPath -ItemType Directory | Out-Null

# Clone the repository
Write-Host "Cloning repository from $repoURL..." -ForegroundColor Yellow
git clone $repoURL $tempRepoPath

# Check if clone was successful
if (-not (Test-Path "$tempRepoPath\.git")) {
    Write-Host "Error: Failed to clone the repository. You may need to provide credentials." -ForegroundColor Red
    
    # Ask for credentials
    $useCredentials = Read-Host "Do you want to provide GitHub credentials? (y/n)"
    
    if ($useCredentials -eq "y") {
        $username = Read-Host "Enter your GitHub username"
        $securePassword = Read-Host "Enter your GitHub personal access token or password" -AsSecureString
        $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
        $password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
        
        # Try cloning with credentials
        $credentialURL = "https://$username`:$password@github.com/$orgName/$repoName.git"
        git clone $credentialURL $tempRepoPath
        
        # Check again
        if (-not (Test-Path "$tempRepoPath\.git")) {
            Write-Host "Error: Still failed to clone the repository" -ForegroundColor Red
            exit
        }
    } else {
        Write-Host "Please run this script again after authenticating with GitHub" -ForegroundColor Yellow
        exit
    }
}

# Navigate to the repository
Push-Location $tempRepoPath

try {
    # Add the fixed files
    Write-Host "Updating files..." -ForegroundColor Yellow
    
    # 1. Check if the fixed index.html file exists
    if (Test-Path $fixedIndexPath) {
        Copy-Item -Path $fixedIndexPath -Destination "index.html" -Force
        Write-Host "- Updated index.html with fixed version" -ForegroundColor Green
    } else {
        # Create a simple index.html with anti-redirect code
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
        Write-Host "- Created simple index.html with anti-redirect code" -ForegroundColor Green
    }
    
    # 2. Create .nojekyll file
    "" | Out-File -FilePath ".nojekyll" -Encoding utf8
    Write-Host "- Added .nojekyll file" -ForegroundColor Green
    
    # 3. Update CNAME file
    $customDomain | Out-File -FilePath "CNAME" -Encoding utf8
    Write-Host "- Updated CNAME file with: $customDomain" -ForegroundColor Green
    
    # Stage the changes
    git add index.html .nojekyll CNAME
    
    # Commit the changes
    Write-Host "Committing changes..." -ForegroundColor Yellow
    git commit -m "Fix: Resolve redirect to /lander issue and update website files"
    
    # Push the changes
    Write-Host "Pushing changes to $repoURL..." -ForegroundColor Yellow
    git push origin $branchName
    
    Write-Host "`nSuccess! Changes have been pushed to GitHub." -ForegroundColor Green
    Write-Host "The updated website should be available at https://$customDomain in a few minutes." -ForegroundColor Green
}
catch {
    Write-Host "Error during deployment: $_" -ForegroundColor Red
}
finally {
    # Return to original directory
    Pop-Location
}

# Clean up
$cleanUp = Read-Host "Do you want to remove the temporary repository? (y/n)"
if ($cleanUp -eq "y") {
    Remove-Item -Path $tempRepoPath -Recurse -Force
    Write-Host "Temporary repository removed" -ForegroundColor Green
}

# Offer to open the website
$openSite = Read-Host "Would you like to open the website in your browser? (y/n)"
if ($openSite -eq "y") {
    Start-Process "https://$customDomain"
}
