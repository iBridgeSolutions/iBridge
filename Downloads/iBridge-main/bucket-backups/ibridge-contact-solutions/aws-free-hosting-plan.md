# AWS Free Tier Hosting Plan for iBridgeSolutions.co.za

This guide will help you deploy your website to AWS using 100% free tier services while setting up your custom domain (ibridgesolutions.co.za) properly to avoid redirects.

## Overview of Solution

We'll use these AWS free tier services:
- **Amazon S3** for static website hosting
- **CloudFront** for global content delivery (CDN) with HTTPS
- **Route 53** for DNS management
- **Certificate Manager** for free SSL certificates

## Step 1: Set Up AWS Account

1. Create a new AWS account if you don't have one
   - Go to [https://aws.amazon.com/](https://aws.amazon.com/)
   - Click "Create an AWS Account"
   - Follow the sign-up process (requires credit card but we'll only use free tier)
   - Choose the Basic Support plan (free)

## Step 2: Create S3 Bucket for Website Hosting

1. Log in to AWS Management Console
2. Navigate to S3 service
3. Create a bucket:
   - Click "Create bucket"
   - Name: `ibridgesolutions.co.za` (exactly matching your domain)
   - Region: Choose the closest to your users (e.g., eu-west-1 for Europe/Africa)
   - Uncheck "Block all public access"
   - Acknowledge the warning about making the bucket public
   - Keep other settings default
   - Click "Create bucket"

4. Configure bucket for static website hosting:
   - Select your new bucket
   - Go to "Properties" tab
   - Scroll to "Static website hosting"
   - Click "Edit"
   - Select "Enable"
   - Set "Index document" to `index.html`
   - Set "Error document" to `error.html` or `index.html`
   - Click "Save changes"

5. Set bucket policy for public access:
   - Go to "Permissions" tab
   - Click "Bucket policy"
   - Add the following policy (replace with your bucket name):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::ibridgesolutions.co.za/*"
    }
  ]
}
```

## Step 3: Request SSL Certificate

1. Navigate to AWS Certificate Manager
2. Click "Request certificate"
3. Choose "Request a public certificate"
4. Add domain names:
   - `ibridgesolutions.co.za`
   - `*.ibridgesolutions.co.za` (for subdomains including www)
5. Choose "DNS validation" method
6. Click "Request"
7. Follow the validation process:
   - Expand each domain
   - Click "Create records in Route 53"
   - Click "Create records"
   - Wait for validation (can take up to 30 minutes)

## Step 4: Create CloudFront Distribution

1. Navigate to CloudFront service
2. Click "Create distribution"
3. Configure origin:
   - Origin domain: Select your S3 website endpoint (e.g., ibridgesolutions.co.za.s3-website-eu-west-1.amazonaws.com)
   - Origin path: Leave empty
   - Name: auto-generated
   - Origin access: "Public"
4. Default cache behavior:
   - Viewer protocol policy: "Redirect HTTP to HTTPS"
   - Cache policy: "CachingOptimized"
   - Origin request policy: "CORS-S3Origin"
5. Settings:
   - Price class: "Use only North America and Europe" (cheapest)
   - Alternate domain names (CNAMEs): Add `ibridgesolutions.co.za` and `www.ibridgesolutions.co.za`
   - Custom SSL certificate: Select the certificate you created
   - Default root object: `index.html`
   - Standard logging: Off
6. Click "Create distribution"
7. Wait for deployment (takes about 15 minutes)
8. Note your CloudFront distribution domain name (e.g., d1234abcdef.cloudfront.net)

## Step 5: Configure Route 53 for Your Domain

1. Navigate to Route 53 service
2. Create a hosted zone:
   - Click "Create hosted zone"
   - Domain name: `ibridgesolutions.co.za`
   - Type: "Public hosted zone"
   - Click "Create hosted zone"

3. Update DNS records:
   - Select your hosted zone
   - Click "Create record"
   - Create A record:
     - Name: Leave empty (for apex domain)
     - Record type: A
     - Toggle "Alias"
     - Route traffic to: "Alias to CloudFront distribution"
     - Select your CloudFront distribution
     - Routing policy: "Simple routing"
     - Click "Create record"

   - Create another record for www:
     - Name: `www`
     - Record type: CNAME
     - Value: Your CloudFront distribution domain name (e.g., d1234abcdef.cloudfront.net)
     - TTL: 300
     - Click "Create record"

4. Note the Route 53 nameservers:
   - In your hosted zone, look for NS (nameserver) records
   - There will be four nameserver addresses
   - Copy these addresses for the next step

## Step 6: Update GoDaddy DNS Settings

1. Log in to your GoDaddy account
2. Navigate to your domain management page
3. Find `ibridgesolutions.co.za` and select "Manage DNS"
4. Find the Nameserver section
5. Select "Custom" nameservers
6. Remove existing nameservers
7. Add the four Route 53 nameservers you noted
8. Save changes

## Step 7: Upload Website to S3

1. Prepare your website files:
   - Create an `error.html` page if you don't have one
   - Make sure all internal links use relative paths
   - Create a `.nojekyll` file at the root to prevent GitHub Pages processing

2. Upload files to S3:
   - Return to S3 console
   - Select your bucket
   - Click "Upload"
   - Drag and drop all website files or click "Add files"
   - Click "Upload"
   - Make sure you maintain the file structure (folders etc.)

## Step 8: Create Simple Deployment Script

```powershell
# AWS Deployment Script for iBridgeSolutions Website
# Save as: deploy-to-aws.ps1

# Install AWS CLI if needed (uncomment line below first time)
# Invoke-WebRequest -Uri "https://awscli.amazonaws.com/AWSCLIV2.msi" -OutFile "AWSCLIV2.msi"; Start-Process msiexec.exe -Wait -ArgumentList "/i AWSCLIV2.msi /quiet"; Remove-Item "AWSCLIV2.msi"

# Configuration
$websiteFolder = "c:\Users\Lwandile Gasela\Downloads\iBridge-main\iBridge-main\iBridge-main"
$s3BucketName = "ibridgesolutions.co.za"

# Login to AWS (run once)
# aws configure

Write-Host "==============================================" -ForegroundColor Yellow
Write-Host "  Deploying iBridgeSolutions Website to AWS" -ForegroundColor Yellow
Write-Host "==============================================" -ForegroundColor Yellow

# Sync website files to S3
Write-Host "`nUploading website files to S3..." -ForegroundColor Cyan
aws s3 sync $websiteFolder s3://$s3BucketName --delete

# Invalidate CloudFront cache for immediate updates
Write-Host "`nInvalidating CloudFront cache..." -ForegroundColor Cyan
$distributionId = "YOUR_CLOUDFRONT_DISTRIBUTION_ID" # Replace with your actual CloudFront distribution ID
aws cloudfront create-invalidation --distribution-id $distributionId --paths "/*"

Write-Host "`nDeployment complete! Website updated at https://ibridgesolutions.co.za" -ForegroundColor Green
Write-Host "Note: It may take a few minutes for CloudFront to refresh its cache." -ForegroundColor Yellow
```

## Step 9: Monitor and Test Your Website

1. Wait for DNS propagation (can take 24-48 hours)
2. Test your website:
   - Visit https://ibridgesolutions.co.za
   - Test the www subdomain: https://www.ibridgesolutions.co.za
   - Check that HTTPS works properly
   - Test page loading speeds
   - Check all links and images
   - Verify there's no redirect to /lander

## Security Benefits of This Setup

1. **CloudFront CDN Protection**: Acts as a layer between your content and potential threats
2. **SSL/TLS Encryption**: Free SSL certificate from AWS Certificate Manager
3. **AWS Security**: Built-in DDoS protection and security features
4. **Content Redundancy**: Content served from global edge locations
5. **No Server Management**: No need to worry about server security patches

## Ongoing Maintenance

1. **Regular Updates**:
   - Edit website files locally
   - Run the deployment script to update S3 and invalidate CloudFront cache

2. **Costs to Monitor** (to stay in free tier):
   - S3: First 5 GB storage free per month
   - CloudFront: First 50 GB data transfer free per month
   - Route 53: Has minimal cost ($0.50/month for hosted zone)

## Troubleshooting Common Issues

1. **Website not updating after deployment**:
   - Check S3 bucket for updated files
   - Manually invalidate CloudFront cache
   - Try hard refresh in browser (Ctrl+F5)

2. **SSL certificate issues**:
   - Verify domain validation is complete in Certificate Manager
   - Make sure certificate region is us-east-1 for CloudFront use

3. **Domain not resolving to AWS**:
   - Check GoDaddy nameservers are correctly set to Route 53
   - Verify Route 53 records are correctly pointing to CloudFront
   - Use DNS propagation checkers to monitor progress

4. **Redirect issues persist**:
   - Check for meta refreshes in HTML
   - Clear browser cache completely
   - Test from different network/device

## AWS vs GitHub Pages Comparison

| Feature | AWS (S3 + CloudFront) | GitHub Pages |
|---------|----------------------|--------------|
| HTTPS | Yes, free with ACM | Yes |
| Custom Domain | Yes | Yes |
| CDN | Yes, global edge locations | Limited |
| Security | Advanced | Basic |
| Performance | Excellent | Good |
| Free Tier Limits | 5GB storage, 50GB transfer/month | Unlimited for public repos |
| Deployment | Via AWS CLI or manual | Via Git push |
| SSL for Custom Domain | Automatic | Manual verification |

This setup provides an enterprise-grade hosting solution completely within AWS Free Tier limits, giving you better performance, security, and reliability than GitHub Pages for your website.
