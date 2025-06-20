$awsExePath = "C:\Program Files\Amazon\AWSCLIV2\aws.exe"
$certificateArn = "arn:aws:acm:us-east-1:640825887118:certificate/c3af2325-0197-44a6-b586-e4fcb029c0a4"
$region = "us-east-1"

Write-Host "Checking certificate status..." -ForegroundColor Cyan

try {
    $result = & $awsExePath acm describe-certificate --certificate-arn $certificateArn --region $region | Out-String
    Write-Host $result
} catch {
    Write-Host "Error checking certificate: $_" -ForegroundColor Red
}
