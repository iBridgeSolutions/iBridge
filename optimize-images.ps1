# PowerShell Script to Optimize Images for Web
# This script compresses PNG images and adds WebP versions

# First, check if we have TinyPNG API key for better compression
$tinyPngApiKey = $null
$useImageMagick = $false
$useNodePackages = $false

function Check-Dependencies {
    # Check for ImageMagick
    $imageMagick = Get-Command -Name magick -ErrorAction SilentlyContinue
    if ($imageMagick) {
        Write-Host "ImageMagick found. Will use for image optimization." -ForegroundColor Green
        $script:useImageMagick = $true
        return
    }
    
    # Check for NPM/Node
    $npm = Get-Command -Name npm -ErrorAction SilentlyContinue
    if ($npm) {
        Write-Host "NPM found. Will install and use imagemin packages." -ForegroundColor Green
        $script:useNodePackages = $true
        return
    }
    
    Write-Host "No image optimization tools found. Please install ImageMagick or Node.js/NPM." -ForegroundColor Yellow
    Write-Host "For best results, install ImageMagick: https://imagemagick.org/script/download.php" -ForegroundColor Yellow
    Write-Host "Or install Node.js: https://nodejs.org/" -ForegroundColor Yellow
}

function Setup-NodePackages {
    if ($script:useNodePackages) {
        Write-Host "Setting up Node.js packages for image optimization..." -ForegroundColor Cyan
        
        # Create package.json if it doesn't exist
        if (!(Test-Path -Path "./package.json")) {
            @"
{
  "name": "image-optimization",
  "version": "1.0.0",
  "description": "Image optimization for iBridge website",
  "scripts": {
    "optimize": "node optimize-images.js"
  },
  "dependencies": {
    "imagemin": "^8.0.1",
    "imagemin-pngquant": "^9.0.2",
    "imagemin-webp": "^6.0.0"
  }
}
"@ | Out-File -FilePath "./package.json" -Encoding utf8
        }
        
        # Create the optimization script
        @"
const imagemin = require('imagemin');
const imageminPngquant = require('imagemin-pngquant');
const imageminWebp = require('imagemin-webp');
const fs = require('fs');
const path = require('path');

// Process PNG files
(async () => {
    console.log('Optimizing PNG images...');
    const files = await imagemin(['images/*.png'], {
        destination: 'images/optimized/',
        plugins: [
            imageminPngquant({
                quality: [0.6, 0.8]
            })
        ]
    });
    
    console.log('PNG optimization complete:', files.length, 'files processed');
})();

// Convert to WebP
(async () => {
    console.log('Converting images to WebP...');
    const files = await imagemin(['images/*.png', 'images/*.jpg', 'images/*.jpeg'], {
        destination: 'images/webp/',
        plugins: [
            imageminWebp({quality: 75})
        ]
    });
    
    console.log('WebP conversion complete:', files.length, 'files processed');
})();
"@ | Out-File -FilePath "./optimize-images.js" -Encoding utf8
        
        # Run npm install to get dependencies
        Write-Host "Installing required Node.js packages..." -ForegroundColor Cyan
        npm install
    }
}

function Optimize-Images-With-ImageMagick {
    Write-Host "Optimizing images with ImageMagick..." -ForegroundColor Cyan
    
    # Create directories if they don't exist
    if (!(Test-Path -Path "./images/optimized")) {
        New-Item -Path "./images/optimized" -ItemType Directory -Force
    }
    
    if (!(Test-Path -Path "./images/webp")) {
        New-Item -Path "./images/webp" -ItemType Directory -Force
    }
    
    # Get all PNG files
    $pngFiles = Get-ChildItem -Path "./images" -Filter "*.png" -File
    
    foreach ($file in $pngFiles) {
        $outputFile = "./images/optimized/$($file.Name)"
        $webpFile = "./images/webp/$($file.BaseName).webp"
        
        Write-Host "Optimizing: $($file.Name)" -ForegroundColor Cyan
        
        # Optimize PNG
        magick convert $file.FullName -strip -resize "1200x1200>" -quality 85 -define png:compression-filter=5 -define png:compression-level=9 -define png:compression-strategy=1 $outputFile
        
        # Convert to WebP
        magick convert $file.FullName -strip -resize "1200x1200>" -quality 80 -define webp:lossless=false $webpFile
    }
    
    # Get all JPG files
    $jpgFiles = Get-ChildItem -Path "./images" -Filter "*.jpg" -File
    $jpgFiles += Get-ChildItem -Path "./images" -Filter "*.jpeg" -File
    
    foreach ($file in $jpgFiles) {
        $outputFile = "./images/optimized/$($file.Name)"
        $webpFile = "./images/webp/$($file.BaseName).webp"
        
        Write-Host "Optimizing: $($file.Name)" -ForegroundColor Cyan
        
        # Optimize JPG
        magick convert $file.FullName -strip -resize "1200x1200>" -quality 85 $outputFile
        
        # Convert to WebP
        magick convert $file.FullName -strip -resize "1200x1200>" -quality 80 -define webp:lossless=false $webpFile
    }
}

function Optimize-With-Node {
    Write-Host "Optimizing images with Node.js packages..." -ForegroundColor Cyan
    npm run optimize
}

function Create-HTML-Helper {
    # Create a helper file that shows how to use WebP with fallback
    $helperContent = @"
<!-- 
HOW TO USE WEBP IMAGES WITH FALLBACK

Method 1: Using the <picture> element (recommended)
-->
<picture>
    <source srcset="/images/webp/iBridge_IMG_1.webp" type="image/webp">
    <img src="/images/iBridge_IMG_1.png" alt="Description" loading="lazy">
</picture>

<!--
Method 2: Using CSS
Add this to your CSS file:
-->
.webp-bg {
    background-image: url('/images/iBridge_IMG_1.png');
}

.webp .webp-bg {
    background-image: url('/images/webp/iBridge_IMG_1.webp');
}

<!--
Then add this JavaScript to detect WebP support:
-->
<script>
    // Check for WebP support
    function checkWebpSupport() {
        var img = new Image();
        img.onload = function() {
            document.documentElement.classList.add('webp');
        };
        img.onerror = function() {
            document.documentElement.classList.add('no-webp');
        };
        img.src = 'data:image/webp;base64,UklGRiQAAABXRUJQVlA4IBgAAAAwAQCdASoBAAEAAgA0JaQAA3AA/vv9UAA=';
    }
    
    // Run the check
    checkWebpSupport();
</script>
"@

    $helperContent | Out-File -FilePath "./webp-usage-guide.html" -Encoding utf8
    Write-Host "Created WebP usage guide: webp-usage-guide.html" -ForegroundColor Green
}

# Main execution
Write-Host "Starting image optimization for iBridge website..." -ForegroundColor Cyan
Check-Dependencies

if ($useNodePackages) {
    Setup-NodePackages
    Optimize-With-Node
} elseif ($useImageMagick) {
    Optimize-Images-With-ImageMagick
} else {
    Write-Host "No optimization tools available. Please install ImageMagick or Node.js." -ForegroundColor Red
}

Create-HTML-Helper
Write-Host "Image optimization process complete!" -ForegroundColor Green
