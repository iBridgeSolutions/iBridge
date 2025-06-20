# Post-Deployment Verification Guide

Once DNS has been configured and propagated, follow these steps to verify your AWS deployment is working correctly.

## 1. Website Access Checks

### Test Basic Access
- [ ] https://www.ibridgesolutions.co.za loads correctly
- [ ] https://ibridgesolutions.co.za loads correctly
- [ ] Images and styles appear properly
- [ ] Navigation links work as expected

### Test Problem Path (/lander)
- [ ] https://www.ibridgesolutions.co.za/lander loads correctly
- [ ] https://ibridgesolutions.co.za/lander loads correctly
- [ ] Both URLs show the expected content without redirecting to GitHub Pages

## 2. SSL Certificate Verification

- [ ] Browser shows secure connection (lock icon)
- [ ] No SSL warnings or certificate errors
- [ ] Certificate is issued to ibridgesolutions.co.za

## 3. Performance Check

- [ ] Pages load quickly
- [ ] Assets (images, CSS, JavaScript) load properly
- [ ] Site performance is equal to or better than the GitHub Pages version

## 4. Technical Verification

Run these scripts to verify the technical aspects of the deployment:

```powershell
# Check overall deployment status
.\verify-deployment-status.ps1

# Test website HTTP response
Invoke-WebRequest -Uri "https://ibridgesolutions.co.za/lander" -UseBasicParsing
Invoke-WebRequest -Uri "https://www.ibridgesolutions.co.za/lander" -UseBasicParsing
```

## 5. DNS Configuration Check

- [ ] CNAME record for www.ibridgesolutions.co.za points to the CloudFront domain
- [ ] Root domain (ibridgesolutions.co.za) correctly points to the CloudFront domain
- [ ] No DNS resolution errors or timeouts

## 6. CloudFront Cache Check

Test that CloudFront is properly caching content:

1. Visit your site for the first time
2. Load a page and note the load time
3. Reload the same page (should be much faster due to caching)

## 7. What to Do If Issues Persist

If you still see redirection issues to GitHub Pages:

1. **Check DNS**: Verify DNS is properly configured in GoDaddy using the "DNS Records" section
2. **Clear Browser Cache**: Your browser might be caching old redirects
3. **Check CloudFront**: Ensure your CloudFront distribution is enabled and properly configured
4. **Verify S3 Content**: Make sure all website files are correctly uploaded to S3
5. **Wait Longer**: DNS changes can sometimes take more than 48 hours to fully propagate

## 8. Final Migration Steps

Once everything is verified working:

- [ ] Update any bookmarks or links to the website
- [ ] Consider disabling GitHub Pages (if no longer needed)
- [ ] Document the new hosting architecture for future reference
- [ ] Set up monitoring or alerts for the AWS services
- [ ] Consider implementing regular backups of your S3 website content
