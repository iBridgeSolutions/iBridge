# iBridge Website - AWS Deployment Quick Guide

## Overview

This guide will help you quickly deploy your iBridge website on AWS using CloudFront and S3, providing:
- Global content delivery with AWS's CDN
- HTTPS security with free SSL certificates
- Scalability for any amount of traffic
- Professional hosting solution

## Quick Start

To quickly deploy your website to AWS and make it publicly accessible on ibridgesolutions.co.za:

1. Run the new comprehensive deployment script:
   ```powershell
   .\complete-aws-deploy.ps1
   ```

2. Follow the prompts to:
   - Configure AWS credentials
   - Create an S3 bucket for your website
   - Upload your website files
   - Create a CloudFront distribution with SSL
   - Configure GoDaddy DNS to point to your CloudFront distribution

3. Wait for DNS propagation (24-48 hours)

4. Check your deployment status:
   ```powershell
   .\check-aws-status.ps1
   ```

## What These New Scripts Do

### complete-aws-deploy.ps1
A new all-in-one script that handles the complete deployment process:
- Installs and configures AWS CLI if needed
- Creates an S3 bucket for website hosting
- Uploads all website files
- Creates an SSL certificate
- Creates a CloudFront distribution
- Provides instructions for DNS configuration

### check-aws-status.ps1
A new diagnostic script to check the status of your deployment:
- Verifies CloudFront distribution status
- Checks S3 bucket configuration
- Tests DNS configuration
- Tests website accessibility
- Provides guidance for any issues found

## DNS Configuration for GoDaddy

After running the deployment script, you need to update your GoDaddy DNS settings:

1. Log in to your GoDaddy account
2. Go to My Products > DNS > Manage DNS for ibridgesolutions.co.za
3. Add/update these records:
   - CNAME record: @ → your-distribution-domain.cloudfront.net
   - CNAME record: www → your-distribution-domain.cloudfront.net

If GoDaddy doesn't allow CNAME for the root domain (@):
1. Use GoDaddy's domain forwarding feature to forward the root domain to www.ibridgesolutions.co.za
2. Ensure the www CNAME points to your CloudFront distribution

## Troubleshooting

If your website isn't accessible after deployment:

1. Run the status check script:
   ```powershell
   .\check-aws-status.ps1
   ```

2. Common issues:
   - DNS hasn't propagated yet (wait 24-48 hours)
   - CloudFront distribution is still deploying (wait 15-30 minutes)
   - SSL certificate validation incomplete (check status in AWS Certificate Manager)
   - Incorrect DNS configuration (verify CNAME records point to your CloudFront domain)

## Updating Your Website

After making changes to your website files:

1. Run this command to update your files on AWS:
   ```powershell
   aws s3 sync . s3://ibridgesolutions.co.za --exclude "*.ps1" --exclude "*.md" --exclude ".git/*"
   ```

2. To immediately see your changes (clearing CloudFront cache):
   ```powershell
   aws cloudfront create-invalidation --distribution-id YOUR_DISTRIBUTION_ID --paths "/*"
   ```
   Replace YOUR_DISTRIBUTION_ID with your actual distribution ID from cloudfront-info.txt

## Why Choose AWS Hosting

- **Global Reach**: Content delivered quickly worldwide via CloudFront's global CDN network
- **Scalability**: Handles any amount of traffic automatically
- **Security**: Free SSL certificates for secure HTTPS connections
- **Reliability**: AWS's 99.9% uptime guarantee
- **Professional**: Enterprise-grade hosting solution

For more detailed instructions, refer to the original [AWS-DEPLOYMENT-GUIDE.md](./AWS-DEPLOYMENT-GUIDE.md)
