# PowerShell script to update all HTML files with standardized components

# Function to get the standardized head section
function Get-StandardHead {
    param (
        [string]$title,
        [string]$description
    )
    
    return @"
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="$description">
    <title>$title</title>
    
    <!-- Font Awesome -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    
    <!-- Google Fonts -->
    <link href="https://fonts.googleapis.com/css2?family=Montserrat:wght@400;500;600;700&family=Playfair+Display:wght@400;700&display=swap" rel="stylesheet">
    
    <!-- Favicon -->
    <link rel="icon" href="images/iBridge_Logo-removebg-preview.png" type="image/png">
    <link rel="apple-touch-icon" href="images/iBridge_Logo-removebg-preview.png">
    
    <!-- CSS Links -->
    <link rel="stylesheet" href="css/styles.css">
    <link rel="stylesheet" href="css/style-enhancements.css">
    <link rel="stylesheet" href="css/components.css">
    <link rel="stylesheet" href="css/theme.css">
    <link rel="stylesheet" href="css/animations.css">
"@
}

# Function to get the standardized header
function Get-StandardHeader {
    return @"
    <header class="enhanced-header">
        <div class="header-container">
            <div class="logo-container">
                <a href="index.html" aria-label="iBridge Home">
                    <img src="images/iBridge_Logo-removebg-preview.png" alt="iBridge Logo" class="fade-in">
                </a>
            </div>
            <nav class="enhanced-nav">
                <button class="mobile-menu-toggle" aria-label="Toggle menu" aria-expanded="false">
                    <i class="fas fa-bars"></i>
                </button>
                <ul class="nav-links stagger-children">
                    <li><a href="index.html" class="nav-link">Home</a></li>
                    <li><a href="about.html" class="nav-link">About</a></li>
                    <li class="nav-dropdown">
                        <a href="services.html" class="nav-link">Services <i class="fas fa-chevron-down"></i></a>
                        <div class="dropdown-content">
                            <a href="contact-center.html" class="dropdown-link">Contact Centre</a>
                            <a href="it-support.html" class="dropdown-link">IT Support</a>
                            <a href="ai-automation.html" class="dropdown-link">AI & Automation</a>
                            <a href="client-interaction.html" class="dropdown-link">Client Interaction</a>
                        </div>
                    </li>
                    <li><a href="contact.html" class="nav-link">Contact</a></li>
                </ul>
                <div class="header-actions">
                    <div class="search-container">
                        <input type="search" class="search-input" placeholder="Search..." aria-label="Search">
                        <i class="fas fa-search search-icon"></i>
                    </div>
                    <button class="theme-toggle" aria-label="Toggle dark mode">
                        <i class="fas fa-moon"></i>
                    </button>
                    <a href="intranet/login.html" class="portal-btn" target="_blank">
                        <i class="fas fa-user-lock"></i>
                        <span>Portal Login</span>
                    </a>
                    <a href="tel:+27112387090" class="portal-btn call-btn">
                        <i class="fas fa-phone"></i>
                        <span>011 238 7090</span>
                    </a>
                </div>
            </nav>
        </div>
    </header>
"@
}

# Function to get the standardized footer
function Get-StandardFooter {
    return @"
    <footer class="footer">
        <div class="container">
            <div class="footer-grid">
                <div class="footer-col">
                    <div class="footer-logo">
                        <img src="images/iBridge_Logo-removebg-preview.png" alt="iBridge Logo" width="150" height="50">
                    </div>
                    <p>Leading provider of contact center solutions and business process outsourcing services in South Africa.</p>
                    <div class="social-links">
                        <a href="#" class="social-link" aria-label="Follow us on Facebook"><i class="fab fa-facebook-f"></i></a>
                        <a href="#" class="social-link" aria-label="Follow us on Twitter"><i class="fab fa-twitter"></i></a>
                        <a href="#" class="social-link" aria-label="Follow us on LinkedIn"><i class="fab fa-linkedin-in"></i></a>
                        <a href="#" class="social-link" aria-label="Follow us on Instagram"><i class="fab fa-instagram"></i></a>
                    </div>
                </div>

                <div class="footer-col">
                    <h4>Quick Links</h4>
                    <ul class="footer-links">
                        <li><a href="index.html">Home</a></li>
                        <li><a href="about.html">About Us</a></li>
                        <li><a href="services.html">Services</a></li>
                        <li><a href="contact.html">Contact</a></li>
                    </ul>
                </div>

                <div class="footer-col">
                    <h4>Our Services</h4>
                    <ul class="footer-links">
                        <li><a href="contact-center.html">Contact Center Solutions</a></li>
                        <li><a href="it-support.html">IT Support & Cloud Services</a></li>
                        <li><a href="ai-automation.html">AI & Automation</a></li>
                        <li><a href="client-interaction.html">Client Interaction</a></li>
                    </ul>
                </div>

                <div class="footer-col">
                    <h4>Contact Info</h4>
                    <ul class="footer-contact">
                        <li>
                            <i class="fas fa-map-marker-alt"></i>
                            332 Kent Ave, Ferndale, Randburg, 2194
                        </li>
                        <li>
                            <i class="fas fa-phone"></i>
                            <a href="tel:+27112387090">011 238 7090</a>
                        </li>
                        <li>
                            <i class="fas fa-envelope"></i>
                            <a href="mailto:info@ibridge.co.za">info@ibridge.co.za</a>
                        </li>
                    </ul>
                </div>
            </div>

            <div class="footer-bottom">
                <p>&copy; <span id="currentYear"></span> <span class="primary">iBridge</span> Contact Solutions. All rights reserved.</p>
                <ul class="footer-legal">
                    <li><a href="#">Privacy Policy</a></li>
                    <li><a href="#">Terms of Service</a></li>
                    <li><a href="#">Cookie Policy</a></li>
                </ul>
            </div>
        </div>
    </footer>

    <!-- Scripts -->
    <script src="js/components.js"></script>
    <script src="js/theme.js"></script>
    <script src="js/animations.js"></script>
"@
}

# Get all HTML files in the main website directory
$htmlFiles = Get-ChildItem -Path "." -Filter "*.html" -Recurse | Where-Object { $_.DirectoryName -notlike "*\intranet*" }

foreach ($file in $htmlFiles) {
    Write-Host "Processing $($file.Name)..."
    
    # Read the file content
    $content = Get-Content -Path $file.FullName -Raw
    
    # Skip files that don't need updating
    if ($content -like "*enhanced-header*") {
        Write-Host "Skipping $($file.Name) - already updated"
        continue
    }
    
    # Extract title and description
    if ($content -match '<title>(.*?)</title>') {
        $title = $matches[1]
    } else {
        $title = "iBridge | Strategic Partner in BPO & BPaaS Solutions"
    }
    
    if ($content -match '<meta name="description" content="(.*?)"') {
        $description = $matches[1]
    } else {
        $description = "Comprehensive BPO & BPaaS solutions including contact center services, IT support, and AI-driven automation for businesses in South Africa."
    }
    
    # Update head section
    $newHead = Get-StandardHead -title $title -description $description
    $content = $content -replace '(?s)(<head>)(.*?)(</head>)', "`$1`n    $newHead`n</head>"
    
    # Update header
    $newHeader = Get-StandardHeader
    if ($content -match '(?s)<header.*?</header>') {
        $content = $content -replace '(?s)<header.*?</header>', $newHeader
    }
    
    # Update footer
    $newFooter = Get-StandardFooter
    if ($content -match '(?s)<footer.*?</footer>') {
        $content = $content -replace '(?s)<footer.*?</footer>.*?</body>', "$newFooter`n</body>"
    } else {
        $content = $content -replace '</body>', "$newFooter`n</body>"
    }
    
    # Save the updated content
    $content | Set-Content -Path $file.FullName -Force
    Write-Host "Updated $($file.Name)"
}

Write-Host "Finished updating all HTML files"
