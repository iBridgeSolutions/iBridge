# Script to deploy the updated website to the main S3 bucket

# Define the main bucket name
$MAIN_BUCKET = "ibridgesolutions-website-640825887118"

# Deploy all website files to the main bucket
Write-Host "Deploying updated website to $MAIN_BUCKET..."
aws s3 sync . s3://$MAIN_BUCKET --exclude "bucket-backups/*" --exclude "*.ps1" --exclude ".git/*" --exclude "AWSCLIV2.msi" --delete --acl public-read

# Invalidate CloudFront cache to ensure changes are immediately visible
$DISTRIBUTION_ID = "E1T7BY6VF4J47N" # The ID we got from the CloudFront list-distributions command
Write-Host "Invalidating CloudFront cache for distribution $DISTRIBUTION_ID..."
aws cloudfront create-invalidation --distribution-id $DISTRIBUTION_ID --paths "/*"

Write-Host "Deployment complete! Your updated website should be visible shortly."
Write-Host "CloudFront Domain: diso379wpy1no.cloudfront.net"
Write-Host "Custom Domains: ibridgesolutions.co.za, www.ibridgesolutions.co.za"
