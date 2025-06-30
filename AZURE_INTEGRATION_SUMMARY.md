# iBridge Intranet - Azure AD Integration Setup

## Actions Completed

1. Created comprehensive Azure AD integration documentation:
   - AZURE_AUTH_CHECKLIST.md - Step-by-step guide for Azure AD configuration
   - diagnose-auth.ps1 - PowerShell diagnostic tool for Azure AD integration

2. Enhanced debugging tools:
   - auth-fixer-azure.html - Azure-specific authentication debugging tool
   - Added Azure AD configuration checks and utilities

3. Updated STATUS_AND_NEXT_STEPS.md:
   - Added specific Azure AD integration section
   - Provided detailed steps for production deployment with Azure AD

4. Verified current Azure AD configuration:
   - Confirmed client ID (6686c610-81cf-4ed7-8241-a91a20f01b06) 
   - Confirmed tenant ID (feeb9a78-4032-4b89-ae79-2100a5dc16a8)
   - Checked redirect URI configuration in login.html

## Next Steps to Complete Azure AD Integration

1. **Sign in to Azure Portal**
   - Go to [https://portal.azure.com](https://portal.azure.com)
   - Sign in with your administrator account

2. **Navigate to App Registration**
   - Click on **Azure Active Directory** in the left sidebar
   - Select **App registrations**
   - Search for "iBridge Portal" or use the client ID: `6686c610-81cf-4ed7-8241-a91a20f01b06`
   - Click on the app name to view its details

3. **Update Authentication Settings**
   - Click on **Authentication** in the left menu
   - Under **Platform configurations**, make sure you have "Web" configured
   - Add these redirect URIs if they're not already present:
     ```
     http://localhost:8090/intranet/login.html
     http://localhost:8090/intranet/
     http://localhost:8090/intranet/index.html
     http://localhost:8090/login.html
     ```
   - If you're accessing through a different URL, add those URLs as well
   - Under "Implicit grant and hybrid flows", make sure both "Access tokens" and "ID tokens" are checked
   - Click "Save" after making changes

4. **Test the Authentication Flow**
   - Run the intranet server:
     ```
     cd to\your\intranet\directory
     .\serve-intranet.ps1
     ```
   - Navigate to http://localhost:8090/intranet/login.html
   - Click on "Sign in with Microsoft 365"
   - Sign in with your iBridge credentials
   - You should be redirected to the intranet homepage after successful login
   - Try navigating to other pages within the intranet to ensure session persistence

5. **Use the Diagnostic Tools If Needed**
   - If you encounter any issues:
     - Check browser console (F12) for error messages
     - Use auth-fixer-azure.html to diagnose Azure AD specific issues
     - Run diagnose-auth.ps1 for comprehensive configuration checks
     - Check for specific error codes in the Microsoft authentication errors
     - Reference the AZURE_AUTH_CHECKLIST.md for troubleshooting steps

Remember that changes in Azure can take up to 15 minutes to fully propagate. If you make changes to your redirect URIs or other settings in the Azure portal, you may need to wait a bit before testing again.

For additional assistance or questions, refer to the Azure AD documentation or contact your Azure administrator.
