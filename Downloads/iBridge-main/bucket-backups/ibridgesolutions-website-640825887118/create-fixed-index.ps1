# Simple Fix for iBridge Website

Write-Host "This script will create a fixed index.html file for your website" -ForegroundColor Cyan
Write-Host

# Get the current location
$scriptPath = Get-Location
$tempIndexPath = Join-Path $scriptPath "temp-index.html"
$fixedIndexPath = Join-Path $scriptPath "fixed-index.html"

# Check if temporary index file exists
if (-not (Test-Path $tempIndexPath)) {
    Write-Host "Error: temp-index.html not found at $tempIndexPath" -ForegroundColor Red
    exit
}

# Create a fixed index.html that addresses the /lander issue
Write-Host "Creating fixed index.html file..." -ForegroundColor Yellow

# Read the temp-index.html content
$tempContent = Get-Content $tempIndexPath -Raw

# Add a script to prevent redirection
$fixedContent = $tempContent -replace '</body>', @'
<!-- Anti-redirect script -->
<script>
if (window.location.pathname.includes('/lander')) {
    // Remove /lander from URL and redirect
    var newPath = window.location.pathname.replace('/lander', '');
    window.history.replaceState({}, document.title, newPath);
    console.log("Prevented redirect to /lander");
}
</script>
</body>
'@

# Create the fixed index.html
$fixedContent | Out-File -FilePath $fixedIndexPath -Encoding utf8

# Also create a .nojekyll file
Write-Host "Creating .nojekyll file..." -ForegroundColor Yellow
"" | Out-File -FilePath (Join-Path $scriptPath ".nojekyll") -Encoding utf8

Write-Host "`nDone!" -ForegroundColor Green
Write-Host "Files created:" -ForegroundColor Green
Write-Host "1. fixed-index.html - Use this as your main index.html" -ForegroundColor Yellow
Write-Host "2. .nojekyll - Upload this to your repository root" -ForegroundColor Yellow
Write-Host "`nInstructions:" -ForegroundColor Cyan
Write-Host "1. Upload these files to your GitHub repository" -ForegroundColor White
Write-Host "2. If you're using GoDaddy, make sure to disable any default landing page" -ForegroundColor White
Write-Host "   - Log in to your GoDaddy account" -ForegroundColor White
Write-Host "   - Go to your domain settings" -ForegroundColor White
Write-Host "   - Look for 'Forwarding' or 'Redirect' settings and disable them" -ForegroundColor White
