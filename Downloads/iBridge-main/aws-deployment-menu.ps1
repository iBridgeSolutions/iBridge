# Interactive AWS Deployment Menu
# This script helps you continue with the AWS deployment for ibridgesolutions.co.za

# Header
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "     IBRIDGESOLUTIONS AWS DEPLOYMENT MENU" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Current Status: CloudFront Distribution Created" -ForegroundColor Green
Write-Host "Next Step: Configure DNS" -ForegroundColor Yellow
Write-Host

# Get CloudFront domain from file
$cloudFrontInfo = Get-Content -Path "cloudfront-info.txt" -Raw -ErrorAction SilentlyContinue
$cloudFrontDomain = "diso379wpy1no.cloudfront.net"
if ($cloudFrontInfo -match "Distribution Domain: (.+)$") {
    $cloudFrontDomain = $matches[1].Trim()
}

# Display CloudFront info
Write-Host "CloudFront Distribution Information:" -ForegroundColor Yellow
Write-Host "- Domain: $cloudFrontDomain" -ForegroundColor White
Write-Host "- This is where your website will be accessible from" -ForegroundColor White
Write-Host

# Main menu function
function Show-MainMenu {
    Write-Host "Choose a DNS Configuration Option:" -ForegroundColor Yellow
    Write-Host
    Write-Host "1) Use GoDaddy with A Records" -ForegroundColor White
    Write-Host "   - Simpler option, keeps DNS at GoDaddy" -ForegroundColor Gray
    Write-Host "   - Uses A records to point to CloudFront IP addresses" -ForegroundColor Gray
    Write-Host
    Write-Host "2) Use AWS Route 53 (Recommended)" -ForegroundColor White
    Write-Host "   - More robust solution with better support for CloudFront" -ForegroundColor Gray
    Write-Host "   - Requires changing nameservers in GoDaddy" -ForegroundColor Gray
    Write-Host
    Write-Host "3) View Current Deployment Status" -ForegroundColor White
    Write-Host
    Write-Host "4) Exit" -ForegroundColor White
    Write-Host
    
    $choice = Read-Host "Enter your choice (1-4)"
    
    switch ($choice) {
        "1" { Show-GoDaddyInstructions }
        "2" { Show-Route53Instructions }
        "3" { Show-DeploymentStatus }
        "4" { exit }
        default { 
            Write-Host "Invalid choice. Please try again." -ForegroundColor Red
            Show-MainMenu
        }
    }
}

# GoDaddy Instructions
function Show-GoDaddyInstructions {
    Clear-Host
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host "     GODADDY DNS CONFIGURATION INSTRUCTIONS" -ForegroundColor Cyan
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host
    Write-Host "You've chosen to use GoDaddy with A Records." -ForegroundColor Yellow
    Write-Host "This option will keep your DNS management at GoDaddy." -ForegroundColor Yellow
    Write-Host
    Write-Host "DNS Records to Add in GoDaddy:" -ForegroundColor Green
    Write-Host "------------------------------------------" -ForegroundColor White
    Write-Host "1. Root Domain (Apex): ibridgesolutions.co.za" -ForegroundColor White
    Write-Host "   - Type: A" -ForegroundColor White
    Write-Host "   - Points to: CloudFront IP addresses (Not recommended, GoDaddy may not accept)" -ForegroundColor Yellow
    Write-Host "   - Recommended: Use Route 53 for root domain support with CloudFront" -ForegroundColor Cyan
    Write-Host
    Write-Host "2. WWW Subdomain: www.ibridgesolutions.co.za" -ForegroundColor White
    Write-Host "   - Type: CNAME" -ForegroundColor White
    Write-Host "   - Points to: $cloudFrontDomain" -ForegroundColor Green
    Write-Host
    Write-Host "If GoDaddy does not allow A or CNAME for the root domain, migrate DNS to Route 53 (Option 2 in main menu)." -ForegroundColor Yellow
    Write-Host
    Write-Host "Would you like to:" -ForegroundColor Yellow
    Write-Host "1) Get step-by-step instructions" -ForegroundColor White
    Write-Host "2) View the visual guide" -ForegroundColor White
    Write-Host "3) Return to main menu" -ForegroundColor White
    Write-Host
    $choice = Read-Host "Enter your choice (1-3)"
    switch ($choice) {
        "1" { 
            Write-Host "`nExecuting setup-godaddy-a-records.ps1..." -ForegroundColor Yellow
            & powershell -ExecutionPolicy Bypass -File .\setup-godaddy-a-records.ps1
            Write-Host "`nPress Enter to return to menu..." -ForegroundColor Cyan
            Read-Host | Out-Null
            Show-GoDaddyInstructions
        }
        "2" { 
            Write-Host "`nOpening GODADDY-DNS-VISUAL-GUIDE.md..." -ForegroundColor Yellow
            Start-Process "notepad" -ArgumentList ".\GODADDY-DNS-VISUAL-GUIDE.md"
            Write-Host "`nPress Enter to return to menu..." -ForegroundColor Cyan
            Read-Host | Out-Null
            Show-GoDaddyInstructions
        }
        "3" { 
            Clear-Host
            Show-MainMenu 
        }
        default { 
            Write-Host "Invalid choice. Please try again." -ForegroundColor Red
            Show-GoDaddyInstructions
        }
    }
}

# Route 53 Instructions
function Show-Route53Instructions {
    Clear-Host
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host "     AWS ROUTE 53 CONFIGURATION INSTRUCTIONS" -ForegroundColor Cyan
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host
    
    Write-Host "You've chosen to use AWS Route 53 (Recommended)." -ForegroundColor Yellow
    Write-Host "This option will migrate your DNS management to AWS Route 53." -ForegroundColor Yellow
    Write-Host
    
    Write-Host "Would you like to:" -ForegroundColor Yellow
    Write-Host "1) Set up Route 53 now" -ForegroundColor White
    Write-Host "2) View information about Route 53" -ForegroundColor White
    Write-Host "3) Return to main menu" -ForegroundColor White
    Write-Host
    
    $choice = Read-Host "Enter your choice (1-3)"
    
    switch ($choice) {
        "1" { 
            Write-Host "`nExecuting setup-route53.ps1..." -ForegroundColor Yellow
            Write-Host "This will create a Route 53 hosted zone for ibridgesolutions.co.za." -ForegroundColor Yellow
            Write-Host "After completion, you'll need to update your nameservers in GoDaddy." -ForegroundColor Yellow
            Write-Host
            
            $confirm = Read-Host "Do you want to proceed? (y/n)"
            if ($confirm -eq "y" -or $confirm -eq "Y") {
                & powershell -ExecutionPolicy Bypass -File .\setup-route53.ps1
            }
            
            Write-Host "`nPress Enter to return to menu..." -ForegroundColor Cyan
            Read-Host | Out-Null
            Show-Route53Instructions
        }
        "2" { 
            Write-Host "`nOpening Route 53 information..." -ForegroundColor Yellow
            Write-Host
            Write-Host "AWS Route 53 Benefits:" -ForegroundColor Green
            Write-Host "- Properly supports root domains with CloudFront" -ForegroundColor White
            Write-Host "- Uses specialized 'Alias' records for AWS services" -ForegroundColor White
            Write-Host "- Better integration with other AWS services" -ForegroundColor White
            Write-Host "- More reliable and faster DNS resolution" -ForegroundColor White
            Write-Host
            Write-Host "Process:" -ForegroundColor Green
            Write-Host "1. Create a Route 53 hosted zone for your domain" -ForegroundColor White
            Write-Host "2. Set up DNS records pointing to CloudFront" -ForegroundColor White
            Write-Host "3. Update nameservers in GoDaddy to point to AWS" -ForegroundColor White
            Write-Host "4. Wait 24-48 hours for DNS propagation" -ForegroundColor White
            Write-Host
            Write-Host "`nPress Enter to return to menu..." -ForegroundColor Cyan
            Read-Host | Out-Null
            Show-Route53Instructions
        }
        "3" { 
            Clear-Host
            Show-MainMenu 
        }
        default { 
            Write-Host "Invalid choice. Please try again." -ForegroundColor Red
            Show-Route53Instructions
        }
    }
}

# Show Deployment Status
function Show-DeploymentStatus {
    Clear-Host
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host "     CURRENT DEPLOYMENT STATUS" -ForegroundColor Cyan
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host
    
    Write-Host "Completed Steps:" -ForegroundColor Green
    Write-Host "✓ AWS CLI installed" -ForegroundColor Green
    Write-Host "✓ S3 bucket created and configured" -ForegroundColor Green
    Write-Host "✓ Website files uploaded to S3" -ForegroundColor Green
    Write-Host "✓ SSL certificate requested and validated" -ForegroundColor Green
    Write-Host "✓ CloudFront distribution created" -ForegroundColor Green
    Write-Host
    
    Write-Host "Current Step:" -ForegroundColor Yellow
    Write-Host "► Configure DNS to point to CloudFront" -ForegroundColor Yellow
    Write-Host
    
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "1. Configure DNS (choose Option 1 or 2)" -ForegroundColor White
    Write-Host "2. Wait for DNS propagation (24-48 hours)" -ForegroundColor White
    Write-Host "3. Verify deployment with verify-full-deployment.ps1" -ForegroundColor White
    Write-Host
    
    Write-Host "Would you like to:" -ForegroundColor Yellow
    Write-Host "1) Check DNS propagation status" -ForegroundColor White
    Write-Host "2) View detailed deployment information" -ForegroundColor White
    Write-Host "3) Return to main menu" -ForegroundColor White
    Write-Host
    
    $choice = Read-Host "Enter your choice (1-3)"
    
    switch ($choice) {
        "1" { 
            Write-Host "`nChecking DNS propagation status..." -ForegroundColor Yellow
            & powershell -ExecutionPolicy Bypass -File .\check-dns-propagation.ps1
            Write-Host "`nPress Enter to return to menu..." -ForegroundColor Cyan
            Read-Host | Out-Null
            Show-DeploymentStatus
        }
        "2" { 
            Write-Host "`nOpening DEPLOYMENT-STATUS-SUMMARY.md..." -ForegroundColor Yellow
            Start-Process "notepad" -ArgumentList ".\DEPLOYMENT-STATUS-SUMMARY.md"
            Write-Host "`nPress Enter to return to menu..." -ForegroundColor Cyan
            Read-Host | Out-Null
            Show-DeploymentStatus
        }
        "3" { 
            Clear-Host
            Show-MainMenu 
        }
        default { 
            Write-Host "Invalid choice. Please try again." -ForegroundColor Red
            Show-DeploymentStatus
        }
    }
}

# Start with the main menu
Clear-Host
Show-MainMenu
