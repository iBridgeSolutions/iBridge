# Complete DNS Configuration Guide for ibridgesolutions.co.za

This guide provides all the steps needed to configure DNS for ibridgesolutions.co.za when using AWS CloudFront.

## 1. DNS Records for Certificate Validation

When setting up AWS SSL certificate, you need to add DNS validation records to GoDaddy:

1. Log in to your GoDaddy account
2. Go to "My Products" or "Domain Manager"
3. Find ibridgesolutions.co.za and click "DNS" or "Manage DNS"
4. Add the CNAME records provided by AWS during certificate request:
   - Type: CNAME
   - Host/Name: (use the name provided by AWS, without the domain part)
   - Points to/Value: (use the exact value provided by AWS)
   - TTL: 1 Hour

To check validation records, you can run the `check-cert.ps1` script.

## 2. DNS Records for CloudFront

After your certificate is validated and CloudFront distribution is created, add these records:

### For www subdomain:
- Type: CNAME
- Host: www
- Points to: [Your CloudFront Domain] (found in cloudfront-info.txt)
- TTL: 1 Hour

### For root domain (@):
- Type: CNAME
- Host: @ (or leave blank)
- Points to: [Your CloudFront Domain] (found in cloudfront-info.txt)
- TTL: 1 Hour

> **Important:** GoDaddy may not support CNAME records for root domains. If this is the case, you have two options:

## 3. Options for Root Domain Configuration

### Option A: Use GoDaddy Forwarding (Not Ideal)
1. In GoDaddy, go to domain settings
2. Find "Forwarding" or "Redirect" settings
3. Set up forwarding from ibridgesolutions.co.za to www.ibridgesolutions.co.za
4. Choose "Forward with masking" (if available)

This is not ideal as it may cause SEO issues and won't properly handle paths like `/lander`.

### Option B: Move DNS Management to AWS Route 53 (Recommended)
1. Create a Route 53 hosted zone for ibridgesolutions.co.za
2. Update nameservers at GoDaddy to point to Route 53 nameservers
3. In Route 53, create an A record for the root domain using an "Alias" to your CloudFront distribution

## 4. Testing DNS Configuration

After making DNS changes, allow 24-48 hours for full propagation. Test the following URLs:

- https://www.ibridgesolutions.co.za
- https://ibridgesolutions.co.za
- https://www.ibridgesolutions.co.za/lander
- https://ibridgesolutions.co.za/lander

## 5. Troubleshooting DNS Issues

If you're experiencing DNS issues:

1. Check DNS propagation using [dnschecker.org](https://dnschecker.org)
2. Verify DNS records are correctly configured in GoDaddy (or Route 53)
3. Make sure CloudFront distribution is enabled and deployed
4. Check that SSL certificate is validated and active
5. Run `verify-deployment-status.ps1` to check the overall deployment status

## 6. Route 53 Setup (If Needed)

If you decide to use Route 53 for better DNS management:

1. Create a Hosted Zone in Route 53 for ibridgesolutions.co.za
2. Note the nameservers provided by Route 53
3. Update the nameservers at GoDaddy to point to Route 53 nameservers
4. In Route 53, create:
   - An A record for the root domain with alias to CloudFront
   - A CNAME record for www pointing to your CloudFront domain
   - Any other required DNS records for certificate validation

For detailed Route 53 configuration, you can create and run the `migrate-to-route53.ps1` script.
