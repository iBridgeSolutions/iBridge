# iBridge Complete Hosting Setup Script
# This script guides you through setting up hosting for your website using:
# 1. GitHub Pages (primary hosting)
# 2. GoDaddy (DNS management)
# 3. AWS (optional CloudFront/S3 with SSL)

$domainName = "ibridgesolutions.co.za"
$githubUser = "iBridgeSolutions" # Replace with your actual GitHub username
$repoName = "iBridge-main" # Replace with your actual repository name

Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "   iBridge COMPLETE HOSTING SETUP ASSISTANT   " -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Verify local repository setup
Write-Host "STEP 1: Verifying Local Repository Setup" -ForegroundColor Green
Write-Host "----------------------------------------" -ForegroundColor Green

# Check if CNAME file exists with correct content
$cnameContent = Get-Content -Path ".\CNAME" -ErrorAction SilentlyContinue
if ($cnameContent -ne $domainName) {
    Write-Host "Creating/Updating CNAME file with domain: $domainName" -ForegroundColor Yellow
    $domainName | Out-File -FilePath ".\CNAME" -NoNewline -Encoding utf8
    Write-Host "✅ CNAME file created/updated" -ForegroundColor Green
} else {
    Write-Host "✅ CNAME file already exists with correct domain" -ForegroundColor Green
}

# Step 2: GitHub Pages Setup
Write-Host "`nSTEP 2: GitHub Pages Setup" -ForegroundColor Green
Write-Host "-----------------------" -ForegroundColor Green
Write-Host "Please perform these actions in your GitHub repository:"
Write-Host "1. Go to https://github.com/$githubUser/$repoName/settings/pages"
Write-Host "2. Under 'Source', select either 'gh-pages' branch or 'main'"
Write-Host "3. Under 'Custom domain', enter: $domainName"
Write-Host "4. Check 'Enforce HTTPS' (once certificate is provisioned)"
Write-Host "5. Click 'Save'"

$githubPagesIPs = @(
    "185.199.108.153",
    "185.199.109.153", 
    "185.199.110.153", 
    "185.199.111.153"
)

Write-Host "`nGitHub Pages IP addresses (for DNS setup):" -ForegroundColor Yellow
$githubPagesIPs | ForEach-Object { Write-Host $_ }

# Step 3: GoDaddy DNS Setup
Write-Host "`nSTEP 3: GoDaddy DNS Setup" -ForegroundColor Green
Write-Host "-----------------------" -ForegroundColor Green
Write-Host "Please configure these DNS records at GoDaddy:"
Write-Host "1. Login to your GoDaddy account"
Write-Host "2. Go to My Products > DNS > Manage DNS for $domainName"
Write-Host "3. Add/update the following A records for your root domain:"

foreach ($ip in $githubPagesIPs) {
    Write-Host "   - A record: @ -> $ip (TTL: 600 or 1 hour)"
}

Write-Host "4. Add/update CNAME record for www subdomain:"
Write-Host "   - CNAME record: www -> $githubUser.github.io (TTL: 600 or 1 hour)"

# Check if we have the godaddy-dns-fix.ps1 script
if (Test-Path ".\godaddy-dns-fix.ps1") {
    Write-Host "`n🔍 Found GoDaddy DNS helper script in repository" -ForegroundColor Cyan
    Write-Host "You can also run 'godaddy-dns-fix.ps1' for automated DNS setup if you have GoDaddy API credentials"
}

# Step 4: Verify DNS Configuration
Write-Host "`nSTEP 4: Verify DNS Configuration" -ForegroundColor Green
Write-Host "------------------------------" -ForegroundColor Green
Write-Host "Would you like to check the current DNS configuration? (Y/N)"
$checkDNS = Read-Host
if ($checkDNS -eq "Y" -or $checkDNS -eq "y") {
    Write-Host "`nChecking DNS configuration for $domainName..."
    nslookup $domainName
    Write-Host "`nChecking DNS configuration for www.$domainName..."
    nslookup www.$domainName
    
    Write-Host "`n⚠️ Note: DNS changes can take 24-48 hours to fully propagate" -ForegroundColor Yellow
}

# Step 5: AWS Integration (Optional)
Write-Host "`nSTEP 5: AWS Integration (Optional)" -ForegroundColor Green
Write-Host "-------------------------------" -ForegroundColor Green
Write-Host "Would you like to set up AWS hosting with CloudFront/S3? (Y/N)"
$setupAWS = Read-Host

if ($setupAWS -eq "Y" -or $setupAWS -eq "y") {
    # Check for existing AWS deployment scripts
    $awsScripts = @(
        "deploy-to-aws.ps1",
        "complete-aws-deployment.ps1",
        "aws-deployment-menu.ps1",
        "github-aws-deploy.ps1"
    )
    
    $foundScript = $false
    foreach ($script in $awsScripts) {
        if (Test-Path ".\$script") {
            $foundScript = $true
            Write-Host "`n🔍 Found AWS deployment script: $script" -ForegroundColor Cyan
            Write-Host "Running AWS deployment script..."
            & ".\$script"
            break
        }
    }
    
    if (-not $foundScript) {
        Write-Host "`n❌ No AWS deployment scripts found. Creating basic AWS setup instructions..." -ForegroundColor Yellow
        
        # Create basic AWS deployment instructions
        $awsInstructions = @"
# AWS Deployment Instructions

## Prerequisites
1. Install AWS CLI: https://aws.amazon.com/cli/
2. Configure AWS credentials: Run `aws configure`

## S3 Bucket Setup
1. Create an S3 bucket for your website:
   ```
   aws s3 mb s3://$domainName --region us-east-1
   ```

2. Enable website hosting on the bucket:
   ```
   aws s3 website s3://$domainName --index-document index.html --error-document error.html
   ```

3. Upload your website files:
   ```
   aws s3 sync . s3://$domainName --exclude "*.ps1" --exclude "*.md" --exclude ".git/*"
   ```

## CloudFront Setup
1. Request an SSL certificate in ACM:
   ```
   aws acm request-certificate --domain-name $domainName --validation-method DNS --subject-alternative-names www.$domainName
   ```

2. Create a CloudFront distribution pointing to your S3 bucket
3. Update your DNS settings to point to the CloudFront distribution

For more detailed instructions, please refer to the AWS documentation:
https://docs.aws.amazon.com/AmazonS3/latest/userguide/website-hosting-custom-domain-walkthrough.html
"@

        $awsInstructions | Out-File -FilePath ".\AWS-SETUP-INSTRUCTIONS.md" -Encoding utf8
        Write-Host "✅ Created AWS-SETUP-INSTRUCTIONS.md with basic AWS setup instructions" -ForegroundColor Green
    }
}

# Final Step: Confirm and commit changes
Write-Host "`nFINAL STEP: Commit and push changes" -ForegroundColor Green
Write-Host "--------------------------------" -ForegroundColor Green
Write-Host "Would you like to commit and push your changes to GitHub? (Y/N)"
$commitChanges = Read-Host

if ($commitChanges -eq "Y" -or $commitChanges -eq "y") {
    Write-Host "`nCommitting changes to repository..."
    git add .
    git commit -m "Update hosting configuration for GitHub Pages and AWS"
    git push
    Write-Host "✅ Changes committed and pushed to GitHub" -ForegroundColor Green
}

Write-Host "`n==============================================" -ForegroundColor Cyan
Write-Host "  SETUP COMPLETE! NEXT STEPS TO CHECK:         " -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "1. Wait for DNS propagation (24-48 hours)"
Write-Host "2. Verify website is accessible at: https://$domainName"
Write-Host "3. Verify website is accessible at: https://www.$domainName"
Write-Host "4. Check GitHub Pages settings for SSL certificate status"
if ($setupAWS -eq "Y" -or $setupAWS -eq "y") {
    Write-Host "5. Complete AWS CloudFront/SSL setup if needed"
}
Write-Host "`nThank you for using the iBridge Complete Hosting Setup Assistant!"
