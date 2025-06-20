# Repository Cleanup Script for iBridge Website
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host " iBridge Website Repository Cleanup Tool" -ForegroundColor Cyan  
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

# Function to offer repository cleanup options
function Show-CleanupOptions {
    Write-Host "`nRepository Cleanup Options:" -ForegroundColor Yellow
    Write-Host "1. Discard all local changes (reset to HEAD)" -ForegroundColor White
    Write-Host "2. Reset to remote branch state (hard reset)" -ForegroundColor White
    Write-Host "3. Clean untracked files (remove files not in git)" -ForegroundColor White
    Write-Host "4. Exit" -ForegroundColor White
    
    $option = Read-Host "`nSelect an option (1-4)"
    return $option
}

# Function to discard all local changes
function Discard-LocalChanges {
    Write-Host "`nDiscarding all local changes..." -ForegroundColor Yellow
    git checkout -- .
    Write-Host "All local changes have been discarded." -ForegroundColor Green
    Write-Host "Current status:" -ForegroundColor Yellow
    git status
}

# Function to reset to remote branch state
function Reset-ToRemote {
    $currentBranch = git rev-parse --abbrev-ref HEAD
    Write-Host "`nResetting to remote state of branch '$currentBranch'..." -ForegroundColor Yellow
    
    # Pull latest changes first
    git fetch origin
    
    # Hard reset to origin/current-branch
    git reset --hard origin/$currentBranch
    
    Write-Host "Repository has been reset to match the remote branch '$currentBranch'." -ForegroundColor Green
    Write-Host "Current status:" -ForegroundColor Yellow
    git status
}

# Function to clean untracked files
function Clean-UntrackedFiles {
    Write-Host "`nThis will remove all untracked files. This action cannot be undone!" -ForegroundColor Red
    $confirm = Read-Host "Are you sure you want to continue? (y/n)"
    
    if ($confirm -eq 'y' -or $confirm -eq 'Y') {
        # First show what would be deleted (dry run)
        Write-Host "Files that will be removed:" -ForegroundColor Yellow
        git clean -n -d
        
        # Confirm again before actually deleting
        $finalConfirm = Read-Host "`nConfirm deletion of these files? (y/n)"
        if ($finalConfirm -eq 'y' -or $finalConfirm -eq 'Y') {
            git clean -f -d
            Write-Host "All untracked files have been removed." -ForegroundColor Green
        } else {
            Write-Host "Operation cancelled." -ForegroundColor Yellow
        }
    } else {
        Write-Host "Operation cancelled." -ForegroundColor Yellow
    }
}

# Main execution
if (Check-GitInstalled) {
    # Show current status
    Write-Host "Current Git Status:" -ForegroundColor Yellow
    git status
    
    # Show options and get user choice
    $exitRequested = $false
    while (-not $exitRequested) {
        $option = Show-CleanupOptions
        
        switch ($option) {
            "1" {
                Discard-LocalChanges
            }
            "2" {
                Reset-ToRemote
            }
            "3" {
                Clean-UntrackedFiles
            }
            "4" {
                $exitRequested = $true
                Write-Host "Exiting cleanup tool." -ForegroundColor Green
            }
            default {
                Write-Host "Invalid option. Please select a number between 1-4." -ForegroundColor Red
            }
        }
        
        if (-not $exitRequested) {
            $continue = Read-Host "`nPerform another operation? (y/n)"
            if ($continue -ne 'y' -and $continue -ne 'Y') {
                $exitRequested = $true
                Write-Host "Exiting cleanup tool." -ForegroundColor Green
            }
        }
    }
} else {
    Write-Host "Please install Git and try again." -ForegroundColor Red
}
