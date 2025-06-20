$certificateArn = Get-Content -Path "certificate-arn.txt" -Raw
$certificateArn = $certificateArn.Trim()
Write-Host "Checking certificate status for: $certificateArn"

try {
    # Call AWS CLI using Start-Process to avoid PowerShell parsing issues
    $output = Start-Process -FilePath "C:\Program Files\Amazon\AWSCLIV2\aws.exe" -ArgumentList "acm describe-certificate --certificate-arn `"$certificateArn`" --region us-east-1" -NoNewWindow -Wait -RedirectStandardOutput "cert-status.txt" -PassThru
    
    # Read the output file
    $certStatus = Get-Content -Path "cert-status.txt" -Raw
    Write-Host "Certificate Details:" -ForegroundColor Cyan
    Write-Host $certStatus -ForegroundColor White
    
    # Check if the certificate is issued
    if ($certStatus -match '"Status":\s*"ISSUED"') {
        Write-Host "Certificate is ISSUED and ready to use!" -ForegroundColor Green
    } elseif ($certStatus -match '"Status":\s*"PENDING_VALIDATION"') {
        Write-Host "Certificate is still PENDING VALIDATION." -ForegroundColor Yellow
        Write-Host "Please make sure DNS validation records are added to GoDaddy." -ForegroundColor Yellow
    } else {
        Write-Host "Certificate is in an unexpected state. Please check the details above." -ForegroundColor Red
    }
} catch {
    Write-Host "Error checking certificate: $_" -ForegroundColor Red
}
