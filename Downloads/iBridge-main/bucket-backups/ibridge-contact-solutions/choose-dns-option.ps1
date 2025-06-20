# Simple AWS DNS Configuration Menu
# This script provides options for DNS configuration

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "     IBRIDGESOLUTIONS AWS DNS CONFIGURATION" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host

Write-Host "CloudFront distribution has been successfully created!" -ForegroundColor Green
Write-Host "Distribution domain: diso379wpy1no.cloudfront.net" -ForegroundColor Yellow
Write-Host

Write-Host "You need to choose how to configure DNS:" -ForegroundColor Cyan
Write-Host

Write-Host "OPTION 1: Use GoDaddy with A Records" -ForegroundColor White
Write-Host "---------------------------------" -ForegroundColor White
Write-Host "• Keep DNS at GoDaddy" -ForegroundColor Gray
Write-Host "• Use A records for the root domain" -ForegroundColor Gray
Write-Host "• Simpler but less robust solution" -ForegroundColor Gray
Write-Host 
Write-Host "To use this option, run:" -ForegroundColor Yellow
Write-Host "  powershell -ExecutionPolicy Bypass -File .\setup-godaddy-a-records.ps1" -ForegroundColor White
Write-Host

Write-Host "OPTION 2: Use AWS Route 53 (Recommended)" -ForegroundColor White
Write-Host "-------------------------------------" -ForegroundColor White
Write-Host "• Migrate DNS to AWS Route 53" -ForegroundColor Gray
Write-Host "• Better integration with CloudFront" -ForegroundColor Gray
Write-Host "• More robust long-term solution" -ForegroundColor Gray
Write-Host 
Write-Host "To use this option, run:" -ForegroundColor Yellow
Write-Host "  powershell -ExecutionPolicy Bypass -File .\setup-route53.ps1" -ForegroundColor White
Write-Host

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "To view detailed comparison of both options:" -ForegroundColor Yellow
Write-Host "  notepad .\DNS-DECISION-GUIDE.md" -ForegroundColor White
Write-Host

$choice = Read-Host "Which option would you like to use? (1 or 2)"

if ($choice -eq "1") {
    Write-Host "`nStarting GoDaddy A Records setup..." -ForegroundColor Green
    & powershell -ExecutionPolicy Bypass -File .\setup-godaddy-a-records.ps1
}
elseif ($choice -eq "2") {
    Write-Host "`nStarting Route 53 setup..." -ForegroundColor Green
    & powershell -ExecutionPolicy Bypass -File .\setup-route53.ps1
}
else {
    Write-Host "`nInvalid choice. Please run one of the commands listed above." -ForegroundColor Red
}
