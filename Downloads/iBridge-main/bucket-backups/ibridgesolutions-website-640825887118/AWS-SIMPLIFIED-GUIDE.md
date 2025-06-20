# Simplified Guide: Deploying ibridgesolutions.co.za to AWS

This guide provides simplified, step-by-step instructions for deploying your website to AWS to fix the `/lander` redirect issue.

## Prerequisites

- AWS Account (ID: 6408-2588-7118)
- Access to your GoDaddy DNS settings
- AWS CLI installed on your computer

## Step 1: Configure AWS CLI

1. Open PowerShell as Administrator
2. Run the following command:
   ```
   powershell -ExecutionPolicy Bypass -File .\setup-aws.ps1
   ```
3. When prompted, enter your AWS Access Key ID and Secret Access Key
   - These credentials can be found in the AWS Console under Security Credentials
   - If you don't have credentials yet, create them in the AWS Console

## Step 2: Create S3 Bucket and Request SSL Certificate

The script from Step 1 will:
- Create an S3 bucket for your website files
- Configure the bucket for web hosting
- Request an SSL certificate for your domain
- Upload your website files to S3

After completion, it will show DNS validation records needed for the SSL certificate.

## Step 3: Validate SSL Certificate (GoDaddy DNS Setup)

1. Log in to your GoDaddy account
2. Navigate to the domain management page for ibridgesolutions.co.za
3. Find "DNS Records" or "Manage DNS" and add the CNAME records provided by the script:
   - Type: CNAME
   - Host/Name: Use the simplified name provided by the script
   - Points To/Value: Use the exact value provided by the script
   - TTL: 1 hour

4. Wait 15-30 minutes for certificate validation
5. Check validation status by running:
   ```
   powershell -ExecutionPolicy Bypass -File .\fixed-check-certificate.ps1
   ```

## Step 4: Create CloudFront Distribution

Once the certificate is validated (status shows as "ISSUED"):

1. Run the CloudFront setup script:
   ```
   powershell -ExecutionPolicy Bypass -File .\setup-cloudfront.ps1
   ```
2. When prompted, enter the SSL Certificate ARN (shown by the certificate validation script)
3. The script will create a CloudFront distribution with proper settings for your domain

## Step 5: Update Domain DNS to Point to CloudFront

After CloudFront is deployed (takes about 15-30 minutes):

1. Log in to your GoDaddy account
2. Navigate to the domain management page for ibridgesolutions.co.za
3. Find "DNS Records" and add/update the following records:

   **For root domain (ibridgesolutions.co.za)**:
   - Type: CNAME
   - Host: @ (or blank for root)
   - Points To: Your CloudFront domain (example: d1234abcde.cloudfront.net)
   - TTL: 1 hour

   **For www subdomain (www.ibridgesolutions.co.za)**:
   - Type: CNAME
   - Host: www
   - Points To: Your CloudFront domain (same as above)
   - TTL: 1 hour

   > **Note:** If GoDaddy doesn't allow CNAME for the root domain (@), consider migrating to Route 53:
   > ```
   > powershell -ExecutionPolicy Bypass -File .\migrate-to-route53.ps1
   > ```

## Step 6: Verify Deployment

Wait 24-48 hours for DNS propagation, then:

1. Run the verification script:
   ```
   powershell -ExecutionPolicy Bypass -File .\verify-aws-deployment.ps1
   ```
2. Check that all components are working correctly
3. Visit your website to ensure the `/lander` redirect issue is fixed

## Maintaining Your Website

To update your website in the future:

```
powershell -ExecutionPolicy Bypass -File .\simple-aws-deploy.ps1
```

This will upload any changes to S3 and invalidate the CloudFront cache.

## Troubleshooting

If you encounter issues:

1. Run the verification script to identify the problem:
   ```
   powershell -ExecutionPolicy Bypass -File .\verify-aws-deployment.ps1
   ```

2. Common issues:
   - **SSL Certificate not validating**: Double-check DNS records in GoDaddy
   - **CloudFront showing "In Progress"**: Wait 15-30 minutes for deployment
   - **Website still redirects to /lander**: Check for forwarding settings in GoDaddy

For detailed instructions, refer to AWS-DEPLOYMENT-GUIDE.md
