# Contact Center Solutions Page Validation

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "   CONTACT CENTER SOLUTIONS VALIDATION" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host

# Check if contact-center.html exists
Write-Host "Checking for contact-center.html file..." -ForegroundColor Yellow
if (Test-Path .\contact-center.html) {
    Write-Host "√ contact-center.html found" -ForegroundColor Green
    $fileSize = (Get-Item .\contact-center.html).Length
    Write-Host "File size: $fileSize bytes" -ForegroundColor Green
    
    # Content validation
    $content = Get-Content .\contact-center.html -Raw
      # Check page title
    if ($content -match "<title>.*Contact Center Solutions.*</title>") {
        Write-Host "√ Page title contains 'Contact Center Solutions'" -ForegroundColor Green
    } else {
        Write-Host "× Page title doesn't contain 'Contact Center Solutions'" -ForegroundColor Red
    }
      # Check page heading
    if ($content -match "<h1.*>.*Contact Center Solutions.*</h1>") {
        Write-Host "√ Page has heading with 'Contact Center Solutions'" -ForegroundColor Green
    } else {
        Write-Host "× Page doesn't have proper heading" -ForegroundColor Red
    }
      # Check content details
    if ($content -match "comprehensive.*contact center solutions|omnichannel|customer.*support") {
        Write-Host "√ Page contains relevant content about contact center solutions" -ForegroundColor Green
    } else {
        Write-Host "× Page might not have proper content" -ForegroundColor Yellow
    }
} else {
    Write-Host "✗ contact-center.html not found" -ForegroundColor Red
    exit
}

Write-Host "`nChecking navigation links in other pages..." -ForegroundColor Yellow

# Function to check links in a file
function Check-Links {
    param(
        [string]$FilePath,
        [string]$Description
    )
    
    if (Test-Path $FilePath) {
        Write-Host "Checking $Description ($FilePath)..." -ForegroundColor White
        $content = Get-Content $FilePath -Raw
        
        # Check for correct links to contact-center.html
        if ($content -match "href=`"contact-center.html`"") {
            Write-Host "  √ Links to contact-center.html found" -ForegroundColor Green
        } else {
            Write-Host "  × No links to contact-center.html found" -ForegroundColor Red
        }
        
        # Check for incorrect links to services.html#contact-center
        if ($content -match "href=`"services.html#contact-center") {
            Write-Host "  × Incorrect links found (services.html#contact-center)" -ForegroundColor Red
        } else {
            Write-Host "  √ No incorrect links found" -ForegroundColor Green
        }
    } else {
        Write-Host "$Description file not found ($FilePath)" -ForegroundColor Yellow
    }
}

# Check all main pages
Check-Links -FilePath ".\index.html" -Description "Home page"
Check-Links -FilePath ".\about.html" -Description "About page"
Check-Links -FilePath ".\services.html" -Description "Services page"
Check-Links -FilePath ".\contact.html" -Description "Contact page"
Check-Links -FilePath ".\it-support.html" -Description "IT Support page"
Check-Links -FilePath ".\ai-automation.html" -Description "AI & Automation page"

Write-Host "`nChecking for Contact Center section in index.html..." -ForegroundColor Yellow
$indexContent = Get-Content .\index.html -Raw
if ($indexContent -match "id=`"contact-center-section`"|Contact Center Solutions section") {
    Write-Host "× Contact Center section might still exist in index.html" -ForegroundColor Red
} else {
    Write-Host "√ No Contact Center section found in index.html" -ForegroundColor Green
}

Write-Host "`nValidation Complete!" -ForegroundColor Cyan
Write-Host "To preview the website, run: .\preview-website.ps1" -ForegroundColor Yellow
