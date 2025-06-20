# AWS Deployment Quick Steps

A condensed step-by-step guide for deploying ibridgesolutions.co.za to AWS.

## 1. Install & Configure ✅

```powershell
# Install AWS CLI
Start-Process -FilePath ".\AWSCLIV2.msi" -Wait

# Configure AWS with credentials
powershell -ExecutionPolicy Bypass -File .\setup-aws.ps1
# (Enter your AWS Access Key and Secret Key when prompted)
```

## 2. Validate SSL Certificate ✅

```powershell
# Check certificate status
powershell -ExecutionPolicy Bypass -File .\fixed-check-certificate.ps1
```

SSL certificate has been successfully validated.

## 3. Setup CloudFront ✅

```powershell
# Create CloudFront distribution
powershell -ExecutionPolicy Bypass -File .\setup-cloudfront.ps1
# (Enter the Certificate ARN when prompted)
```

CloudFront distribution has been created:
- **Distribution ID**: E1T7BY6VF4J47N
- **Distribution Domain**: diso379wpy1no.cloudfront.net

## 4. Configure DNS ⬅️ CURRENT STEP

**Problem**: You're getting "Record data is invalid" when trying to add a CNAME for the root domain (@) in GoDaddy.

**Choose Your DNS Option**:
```powershell
# Run the DNS configuration menu
powershell -ExecutionPolicy Bypass -File .\choose-dns-option.ps1
```

This will present two options:

**Option 1: Use A Records in GoDaddy**
- Keep DNS at GoDaddy
- Use A records for the root domain
- Simple but less robust

**Option 2: Use AWS Route 53 (Recommended)**
- Migrate DNS to AWS Route 53
- More robust solution with better CloudFront support

To directly use either option without the menu:

```powershell
# Option 1: GoDaddy with A Records
powershell -ExecutionPolicy Bypass -File .\setup-godaddy-a-records.ps1

# Option 2: AWS Route 53 (Recommended)
powershell -ExecutionPolicy Bypass -File .\setup-route53.ps1
```

**Option B: Use Route 53 (recommended)**
```powershell
# Migrate DNS to Route 53 
powershell -ExecutionPolicy Bypass -File .\setup-route53.ps1
# Update nameservers in GoDaddy as instructed
```

**Check DNS Status**
```powershell
# Verify DNS configuration
powershell -ExecutionPolicy Bypass -File .\check-dns-propagation.ps1
```

## 5. Check DNS Propagation

After configuring DNS, check if changes are propagating:

```powershell
# Check DNS status
powershell -ExecutionPolicy Bypass -File .\check-dns-propagation.ps1
```

DNS changes can take 24-48 hours to fully propagate worldwide.

## 6. Verify Full Deployment

Once DNS has propagated, verify the complete deployment:

```powershell
# Comprehensive deployment verification
powershell -ExecutionPolicy Bypass -File .\verify-full-deployment.ps1
```

## 7. Future Website Updates

```powershell
# Upload new files and invalidate cache
powershell -ExecutionPolicy Bypass -File .\simple-aws-deploy.ps1
```

**CloudFront Distribution ID:** E1T7BY6VF4J47N
**CloudFront Domain:** diso379wpy1no.cloudfront.net
**AWS Account ID:** 6408-2588-7118
