# Manual Upload to iBridgeSolutions/iBridge Repository

# Introduction
Write-Host "=== Manual Upload to iBridgeSolutions/iBridge ===" -ForegroundColor Cyan
Write-Host "This script will guide you through manually uploading the fixed files to GitHub" -ForegroundColor Cyan
Write-Host

# File locations
$sourceDir = "c:\Users\Lwandile Gasela\Downloads\iBridge-main"
$fixedIndexPath = Join-Path $sourceDir "fixed-index.html"

# Check if files exist
if (-not (Test-Path $fixedIndexPath)) {
    Write-Host "Error: fixed-index.html not found at $fixedIndexPath" -ForegroundColor Red
    exit
}

# Instructions
Write-Host "To fix the website redirection issue, follow these steps:" -ForegroundColor Yellow
Write-Host

Write-Host "Step 1: Open a browser and go to the GitHub repository" -ForegroundColor White
Write-Host "- Go to: https://github.com/iBridgeSolutions/iBridge" -ForegroundColor Cyan
Write-Host

Write-Host "Step 2: Update the index.html file" -ForegroundColor White
Write-Host "- Click on the index.html file in the repository"
Write-Host "- Click the pencil icon (Edit this file)"
Write-Host "- Delete all existing content"
Write-Host "- Copy and paste the content from your fixed-index.html file"
Write-Host "- Here's the content of your fixed-index.html:" -ForegroundColor Cyan
Write-Host "-----------------------------"
Get-Content $fixedIndexPath | ForEach-Object { Write-Host $_ }
Write-Host "-----------------------------"
Write-Host "- Scroll down and enter a commit message: ""Fix: Resolve redirect to /lander issue"""
Write-Host "- Click 'Commit changes'"
Write-Host

Write-Host "Step 3: Add a .nojekyll file" -ForegroundColor White
Write-Host "- Go back to the main repository page"
Write-Host "- Click 'Add file' > 'Create new file'"
Write-Host "- Name the file: .nojekyll (don't add any content)"
Write-Host "- Scroll down and enter a commit message: ""Add .nojekyll to disable Jekyll processing"""
Write-Host "- Click 'Commit changes'"
Write-Host

Write-Host "Step 4: Verify the CNAME file" -ForegroundColor White
Write-Host "- Check if there's a CNAME file in the repository"
Write-Host "- If it exists, ensure it contains only: ibridgesolutions.co.za"
Write-Host "- If it doesn't exist, create one with 'Add file' > 'Create new file'"
Write-Host "- Name the file: CNAME"
Write-Host "- Add content: ibridgesolutions.co.za"
Write-Host "- Commit the changes"
Write-Host

Write-Host "Step 5: Check GitHub Pages settings" -ForegroundColor White
Write-Host "- Go to Settings > Pages"
Write-Host "- Ensure Source is set to 'Deploy from a branch'"
Write-Host "- Branch should be 'main' and folder should be '/ (root)'"
Write-Host "- Custom domain should be: ibridgesolutions.co.za"
Write-Host "- Check 'Enforce HTTPS' if it's available"
Write-Host "- Click Save if you made any changes"
Write-Host

Write-Host "Step 6: Check GoDaddy settings" -ForegroundColor White
Write-Host "- Log in to your GoDaddy account"
Write-Host "- Find and manage ibridgesolutions.co.za"
Write-Host "- Check for any Forwarding or Website Redirect settings and disable them"
Write-Host "- Make sure any 'Coming Soon' or lander pages are disabled"
Write-Host "- Verify your DNS settings point to GitHub Pages (see GoDaddy-DNS-Guide.md)"
Write-Host

Write-Host "The fix should be complete! Wait about 5-10 minutes for changes to take effect." -ForegroundColor Green
Write-Host "Then visit https://ibridgesolutions.co.za to check if the redirect is fixed." -ForegroundColor Green

# Offer to open the repository in a browser
$openRepo = Read-Host "Would you like to open the GitHub repository in your browser now? (y/n)"
if ($openRepo -eq "y") {
    Start-Process "https://github.com/iBridgeSolutions/iBridge"
}

# Offer to open the GitHub Pages settings
$openSettings = Read-Host "Would you like to open the GitHub Pages settings? (y/n)"
if ($openSettings -eq "y") {
    Start-Process "https://github.com/iBridgeSolutions/iBridge/settings/pages"
}
