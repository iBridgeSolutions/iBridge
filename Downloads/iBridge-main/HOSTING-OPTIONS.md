# iBridge Website Hosting Options

## Current Status

Your website is currently hosted with **AWS CloudFront**, as indicated by the IP addresses (52.85.216.x) in your DNS records. You also have a properly configured CNAME file for GitHub Pages.

## Hosting Options Comparison

### GitHub Pages (Free)
- **Pros**: 
  - Completely free
  - Simple setup
  - Built-in HTTPS
  - Automatic deployment from repository
- **Cons**:
  - Limited functionality
  - No server-side processing
  - Limited to static content

### AWS CloudFront/S3 (Pay as you go)
- **Pros**:
  - Highly scalable
  - Global content delivery network
  - Advanced features (caching, edge functions)
  - Better performance for global audiences
- **Cons**:
  - Cost (based on usage)
  - More complex setup
  - Requires ongoing maintenance

## Recommended Scripts

### For GitHub Pages Setup:
```powershell
./setup-complete-hosting.ps1  # Select GitHub Pages option
```

### For AWS CloudFront Setup:
```powershell
./setup-complete-hosting.ps1  # Select AWS option
```

### To Switch Between Hosting Options:
```powershell
./switch-hosting.ps1
```

### To Check Your Current DNS Configuration:
```powershell
./check-dns-configuration.ps1
```

### To Verify/Update CNAME File:
```powershell
./check-cname.ps1
```

## Required DNS Records

### For GitHub Pages:
- **A Records** (for root domain):
  - 185.199.108.153
  - 185.199.109.153
  - 185.199.110.153
  - 185.199.111.153
- **CNAME Record** (for www subdomain):
  - www → ibridgesolutions.github.io

### For AWS CloudFront:
- **A/ALIAS Records** (for both root and www):
  - Point to your CloudFront distribution (d123456abcdef.cloudfront.net)

## Important Notes

1. **DNS Propagation**: After changing DNS settings, allow 24-48 hours for full propagation.
2. **SSL Certificates**: 
   - GitHub Pages automatically provisions certificates when properly configured
   - AWS requires a certificate in AWS Certificate Manager
3. **CNAME File**: Required for GitHub Pages custom domain regardless of DNS settings

## Need Help?

Run the diagnostic scripts provided to troubleshoot any issues, or refer to:
- [GitHub Pages Documentation](https://docs.github.com/en/pages)
- [AWS CloudFront Documentation](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/Introduction.html)
