# PowerShell Script to Minify CSS and JavaScript Files
# This script creates minified versions of CSS and JS files with .min suffix

function Test-Dependencies {
    # Check for Node.js
    $node = Get-Command -Name node -ErrorAction SilentlyContinue
    if ($node) {
        Write-Host "Node.js found. Will use for minification." -ForegroundColor Green
        return $true
    }
    
    Write-Host "Node.js not found. Please install Node.js: https://nodejs.org/" -ForegroundColor Yellow
    return $false
}

function Install-NodePackages {
    Write-Host "Setting up Node.js packages for minification..." -ForegroundColor Cyan
    
    # Create package.json if it doesn't exist
    if (!(Test-Path -Path "./minify-package.json")) {
        @"
{
  "name": "minification",
  "version": "1.0.0",
  "description": "CSS and JS minification for iBridge website",
  "scripts": {
    "minify-css": "cleancss -o ./css/styles.min.css ./css/styles.css && cleancss -o ./css/style-enhancements.min.css ./css/style-enhancements.css",
    "minify-js": "uglifyjs ./js/main.js -c -m -o ./js/main.min.js && uglifyjs ./js/accessibility.js -c -m -o ./js/accessibility.min.js",
    "minify": "npm run minify-css && npm run minify-js"
  },
  "devDependencies": {
    "clean-css-cli": "^5.6.0",
    "uglify-js": "^3.17.0"
  }
}
"@ | Out-File -FilePath "./minify-package.json" -Encoding utf8
    }
    
    # Install dependencies
    Write-Host "Installing required Node.js packages for minification..." -ForegroundColor Cyan
    npm install --package-lock-only --no-package-lock --quiet --no-save --prefix . -D clean-css-cli uglify-js
}

function Start-Minification {
    Write-Host "Starting minification process..." -ForegroundColor Cyan
    
    # Minify CSS files
    Write-Host "Minifying CSS files..." -ForegroundColor Cyan
    npx cleancss -o ./css/styles.min.css ./css/styles.css
    npx cleancss -o ./css/style-enhancements.min.css ./css/style-enhancements.css
    
    # Minify JS files
    Write-Host "Minifying JavaScript files..." -ForegroundColor Cyan
    npx uglifyjs ./js/main.js -c -m -o ./js/main.min.js
    npx uglifyjs ./js/accessibility.js -c -m -o ./js/accessibility.min.js
}

function Update-HTML-References {
    Write-Host "Creating helper script to update HTML references..." -ForegroundColor Cyan
    
    @"
# Helper script to update HTML files to use minified resources
# Run this after testing the minified files to ensure they work correctly

function Update-CSSReferences {
    Write-Host "Updating CSS references in HTML files..." -ForegroundColor Cyan
    
    # Get all HTML files
    \$htmlFiles = Get-ChildItem -Path "./" -Filter "*.html" -File
    
    foreach (\$file in \$htmlFiles) {
        \$content = Get-Content \$file.FullName -Raw
        
        # Replace CSS references
        \$updatedContent = \$content -replace '(/css/styles.css)"', '/css/styles.min.css"'
        \$updatedContent = \$updatedContent -replace '(/css/style-enhancements.css)"', '/css/style-enhancements.min.css"'
        
        # Replace JS references
        \$updatedContent = \$updatedContent -replace '(/js/main.js)"', '/js/main.min.js"'
        \$updatedContent = \$updatedContent -replace '(/js/accessibility.js)"', '/js/accessibility.min.js"'
        
        # Only write back if changes were made
        if (\$content -ne \$updatedContent) {
            Set-Content -Path \$file.FullName -Value \$updatedContent
            Write-Host "Updated: \$(\$file.Name)" -ForegroundColor Green
        } else {
            Write-Host "No changes needed for: \$(\$file.Name)" -ForegroundColor Yellow
        }
    }
}

# Call the function to update HTML files
# Uncomment when ready to apply changes
# Update-CSSReferences
Write-Host "This script will update HTML files to use minified CSS and JS files."
Write-Host "Uncomment the 'Update-CSSReferences' line to apply changes after testing minified files."
"@ | Out-File -FilePath "./update-to-minified.ps1" -Encoding utf8
}

# Main execution
Write-Host "Starting CSS and JS minification for iBridge website..." -ForegroundColor Cyan
$canProceed = Test-Dependencies

if ($canProceed) {
    Install-NodePackages
    Start-Minification
    Update-HTML-References
    
    Write-Host "Minification process complete!" -ForegroundColor Green
    Write-Host "Created minified versions of CSS and JS files with .min suffix." -ForegroundColor Green
    Write-Host "Use update-to-minified.ps1 to update HTML references after testing." -ForegroundColor Green
} else {
    Write-Host "Cannot proceed with minification. Please install required dependencies." -ForegroundColor Red
}
