# Script to clean up duplicate S3 buckets after successful deployment
# Important: Make sure your deployment is successful before running this script!

# Define buckets to remove
$BUCKETS_TO_REMOVE = @("ibridge-contact-solutions", "ibridgesolutions.co.za")

# Confirm with user before proceeding
Write-Host "WARNING: This script will empty and delete the following S3 buckets:"
$BUCKETS_TO_REMOVE | ForEach-Object { Write-Host "- $_" }
Write-Host ""
$confirm = Read-Host "Are you sure you want to proceed? (yes/no)"

if ($confirm -ne "yes") {
    Write-Host "Operation cancelled. No buckets were deleted."
    exit
}

# Process each bucket
foreach ($bucket in $BUCKETS_TO_REMOVE) {
    Write-Host "Processing bucket: $bucket"
    
    # First remove all objects from the bucket
    Write-Host "Removing all objects from $bucket..."
    aws s3 rm s3://$bucket --recursive
    
    # Then remove bucket website configuration
    Write-Host "Removing website configuration from $bucket..."
    aws s3 website s3://$bucket --delete
    
    # Finally, delete the empty bucket
    Write-Host "Deleting bucket $bucket..."
    aws s3api delete-bucket --bucket $bucket
}

Write-Host "Cleanup complete! The following buckets have been removed:"
$BUCKETS_TO_REMOVE | ForEach-Object { Write-Host "- $_" }
Write-Host ""
Write-Host "Your website remains accessible on the main bucket: ibridgesolutions-website-640825887118"
