# iBridge Website Deployment Guide

This guide provides instructions for deploying the iBridge website to both GitHub Pages and GoDaddy hosting.

## GitHub Pages Deployment

The iBridge website is already set up to be deployed to GitHub Pages. Here's how to update the deployment:

1. Make your changes to the website files
2. Commit and push the changes to the `gh-pages` branch:
   ```
   git add .
   git commit -m "Your commit message describing the changes"
   git push origin gh-pages
   ```
3. GitHub will automatically build and deploy the website
4. The website will be accessible at your GitHub Pages URL (typically `https://username.github.io/iBridge`)

## GoDaddy Hosting Deployment

To deploy the website to GoDaddy hosting:

### Method 1: Direct File Upload via FTP

1. Gather all the website files from the repository
2. Connect to your GoDaddy hosting account using FTP credentials:
   - Host: Your FTP hostname from GoDaddy (usually `ftp.yourdomain.com`) 
   - Username: Your FTP username
   - Password: Your FTP password
   - Port: 21 (default FTP port)
3. Use an FTP client like FileZilla to upload the files
4. Upload the files to the public_html directory (or the appropriate directory for your domain)

### Method 2: GoDaddy File Manager

1. Log in to your GoDaddy account
2. Go to "My Products" and select your hosting package
3. Click on "File Manager"
4. Navigate to the public_html directory
5. Upload the website files directly through the web interface

### Method 3: Automated Deployment via FTP Script

You can use the following PowerShell script to automate deployment to GoDaddy:

```powershell
# GoDaddy FTP Deployment Script
$ftpHost = "ftp.yourdomain.com" # Replace with your FTP hostname
$ftpUser = "your-ftp-username" # Replace with your FTP username
$ftpPass = "your-ftp-password" # Replace with your FTP password
$localFolder = "C:\path\to\your\local\website\files" # Replace with your local folder path
$remoteFolder = "/public_html" # Replace with your remote folder path

# Create FTP request
$ftp = [System.Net.FtpWebRequest]::Create("ftp://$ftpHost$remoteFolder")
$ftp.Credentials = New-Object System.Net.NetworkCredential($ftpUser, $ftpPass)
$ftp.Method = [System.Net.WebRequestMethods+Ftp]::ListDirectory

# Get local files
$localFiles = Get-ChildItem -Path $localFolder -Recurse -File

# Upload files
foreach ($file in $localFiles) {
    $relativePath = $file.FullName.Replace("$localFolder", "").Replace("\", "/")
    $remotePath = "$remoteFolder$relativePath"
    
    # Create FTP request for upload
    $uri = New-Object System.Uri("ftp://$ftpHost$remotePath")
    $ftpUpload = [System.Net.FtpWebRequest]::Create($uri)
    $ftpUpload.Credentials = New-Object System.Net.NetworkCredential($ftpUser, $ftpPass)
    $ftpUpload.Method = [System.Net.WebRequestMethods+Ftp]::UploadFile
    $ftpUpload.UseBinary = $true
    $ftpUpload.KeepAlive = $false
    
    # Read file content and upload
    $fileContent = [System.IO.File]::ReadAllBytes($file.FullName)
    $ftpUpload.ContentLength = $fileContent.Length
    
    try {
        $requestStream = $ftpUpload.GetRequestStream()
        $requestStream.Write($fileContent, 0, $fileContent.Length)
        $requestStream.Close()
        
        $response = $ftpUpload.GetResponse()
        Write-Host "Upload successful: $relativePath"
        $response.Close()
    }
    catch {
        Write-Host "Error uploading file $relativePath`: $_"
    }
}

Write-Host "Deployment complete!"
```

Save this script as `deploy-to-godaddy.ps1` and run it to deploy your website to GoDaddy hosting.

## Optimizing the Deployment Package

Before deploying, optimize your website files for performance:

1. Minify CSS and JavaScript files:
   - Use tools like [Minifier](https://www.minifier.org/) to compress your CSS and JavaScript files
   
2. Optimize images:
   - Use tools like [TinyPNG](https://tinypng.com/) or [ImageOptim](https://imageoptim.com/) to compress images
   - Consider using WebP format for images with appropriate fallbacks

3. Implement browser caching:
   - Add appropriate cache headers to your server configuration

4. Remove unnecessary files:
   - Ensure you're not deploying development files, backups, or other unnecessary files

## Post-Deployment Verification

After deploying to either GitHub Pages or GoDaddy:

1. Test all pages and functionality
2. Check for broken links and images
3. Verify that forms work correctly
4. Test performance using tools like Google PageSpeed Insights
5. Test the website on different browsers and devices to ensure compatibility

## Troubleshooting

### Common GitHub Pages Issues:
- **404 errors**: Make sure the repository settings are configured to use the gh-pages branch for GitHub Pages
- **CSS/JS not loading**: Ensure paths are relative and not absolute

### Common GoDaddy Hosting Issues:
- **Permission issues**: Make sure files and directories have appropriate permissions (typically 644 for files and 755 for directories)
- **File path issues**: Ensure all internal links use relative paths
- **503 errors**: Contact GoDaddy support if you experience server errors
