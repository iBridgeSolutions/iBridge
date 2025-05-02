# deploy.ps1
# 1. Move files from 'GitHub Pages Website' to parent directory (if any remain)
$websiteDir = Join-Path $PSScriptRoot 'GitHub Pages Website'
if (Test-Path $websiteDir) {
    $moveScript = Join-Path $websiteDir 'move-to-parent.ps1'
    if (Test-Path $moveScript) {
        Write-Host 'Moving files from GitHub Pages Website...'
        & $moveScript
    }
}

# 2. Git add, commit, and push
Write-Host 'Staging all changes...'
git add .
Write-Host 'Committing changes...'
git commit -m "Automated deployment to GitHub Pages" | Out-Null
Write-Host 'Pushing to GitHub...'
git push

# 3. Open GitHub Pages settings (customize your repo URL below)
$repoUrl = "https://github.com/Blxckukno/iBridge/settings/pages"
Start-Process $repoUrl

Write-Host 'Deployment script finished. Complete GitHub Pages setup in your browser if needed.'
