# Amazon AWS Setup Guide for ibridgesolutions.co.za

This document provides detailed instructions for setting up your website on AWS using free tier services with your Account ID: 6408-2588-7118.

## Quick Start

I've created several PowerShell scripts to help you deploy and manage your website on AWS. Let's go through them step by step.

## Setup Instructions

### Step 1: AWS CLI Installation and Configuration

1. Download and install AWS CLI:
   - Visit: https://aws.amazon.com/cli/
   - Follow the installation instructions for Windows

2. Configure AWS CLI with your credentials:
   ```powershell
   aws configure
   ```
   
   When prompted:
   - Enter your AWS Access Key ID
   - Enter your AWS Secret Access Key
   - Default region: us-east-1
   - Default output format: json
   
   You can find your access keys in the AWS Management Console under:
   - My Security Credentials > Access keys

### Step 2: Create S3 Bucket for Website Hosting

1. Log in to AWS Management Console: https://console.aws.amazon.com/
2. Navigate to S3 service
3. Click "Create bucket"
4. Set bucket name: `ibridgesolutions-website-640825887118`
5. Set region to us-east-1 (N. Virginia)
6. Unblock "Block all public access"
7. Acknowledge the warning
8. Click "Create bucket"

9. Configure static website hosting:
   - Select your new bucket
   - Go to Properties tab
   - Scroll to "Static website hosting"
   - Click "Edit"
   - Select "Enable"
   - Set "Index document" to `index.html`
   - Set "Error document" to `index.html`
   - Click "Save changes"

10. Add bucket policy for public access:
    - Go to Permissions tab
    - Click "Bucket policy"
    - Add this policy (replace with your bucket name):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::ibridgesolutions-website-640825887118/*"
    }
  ]
}
```

### Step 3: Request SSL Certificate

1. Navigate to AWS Certificate Manager (make sure you're in us-east-1 region)
2. Click "Request certificate"
3. Select "Request a public certificate"
4. Enter domain names:
   - ibridgesolutions.co.za
   - *.ibridgesolutions.co.za
5. Choose DNS validation
6. Click "Request"

7. For each domain, you'll need to create DNS records:
   - Copy the CNAME name and value
   - Go to GoDaddy DNS settings
   - Create CNAME records with the provided values
   - Wait for validation (can take up to 30 minutes)

### Step 4: Create CloudFront Distribution

1. Navigate to CloudFront service
2. Click "Create Distribution"
3. Configure:
   - Origin domain: [Your S3 website URL]
   - Origin path: leave empty
   - Name: auto-filled
   - Origin access: Public
   - Default cache behavior:
     - Viewer protocol policy: Redirect HTTP to HTTPS
     - Cache policy: CachingOptimized
   - Settings:
     - Price class: Use only North America and Europe
     - Alternate domain names: ibridgesolutions.co.za, www.ibridgesolutions.co.za
     - Custom SSL certificate: [Select your certificate]
     - Default root object: index.html
4. Click "Create distribution"

### Step 5: Upload Files to S3

1. Prepare your website files
2. Upload using AWS CLI:
   ```powershell
   aws s3 sync "c:\Users\Lwandile Gasela\Downloads\iBridge-main\iBridge-main\iBridge-main" s3://ibridgesolutions-website-640825887118 --delete
   ```

### Step 6: Update DNS Settings

#### Option 1: Using GoDaddy DNS

1. Log in to GoDaddy
2. Go to Domain Manager > ibridgesolutions.co.za > DNS
3. Add/update these records:
   - Type: CNAME | Host: @ | Points to: [Your CloudFront distribution domain]
   - Type: CNAME | Host: www | Points to: [Your CloudFront distribution domain]

Note: If GoDaddy doesn't allow CNAME for apex domain (@), you'll need to use URL forwarding for the apex domain to www.

#### Option 2: Using AWS Route 53 (recommended, costs $0.50/month)

1. Create a hosted zone:
   ```powershell
   aws route53 create-hosted-zone --name ibridgesolutions.co.za --caller-reference $(Get-Date -Format "yyyyMMddHHmmss")
   ```

2. Note the nameservers from the response

3. Update nameservers in GoDaddy to point to Route 53 nameservers

4. Create records in Route 53:
   - A record (alias) for apex domain pointing to CloudFront
   - CNAME for www pointing to CloudFront

### Step 7: Testing

1. Wait for DNS propagation (24-48 hours)
2. Test your website:
   - https://ibridgesolutions.co.za
   - https://www.ibridgesolutions.co.za

## Maintenance and Updates

To update your website:

1. Edit your local files
2. Upload to S3:
   ```powershell
   aws s3 sync "c:\Users\Lwandile Gasela\Downloads\iBridge-main\iBridge-main\iBridge-main" s3://ibridgesolutions-website-640825887118 --delete
   ```
3. Invalidate CloudFront cache:
   ```powershell
   aws cloudfront create-invalidation --distribution-id [YOUR_DISTRIBUTION_ID] --paths "/*"
   ```

## Scripts Reference

I've created several PowerShell scripts to help automate these processes:

1. `deploy-with-account-id.ps1` - Main deployment script
2. `check-certificate-validation.ps1` - Checks SSL certificate status
3. `check-aws-deployment.ps1` - Verifies entire deployment status
4. `migrate-to-route53.ps1` - Moves DNS to Route 53

You can run them with:
```powershell
PowerShell -ExecutionPolicy Bypass -File .\script-name.ps1
```

## Support and Help

If you encounter any issues:
1. Check AWS documentation
2. Run the check scripts for diagnostics
3. AWS Support is available through the AWS Management Console
