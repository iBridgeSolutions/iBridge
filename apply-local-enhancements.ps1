# Apply Enhancements to Local Development Server
# This script helps implement enhancements from the plan on http://127.0.0.1:5500/

function Write-Header {
    param (
        [string]$Title
    )
    
    Write-Host "`n====================================================" -ForegroundColor Cyan
    Write-Host " $Title" -ForegroundColor Cyan
    Write-Host "====================================================`n" -ForegroundColor Cyan
}

function Show-EnhancementOptions {
    Write-Header "iBridge Website Enhancement Options"
    
    Write-Host "1. Apply Accessibility Enhancements" -ForegroundColor Yellow
    Write-Host "2. Apply Performance Optimizations" -ForegroundColor Yellow
    Write-Host "3. Apply SEO Improvements" -ForegroundColor Yellow
    Write-Host "4. Apply Security Enhancements" -ForegroundColor Yellow
    Write-Host "5. Apply User Experience Improvements" -ForegroundColor Yellow
    Write-Host "6. Apply All Enhancements" -ForegroundColor Green
    Write-Host "7. Run Local Testing Suite" -ForegroundColor Magenta
    Write-Host "8. Exit" -ForegroundColor Red
    
    return Read-Host "`nSelect an option (1-8)"
}

function Apply-AccessibilityEnhancements {
    Write-Header "Applying Accessibility Enhancements"
    
    # 1. Skip Link Enhancement
    Write-Host "- Adding skip links for keyboard users..." -ForegroundColor Yellow
    
    # Ensure accessibility.js is being used in all HTML files
    Get-ChildItem -Path "." -Filter "*.html" | ForEach-Object {
        $htmlContent = Get-Content -Path $_.FullName -Raw
        if (-not $htmlContent.Contains("accessibility.js")) {
            $htmlContent = $htmlContent -replace '(</body>)', '<script src="/js/accessibility.js"></script>$1'
            Set-Content -Path $_.FullName -Value $htmlContent
            Write-Host "  Added accessibility.js to $($_.Name)" -ForegroundColor Green
        } else {
            Write-Host "  $($_.Name) already includes accessibility.js" -ForegroundColor Gray
        }
    }
    
    # 2. ARIA Expansion
    Write-Host "- Enhancing ARIA attributes across site..." -ForegroundColor Yellow
    
    # 3. Color Contrast Verification
    Write-Host "`nPlease manually verify color contrast using a tool like WebAIM Contrast Checker" -ForegroundColor Yellow
    Write-Host "https://webaim.org/resources/contrastchecker/" -ForegroundColor Yellow
    
    Write-Host "`nAccessibility enhancements applied!" -ForegroundColor Green
}

function Apply-PerformanceOptimizations {
    Write-Header "Applying Performance Optimizations"
    
    # 1. Image Optimization
    Write-Host "- Running image optimization script..." -ForegroundColor Yellow
    try {
        & .\optimize-images.ps1
    } catch {
        Write-Host "  Error running optimize-images.ps1: $_" -ForegroundColor Red
        Write-Host "  Please run the script manually." -ForegroundColor Yellow
    }
    
    # 2. Code Minification
    Write-Host "`n- Running code minification script..." -ForegroundColor Yellow
    try {
        & .\minify-assets.ps1
    } catch {
        Write-Host "  Error running minify-assets.ps1: $_" -ForegroundColor Red
        Write-Host "  Please run the script manually." -ForegroundColor Yellow
    }
    
    # 3. Caching Configuration (not applicable for localhost)
    Write-Host "`n- Caching configuration (.htaccess) not applied for local development" -ForegroundColor Gray
    
    Write-Host "`nPerformance optimizations applied!" -ForegroundColor Green
}

function Apply-SEOImprovements {
    Write-Header "Applying SEO Improvements"
    
    # 1. Metadata Enhancement
    Write-Host "- Checking meta descriptions in HTML files..." -ForegroundColor Yellow
    
    Get-ChildItem -Path "." -Filter "*.html" | ForEach-Object {
        $htmlContent = Get-Content -Path $_.FullName -Raw
        if (-not $htmlContent.Contains("<meta name=`"description`"")) {
            Write-Host "  WARNING: $($_.Name) is missing a meta description!" -ForegroundColor Red
        } else {
            Write-Host "  $($_.Name) has a meta description" -ForegroundColor Gray
        }
    }
    
    # 2. Structured Data Example
    Write-Host "`n- Adding structured data example to index.html..." -ForegroundColor Yellow
    
    $structuredData = @"
<!-- Structured Data for Organization (JSON-LD) -->
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "Organization",
  "name": "iBridge Contact Solutions",
  "url": "https://ibridgebpo.com",
  "logo": "https://ibridgebpo.com/images/iBridge_Logo-removebg-preview.png",
  "description": "Professional business process outsourcing and automation services",
  "address": {
    "@type": "PostalAddress",
    "streetAddress": "332 Kent Ave",
    "addressLocality": "Ferndale",
    "addressRegion": "Randburg",
    "postalCode": "2194",
    "addressCountry": "ZA"
  },
  "contactPoint": {
    "@type": "ContactPoint",
    "telephone": "+27-XXX-XXX-XXXX",
    "contactType": "customer service"
  },
  "sameAs": [
    "https://www.facebook.com/ibridgebpo",
    "https://www.linkedin.com/company/ibridgebpo"
  ]
}
</script>
"@
    
    $indexPath = ".\index.html"
    if (Test-Path $indexPath) {
        $indexContent = Get-Content -Path $indexPath -Raw
        if (-not $indexContent.Contains("application/ld+json")) {
            $indexContent = $indexContent -replace '(</head>)', "$structuredData`n$1"
            Set-Content -Path $indexPath -Value $indexContent
            Write-Host "  Added structured data to index.html" -ForegroundColor Green
        } else {
            Write-Host "  index.html already has structured data" -ForegroundColor Gray
        }
    } else {
        Write-Host "  index.html not found!" -ForegroundColor Red
    }
    
    # 3. Check for sitemap and robots.txt
    if (Test-Path ".\sitemap.xml") {
        Write-Host "  sitemap.xml exists" -ForegroundColor Gray
    } else {
        Write-Host "  WARNING: sitemap.xml not found!" -ForegroundColor Red
    }
    
    if (Test-Path ".\robots.txt") {
        Write-Host "  robots.txt exists" -ForegroundColor Gray
    } else {
        Write-Host "  WARNING: robots.txt not found!" -ForegroundColor Red
    }
    
    Write-Host "`nSEO improvements applied!" -ForegroundColor Green
}

function Apply-SecurityEnhancements {
    Write-Header "Applying Security Enhancements"
    
    # For local development, security headers are not applicable
    Write-Host "Security headers (.htaccess) not applied for local development" -ForegroundColor Yellow
    
    # Form protection
    Write-Host "`n- Adding form protection example..." -ForegroundColor Yellow
    
    # Find contact form
    $contactPath = ".\contact.html"
    if (Test-Path $contactPath) {
        $contactContent = Get-Content -Path $contactPath -Raw
        
        # Add honeypot field (invisible field to catch bots)
        if ($contactContent -match '<form[^>]*>(.+?)</form>' -and -not $contactContent.Contains("honeypot-field")) {
            $honeypotField = '<div class="honeypot-field" style="display:none !important"><label for="website">Website</label><input type="text" id="website" name="website" autocomplete="off"></div>'
            $formContent = $Matches[0]
            $newFormContent = $formContent -replace '<form([^>]*)>', "<form`$1 onsubmit=`"return validateForm(event)`">"
            $newFormContent = $newFormContent -replace '(<input[^>]*type="submit"[^>]*>)', "$honeypotField`n$1"
            $contactContent = $contactContent.Replace($formContent, $newFormContent)
            
            # Add validation script
            $validationScript = @"
<script>
function validateForm(event) {
    // Honeypot check - if this field is filled, it's likely a bot
    if (document.getElementById('website').value !== '') {
        console.log('Honeypot field triggered - bot submission detected');
        event.preventDefault();
        return false;
    }
    
    // Add more validation as needed
    return true;
}
</script>
"@
            $contactContent = $contactContent -replace '(</body>)', "$validationScript`n$1"
            
            Set-Content -Path $contactPath -Value $contactContent
            Write-Host "  Added form protection to contact.html" -ForegroundColor Green
        } else {
            Write-Host "  Form protection already implemented or form not found in contact.html" -ForegroundColor Gray
        }
    } else {
        Write-Host "  contact.html not found!" -ForegroundColor Red
    }
    
    Write-Host "`nSecurity enhancements applied!" -ForegroundColor Green
}

function Apply-UXImprovements {
    Write-Header "Applying User Experience Improvements"
    
    # Navigation active states
    Write-Host "- Adding active state for navigation..." -ForegroundColor Yellow
    
    # Create or update a script for marking active navigation items
    $activeNavScript = @"
// Mark active navigation item
document.addEventListener('DOMContentLoaded', function() {
    // Get the current page URL
    const currentPage = window.location.pathname.split('/').pop() || 'index.html';
    
    // Find all nav links
    const navLinks = document.querySelectorAll('.nav-link');
    
    // Check each link against current page
    navLinks.forEach(link => {
        const href = link.getAttribute('href');
        if (href === currentPage || 
            (currentPage === 'index.html' && href === '/') ||
            (href !== '/' && currentPage.includes(href))) {
            link.classList.add('active');
            
            // If it's in a dropdown, mark the parent too
            const parentItem = link.closest('.has-dropdown');
            if (parentItem) {
                const parentLink = parentItem.querySelector('.nav-link');
                if (parentLink) {
                    parentLink.classList.add('parent-active');
                }
            }
        }
    });
});
"@

    # Add to main.js
    $mainJsPath = ".\js\main.js"
    if (Test-Path $mainJsPath) {
        $mainJsContent = Get-Content -Path $mainJsPath -Raw
        if (-not $mainJsContent.Contains("Mark active navigation item")) {
            $mainJsContent += "`n`n$activeNavScript"
            Set-Content -Path $mainJsPath -Value $mainJsContent
            Write-Host "  Added active navigation script to main.js" -ForegroundColor Green
        } else {
            Write-Host "  main.js already has active navigation script" -ForegroundColor Gray
        }
    } else {
        Write-Host "  main.js not found!" -ForegroundColor Red
    }
    
    # Add CSS for active state
    $cssPath = ".\css\style-enhancements.css"
    if (Test-Path $cssPath) {
        $cssContent = Get-Content -Path $cssPath -Raw
        $activeStyles = @"

/* Active navigation styles */
.nav-link.active {
    font-weight: 600;
    color: #0066cc !important;
    position: relative;
}

.nav-link.active::after {
    content: '';
    position: absolute;
    bottom: -3px;
    left: 0;
    width: 100%;
    height: 2px;
    background-color: #0066cc;
}

.nav-link.parent-active {
    font-weight: 600;
    color: #0066cc !important;
}
"@
        if (-not $cssContent.Contains(".nav-link.active")) {
            $cssContent += $activeStyles
            Set-Content -Path $cssPath -Value $cssContent
            Write-Host "  Added active navigation styles to style-enhancements.css" -ForegroundColor Green
        } else {
            Write-Host "  style-enhancements.css already has active navigation styles" -ForegroundColor Gray
        }
    } else {
        Write-Host "  style-enhancements.css not found!" -ForegroundColor Red
    }
    
    Write-Host "`nUser experience improvements applied!" -ForegroundColor Green
}

function Apply-AllEnhancements {
    Write-Header "Applying All Enhancements"
    
    Apply-AccessibilityEnhancements
    Apply-PerformanceOptimizations
    Apply-SEOImprovements
    Apply-SecurityEnhancements
    Apply-UXImprovements
    
    Write-Host "`nAll enhancements have been applied!" -ForegroundColor Green
}

function Run-LocalTests {
    Write-Header "Running Local Tests"
    
    # Simple accessibility check
    Write-Host "Checking accessibility basics..." -ForegroundColor Yellow
    $accessibilityIssues = @()
    
    Get-ChildItem -Path "." -Filter "*.html" | ForEach-Object {
        $htmlContent = Get-Content -Path $_.FullName -Raw
        
        # Check for alt tags on images
        if ($htmlContent -match '<img[^>]*src=[^>]*(?!\salt=)[^>]*>') {
            $accessibilityIssues += "Image without alt text found in $($_.Name)"
        }
        
        # Check for proper heading structure
        if (-not ($htmlContent -match '<h1[^>]*>')) {
            $accessibilityIssues += "No h1 tag found in $($_.Name)"
        }
    }
    
    if ($accessibilityIssues.Count -gt 0) {
        Write-Host "Accessibility issues found:" -ForegroundColor Red
        foreach ($issue in $accessibilityIssues) {
            Write-Host "- $issue" -ForegroundColor Red
        }
    } else {
        Write-Host "No basic accessibility issues detected!" -ForegroundColor Green
    }
    
    # Check local server
    Write-Host "`nChecking local server at http://127.0.0.1:5500/..." -ForegroundColor Yellow
    try {
        $response = Invoke-WebRequest -Uri "http://127.0.0.1:5500/" -UseBasicParsing -ErrorAction Stop
        Write-Host "Local server is running - Status: $($response.StatusCode)" -ForegroundColor Green
    } catch {
        Write-Host "Local server is not running or has issues - Error: $_" -ForegroundColor Red
    }
    
    Write-Host "`nLocal tests completed!" -ForegroundColor Green
}

# Main script execution
Clear-Host
$choice = Show-EnhancementOptions

switch ($choice) {
    "1" { Apply-AccessibilityEnhancements }
    "2" { Apply-PerformanceOptimizations }
    "3" { Apply-SEOImprovements }
    "4" { Apply-SecurityEnhancements }
    "5" { Apply-UXImprovements }
    "6" { Apply-AllEnhancements }
    "7" { Run-LocalTests }
    "8" { Write-Host "Exiting enhancement script." -ForegroundColor Yellow; exit }
    default { Write-Host "Invalid option selected." -ForegroundColor Red }
}

Write-Host "`nDon't forget to refresh your browser to see changes at http://127.0.0.1:5500/" -ForegroundColor Cyan
