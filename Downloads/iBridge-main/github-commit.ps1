# Script to commit and push changes to GitHub
Write-Host "==================================" -ForegroundColor Cyan
Write-Host "GitHub Commit & Push Utility" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
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

# Function to commit and push changes
function Commit-AndPushToGitHub {
    param(
        [string]$CommitMessage
    )
    
    # Add all modified files
    Write-Host "Adding modified files..." -ForegroundColor Yellow
    git add about.html ai-automation.html contact-center.html contact.html it-support.html index.html services.html
    git add css/* js/*
    
    # Add new script files
    git add preview-website.ps1 start-website-preview.ps1 validate-contact-center.ps1
    
    # Commit changes
    Write-Host "Committing changes..." -ForegroundColor Yellow
    git commit -m "$CommitMessage"
    
    # Push to remote repository
    Write-Host "Pushing to GitHub..." -ForegroundColor Yellow
    git push origin gh-pages
    
    # Check status after push
    Write-Host "Checking final status..." -ForegroundColor Yellow
    git status
}

# Main execution
if (Check-GitInstalled) {
    # Display current branch and status
    Write-Host "Current Git Status:" -ForegroundColor Yellow
    git status
    
    # Get commit message from user
    $defaultMessage = "Update Contact Center page to standalone page and update all site navigation/footer links"
    $commitMessage = Read-Host "Enter commit message (default: '$defaultMessage')"
    
    if ([string]::IsNullOrWhiteSpace($commitMessage)) {
        $commitMessage = $defaultMessage
    }
    
    # Confirm before proceeding
    $confirmation = Read-Host "Ready to commit and push changes to GitHub? (y/n)"
    if ($confirmation -eq 'y' -or $confirmation -eq 'Y') {
        Commit-AndPushToGitHub -CommitMessage $commitMessage
        
        Write-Host "`nGitHub update completed!" -ForegroundColor Green
        Write-Host "To deploy to AWS, run: .\deploy-to-aws.ps1" -ForegroundColor Cyan
    } else {
        Write-Host "Operation cancelled by user." -ForegroundColor Yellow
    }
} else {
    Write-Host "Please install Git and try again." -ForegroundColor Red
}
