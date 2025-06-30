#!/usr/bin/env pwsh
# Azure AD Authentication Diagnostic Script for iBridge Intranet

function Write-ColorOutput {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ConsoleColor]$ForegroundColor = [ConsoleColor]::White
    )
    
    $originalColor = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    Write-Output $Message
    $host.UI.RawUI.ForegroundColor = $originalColor
}

function Test-RedirectUri {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Uri
    )
    
    try {
        $response = Invoke-WebRequest -Uri $Uri -Method Head -UseBasicParsing -ErrorAction SilentlyContinue
        return $true
    }
    catch {
        return $false
    }
}

# Header
Write-ColorOutput "====================================" -ForegroundColor Cyan
Write-ColorOutput "   iBridge Azure AD Authentication   " -ForegroundColor Cyan
Write-ColorOutput "           Diagnostic Tool           " -ForegroundColor Cyan
Write-ColorOutput "====================================" -ForegroundColor Cyan
Write-ColorOutput ""

# Check if running in admin mode
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
Write-ColorOutput "Running as administrator: $isAdmin" -ForegroundColor ($isAdmin ? 'Green' : 'Yellow')
Write-ColorOutput ""

# Get Azure AD application details
$clientId = "2f833c55-f976-4d6c-ad96-fa357119f0ee"
$tenantId = "feeb9a78-4032-4b89-ae79-2100a5dc16a8"
$appName = "iBridge Portal"

Write-ColorOutput "Azure AD Application Details:" -ForegroundColor Green
Write-ColorOutput "- Name: $appName"
Write-ColorOutput "- Client ID: $clientId"
Write-ColorOutput "- Tenant ID: $tenantId"
Write-ColorOutput ""

# Check if application exists in Azure AD
Write-ColorOutput "Checking Azure AD application..." -ForegroundColor Yellow
Write-ColorOutput "NOTE: This script cannot check the Azure AD directory without connecting to Azure." -ForegroundColor Yellow
Write-ColorOutput "To check if the application is registered properly:" -ForegroundColor Yellow
Write-ColorOutput "1. Open https://portal.azure.com" -ForegroundColor White
Write-ColorOutput "2. Navigate to Azure Active Directory > App registrations" -ForegroundColor White
Write-ColorOutput "3. Search for 'iBridge Portal' or the client ID: $clientId" -ForegroundColor White
Write-ColorOutput "4. Ensure it exists and is properly configured" -ForegroundColor White
Write-ColorOutput ""

# Check redirect URIs
Write-ColorOutput "Checking redirect URIs..." -ForegroundColor Yellow
$baseUrl = "http://localhost:8090"
$redirectUris = @(
    "$baseUrl/intranet/login.html",
    "$baseUrl/intranet/",
    "$baseUrl/intranet/index.html",
    "$baseUrl/login.html"
)

Write-ColorOutput "The following redirect URIs should be registered in Azure AD:" -ForegroundColor White
foreach ($uri in $redirectUris) {
    $accessible = Test-RedirectUri -Uri $uri
    $color = if ($accessible) { 'Green' } else { 'Red' }
    $status = if ($accessible) { "REACHABLE" } else { "NOT REACHABLE" }
    Write-ColorOutput "- $uri [$status]" -ForegroundColor $color
}
Write-ColorOutput ""

# Check for the login.html file
$loginHtmlPath = Join-Path (Get-Location) "intranet\login.html"
if (Test-Path $loginHtmlPath) {
    Write-ColorOutput "Found login.html file." -ForegroundColor Green
    
    # Check if clientId matches
    $loginHtmlContent = Get-Content $loginHtmlPath -Raw
    if ($loginHtmlContent -match "clientId: `"$clientId`"") {
        Write-ColorOutput "- Client ID in login.html matches the expected value." -ForegroundColor Green
    } else {
        Write-ColorOutput "- CLIENT ID MISMATCH! Please verify the client ID in login.html." -ForegroundColor Red
    }
    
    # Check if tenantId matches
    if ($loginHtmlContent -match "authority: `"https://login\.microsoftonline\.com/$tenantId`"") {
        Write-ColorOutput "- Tenant ID in login.html matches the expected value." -ForegroundColor Green
    } else {
        Write-ColorOutput "- TENANT ID MISMATCH! Please verify the authority URL in login.html." -ForegroundColor Red
    }
    
    # Check redirectUri configuration
    if ($loginHtmlContent -match "const redirectUri = window\.location\.origin \+ `"/intranet/login\.html`"") {
        Write-ColorOutput "- Redirect URI configuration appears correct." -ForegroundColor Green
    } else {
        Write-ColorOutput "- REDIRECT URI CONFIGURATION ISSUE! Please verify the redirectUri setting in login.html." -ForegroundColor Red
    }
} else {
    Write-ColorOutput "Could not find login.html file at $loginHtmlPath" -ForegroundColor Red
}
Write-ColorOutput ""

# Check for debug tools
$debugTools = @(
    "intranet\session-debug.html",
    "intranet\auth-fixer.html",
    "intranet\redirect-test.html",
    "intranet\path-test.html"
)

Write-ColorOutput "Checking for diagnostic tools..." -ForegroundColor Yellow
foreach ($tool in $debugTools) {
    $toolPath = Join-Path (Get-Location) $tool
    if (Test-Path $toolPath) {
        Write-ColorOutput "- Found $tool" -ForegroundColor Green
    } else {
        Write-ColorOutput "- Missing $tool" -ForegroundColor Red
    }
}
Write-ColorOutput ""

# Check for intranet.js file
$intranetJsPath = Join-Path (Get-Location) "intranet\js\intranet.js"
if (Test-Path $intranetJsPath) {
    Write-ColorOutput "Found intranet.js file." -ForegroundColor Green
    
    # Check authentication function
    $intranetJsContent = Get-Content $intranetJsPath -Raw
    if ($intranetJsContent -match "function checkAuthentication\(\)") {
        Write-ColorOutput "- Authentication check function found in intranet.js." -ForegroundColor Green
    } else {
        Write-ColorOutput "- MISSING AUTHENTICATION FUNCTION! Please verify intranet.js." -ForegroundColor Red
    }
    
    # Check logout function
    if ($intranetJsContent -match "window\.logout = function\(\)") {
        Write-ColorOutput "- Logout function found in intranet.js." -ForegroundColor Green
    } else {
        Write-ColorOutput "- MISSING LOGOUT FUNCTION! Please verify intranet.js." -ForegroundColor Red
    }
} else {
    Write-ColorOutput "Could not find intranet.js file at $intranetJsPath" -ForegroundColor Red
}
Write-ColorOutput ""

# Start diagnostic server
Write-ColorOutput "Starting diagnostic server..." -ForegroundColor Yellow
Write-ColorOutput "To test authentication, you can run: .\serve-intranet.ps1" -ForegroundColor White
Write-ColorOutput "This will start a local server at $baseUrl" -ForegroundColor White
Write-ColorOutput ""

# Show next steps
Write-ColorOutput "Next Steps:" -ForegroundColor Green
Write-ColorOutput "1. Make sure all redirect URIs are registered in Azure AD" -ForegroundColor White
Write-ColorOutput "2. Start the intranet server using .\serve-intranet.ps1" -ForegroundColor White
Write-ColorOutput "3. Navigate to $baseUrl/intranet/login.html" -ForegroundColor White
Write-ColorOutput "4. Test signing in with Microsoft 365" -ForegroundColor White
Write-ColorOutput "5. If you encounter any errors, use the diagnostic tools:" -ForegroundColor White
Write-ColorOutput "   - $baseUrl/intranet/session-debug.html" -ForegroundColor White
Write-ColorOutput "   - $baseUrl/intranet/auth-fixer.html" -ForegroundColor White
Write-ColorOutput ""

Write-ColorOutput "For detailed authentication steps, see:" -ForegroundColor Cyan
Write-ColorOutput "intranet\AZURE_AUTH_CHECKLIST.md" -ForegroundColor White
Write-ColorOutput ""
