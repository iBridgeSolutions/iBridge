# AWS Deployment Status and DNS Fix

## Current Status

✅ **S3 Bucket Created**: Website files uploaded to S3
✅ **SSL Certificate**: Successfully requested and validated 
✅ **CloudFront Distribution**: Created successfully
- **Distribution ID**: E1T7BY6VF4J47N
- **Distribution Domain**: diso379wpy1no.cloudfront.net

❌ **DNS Configuration**: CNAME record for root domain not working in GoDaddy

## The Issue

GoDaddy does not allow CNAME records for root domains (the @ symbol). This is a technical limitation of many traditional DNS providers.

## Solutions

### Solution 1: Use A Records in GoDaddy

1. Run `.\fix-godaddy-root-domain.ps1` to get the correct A records
2. Add these A records in GoDaddy for the root domain:
   - Type: A
   - Host: @ (or leave blank)  
   - Value: 13.32.99.117
   - TTL: 1 Hour
3. Add three more A records with the same host (@) pointing to:
   - 13.32.99.89
   - 13.32.99.57  
   - 13.32.99.45
4. Add a CNAME record for www:
   - Type: CNAME
   - Host: www
   - Value: diso379wpy1no.cloudfront.net
   - TTL: 1 Hour

**Limitations**: If AWS changes these IP addresses in the future, your website might become inaccessible.

### Solution 2: Use AWS Route 53 (Recommended)

Route 53 properly supports root domains with CloudFront using a feature called "Alias" records.

1. Run `.\setup-route53.ps1` to create a Route 53 hosted zone with proper records
2. Update your domain's nameservers in GoDaddy with the AWS nameservers
   - Go to domain management in GoDaddy
   - Look for "Nameservers" section
   - Choose "Custom" nameservers
   - Enter the four AWS nameservers provided by the script
3. Wait 24-48 hours for DNS propagation

## Verification

After implementing either solution, run:
```
powershell -ExecutionPolicy Bypass -File .\check-dns-propagation.ps1
```

This will check if your DNS settings are properly configured and propagated.

## Testing the Deployment

Once DNS is properly configured and propagated, test these URLs:
- https://ibridgesolutions.co.za
- https://www.ibridgesolutions.co.za  
- https://ibridgesolutions.co.za/lander (to verify the redirect fix)

## Reference Files

- `GODADDY-DNS-FIX.md` - Detailed explanation of the GoDaddy DNS issue
- `fix-godaddy-root-domain.ps1` - Script to get CloudFront A record IPs
- `setup-route53.ps1` - Script to set up Route 53 DNS
- `check-dns-propagation.ps1` - Script to check DNS status
- `AWS-QUICK-STEPS.md` - Quick reference guide for the deployment
