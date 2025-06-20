# AWS Deployment Files Summary

I've created the following files to help you deploy your iBridge Solutions website to AWS for free:

## 1. Deployment Scripts

### Main Deployment Scripts
- **deploy-with-account-id.ps1**: Complete deployment script that sets up S3, CloudFront, and SSL
- **simple-aws-deploy.ps1**: Simple script for quick updates to your website

### Helper Scripts
- **check-certificate-validation.ps1**: Verifies SSL certificate status and provides validation instructions
- **check-aws-deployment.ps1**: Comprehensive deployment status checker
- **migrate-to-route53.ps1**: Script for migrating DNS to Route 53 (optional)

## 2. Documentation

### Step-by-Step Guides
- **AWS-DEPLOYMENT-GUIDE.md**: Complete guide for using the automated deployment scripts
- **AWS-MANUAL-SETUP-GUIDE.md**: Manual step-by-step guide for AWS console setup
- **AWS-QUICK-REFERENCE.md**: Concise checklist and commands reference

## Getting Started

1. **First time setup**:
   - Install AWS CLI from https://aws.amazon.com/cli/
   - Run `aws configure` and enter your AWS credentials
   - Run PowerShell as administrator and execute:
     ```powershell
     PowerShell -ExecutionPolicy Bypass -File .\deploy-with-account-id.ps1
     ```

2. **Check deployment status**:
   ```powershell
   PowerShell -ExecutionPolicy Bypass -File .\check-aws-deployment.ps1
   ```

3. **Verify certificate validation**:
   ```powershell
   PowerShell -ExecutionPolicy Bypass -File .\check-certificate-validation.ps1
   ```

4. **Future updates** (after initial setup):
   ```powershell
   PowerShell -ExecutionPolicy Bypass -File .\simple-aws-deploy.ps1
   ```

## Account Information
- AWS Account ID: 6408-2588-7118
- S3 Bucket Name: ibridgesolutions-website-640825887118
- Domain: ibridgesolutions.co.za

## AWS Free Tier Usage
This setup uses AWS Free Tier services:
- S3: 5GB storage free
- CloudFront: 50GB data transfer free
- Certificate Manager: Free SSL certificates
- Route 53: $0.50/month (optional)
