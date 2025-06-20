# Fix GoDaddy DNS Configuration Script
# This script provides instructions and helps you fix the DNS settings for ibridgesolutions.co.za

function Show-Header {
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "            FIX IBRIDGESOLUTIONS.CO.ZA DNS SETTINGS             " -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host
}

function Check-CurrentDNS {
    Write-Host "Checking current DNS configuration..." -ForegroundColor Yellow
    
    try {
        $aRecords = Resolve-DnsName -Name "ibridgesolutions.co.za" -Type A -ErrorAction SilentlyContinue
        
        Write-Host "Current A Records:" -ForegroundColor White
        $foundIPs = @()
        foreach ($record in $aRecords) {
            if ($record.Type -eq "A") {
                $foundIPs += $record.IPAddress
                Write-Host "  - $($record.IPAddress)" -ForegroundColor Red
            }
        }
        
        Write-Host "`nCorrect GitHub Pages IPs should be:" -ForegroundColor White
        $githubIPs = @(
            "185.199.108.153",
            "185.199.109.153",
            "185.199.110.153",
            "185.199.111.153"
        )
        
        foreach ($ip in $githubIPs) {
            Write-Host "  + $ip" -ForegroundColor Green
        }
        
        # Check CNAME for www
        $cnameRecords = Resolve-DnsName -Name "www.ibridgesolutions.co.za" -Type CNAME -ErrorAction SilentlyContinue
        if ($cnameRecords) {
            $cname = ($cnameRecords | Where-Object { $_.Type -eq "CNAME" } | Select-Object -First 1).NameHost
            Write-Host "`nCurrent CNAME for www.ibridgesolutions.co.za:" -ForegroundColor White
            Write-Host "  - $cname" -ForegroundColor Red
            
            Write-Host "`nCorrect CNAME should be:" -ForegroundColor White
            Write-Host "  + ibridgesolutions.github.io" -ForegroundColor Green
        } else {
            Write-Host "`nNo CNAME record found for www.ibridgesolutions.co.za" -ForegroundColor Red
            Write-Host "Correct CNAME should be:" -ForegroundColor White
            Write-Host "  + ibridgesolutions.github.io" -ForegroundColor Green
        }
    } catch {
        Write-Host "Error checking DNS: $_" -ForegroundColor Red
    }
    
    Write-Host "`nDNS changes are needed to fix the website!" -ForegroundColor Yellow
}

function Show-Instructions {
    Write-Host "`n=== STEPS TO FIX GODADDY DNS CONFIGURATION ===" -ForegroundColor Green
    
    Write-Host "`n1. Log in to your GoDaddy account at godaddy.com" -ForegroundColor White
    Write-Host "2. Go to 'My Products'" -ForegroundColor White
    Write-Host "3. Find ibridgesolutions.co.za in your domains list" -ForegroundColor White
    Write-Host "4. Click on 'DNS'" -ForegroundColor White
    Write-Host
    Write-Host "5. UPDATE A RECORDS:" -ForegroundColor Yellow
    Write-Host "   a) Find and REMOVE ALL existing A records for @" -ForegroundColor White
    Write-Host "   b) Add these FOUR new A records:" -ForegroundColor White
    Write-Host "      - Type: A | Host: @ | Points to: 185.199.108.153 | TTL: 1 hour" -ForegroundColor Green
    Write-Host "      - Type: A | Host: @ | Points to: 185.199.109.153 | TTL: 1 hour" -ForegroundColor Green
    Write-Host "      - Type: A | Host: @ | Points to: 185.199.110.153 | TTL: 1 hour" -ForegroundColor Green
    Write-Host "      - Type: A | Host: @ | Points to: 185.199.111.153 | TTL: 1 hour" -ForegroundColor Green
    Write-Host
    Write-Host "6. UPDATE CNAME RECORD:" -ForegroundColor Yellow
    Write-Host "   a) Find and remove any existing CNAME record for www" -ForegroundColor White
    Write-Host "   b) Add this CNAME record:" -ForegroundColor White
    Write-Host "      - Type: CNAME | Host: www | Points to: ibridgesolutions.github.io | TTL: 1 hour" -ForegroundColor Green
    Write-Host
    Write-Host "7. DISABLE WEBSITE REDIRECT:" -ForegroundColor Yellow
    Write-Host "   a) In your domain dashboard, look for 'Website Redirect' settings" -ForegroundColor White
    Write-Host "   b) Disable any redirect to /lander" -ForegroundColor White
    Write-Host "   c) Turn off any 'Coming Soon' or 'Under Construction' pages" -ForegroundColor White
}

function Open-GoDaddyLogin {
    $response = Read-Host "`nWould you like to open GoDaddy login page now? (Y/N)"
    if ($response.ToUpper() -eq "Y") {
        Write-Host "Opening GoDaddy login page..." -ForegroundColor Cyan
        Start-Process "https://www.godaddy.com/sign-in"
    }
}

function Show-VerificationInstructions {
    Write-Host "`n=== AFTER MAKING DNS CHANGES ===" -ForegroundColor Yellow
    Write-Host "1. Wait 24-48 hours for DNS changes to fully propagate" -ForegroundColor White
    Write-Host "2. Run this command to check if DNS changes are working:" -ForegroundColor White
    Write-Host "   cd `"c:\Users\Lwandile Gasela\Downloads\iBridge-main`" ; .\simple-dns-check.ps1" -ForegroundColor Cyan
    Write-Host "3. Visit https://ibridgesolutions.co.za to verify the website loads correctly" -ForegroundColor White
    Write-Host "4. If you still have issues, contact GoDaddy support to ask about any hidden redirect rules" -ForegroundColor White
}

function Show-Footer {
    Write-Host "`n================================================================" -ForegroundColor Cyan
    Write-Host "      Once DNS is fixed, your website should work properly!      " -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
}

# Main script execution
Clear-Host
Show-Header
Check-CurrentDNS
Show-Instructions
Open-GoDaddyLogin
Show-VerificationInstructions
Show-Footer
