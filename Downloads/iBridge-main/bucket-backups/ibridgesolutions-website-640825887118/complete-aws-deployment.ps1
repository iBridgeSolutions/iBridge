# Complete AWS Deployment Script
# This script helps finalize the AWS deployment for ibridgesolutions.co.za

# Header
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "     COMPLETE AWS DEPLOYMENT FOR IBRIDGESOLUTIONS" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host

# Get CloudFront info
$cloudFrontDomain = "diso379wpy1no.cloudfront.net"
if (Test-Path "cloudfront-info.txt") {
    $cloudFrontInfo = Get-Content -Path "cloudfront-info.txt" -Raw
    if ($cloudFrontInfo -match "Distribution Domain: (.+)$") {
        $cloudFrontDomain = $matches[1].Trim()
    }
}

# Current status
Write-Host "Current Deployment Status:" -ForegroundColor Yellow
Write-Host "- CloudFront Distribution: CREATED ✓" -ForegroundColor Green
Write-Host "- Distribution Domain: $cloudFrontDomain" -ForegroundColor Green
Write-Host "- Next Step: DNS Configuration" -ForegroundColor Yellow
Write-Host

# Main menu
Write-Host "Choose an action to continue deployment:" -ForegroundColor Cyan
Write-Host
Write-Host "1) Configure DNS options" -ForegroundColor White
Write-Host "2) Check DNS propagation status" -ForegroundColor White
Write-Host "3) Verify complete deployment" -ForegroundColor White
Write-Host "4) View current deployment status" -ForegroundColor White
Write-Host "5) Exit" -ForegroundColor White
Write-Host

$choice = Read-Host "Enter your choice (1-5)"

switch ($choice) {
    "1" {
        Write-Host "`nLaunching DNS configuration menu..." -ForegroundColor Yellow
        & powershell -ExecutionPolicy Bypass -File .\choose-dns-option.ps1
    }
    "2" {
        Write-Host "`nChecking DNS propagation status..." -ForegroundColor Yellow
        & powershell -ExecutionPolicy Bypass -File .\check-dns-propagation.ps1
    }
    "3" {
        Write-Host "`nVerifying complete deployment..." -ForegroundColor Yellow
        & powershell -ExecutionPolicy Bypass -File .\verify-full-deployment.ps1
    }
    "4" {
        Write-Host "`nOpening current status document..." -ForegroundColor Yellow
        Start-Process "notepad" -ArgumentList ".\CURRENT-STATUS-AND-NEXT-STEPS.md"
    }
    "5" {
        Write-Host "`nExiting..." -ForegroundColor Yellow
        exit
    }
    default {
        Write-Host "`nInvalid choice. Please run the script again and select a valid option." -ForegroundColor Red
    }
}
