# iBridge Intranet Azure AD Integration Checklist

This guide will help you finalize the Microsoft 365 login integration for the iBridge intranet portal. Follow these steps to ensure proper authentication and session management.

## 1. Verify Azure AD Application Configuration

1. **Sign in to Azure Portal**: [https://portal.azure.com](https://portal.azure.com)

2. **Navigate to App Registration**:
   - Search for "Azure Active Directory" in the top search bar and click on it
   - Select "App registrations" from the left menu
   - Find "iBridge Portal" in the list (Client ID: `2f833c55-f976-4d6c-ad96-fa357119f0ee`)
   - Click on the app name to view its details

3. **Verify Application Details**:
   - Confirm the Client ID matches: `2f833c55-f976-4d6c-ad96-fa357119f0ee`
   - Confirm the Directory (tenant) ID matches: `feeb9a78-4032-4b89-ae79-2100a5dc16a8`

4. **Check Authentication Settings**:
   - Click on "Authentication" in the left menu
   - Under "Platform configurations", make sure you have "Web" configured
   - Ensure the following redirect URIs are registered:
     ```
     http://localhost:8090/intranet/login.html
     http://localhost:8090/intranet/
     http://localhost:8090/intranet/index.html
     http://localhost:8090/login.html
     ```
   - If you're accessing through a different URL or domain, add those URLs as well
   - Under "Implicit grant and hybrid flows", make sure both "Access tokens" and "ID tokens" are checked
   - Click "Save" if you made any changes

5. **Confirm API Permissions**:
   - Click on "API permissions" in the left menu
   - Ensure you have at least `User.Read` permission from Microsoft Graph
   - Look for "Microsoft Graph" with the permission "User.Read"
   - Check if the permission status shows as "Granted for..."
   - If not, click "Grant admin consent for [Your Organization]" at the top
   
6. **Handle "Need admin approval" Error**:
   - If you see a "Need admin approval" message when trying to log in, this means admin consent hasn't been granted
   - To fix this, an admin must:
      - Sign in to the [Azure portal](https://portal.azure.com)
      - Go to Azure Active Directory → App registrations → iBridge Portal
      - Select "API permissions" from the left menu
      - Click "Grant admin consent for [Your Organization]" button at the top
   - Alternatively, access the [Microsoft 365 Admin Center](https://admin.microsoft.com/)
      - Navigate to "Settings" → "Integrated apps"
      - Find the "iBridge Portal" app and approve it
      - If you don't see it, use "Add an app" and enter the application ID

## 2. Update Client Configuration in Your Code

Your login.html file already has the correct configuration, but verify these settings:

1. **Check clientId and tenantId**:
   ```javascript
   const msalConfig = {
       auth: {
           clientId: "2f833c55-f976-4d6c-ad96-fa357119f0ee",
           authority: "https://login.microsoftonline.com/feeb9a78-4032-4b89-ae79-2100a5dc16a8",
           redirectUri: redirectUri,
           navigateToLoginRequestUrl: false
       },
       cache: {
           cacheLocation: "localStorage",
           storeAuthStateInCookie: true
       }
   };
   ```

2. **Ensure redirectUri is set correctly**:
   ```javascript
   const redirectUri = window.location.origin + "/intranet/login.html";
   ```

## 3. Testing Authentication Flow

1. **Clear All Browser Data**:
   - Open your browser's settings
   - Clear cookies, cache, and local storage
   - Close and reopen your browser

2. **Start the Dev Server**:
   ```powershell
   # From the root directory
   .\serve-intranet.ps1
   ```

3. **Test Authentication**:
   - Navigate to `http://localhost:8090/intranet/login.html`
   - Click the "Sign in with Microsoft 365" button
   - You should be redirected to the Microsoft login page
   - Sign in with your iBridge credentials (e.g., lwandile.gasela@ibridge.co.za)
   - After successful login, you should be redirected to the iBridge intranet homepage
   - The session should persist - try navigating to other pages within the intranet

4. **Check for Login Issues**:
   - If you encounter an error at the Microsoft login page, note the error code
   - Common issues include:
     - AADSTS50011: Redirect URI mismatch (fix by adding the exact URI to Azure)
     - AADSTS700016: The application was not found in the tenant (check clientId)
     - AADSTS65001: Consent required (admin needs to grant permissions)

## 4. Debug Authentication Problems

If you experience authentication issues:

1. **Use the debug tools**:
   - Visit `http://localhost:8090/intranet/session-debug.html` to check session state
   - Check the browser console (F12) for error messages
   - Look for "Authentication error:" entries

2. **Check for Redirect URI Issues**:
   - Compare the redirect URI in your code with what's registered in Azure
   - They must match exactly (including http vs https, slashes, etc.)
   - Run `http://localhost:8090/intranet/auth-fixer.html` to help diagnose auth cookie issues

3. **Verify Session Handling**:
   - After login, check if sessionStorage.getItem('user') contains data
   - Verify that authentication cookies are set (user_authenticated and intranet_session)

## 5. Deploying to Production

When you're ready to deploy to a production environment:

1. **Add Production Redirect URIs to Azure**:
   - Add your production domain redirect URIs in the Azure portal
   - For example:
     ```
     https://yourcompanydomain.com/intranet/login.html
     https://yourcompanydomain.com/intranet/
     https://yourcompanydomain.com/intranet/index.html
     ```

2. **Test on Production Environment**:
   - Deploy your updates to the production server
   - Test the authentication flow in production
   - Verify that all paths and redirects work correctly

## 6. Additional Resources

- [Microsoft Authentication Library (MSAL) Documentation](https://docs.microsoft.com/en-us/azure/active-directory/develop/msal-overview)
- [Azure AD Single-page Application Tutorial](https://docs.microsoft.com/en-us/azure/active-directory/develop/tutorial-v2-javascript-spa)
- [Azure Portal](https://portal.azure.com)

## Getting Help

If you continue to experience issues after following this guide:

1. Take screenshots of any error messages
2. Note the exact URL you're using to access the application
3. Check the browser console logs
4. Document the steps you've taken
5. Contact your Azure administrator or IT support

Remember, authentication changes in Azure can take up to 15 minutes to fully propagate.
