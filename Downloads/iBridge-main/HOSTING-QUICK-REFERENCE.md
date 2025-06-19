# iBridge Website Hosting Quick Reference Guide

## DNS Configuration

### GitHub Pages IP Addresses
- 185.199.108.153
- 185.199.109.153
- 185.199.110.153
- 185.199.111.153

### Required DNS Records (GoDaddy)
1. **A Records for Root Domain**:
   - **Host**: @ (root domain)
   - **Points to**: All four GitHub Pages IP addresses (add four separate A records)
   - **TTL**: 600 or 1 hour

2. **CNAME Record for WWW Subdomain**:
   - **Host**: www
   - **Points to**: ibridgesolutions.github.io (your GitHub username + .github.io)
   - **TTL**: 600 or 1 hour

## GitHub Pages Setup
1. Go to your GitHub repository settings: https://github.com/iBridgeSolutions/iBridge-main/settings/pages
2. Choose deployment source (gh-pages branch)
3. Enter custom domain: ibridgesolutions.co.za
4. Check "Enforce HTTPS" (after certificate is provisioned)

## Local Repository Requirements
1. CNAME file in repository root containing only: ibridgesolutions.co.za
2. All website files committed and pushed to the gh-pages branch

## Verifying Your Setup
1. Run `check-dns-configuration.ps1` to check DNS settings
2. Visit https://ibridgesolutions.co.za and https://www.ibridgesolutions.co.za
3. Check for valid SSL (lock icon in browser)

## Troubleshooting
- **Site not loading**: DNS may still be propagating (wait 24-48 hours)
- **SSL not working**: Make sure "Enforce HTTPS" is checked in GitHub Pages settings
- **404 errors**: Ensure repository is public, and pages are built from correct branch

## AWS CloudFront/S3 Setup (Alternative or Additional Hosting)
For AWS CloudFront/S3 setup with SSL, run:
```
setup-complete-hosting.ps1
```
And select "Yes" for AWS integration.

## Contact Support
If you continue experiencing issues, contact GitHub Support or visit:
https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site
