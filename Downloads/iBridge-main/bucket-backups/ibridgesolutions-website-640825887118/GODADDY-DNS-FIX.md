# GoDaddy DNS Fix Guide

## The Problem
You're seeing "Record data is invalid" when trying to add a CNAME record for the root domain (@) in GoDaddy.

![GoDaddy DNS Error](godaddy-dns-error.jpg)

This is happening because GoDaddy (and most traditional DNS providers) **don't allow CNAME records for root domains** (the @ symbol). This is due to DNS standards that require the root domain to use A records.

## Solution Options

### Option 1: Use A Records instead of CNAME (Simple but Limited)

For the **www subdomain**:
- Type: CNAME
- Host: www
- Points to: diso379wpy1no.cloudfront.net
- TTL: 1 Hour

For the **root domain (@)**:
- Type: A
- Host: @ (or leave blank)
- Points to: Set up four A records with these IP addresses:
  - 13.32.99.117
  - 13.32.99.89  
  - 13.32.99.57
  - 13.32.99.45
- TTL: 1 Hour

**Important limitation**: This approach will work, but if AWS changes their CloudFront IPs in the future, your website may go down.

### Option 2: Use Route 53 (Recommended)

AWS Route 53 properly supports root domains with CloudFront using a feature called "Alias" records. This is the preferred solution.

1. Run the migration script:
```powershell
powershell -ExecutionPolicy Bypass -File .\migrate-to-route53.ps1
```

2. The script will create a Route 53 hosted zone and show you the AWS nameservers to use

3. In GoDaddy, change your domain's nameservers to the ones provided by Route 53:
   - Go to your domain in GoDaddy
   - Look for "Nameservers" section
   - Select "Custom" or "I'll use my own nameservers"
   - Enter the four AWS nameservers
   - Save changes

4. Wait 24-48 hours for DNS propagation

### Option 3: Use GoDaddy's Website Redirect

If you really want to keep DNS at GoDaddy:
1. Set up the www subdomain with CNAME as described above
2. Use GoDaddy's domain forwarding to redirect the root domain to the www version:
   - Go to your domain settings
   - Look for "Forwarding" or "Redirect"
   - Set up a redirect from ibridgesolutions.co.za to www.ibridgesolutions.co.za
   - Choose 301 (permanent) redirect
   - Make sure SSL/HTTPS is enabled

## Checking DNS Propagation

After making any DNS changes, run:
```powershell
powershell -ExecutionPolicy Bypass -File .\check-dns-propagation.ps1
```

## Need Help?
If you continue to experience issues, please refer to the comprehensive `GoDaddy-to-AWS-DNS-Guide.md` document or contact AWS support.
