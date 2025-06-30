# iBridge Azure Authentication Fix - SPA Configuration

## The Issue

The error you're seeing:

```text
Authentication error: invalid_request: 9002326 - AADSTS9002326: Cross-origin token redemption is permitted only for the 'Single-Page Application' client-type
```

This occurs because your app is registered as a "Web" application, but you're using MSAL.js in a browser context, which now requires the "Single-Page Application" (SPA) client type for security reasons.

## The Fix

### Update App Registration to SPA Type

1. Sign in to the Microsoft Entra admin center at [https://entra.microsoft.com](https://entra.microsoft.com)

2. Navigate to "App registrations" and select your "iBridge Portal" app

3. Go to "Authentication" in the left menu

4. Under "Platform configurations", you need to:
   - **Add a platform**: Click "+ Add a platform"
   - Select **Single-page application**
   - Enter these redirect URIs:
   
     ```text
     http://localhost:8090/intranet/login.html
     http://localhost:8090/intranet/
     http://localhost:8090/intranet/index.html
     http://localhost:8090/login.html
     ```
   
   - Click "Configure"

5. You can keep the "Web" platform configuration as well, but the SPA configuration is necessary for browser-based authentication

### Optional: Use the Admin Script

I've also created an update script that will help ensure your app is properly configured:

```powershell
# Run this from your project directory
.\update-app-to-spa.ps1
```

## Testing After Fix

After making these changes:

1. Restart your browser (to clear any cached auth tokens)
2. Navigate to `http://localhost:8090/intranet/auth-test.html` in an external browser
3. Try authenticating again

This should resolve the cross-origin token redemption error.

## Why This Happens

Microsoft has enhanced security for modern authentication flows:

- Web applications use auth code flow with PKCE for server-side apps
- Single-Page Applications (SPAs) use auth code flow with PKCE for client-side browser apps
- Implicit flow (what you were using) is being phased out due to security concerns

By registering your app as a SPA, you're telling Microsoft's auth services that your application is a browser-based JavaScript app that should use the appropriate security protocols.
