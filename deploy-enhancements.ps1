# iBridge Website Live Enhancement Deployment Script
# This script deploys all enhancements to the live server
# June 26, 2025

# FTP credentials
$ftpUrl = "ftp://ftp.ibridgebpo.com"
$username = "ibridgeb"
$password = "QGum81-7ci2L)N"
$remoteDir = "/public_html/"
$localDir = $PSScriptRoot # Current directory where this script is located

# Function to send a file to FTP
function Send-FileToFTP {
    param (
        [string]$LocalPath,
        [string]$RemotePath
    )
    
    try {
        $webclient = New-Object System.Net.WebClient
        $webclient.Credentials = New-Object System.Net.NetworkCredential($username, $password)
        
        Write-Host "Uploading: $LocalPath to $RemotePath" -ForegroundColor Cyan
        $webclient.UploadFile("$ftpUrl$RemotePath", $LocalPath)
        Write-Host "Upload successful: $LocalPath" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "Error uploading $LocalPath : $_" -ForegroundColor Red
        return $false
    }
}

# Function to create FTP directory
function New-FtpDirectory {
    param (
        [string]$DirectoryPath
    )
    
    try {
        $ftpRequest = [System.Net.FtpWebRequest]::Create("$ftpUrl$DirectoryPath")
        $ftpRequest.Method = [System.Net.WebRequestMethods+Ftp]::MakeDirectory
        $ftpRequest.Credentials = New-Object System.Net.NetworkCredential($username, $password)
        $ftpRequest.UsePassive = $true
        $ftpRequest.UseBinary = $true
        $ftpRequest.KeepAlive = $false
        
        $ftpResponse = $ftpRequest.GetResponse()
        Write-Host "Directory created: $DirectoryPath" -ForegroundColor Green
        $ftpResponse.Close()
        return $true
    }
    catch [System.Net.WebException] {
        $response = $_.Exception.Response -as [System.Net.FtpWebResponse]
        if ($response.StatusCode -eq [System.Net.FtpStatusCode]::ActionNotTakenFileUnavailable) {
            Write-Host "Directory may already exist: $DirectoryPath" -ForegroundColor Yellow
            return $true
        }
        else {
            Write-Host "Error creating directory $DirectoryPath : $_" -ForegroundColor Red
            return $false
        }
    }
}

# Deploy main enhancement files
function Deploy-Enhancements {
    Write-Host "Starting deployment of enhancements..." -ForegroundColor Green
    
    # Upload the .htaccess file
    Send-FileToFTP -LocalPath "$localDir\.htaccess" -RemotePath "$remoteDir.htaccess"
    
    # Upload the enhanced accessibility.js
    Send-FileToFTP -LocalPath "$localDir\js\accessibility.js" -RemotePath "$remoteDir/js/accessibility.js"
    
    # Upload the error pages
    Send-FileToFTP -LocalPath "$localDir\404.html" -RemotePath "$remoteDir/404.html"
    Send-FileToFTP -LocalPath "$localDir\500.html" -RemotePath "$remoteDir/500.html"
    
    # Upload the enhancement plan
    Send-FileToFTP -LocalPath "$localDir\enhancement-plan.md" -RemotePath "$remoteDir/enhancement-plan.md"
}

# Check if the site can be accessed
function Test-SiteAccess {
    param (
        [string]$Url
    )
    
    try {
        $request = [System.Net.WebRequest]::Create($Url)
        $request.Method = "HEAD"
        $request.Timeout = 15000
        $response = $request.GetResponse()
        $httpStatus = $response.StatusCode
        
        $response.Close()
        
        if ($httpStatus -eq "OK") {
            Write-Host "Site is accessible at $Url" -ForegroundColor Green
            return $true
        }
        else {
            Write-Host "Site returned status: $httpStatus" -ForegroundColor Yellow
            return $false
        }
    }
    catch {
        Write-Host "Could not access the site at $Url : $_" -ForegroundColor Red
        return $false
    }
}

# Verify deployment by checking key URLs
function Test-Deployment {
    Write-Host "Verifying deployment..." -ForegroundColor Cyan
    
    # Use IP address since the domain might not be pointing to the server yet
    $ipAddress = "129.232.246.250"
    
    Test-SiteAccess -Url "http://$ipAddress/index.html"
    Test-SiteAccess -Url "http://$ipAddress/404.html"
    Test-SiteAccess -Url "http://$ipAddress/js/accessibility.js"
    
    Write-Host "Deployment verification complete." -ForegroundColor Cyan
}

# Main execution
Write-Host "Starting deployment of enhancements to live server..." -ForegroundColor Green
Deploy-Enhancements
Test-Deployment

Write-Host "Enhancement deployment process completed!" -ForegroundColor Green
