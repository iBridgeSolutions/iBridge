# iBridge Solutions AWS Deployment Guide

## Account Information
- **AWS Account ID:** 6408-2588-7118
- **Domain:** ibridgesolutions.co.za

## Table of Contents
1. [Deployment Overview](#deployment-overview)
2. [Deployment Scripts](#deployment-scripts)
3. [Step-by-Step Process](#step-by-step-process)
4. [DNS Configuration Options](#dns-configuration-options)
5. [Troubleshooting](#troubleshooting)
6. [Future Updates](#future-updates)

## Deployment Overview

This guide will help you deploy your iBridge Solutions website to Amazon Web Services (AWS) using the free tier services. The deployment uses:

- **Amazon S3** for hosting website files
- **AWS CloudFront** for global content delivery and HTTPS
- **AWS Certificate Manager** for free SSL certificate
- **Route 53** (optional) for advanced DNS management

## Deployment Scripts

The following scripts have been created to help you deploy and manage your website:

| Script | Purpose |
|--------|---------|
| `deploy-with-account-id.ps1` | **Main deployment script** - creates S3 bucket, requests SSL certificate, sets up CloudFront |
| `check-certificate-validation.ps1` | Checks the status of your SSL certificate validation |
| `check-aws-deployment.ps1` | Verifies the status of your entire deployment (S3, CloudFront, DNS) |
| `migrate-to-route53.ps1` | Optional script to move DNS management from GoDaddy to AWS Route 53 |

## Step-by-Step Process

### 1. Initial Setup

1. Make sure you have AWS CLI installed
   - If not, the deployment script will help install it

2. Run the main deployment script:
   ```powershell
   .\deploy-with-account-id.ps1
   ```

3. The script will:
   - Check for AWS CLI installation and configuration
   - Create an S3 bucket for your website
   - Request an SSL certificate for your domain
   - Configure SSL certificate validation
   - Create a CloudFront distribution
   - Upload your website files to S3
   - Provide DNS configuration instructions

### 2. Certificate Validation

1. After running the deployment script, check certificate status:
   ```powershell
   .\check-certificate-validation.ps1
   ```

2. Follow the instructions to add DNS validation records to GoDaddy
   - This step is necessary for AWS to issue your SSL certificate
   - Certificate validation can take up to 30 minutes after adding DNS records

### 3. DNS Configuration

**You have two options for DNS configuration:**

#### Option 1: Update GoDaddy DNS (Simpler, Limitations)
1. Log in to GoDaddy account
2. Navigate to DNS management for ibridgesolutions.co.za
3. Add CNAME records pointing to your CloudFront distribution
4. Note: GoDaddy may not support CNAME for apex domains (without www)

#### Option 2: Migrate to Route 53 (Better, Small Cost)
1. Run the Route 53 migration script:
   ```powershell
   .\migrate-to-route53.ps1
   ```
2. Follow the instructions to update nameservers at GoDaddy
3. This option costs $0.50/month but provides better control and apex domain support

### 4. Verify Deployment

After configuring DNS and waiting for propagation (24-48 hours), verify everything works:

```powershell
.\check-aws-deployment.ps1
```

The script will check:
- S3 bucket configuration
- SSL certificate validation status
- CloudFront distribution status
- DNS configuration
- Website accessibility
- Whether the /lander redirect issue is fixed

## DNS Configuration Options

### GoDaddy DNS (Free)

**Pros:**
- No additional cost
- Simpler management if you're familiar with GoDaddy

**Cons:**
- May not support CNAME for apex domain (without www)
- May require workarounds for apex domain

**Settings needed:**
- CNAME record for www.ibridgesolutions.co.za pointing to your CloudFront distribution
- For apex domain, you may need to use GoDaddy's URL forwarding to www subdomain

### Route 53 DNS ($0.50/month)

**Pros:**
- Supports apex domain with CloudFront using alias records
- Better DNS performance globally
- Advanced routing options if needed
- Integrated with AWS services

**Cons:**
- Small monthly cost ($0.50/month)
- Requires changing nameservers

**Settings needed:**
- Run migrate-to-route53.ps1 script
- Update nameservers at GoDaddy with Route 53 nameservers

## Troubleshooting

### SSL Certificate Issues
- Run `.\check-certificate-validation.ps1` to see validation status
- Ensure DNS validation records are correctly added at GoDaddy
- Certificate validation can take up to 30 minutes after DNS records are added

### Website Not Accessible
- Run `.\check-aws-deployment.ps1` to diagnose issues
- Verify DNS configuration is correct
- Check that CloudFront distribution is deployed (can take 15-30 minutes)
- Clear browser cache and try in incognito mode

### Still Seeing /lander Redirect
- Make sure GoDaddy website builder is disabled
- Check for any URL forwarding in GoDaddy settings
- Clear browser cache completely
- Try accessing from a different network

## Future Updates

To update your website in the future:

1. Edit your website files locally in the folder:
   ```
   c:\Users\Lwandile Gasela\Downloads\iBridge-main\iBridge-main\iBridge-main
   ```

2. Run the deployment script to upload changes:
   ```powershell
   .\deploy-with-account-id.ps1
   ```

The script will upload your modified files and invalidate the CloudFront cache so changes appear immediately.
