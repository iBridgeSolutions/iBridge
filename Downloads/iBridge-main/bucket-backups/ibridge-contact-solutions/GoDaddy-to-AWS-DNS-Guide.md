# GoDaddy to AWS DNS Migration Guide

This guide explains how to properly configure DNS for ibridgesolutions.co.za when moving from GoDaddy to AWS hosting.

## Option 1: Keep DNS Management at GoDaddy (Simpler, Some Limitations)

### Step 1: Locate DNS Management

1. Log in to GoDaddy
2. Go to "My Products" or "Domain Manager"
3. Find ibridgesolutions.co.za and click "DNS" or "Manage DNS"

### Step 2: Add Certificate Validation Records

When running the AWS deployment scripts, you'll need to add CNAME records for certificate validation:

1. In GoDaddy DNS management, click "Add Record"
2. Add each CNAME record shown by the certificate validation script:
   - Type: CNAME
   - Host/Name: Use the simplified name (without the domain)
   - Points to/Value: Use the exact value provided
   - TTL: 1 hour

### Step 3: Update Domain to Point to CloudFront

After certificate validation and CloudFront distribution creation:

1. In GoDaddy DNS management, add/update these records:

   **For www subdomain:**
   - Type: CNAME
   - Host: www
   - Points to: Your CloudFront domain (e.g., d1234abcd.cloudfront.net)
   - TTL: 1 hour

   **For root domain (@):**
   - Type: CNAME
   - Host: @ (or leave blank)
   - Points to: Your CloudFront domain
   - TTL: 1 hour

   > **Important:** Some DNS providers (including GoDaddy) don't allow CNAME records for root domains.
   > If you see an error when trying to add a CNAME for the root domain, use Option 2 below.

### Step 4: Disable Forwarding/Redirects

To fix the `/lander` redirect issue:

1. In GoDaddy domain settings, look for "Forwarding," "Redirects," or "Website Settings"
2. Ensure there are no active forwarding rules for ibridgesolutions.co.za
3. If you find any redirects to `/lander`, disable them

## Option 2: Migrate DNS to AWS Route 53 (Recommended for Full Control)

For better control and to fix root domain limitations, migrate DNS management to AWS Route 53:

### Step 1: Create Route 53 Hosted Zone

Run the migration script:
```
powershell -ExecutionPolicy Bypass -File .\migrate-to-route53.ps1
```

The script will:
- Create a Route 53 hosted zone for ibridgesolutions.co.za
- Set up proper A records for both root and www domains pointing to CloudFront
- Show you the nameservers to update at GoDaddy

### Step 2: Update Nameservers at GoDaddy

1. Log in to GoDaddy
2. Go to domain management for ibridgesolutions.co.za
3. Look for "Nameservers" or "Name Servers"
4. Select "Custom" nameservers
5. Enter the four Route 53 nameservers provided by the script
   (Example: ns-123.awsdns-12.com, ns-456.awsdns-34.net, etc.)
6. Save changes

### Step 3: Wait for DNS Propagation

1. DNS changes typically take 24-48 hours to fully propagate
2. You can check progress using:
   ```
   powershell -ExecutionPolicy Bypass -File .\check-dns-propagation.ps1
   ```

## Benefits of Using Route 53

- Properly supports root domains with CloudFront
- Handles both www and non-www versions correctly
- Better performance with AWS's global DNS infrastructure
- Easier management of AWS resources
- Prevents issues with the `/lander` redirect

## Cost Note

Route 53 costs approximately $0.50/month per hosted zone, but provides significant benefits for professional websites.

## Verification

After either option, verify your setup with:
```
powershell -ExecutionPolicy Bypass -File .\verify-aws-deployment.ps1
```

The script will check that DNS is correctly configured and the `/lander` redirect issue is fixed.