# Fix for Redirect URI Errors in Azure AD Authentication

This guide will help you resolve redirect URI errors (AADSTS500113 or AADSTS50011) that appear during Microsoft authentication.

## Problem

The error occurs because the redirect URI in your application code doesn't match any of the authorized redirect URIs registered in your Azure AD application. 

**Current error message:**
```
AADSTS50011: The redirect URI 'http://localhost:8090/login.html' specified in the request does not match the redirect URIs configured for the application
```

This indicates the application is trying to use `http://localhost:8090/login.html` as the redirect URI, but this exact URI is not registered in the Azure portal.

## Step-by-Step Solution

1. **Sign in to Azure Portal**
   - Go to [https://portal.azure.com](https://portal.azure.com)
   - Sign in with the account that has admin access to your Azure AD

2. **Navigate to App Registration**
   - Click on **Azure Active Directory** in the left sidebar
   - Select **App registrations**
   - Search for "iBridge Portal" or use the client ID: `2f833c55-f976-4d6c-ad96-fa357119f0ee`
   - Click on the app when you find it

3. **Update Authentication Settings**
   - Click on **Authentication** in the left sidebar of your app registration
   - Under **Platform configurations**, you should see "Web" - click on it
     - If you don't see it, click **Add a platform** and select **Web**

4. **Add Redirect URIs**
   - In the **Redirect URIs** section, add these exact URIs:
     - `http://localhost:8090/intranet/login.html`
     - `http://localhost:8090/login.html` (this is the one causing the current error)
     - `http://localhost:8090/intranet/`
     - `http://localhost:8090/intranet/index.html`
   
   - If you're accessing the site using a different URL, also add that exact URL
   - **IMPORTANT**: The URIs must match EXACTLY what's in the error message

5. **Configure Token Settings**
   - Ensure **Access tokens** and **ID tokens** are checked under "Implicit grant and hybrid flows" section
   - If they aren't checked, check both boxes

6. **Save Changes**
   - Click the **Save** button at the top

7. **Wait for Changes to Apply**
   - Changes to authentication settings can take up to 15 minutes to fully propagate in Azure AD
   - You can try authentication again after a few minutes

8. **Test the Authentication**
   - Return to your application and try signing in again
   - You should no longer see the "No reply address is registered" error

## Debugging Information

If you continue to experience issues, check the browser console (F12) for more details. Look for these specific logs:
- "Using exact redirect URI:" - This shows what your code is sending
- "Login request configuration:" - This shows the full authentication request

## Need More Help?

If you continue to experience issues, please:

1. Take a screenshot of your Azure AD application's Authentication settings
2. Note the exact URL you're using to access the application
3. Check the browser console logs for any errors
4. Contact your Azure administrator or IT support for assistance

Remember: The redirect URI must match **exactly** - including http/https, domain, path, and case sensitivity.
