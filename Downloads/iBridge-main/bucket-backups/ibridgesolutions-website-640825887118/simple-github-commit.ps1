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
    
    # Essential files that were modified for Contact Center Solutions change
    $essentialFiles = @(
        "index.html",
        "about.html", 
        "services.html",
        "contact.html",
        "contact-center.html",
        "it-support.html",
        "ai-automation.html"
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
    git commit -m "$CommitMessage"
    
    # Push to remote repository
    Write-Host "Pushing to GitHub..." -ForegroundColor Yellow
    git push origin gh-pages
    
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
    $defaultMessage = "Update Contact Center Solutions to standalone page and update navigation links"
    $commitMessage = Read-Host "Enter commit message (default: '$defaultMessage')"
    
    if ([string]::IsNullOrWhiteSpace($commitMessage)) {
        $commitMessage = $defaultMessage
    }
    
    # Confirm before proceeding
    $confirmation = Read-Host "Ready to commit only essential HTML files to GitHub? (y/n)"
    if ($confirmation -eq 'y' -or $confirmation -eq 'Y') {
        Commit-EssentialFiles -CommitMessage $commitMessage
        Write-Host "`n=================================================" -ForegroundColor Cyan
        Write-Host " GITHUB COMMIT COMPLETED!" -ForegroundColor Cyan
        Write-Host "=================================================" -ForegroundColor Cyan
    } else {
        Write-Host "Operation cancelled." -ForegroundColor Yellow
    }
} else {
    Write-Host "Please install Git and try again." -ForegroundColor Red
}
