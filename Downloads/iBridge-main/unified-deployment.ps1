# Unified Deployment Script for AWS and GitHub Pages

# Step 1: Deploy to AWS
Write-Host "Deploying to AWS..." -ForegroundColor Yellow
try {
    # Upload files to S3
    aws s3 sync . s3://ibridgesolutions.co.za --delete
    Write-Host "✓ Files uploaded to S3" -ForegroundColor Green

    # Invalidate CloudFront cache
    aws cloudfront create-invalidation --distribution-id YOUR_DISTRIBUTION_ID --paths "/*"
    Write-Host "✓ CloudFront cache invalidated" -ForegroundColor Green
} catch {
    Write-Host "✗ Error deploying to AWS: $_" -ForegroundColor Red
    exit 1
}

# Step 2: Sync with GitHub Pages
Write-Host "Syncing with GitHub Pages..." -ForegroundColor Yellow
try {
    git add .
    git commit -m "Automated deployment"
    git push origin main
    Write-Host "✓ Changes pushed to GitHub" -ForegroundColor Green
} catch {
    Write-Host "✗ Error syncing with GitHub Pages: $_" -ForegroundColor Red
    exit 1
}

Write-Host "Deployment completed successfully!" -ForegroundColor Green
