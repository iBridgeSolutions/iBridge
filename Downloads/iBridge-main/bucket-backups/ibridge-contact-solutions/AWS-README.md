# iBridge AWS Deployment Toolkit

This repository contains all the tools and scripts you need to deploy iBridgeSolutions.co.za to AWS Free Tier and fix the GoDaddy "/lander" redirect issue.

## Account Information

- AWS Account ID: 6408-2588-7118

## Overview

The solution uses these AWS services (all within free tier limits):
- **Amazon S3** - Static website hosting
- **CloudFront** - Global CDN with HTTPS
- **Route 53** - DNS management
- **Certificate Manager** - Free SSL certificates

## Quick Start Guide

### Step 1: Run the All-in-One Deployment Script

This interactive script handles the complete AWS setup process:

```powershell
.\deploy-to-aws-updated.ps1
```

Follow the prompts to:
- Configure AWS credentials
- Create S3 bucket
- Request SSL certificate
- Set up CloudFront distribution
- Configure Route 53 DNS
- Upload website files

### Step 2: Update GoDaddy Nameservers

After running the script, you'll get a list of AWS nameservers.
Update your GoDaddy domain settings to use these nameservers.

### Step 3: Verify Your Deployment

After DNS changes have had time to propagate:

```powershell
.\verify-aws-deployment.ps1
```

## File Structure

- `aws-free-hosting-plan.md` - Complete guide with architecture details
- `deploy-to-aws.ps1` - Initial deployment script for S3 setup
- `aws-ssl-helper.ps1` - Helper for SSL certificate management
- `verify-aws-dns.ps1` - Script to verify DNS configuration

## Advantages Over GitHub Pages

This AWS setup provides:
1. **Better Performance** - Global CDN with edge locations worldwide
2. **Enhanced Security** - Free SSL, CloudFront security features
3. **Reliability** - Enterprise-grade infrastructure
4. **Scalability** - Can handle high traffic if needed
5. **Fixes /lander Redirect** - Complete control over domain configuration

## Costs

This setup stays within AWS Free Tier limits:
- S3: First 5GB storage free
- CloudFront: First 50GB data transfer free
- Route 53: ~$0.50/month for hosted zone (only non-free component)
- Certificate Manager: Free SSL certificates

## Troubleshooting

If you encounter issues, check:
1. **DNS Propagation** - Changes can take 24-48 hours
2. **Certificate Validation** - Must be completed before CloudFront deployment
3. **S3 Permissions** - Bucket must be publicly accessible
4. **CloudFront Settings** - Distribution must point to correct origin
5. **Route 53 Configuration** - Must have proper A and CNAME records

## Next Steps

After deployment:
1. Set up monitoring with AWS CloudWatch
2. Create a CI/CD pipeline for automatic updates
3. Configure custom error pages
4. Implement browser caching
