# Check CNAME file for GitHub Pages
# This script checks if the CNAME file exists and contains the correct domain

$domainName = "ibridgesolutions.co.za"

Write-Host "Checking CNAME file for GitHub Pages..." -ForegroundColor Cyan
Write-Host "-------------------------------------" -ForegroundColor Cyan

# Check if CNAME file exists
if (Test-Path ".\CNAME") {
    $cnameContent = Get-Content -Path ".\CNAME" -ErrorAction SilentlyContinue
    
    # Check if content matches expected domain
    if ($cnameContent -eq $domainName) {
        Write-Host "✅ CNAME file found with correct content: $cnameContent" -ForegroundColor Green
    } else {
        Write-Host "⚠️ CNAME file found but contains incorrect content:" -ForegroundColor Yellow
        Write-Host "   Current: $cnameContent" -ForegroundColor Yellow
        Write-Host "   Expected: $domainName" -ForegroundColor Yellow
        
        Write-Host "`nWould you like to update the CNAME file with the correct domain? (Y/N)"
        $updateCNAME = Read-Host
        
        if ($updateCNAME -eq "Y" -or $updateCNAME -eq "y") {
            $domainName | Out-File -FilePath ".\CNAME" -NoNewline -Encoding utf8
            Write-Host "✅ CNAME file updated with correct domain: $domainName" -ForegroundColor Green
        }
    }
} else {
    Write-Host "❌ CNAME file not found" -ForegroundColor Red
    
    Write-Host "`nWould you like to create a CNAME file with the correct domain? (Y/N)"
    $createCNAME = Read-Host
    
    if ($createCNAME -eq "Y" -or $createCNAME -eq "y") {
        $domainName | Out-File -FilePath ".\CNAME" -NoNewline -Encoding utf8
        Write-Host "✅ CNAME file created with domain: $domainName" -ForegroundColor Green
    }
}

# Remind about committing the changes
if ($updateCNAME -eq "Y" -or $createCNAME -eq "Y") {
    Write-Host "`nRemember to commit and push the CNAME file to your repository:" -ForegroundColor Cyan
    Write-Host "git add CNAME"
    Write-Host "git commit -m 'Add CNAME file for GitHub Pages'"
    Write-Host "git push"
}

Write-Host "`nFor GitHub Pages to use your custom domain ($domainName):" -ForegroundColor Cyan
Write-Host "1. The CNAME file must be in the root of your repository"
Write-Host "2. The file should contain only the domain name (no www, http, or other text)"
Write-Host "3. The domain must be properly configured with DNS settings"
Write-Host "   - A records for root domain pointing to GitHub Pages IP addresses"
Write-Host "   - CNAME record for www subdomain pointing to your github.io domain"
