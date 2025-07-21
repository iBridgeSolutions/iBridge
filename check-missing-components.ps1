# PowerShell script to check and fix missing components

# Function to check if a file has required CSS and JS links
function Test-RequiredComponents {
    param (
        [string]$content
    )
    
    $missing = @{
        css = @()
        js = @()
    }
    
    # Check for required CSS files
    $cssFiles = @(
        'components.css',
        'theme.css',
        'animations.css'
    )
    
    foreach ($css in $cssFiles) {
        if ($content -notmatch [regex]::Escape($css)) {
            $missing.css += $css
        }
    }
    
    # Check for required JS files
    $jsFiles = @(
        'components.js',
        'theme.js',
        'animations.js'
    )
    
    foreach ($js in $jsFiles) {
        if ($content -notmatch [regex]::Escape($js)) {
            $missing.js += $js
        }
    }
    
    return $missing
}

# Function to add missing CSS links
function Add-CssLinks {
    param (
        [string]$content,
        [array]$missingFiles
    )
    
    $cssLinks = ""
    foreach ($file in $missingFiles) {
        $cssLinks += "    <link rel=`"stylesheet`" href=`"css/$file`">`n"
    }
    
    # Add CSS links before the closing head tag
    $content = $content -replace '</head>', "$cssLinks</head>"
    return $content
}

# Function to add missing JS scripts
function Add-JsScripts {
    param (
        [string]$content,
        [array]$missingFiles
    )
    
    $jsScripts = ""
    foreach ($file in $missingFiles) {
        $jsScripts += "    <script src=`"js/$file`"></script>`n"
    }
    
    # Add JS scripts before the closing body tag
    $content = $content -replace '</body>', "$jsScripts</body>"
    return $content
}

# Function to check and add theme toggle button
function Add-ThemeToggle {
    param (
        [string]$content
    )
    
    if ($content -notmatch '<button.*?class="theme-toggle".*?>') {
        $themeToggle = @'
                    <button class="theme-toggle" aria-label="Toggle dark mode">
                        <i class="fas fa-moon"></i>
                    </button>
'@
        
        # Add theme toggle before the portal login button
        $content = $content -replace '(<a href="intranet/login.html".*?</a>)', "$themeToggle`n                    `$1"
    }
    
    return $content
}

# Get all HTML files
$htmlFiles = Get-ChildItem -Path "." -Filter "*.html" -Recurse

foreach ($file in $htmlFiles) {
    Write-Host "Checking $($file.Name)..."
    
    # Read file content
    $content = Get-Content -Path $file.FullName -Raw
    
    # Skip empty files
    if ([string]::IsNullOrWhiteSpace($content)) {
        Write-Host "Skipping empty file: $($file.Name)"
        continue
    }
    
    # Check for required components
    $missing = Test-RequiredComponents -content $content
    $needsUpdate = $false
    
    # Add missing CSS files
    if ($missing.css.Count -gt 0) {
        Write-Host "Adding missing CSS files: $($missing.css -join ', ')"
        $content = Add-CssLinks -content $content -missingFiles $missing.css
        $needsUpdate = $true
    }
    
    # Add missing JS files
    if ($missing.js.Count -gt 0) {
        Write-Host "Adding missing JS files: $($missing.js -join ', ')"
        $content = Add-JsScripts -content $content -missingFiles $missing.js
        $needsUpdate = $true
    }
    
    # Check for theme toggle button
    if ($content -match '<div class="header-actions">' -and $content -notmatch '<button.*?class="theme-toggle".*?>') {
        Write-Host "Adding theme toggle button"
        $content = Add-ThemeToggle -content $content
        $needsUpdate = $true
    }
    
    # Update file if needed
    if ($needsUpdate) {
        $content | Set-Content -Path $file.FullName -Force
        Write-Host "Updated $($file.Name)"
    } else {
        Write-Host "No updates needed for $($file.Name)"
    }
}

Write-Host "Finished checking all HTML files"
