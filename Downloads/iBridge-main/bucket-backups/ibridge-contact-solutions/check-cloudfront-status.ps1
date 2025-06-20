# Check CloudFront Distribution Status
# This script checks if the CloudFront distribution has been created and extracts information

$awsExePath = "C:\Program Files\Amazon\AWSCLIV2\aws.exe"

Write-Host "Checking CloudFront distribution status..." -ForegroundColor Cyan

# Check if we have the output file from CloudFront creation
if (Test-Path "cloudfront-output.txt") {
    $cfOutput = Get-Content -Path "cloudfront-output.txt" -Raw
    
    # Extract Distribution ID and Domain Name
    $distId = if ($cfOutput -match '"Id":\s*"([^"]+)"') { $matches[1] } else { "Unknown" }
    $distDomain = if ($cfOutput -match '"DomainName":\s*"([^"]+)"') { $matches[1] } else { "Unknown" }
    
    Write-Host "CloudFront Distribution Information:" -ForegroundColor Green
    Write-Host "  Distribution ID: $distId" -ForegroundColor Cyan
    Write-Host "  Distribution Domain: $distDomain" -ForegroundColor Cyan
    
    # Save or update CloudFront info
    if ($distId -ne "Unknown" -and $distDomain -ne "Unknown") {
        $certificateArn = Get-Content -Path "certificate-arn.txt" -Raw
        $certificateArn = $certificateArn.Trim()
        
        @"
CloudFront Distribution Information
==================================
Distribution ID: $distId
Distribution Domain: $distDomain
SSL Certificate ARN: $certificateArn
"@ | Out-File -FilePath "cloudfront-info.txt" -Encoding ascii
        
        Write-Host "CloudFront information saved to cloudfront-info.txt" -ForegroundColor Green
        
        # Display DNS configuration instructions
        Write-Host "`nDNS Configuration Instructions:" -ForegroundColor Yellow
        Write-Host "Add these DNS records to GoDaddy:" -ForegroundColor White
        
        Write-Host "`nFor www subdomain:" -ForegroundColor Cyan
        Write-Host "Type: CNAME" -ForegroundColor White
        Write-Host "Host: www" -ForegroundColor White
        Write-Host "Points to: $distDomain" -ForegroundColor White
        Write-Host "TTL: 1 Hour" -ForegroundColor White
        
        Write-Host "`nFor root domain (if GoDaddy allows):" -ForegroundColor Cyan
        Write-Host "Type: CNAME" -ForegroundColor White
        Write-Host "Host: @" -ForegroundColor White
        Write-Host "Points to: $distDomain" -ForegroundColor White
        Write-Host "TTL: 1 Hour" -ForegroundColor White
        
        Write-Host "`nNote: GoDaddy may not support CNAME for root domains. See Complete-DNS-Guide.md for alternatives." -ForegroundColor Yellow
    } else {
        Write-Host "Could not extract complete CloudFront distribution information." -ForegroundColor Yellow
    }
} else {
    Write-Host "CloudFront distribution output file not found." -ForegroundColor Red
    Write-Host "If you've already run simplified-cloudfront-setup.ps1, check for any errors during execution." -ForegroundColor Yellow
}

# Provide information on how to manually view distributions
Write-Host "`nTo manually list CloudFront distributions, run:" -ForegroundColor Yellow
Write-Host "& '$awsExePath' cloudfront list-distributions --region us-east-1" -ForegroundColor White

Write-Host "`nNext Steps:" -ForegroundColor Green
Write-Host "1. Configure DNS in GoDaddy using the instructions above" -ForegroundColor White
Write-Host "2. Wait for DNS propagation (24-48 hours)" -ForegroundColor White
Write-Host "3. Run verify-deployment-status.ps1 to check the overall deployment" -ForegroundColor White
