# Create backup directories
New-Item -ItemType Directory -Path ".\bucket-backups" -Force
New-Item -ItemType Directory -Path ".\bucket-backups\ibridge-contact-solutions" -Force
New-Item -ItemType Directory -Path ".\bucket-backups\ibridgesolutions-website-640825887118" -Force
New-Item -ItemType Directory -Path ".\bucket-backups\ibridgesolutions.co.za" -Force

# Backup bucket contents
Write-Host "Backing up ibridge-contact-solutions bucket..."
aws s3 sync s3://ibridge-contact-solutions .\bucket-backups\ibridge-contact-solutions --quiet

Write-Host "Backing up ibridgesolutions-website-640825887118 bucket..."
aws s3 sync s3://ibridgesolutions-website-640825887118 .\bucket-backups\ibridgesolutions-website-640825887118 --quiet

Write-Host "Backing up ibridgesolutions.co.za bucket..."
aws s3 sync s3://ibridgesolutions.co.za .\bucket-backups\ibridgesolutions.co.za --quiet

Write-Host "Backup complete!"
