# Simplified GitHub Commit Script for iBridge Website
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host " iBridge Website Simplified GitHub Commit Tool" -ForegroundColor Cyan  
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host

# Function to check if git is installed
function Check-GitInstalled {
    try {
        $gitVersion = git --version
        Write-Host "Git is installed: $gitVersion" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "Git is not installed or not in PATH!" -ForegroundColor Red
        return $false
    }
}

# Function to commit only essential HTML files
function Commit-EssentialFiles {
    param(
        [string]$CommitMessage
    )
    
    Write-Host "Committing only essential Contact Center page changes..." -ForegroundColor Yellow
    
    # Essential files that were modified for website style updates and omnichannel additions
    $essentialFiles = @(
        "index.html",
        "omnichannel.html",
        "about.html", 
        "services.html",
        "contact.html",
        "contact-center.html",
        "it-support.html",
        "ai-automation.html",
        "css/styles-fixed.css",
        "css/style-enhancements.css",
        "sync-to-aws.ps1"
    )
    
    # Check which files exist and add them individually to staging
    foreach ($file in $essentialFiles) {
        if (Test-Path $file) {
            Write-Host "Adding $file to staging..." -ForegroundColor White
            git add $file
            Write-Host "√ Added $file" -ForegroundColor Green
        }
    }
    
    # Commit only the staged changes
    Write-Host "Committing changes with message: $CommitMessage" -ForegroundColor Yellow
    git commit -m "$CommitMessage"    # Get current branch
    $currentBranch = (git rev-parse --abbrev-ref HEAD).Trim()
    
    # Push to remote repository
    Write-Host "Pushing to GitHub on branch $currentBranch..." -ForegroundColor Yellow
    git push origin $currentBranch
    
    # Show status after push
    Write-Host "GitHub commit status:" -ForegroundColor Yellow
    git status
}

# Main execution
if (Check-GitInstalled) {
    # Show current status
    Write-Host "Current Git Status:" -ForegroundColor Yellow
    git status
      # Get commit message from user
    $defaultMessage = "Improve website styling and move Omnichannel Experience to header navigation"
    $commitMessage = Read-Host "Enter commit message (default: '$defaultMessage')"
    
    if ([string]::IsNullOrWhiteSpace($commitMessage)) {
        $commitMessage = $defaultMessage
    }
    
    # Confirm before proceeding
    $confirmation = Read-Host "Ready to commit only essential HTML files to GitHub? (y/n)"
    if ($confirmation -eq 'y' -or $confirmation -eq 'Y') {        Commit-EssentialFiles -CommitMessage $commitMessage
        Write-Host "`n=================================================" -ForegroundColor Cyan
        Write-Host " GITHUB COMMIT COMPLETED!" -ForegroundColor Cyan
        Write-Host "=================================================" -ForegroundColor Cyan
        
        # Ask if user wants to sync to AWS
        $syncAWS = Read-Host "Would you like to sync changes to AWS S3? (y/n)"
        if ($syncAWS -eq 'y' -or $syncAWS -eq 'Y') {
            Write-Host "Syncing to AWS S3..." -ForegroundColor Yellow
            & .\sync-to-aws.ps1
            Write-Host "`n=================================================" -ForegroundColor Cyan
            Write-Host " AWS SYNC COMPLETED!" -ForegroundColor Cyan
            Write-Host "=================================================" -ForegroundColor Cyan
        }
    } else {
        Write-Host "Operation cancelled." -ForegroundColor Yellow
    }
} else {
    Write-Host "Please install Git and try again." -ForegroundColor Red
}
