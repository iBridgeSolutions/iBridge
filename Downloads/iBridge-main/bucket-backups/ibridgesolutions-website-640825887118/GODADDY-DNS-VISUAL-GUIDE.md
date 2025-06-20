# GoDaddy DNS Setup Guide with Screenshots

## The Problem: "Record data is invalid" Error

When trying to add a CNAME record for the root domain (@) in GoDaddy, you receive the error:
```
Record data is invalid.
```

This happens because GoDaddy, like many traditional DNS providers, doesn't allow CNAME records for root domains due to DNS standards.

## Solution: Use A Records Instead

### STEP 1: Go to DNS Management

1. Log in to your GoDaddy account
2. Navigate to "My Products" or "Domain Manager"
3. Find ibridgesolutions.co.za and click "DNS" or "Manage DNS"

### STEP 2: Add A Records for the Root Domain

For the **root domain** (leaving the Host field blank or using @):

1. Click "Add Record"
2. Select record type: **A**
3. Host: **@** (or leave blank)
4. Points to: **13.32.99.117**
5. TTL: **1 Hour**
6. Click "Save"

Repeat this process for the following three IP addresses:
- 13.32.99.89
- 13.32.99.57
- 13.32.99.45

When finished, you should have **four A records** for the root domain.

### STEP 3: Add CNAME Record for WWW

For the **www subdomain**:

1. Click "Add Record"
2. Select record type: **CNAME**
3. Host: **www**
4. Points to: **diso379wpy1no.cloudfront.net**
5. TTL: **1 Hour**
6. Click "Save"

### STEP 4: Remove Any GitHub Pages Records

If you have any existing records pointing to GitHub Pages, remove them:
- Any TXT records with GitHub verification values
- Any existing A records pointing to GitHub Pages IPs (185.199.108.153, etc.)
- Any existing CNAME records pointing to GitHub domains

### STEP 5: Wait for DNS Propagation

DNS changes can take 24-48 hours to fully propagate worldwide. Be patient!

You can check the status by running:
```powershell
powershell -ExecutionPolicy Bypass -File .\check-dns-propagation.ps1
```

## Why This Works

Using multiple A records for the root domain allows you to point directly to AWS CloudFront's IP addresses. The CNAME for the www subdomain points to your CloudFront distribution.

Both will route traffic through CloudFront to your S3-hosted website. This configuration provides:
- Proper SSL/HTTPS encryption
- Improved performance with CloudFront's global CDN
- The fix for the /lander redirect issue

## Alternative: AWS Route 53

For a more robust solution, consider using AWS Route 53 for DNS management:
```powershell
powershell -ExecutionPolicy Bypass -File .\setup-route53.ps1
```

This creates a Route 53 hosted zone and properly configures both root and www domains using AWS's specialized "Alias" records.
