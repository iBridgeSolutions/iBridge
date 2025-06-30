# FTP Upload Script for iBridgeBPO.com
# Created: June 26, 2025

$ftpUrl = "ftp://ftp.ibridgebpo.com"
$username = "ibridgeb"
$password = "QGum81-7ci2L)N"
$remoteDir = "/public_html/"
$localDir = $PSScriptRoot # Current directory where this script is located

function Send-FileToFTP {
    param (
        [string]$LocalPath,
        [string]$RemotePath
    )
    
    try {
        $webclient = New-Object System.Net.WebClient
        $webclient.Credentials = New-Object System.Net.NetworkCredential($username, $password)
        
        Write-Host "Uploading: $LocalPath to $RemotePath"
        $webclient.UploadFile("$ftpUrl$RemotePath", $LocalPath)
        Write-Host "Upload successful: $LocalPath" -ForegroundColor Green
    }
    catch {
        Write-Host "Error uploading $LocalPath : $_" -ForegroundColor Red
    }
}

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

function Send-DirectoryToFTP {
    param (
        [string]$LocalDir,
        [string]$RemoteDir
    )
    
    # Ensure remote directory exists
    New-FtpDirectory -DirectoryPath $RemoteDir
    
    # Get all files in the local directory
    $files = Get-ChildItem -Path $LocalDir -File
    foreach ($file in $files) {
        Send-FileToFTP -LocalPath $file.FullName -RemotePath "$RemoteDir$($file.Name)"
    }
    
    # Get all subdirectories
    $subdirs = Get-ChildItem -Path $LocalDir -Directory
    foreach ($subdir in $subdirs) {
        $newLocalDir = Join-Path -Path $LocalDir -ChildPath $subdir.Name
        $newRemoteDir = "$RemoteDir$($subdir.Name)/"
        Send-DirectoryToFTP -LocalDir $newLocalDir -RemoteDir $newRemoteDir
    }
}

Write-Host "Starting upload to iBridgeBPO.com..." -ForegroundColor Cyan
Send-DirectoryToFTP -LocalDir $localDir -RemoteDir $remoteDir
Write-Host "Upload completed!" -ForegroundColor Green
