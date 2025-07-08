# Azure AD Redirect URI Troubleshooting

This guide will help you fix the Azure AD redirect URI issues with the iBridge website on GitHub Pages.

## Problem

When trying to log into the intranet portal on GitHub Pages, you may encounter an error like:

```text
AADSTS50011: The redirect URI 'https://ibridgesolutions.github.io/intranet/login.html' specified in the request does not match the redirect URIs configured for the application.
```

This happens because GitHub Pages project sites are hosted under a repository path (e.g., `/iBridge/`) but the Azure AD application is configured with a redirect URI that doesn't include this path.

## Solution

### Option 1: Use the PowerShell Script (Recommended)

1. Open PowerShell as an administrator
2. Navigate to the folder containing the scripts
3. Run the verification script first to check current configuration:

   ```powershell
   .\check-azure-redirect-uris.ps1
   ```

4. If needed, run the update script to add the correct redirect URI:

   ```powershell
   .\update-azure-redirect-uri.ps1
   ```
5. Wait for Azure AD changes to propagate (may take a few minutes)
6. Clear your browser cache or use an incognito/private window
7. Try logging in again at: [https://ibridgesolutions.github.io/iBridge/intranet/login.html](https://ibridgesolutions.github.io/iBridge/intranet/login.html)

### Option 2: Manual Update in Azure Portal

1. Sign in to the [Azure Portal](https://portal.azure.com)
2. Navigate to **Azure Active Directory** → **App registrations**
3. Select your application (ID: `6686c610-81cf-4ed7-8241-a91a20f01b06`)
4. Click on **Authentication** in the left menu
5. Under **Redirect URIs**, add the following URL:

   ```text
   https://ibridgesolutions.github.io/iBridge/intranet/login.html
   ```
   
6. Click **Save** at the top of the page
7. Clear your browser cache or use an incognito/private window
8. Try logging in again

### Option 3: Use the Redirect URI Checker Tool

For visual verification and additional troubleshooting:

1. Open the redirect URI checker tool in your browser:
   - Local: [http://localhost:8090/intranet/redirect-uri-checker.html](http://localhost:8090/intranet/redirect-uri-checker.html)
   - GitHub Pages: [https://ibridgesolutions.github.io/iBridge/intranet/redirect-uri-checker.html](https://ibridgesolutions.github.io/iBridge/intranet/redirect-uri-checker.html)
2. The tool will analyze your environment and show the correct redirect URI to configure
3. Follow the instructions on the page to update your Azure AD application

## Verifying the Fix

After updating the redirect URI:

1. Clear your browser cache or use an incognito/private window
2. Go to [https://ibridgesolutions.github.io/iBridge/intranet/login.html](https://ibridgesolutions.github.io/iBridge/intranet/login.html)
3. Click "Sign in with Microsoft 365"
4. You should now be able to authenticate without the redirect URI error

## Still Having Issues?

If you're still experiencing problems:

1. Check browser console for any JavaScript errors
2. Verify the Azure AD application has the exact correct redirect URI (including correct casing)
3. Make sure your user account has access to the Azure AD application
4. Try different browsers or devices
5. Check if there are any pending changes that need to be pushed to GitHub
