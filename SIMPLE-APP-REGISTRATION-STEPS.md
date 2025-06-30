# Manual iBridge Portal Registration Steps

## If you're seeing the "Need admin approval" message, follow these steps:

### Option 1: Register the app manually in Microsoft Entra

1. Go to [https://entra.microsoft.com](https://entra.microsoft.com)
2. Click on "App registrations" in the left menu
3. Click "New registration"
4. Fill in the details:
   - Name: iBridge Portal
   - Account type: Accounts in this organizational directory only
   - Redirect URI: Web - http://localhost:8090/intranet/login.html
5. Click "Register"
6. Note the Application (client) ID and Directory (tenant) ID
7. Update your login.html with these IDs

### Option 2: Login with admin account and grant permissions

If you see the "Need admin approval" screen:

1. Click "Have an admin account? Sign in with that account"
2. Login with your admin account
3. On the consent page, check all the permissions
4. Click "Accept"

### Option 3: Try Azure CLI registration

1. Install Azure CLI from [https://aka.ms/installazurecliwindows](https://aka.ms/installazurecliwindows)
2. Open PowerShell and run:
   ```powershell
   .\register-app-with-cli.ps1
   ```
3. Follow the login prompts
4. Azure CLI often has fewer permission issues

### Option 4: Simplest approach - Use Application Registration Portal

1. Go to [https://apps.dev.microsoft.com](https://apps.dev.microsoft.com)
2. Sign in with your Microsoft 365 admin account
3. Click "New registration"
4. Name the application "iBridge Portal"
5. Under "Platform configurations", add these redirect URIs:
   ```
   http://localhost:8090/intranet/login.html
   http://localhost:8090/intranet/
   http://localhost:8090/intranet/index.html
   http://localhost:8090/login.html
   ```
6. Enable implicit grant
7. Add Microsoft Graph User.Read permission
8. Save your changes and note the Application ID

## After App Registration

1. Update login.html with your new client ID and tenant ID
2. Start local server: `.\intranet\serve-intranet.ps1`
3. Test login at http://localhost:8090/intranet/login.html
