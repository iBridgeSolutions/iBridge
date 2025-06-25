# Website Verification Test Script
# This script checks if the website is properly configured and not redirecting to /lander

function Test-Website {
    param (
        [string]$url
    )
    
    try {
        Write-Host "Testing $url..." -ForegroundColor Yellow
        
        # Make a web request and follow redirects
        $request = [System.Net.WebRequest]::Create($url)
        $request.AllowAutoRedirect = $false
        $response = $request.GetResponse()
        
        $statusCode = [int]$response.StatusCode
        $statusDescription = $response.StatusDescription
        $finalUrl = $response.ResponseUri
        
        if ($statusCode -eq 200) {
            Write-Host "✓ Success! Status: $statusCode $statusDescription" -ForegroundColor Green
        } else {
            Write-Host "✗ Unexpected status code: $statusCode $statusDescription" -ForegroundColor Red
        }
        
        # Check for redirects
        if ($finalUrl -ne $url) {
            Write-Host "⚠ Redirect detected to: $finalUrl" -ForegroundColor Yellow
            
            if ($finalUrl -like "*lander*") {
                Write-Host "✗ PROBLEM: Still redirecting to /lander!" -ForegroundColor Red
                Write-Host "  This indicates DNS is not properly configured or GoDaddy redirect is still active" -ForegroundColor Red
            }
        } else {
            Write-Host "✓ No redirects detected" -ForegroundColor Green
        }
        
        $response.Close()
    } catch {
        Write-Host "✗ Error accessing $url" -ForegroundColor Red
        Write-Host "  $_" -ForegroundColor Red
        
        # Check if it's a DNS resolution error
        if ($_.Exception.Message -like "*name resolution*") {
            Write-Host "`n⚠ This appears to be a DNS issue." -ForegroundColor Yellow
            Write-Host "  - DNS changes may still be propagating" -ForegroundColor Yellow
            Write-Host "  - GoDaddy DNS settings may not be properly configured" -ForegroundColor Yellow
        }
    }
}

# Main script
Clear-Host
Write-Host "==== iBridgeSolutions Website Test ====`n" -ForegroundColor Cyan

# Test both www and non-www versions
Test-Website -url "https://ibridgesolutions.co.za"
Write-Host
Test-Website -url "https://www.ibridgesolutions.co.za"

# Provide additional information
Write-Host "`n==== Next Steps ====`n" -ForegroundColor Cyan
Write-Host "If the website is still not working correctly:" -ForegroundColor White
Write-Host "1. DNS changes may still be propagating (can take 24-48 hours)" -ForegroundColor White
Write-Host "2. Run the fix-godaddy-dns.ps1 script to verify proper DNS settings" -ForegroundColor White
Write-Host "3. Make sure all GoDaddy redirect settings are disabled" -ForegroundColor White
Write-Host "4. Try clearing your browser cache or using incognito mode" -ForegroundColor White
