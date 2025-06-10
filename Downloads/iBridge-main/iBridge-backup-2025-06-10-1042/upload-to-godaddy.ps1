# iBridge Website FTP Upload Script for GoDaddy
# This script uploads your deployment ZIP file to GoDaddy hosting via FTP

param(
    [string]$FtpHost = $(Read-Host 'Enter your GoDaddy FTP host (e.g., ftp.yourdomain.com)'),
    [string]$FtpUser = $(Read-Host 'Enter your GoDaddy FTP username'),
    [string]$FtpPass = $(Read-Host 'Enter your GoDaddy FTP password (input hidden)'),
    [string]$LocalZip = "iBridge-deployment-2025-06-06-0033.zip",
    [string]$RemotePath = "/public_html/iBridge-deployment-2025-06-06-0033.zip"
)

Write-Host "=== iBridge Website FTP Upload ===" -ForegroundColor Green

if (!(Test-Path $LocalZip)) {
    Write-Host "ERROR: Deployment ZIP file not found: $LocalZip" -ForegroundColor Red
    exit 1
}

# Create FTP request
$ftpUri = "ftp://$FtpHost$RemotePath"
$ftpRequest = [System.Net.FtpWebRequest]::Create($ftpUri)
$ftpRequest.Method = [System.Net.WebRequestMethods+Ftp]::UploadFile
$ftpRequest.Credentials = New-Object System.Net.NetworkCredential($FtpUser, $FtpPass)
$ftpRequest.UseBinary = $true
$ftpRequest.UsePassive = $true
$ftpRequest.KeepAlive = $false

# Read file data
$fileContent = [System.IO.File]::ReadAllBytes($LocalZip)
$ftpRequest.ContentLength = $fileContent.Length

try {
    $requestStream = $ftpRequest.GetRequestStream()
    $requestStream.Write($fileContent, 0, $fileContent.Length)
    $requestStream.Close()
    Write-Host "Upload complete! File uploaded to $ftpUri" -ForegroundColor Green
    Write-Host "Next: Log into GoDaddy cPanel, go to File Manager, extract the ZIP in public_html, and test your site."
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
