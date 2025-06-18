# Fix for www.ibridgesolutions.co.za DNS Configuration

This guide helps you fix the error: `www.ibridgesolutions.co.za is improperly configured`

## The Problem

Your website's DNS settings for the `www` subdomain (www.ibridgesolutions.co.za) are not correctly configured. 
The CNAME record needs to point to `blxckukno.github.io` (based on your GitHub username).

## Step-by-Step Fix

### 1. Log in to Your Domain Registrar

Log in to the control panel where you manage ibridgesolutions.co.za (GoDaddy, Namecheap, etc.)

### 2. Navigate to DNS Settings

Find the DNS management section for ibridgesolutions.co.za.

### 3. Update the CNAME Record for www

1. Find the existing CNAME record for `www`
2. **Delete** or edit the existing record
3. Create a new CNAME record with these values:
   - **Type:** CNAME
   - **Host/Name:** www
   - **Value/Points to:** blxckukno.github.io
   - **TTL:** 1 Hour (or Automatic/Default)

### 4. Save Your Changes

Click Save or Apply to save your changes.

### 5. Wait for DNS Propagation

DNS changes can take 24-48 hours to fully propagate. Wait at least a few hours before checking.

### 6. Verify the Changes

You can verify your DNS changes have propagated using the check-dns-propagation.ps1 script:

```powershell
cd "c:\Users\Lwandile Gasela\Downloads\iBridge-main"
.\check-dns-propagation.ps1
```

### 7. Clear Your DNS Cache

Clear your local DNS cache to ensure you're seeing the updated DNS records:

```powershell
ipconfig /flushdns
```

### 8. Test the www Subdomain

Once DNS propagation is complete, test the www subdomain:

```powershell
cd "c:\Users\Lwandile Gasela\Downloads\iBridge-main"
.\test-custom-domain.ps1
```

You should also be able to visit https://www.ibridgesolutions.co.za directly in your browser.

## Additional Resources

- Use online tools to check DNS propagation:
  - [whatsmydns.net](https://www.whatsmydns.net/#CNAME/www.ibridgesolutions.co.za)
  - [dnschecker.org](https://dnschecker.org/dns-check.php?query=www.ibridgesolutions.co.za&rtype=CNAME)

- Test your domain with GitHub's troubleshooting tool:
  - Go to your repository → Settings → Pages
  - Look for any error messages under the Custom domain section
