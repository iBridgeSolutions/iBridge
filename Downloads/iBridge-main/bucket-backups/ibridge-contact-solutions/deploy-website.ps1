# Deploy iBridge Website to GitHub Pages

# Configuration - Update these values
$githubUsername = "Blxckukno" # Replace with your actual GitHub username
$repoName = "iBridge"
$targetDir = "c:\Users\Lwandile Gasela\Downloads\iBridge-main\iBridge-main\iBridge-main" # Where the most complete website files are

# Verify target directory exists
if (-not (Test-Path $targetDir)) {
    Write-Host "Error: Target directory not found at $targetDir" -ForegroundColor Red
    Write-Host "Please specify the correct path to your website files" -ForegroundColor Yellow
    exit
}

# Copy fixed index.html to target directory
$fixedIndexPath = "c:\Users\Lwandile Gasela\Downloads\iBridge-main\fixed-index.html"
if (Test-Path $fixedIndexPath) {
    Write-Host "Copying fixed index.html to target directory..." -ForegroundColor Yellow
    Copy-Item $fixedIndexPath -Destination "$targetDir\index.html" -Force
    Write-Host "Fixed index.html copied successfully" -ForegroundColor Green
} else {
    Write-Host "Warning: fixed-index.html not found. Continuing with existing index.html" -ForegroundColor Yellow
}

# Create .nojekyll file
Write-Host "Creating .nojekyll file..." -ForegroundColor Yellow
"" | Out-File -FilePath "$targetDir\.nojekyll" -Encoding utf8
Write-Host ".nojekyll file created" -ForegroundColor Green

# Make sure the CNAME file exists and has correct content
$cnameContent = "ibridgesolutions.co.za"
Write-Host "Updating CNAME file..." -ForegroundColor Yellow
$cnameContent | Out-File -FilePath "$targetDir\CNAME" -Encoding utf8 -NoNewline
Write-Host "CNAME file updated" -ForegroundColor Green

# Initialize Git repository if needed
Push-Location $targetDir
try {
    if (-not (Test-Path "$targetDir\.git")) {
        Write-Host "Initializing new Git repository..." -ForegroundColor Yellow
        git init
        Write-Host "Git repository initialized" -ForegroundColor Green
    }

    # Configure Git if needed
    $gitUserName = git config --global user.name
    $gitUserEmail = git config --global user.email
    
    if (-not $gitUserName) {
        $inputName = Read-Host "Enter your name for Git configuration"
        git config --global user.name "$inputName"
    }
    
    if (-not $gitUserEmail) {
        $inputEmail = Read-Host "Enter your email for Git configuration"
        git config --global user.email "$inputEmail"
    }

    # Check if remote exists, if not add it
    $remoteUrl = git remote get-url origin 2>$null
    if (-not $?) {
        Write-Host "Adding GitHub remote..." -ForegroundColor Yellow
        git remote add origin "https://github.com/$githubUsername/$repoName.git"
        Write-Host "GitHub remote added" -ForegroundColor Green
    }

    # Add all files
    Write-Host "Adding files to Git..." -ForegroundColor Yellow
    git add .
    
    # Commit changes
    Write-Host "Committing changes..." -ForegroundColor Yellow
    git commit -m "Fix website redirection issue and update files"
    
    # Push to GitHub
    Write-Host "Pushing to GitHub..." -ForegroundColor Yellow
    $pushSuccess = $false
    
    try {
        # Try pushing to main branch
        git push -u origin main
        $pushSuccess = $true
    } catch {
        Write-Host "Failed to push to main branch, trying master branch..." -ForegroundColor Yellow
        try {
            git push -u origin master
            $pushSuccess = $true
        } catch {
            Write-Host "Failed to push to master branch, trying gh-pages branch..." -ForegroundColor Yellow
            try {
                git push -u origin gh-pages
                $pushSuccess = $true
            } catch {
                Write-Host "Failed to push to gh-pages branch. Creating gh-pages branch..." -ForegroundColor Yellow
                git checkout -b gh-pages
                git push -u origin gh-pages
                $pushSuccess = $true
            }
        }
    }
    
    if ($pushSuccess) {
        Write-Host "`nSuccess! Website files have been pushed to GitHub." -ForegroundColor Green
        Write-Host "GitHub Pages will now build and deploy your website." -ForegroundColor Green
        Write-Host "This process may take a few minutes." -ForegroundColor Yellow
        
        # GitHub Pages Configuration Instructions
        Write-Host "`nImportant Next Steps:" -ForegroundColor Cyan
        Write-Host "1. Go to GitHub repository settings: https://github.com/$githubUsername/$repoName/settings/pages" -ForegroundColor White
        Write-Host "2. Make sure the Source is set to 'gh-pages' (or whichever branch was successful)" -ForegroundColor White
        Write-Host "3. Confirm Custom Domain is set to 'ibridgesolutions.co.za'" -ForegroundColor White
        Write-Host "4. Check 'Enforce HTTPS' once the domain is verified" -ForegroundColor White
        
        # GoDaddy Configuration Instructions
        Write-Host "`nGoDaddy Configuration (to prevent /lander redirect):" -ForegroundColor Cyan
        Write-Host "1. Log in to your GoDaddy account" -ForegroundColor White
        Write-Host "2. Go to My Products > Domains > ibridgesolutions.co.za" -ForegroundColor White
        Write-Host "3. Look for Website or Website Redirect settings and ensure no redirects are active" -ForegroundColor White
        Write-Host "4. Check DNS settings to ensure they point to GitHub Pages:" -ForegroundColor White
        Write-Host "   - Four A records for @ pointing to GitHub IPs" -ForegroundColor White
        Write-Host "   - CNAME record for www pointing to $githubUsername.github.io" -ForegroundColor White
        
        Write-Host "`nYour website should be available at https://ibridgesolutions.co.za soon." -ForegroundColor Green
        Write-Host "It may take up to 24 hours for DNS changes and GitHub Pages to fully update." -ForegroundColor Yellow
    } else {
        Write-Host "Failed to push to any branch. Please check your GitHub credentials and try again." -ForegroundColor Red
    }
} catch {
    Write-Host "Error during deployment: $_" -ForegroundColor Red
} finally {
    Pop-Location
}
