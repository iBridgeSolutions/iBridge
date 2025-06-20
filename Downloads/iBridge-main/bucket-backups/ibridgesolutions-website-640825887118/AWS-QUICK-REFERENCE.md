# AWS Free Tier Website Deployment Checklist

## Account Details
- AWS Account ID: 6408-2588-7118
- Domain: ibridgesolutions.co.za

## Required Resources
1. ✅ **S3 Bucket**: ibridgesolutions-website-640825887118
2. ✅ **SSL Certificate**: For ibridgesolutions.co.za and *.ibridgesolutions.co.za
3. ✅ **CloudFront Distribution**: For content delivery with HTTPS

## Deployment Steps

### 1. AWS CLI Installation
```
# Download from: https://aws.amazon.com/cli/
# After installation, configure with:
aws configure
```

### 2. S3 Bucket Setup
```
# Create bucket
aws s3api create-bucket --bucket ibridgesolutions-website-640825887118 --region us-east-1

# Configure for static website hosting
aws s3 website s3://ibridgesolutions-website-640825887118/ --index-document index.html --error-document index.html

# Set bucket policy for public access (save to bucket-policy.json first)
aws s3api put-bucket-policy --bucket ibridgesolutions-website-640825887118 --policy file://bucket-policy.json
```

### 3. SSL Certificate Setup
```
# Request certificate
aws acm request-certificate --domain-name ibridgesolutions.co.za --validation-method DNS --subject-alternative-names "*.ibridgesolutions.co.za" --region us-east-1

# Check validation status
aws acm describe-certificate --certificate-arn YOUR_CERT_ARN --region us-east-1
```

### 4. CloudFront Distribution
- Create in AWS Console (easier than CLI for initial setup)
- Use S3 website endpoint as origin
- Add custom domain names
- Select SSL certificate
- Set "Redirect HTTP to HTTPS"

### 5. Upload Website Files
```
# Upload all files
aws s3 sync "c:\Users\Lwandile Gasela\Downloads\iBridge-main\iBridge-main\iBridge-main" s3://ibridgesolutions-website-640825887118 --delete
```

### 6. DNS Configuration
1. **Option A: GoDaddy DNS**
   - Add CNAME for www pointing to CloudFront
   - Set up URL forward for apex domain to www

2. **Option B: Route 53 DNS**
   - Create hosted zone
   - Update nameservers at GoDaddy
   - Create A (alias) for apex domain
   - Create CNAME for www subdomain

### 7. Test Deployment
- Wait for DNS propagation (24-48 hours)
- Visit https://ibridgesolutions.co.za
- Visit https://www.ibridgesolutions.co.za
- Check that site loads without /lander redirect

### 8. Future Updates
```
# Run simple-aws-deploy.ps1 for updates
PowerShell -ExecutionPolicy Bypass -File .\simple-aws-deploy.ps1
```

## Helpful Scripts
- `deploy-with-account-id.ps1`: Complete deployment script
- `check-certificate-validation.ps1`: Verify SSL certificate status
- `check-aws-deployment.ps1`: Check overall deployment status
- `migrate-to-route53.ps1`: Move DNS to Route 53
- `simple-aws-deploy.ps1`: Quick updates to existing deployment

## Cost Management
- S3: First 5GB storage free per month
- CloudFront: First 50GB data transfer free per month
- Route 53: $0.50/month for hosted zone (if used)
- Certificate Manager: Free
- TOTAL: $0 - $0.50/month depending on DNS choice

To monitor costs: https://console.aws.amazon.com/billing/home
