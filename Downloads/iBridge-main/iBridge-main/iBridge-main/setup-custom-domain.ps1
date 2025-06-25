# Custom Domain Configuration Script for iBridge Website

# Configuration
$repoPath = "c:\Users\Lwandile Gasela\Downloads\iBridge-main\iBridge-main\iBridge-main"
$customDomain = "ibridgesolutions.co.za"
$repoURL = "https://github.com/iBridgeSolutions/iBridge.git"
$repoName = "iBridge"
$orgName = "iBridgeSolutions"

Write-Host "=== iBridge Website Custom Domain Setup ===" -ForegroundColor Cyan
Write-Host "This script will configure your GitHub Pages to use the custom domain: $customDomain" -ForegroundColor Cyan
Write-Host

# Check if repository folder exists
if (-not (Test-Path $repoPath)) {
    Write-Host "Error: Repository folder does not exist: $repoPath" -ForegroundColor Red
    exit
}

# Create or update CNAME file
Write-Host "Creating CNAME file with domain: $customDomain" -ForegroundColor Green
Set-Content -Path "$repoPath\CNAME" -Value $customDomain -Force

# Navigate to repository folder
Push-Location $repoPath

try {
    # Check if directory is a git repository
    if (-not (Test-Path "$repoPath\.git")) {
        Write-Host "Error: The specified folder is not a Git repository." -ForegroundColor Red
        exit
    }

    # Git operations
    Write-Host "Committing changes..." -ForegroundColor Green
    git add CNAME
    git commit -m "Add custom domain: $customDomain"

    # Push to GitHub
    Write-Host "Pushing changes to GitHub repository..." -ForegroundColor Green
    git push origin main

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to push changes. You might need authentication or access rights." -ForegroundColor Red
        Write-Host "Please try authenticating manually with Git and run this script again." -ForegroundColor Yellow
        exit
    }

    Write-Host
    Write-Host "IMPORTANT: DNS Configuration Instructions" -ForegroundColor Yellow
    Write-Host "---------------------------------------" -ForegroundColor Yellow
    Write-Host "To complete the custom domain setup, you need to configure your DNS records:" -ForegroundColor White
    Write-Host
    Write-Host "1. Log in to your domain provider's website (where you registered ibridgesolutions.co.za)" -ForegroundColor White
    Write-Host "2. Navigate to the DNS settings/configuration section" -ForegroundColor White
    Write-Host "3. Add the following A records pointing to GitHub Pages IP addresses:" -ForegroundColor White
    Write-Host "   - A record: @ -> 185.199.108.153" -ForegroundColor Cyan
    Write-Host "   - A record: @ -> 185.199.109.153" -ForegroundColor Cyan
    Write-Host "   - A record: @ -> 185.199.110.153" -ForegroundColor Cyan
    Write-Host "   - A record: @ -> 185.199.111.153" -ForegroundColor Cyan
    Write-Host
    Write-Host "4. Add a CNAME record for the www subdomain:" -ForegroundColor White
    Write-Host "   - CNAME record: www -> $orgName.github.io" -ForegroundColor Cyan
    Write-Host
    Write-Host "5. DNS changes may take up to 24-48 hours to propagate fully" -ForegroundColor White
    Write-Host
    Write-Host "6. After pushing changes, complete the GitHub Pages setup:" -ForegroundColor White
    Write-Host "   - Go to https://github.com/$orgName/$repoName/settings/pages" -ForegroundColor White
    Write-Host "   - Ensure 'main' branch is selected as source" -ForegroundColor White
    Write-Host "   - In the 'Custom domain' section, your domain $customDomain should be entered" -ForegroundColor White
    Write-Host "   - Check 'Enforce HTTPS' once the domain is verified (may take up to 24 hours)" -ForegroundColor White
    Write-Host "   - Click 'Save'" -ForegroundColor White
    Write-Host
    
    # Try to open the GitHub Pages settings page in the default browser
    Start-Process "https://github.com/$orgName/$repoName/settings/pages"
}
catch {
    Write-Host "Error: $_" -ForegroundColor Red
}
finally {
    # Navigate back to original directory
    Pop-Location
}

Write-Host "Custom domain configuration script completed!" -ForegroundColor Green
Write-Host "Your website should be available at http://$customDomain after DNS propagation (24-48 hours)" -ForegroundColor Green
