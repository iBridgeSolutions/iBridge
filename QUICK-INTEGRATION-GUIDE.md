# Quick Guide: Integrating iBridge Intranet with Microsoft 365

This guide provides simplified steps to manually register your iBridge Portal app in Microsoft Entra ID through the Microsoft 365 admin center.

## Step 1: Access Microsoft Entra from Microsoft 365 Admin Center

1. Navigate to [Microsoft 365 admin center](https://admin.microsoft.com/)
2. Sign in with your Microsoft 365 admin account
3. From the left navigation, expand **All admin centers**
4. Click on **Identity (Entra ID)** - this will take you to the Microsoft Entra admin center

## Step 2: Register the iBridge Portal App

1. In the Microsoft Entra admin center, navigate to **App registrations** (you may need to look in the Azure Active Directory menu)
2. Click **+ New registration**
3. Enter the following information:
   - **Name**: iBridge Portal
   - **Supported account types**: Accounts in this organizational directory only
   - **Redirect URI**: Web → `http://localhost:8090/intranet/login.html`
4. Click **Register**

## Step 3: Configure the App Registration

After registration, you'll be taken to the app's overview page:

1. **Copy these values** as you'll need them later:
   - Application (client) ID
   - Directory (tenant) ID

2. **Add additional redirect URIs**:
   - In the left menu, click on **Authentication**
   - Under the "Web" platform, add these additional redirect URIs:
     - `http://localhost:8090/intranet/`
     - `http://localhost:8090/intranet/index.html`
     - `http://localhost:8090/login.html`
   - Check the boxes for **ID tokens** and **Access tokens** under Implicit grant
   - Click **Save**

3. **Add API permissions**:
   - In the left menu, click on **API permissions**
   - Click **+ Add a permission**
   - Select **Microsoft Graph**
   - Select **Delegated permissions**
   - Search for and select **User.Read**
   - Click **Add permissions**
   - Click **Grant admin consent for [Your Org]** and confirm

## Step 4: Update the login.html File

1. Open the file: `intranet\login.html` in your editor
2. Find the MSAL configuration section (around line 290)
3. Update these values:
   - **clientId**: Replace with your Application (client) ID
   - **authority**: Replace the tenant ID portion with your Directory (tenant) ID
4. Also update the clientId variable defined later in the code (around line 357)

Before:

```javascript
const msalConfig = {
    auth: {
        clientId: "2f833c55-f976-4d6c-ad96-fa357119f0ee", 
        authority: "https://login.microsoftonline.com/feeb9a78-4032-4b89-ae79-2100a5dc16a8",
        redirectUri: redirectUri,
        navigateToLoginRequestUrl: false
    },
    // ...
};
```

After (with your IDs):

```javascript
const msalConfig = {
    auth: {
        clientId: "your-application-client-id", 
        authority: "https://login.microsoftonline.com/your-directory-tenant-id",
        redirectUri: redirectUri,
        navigateToLoginRequestUrl: false
    },
    // ...
};
```

## Step 5: Test the Integration

1. Start your intranet server:

   ```powershell
   .\intranet\serve-intranet.ps1
   ```

2. Open your browser and navigate to:

   ```text
   http://localhost:8090/intranet/login.html
   ```

3. Click "Sign in with Microsoft 365"
4. You should be redirected to the Microsoft login page
5. After signing in, you should be redirected back to the intranet

## Troubleshooting

If you encounter issues:

1. **"Need admin approval"** error
   - Make sure you completed the "Grant admin consent" step
   - Try accessing the admin consent URL directly:

     ```text
     https://login.microsoftonline.com/YOUR-TENANT-ID/adminconsent?client_id=YOUR-CLIENT-ID
     ```

2. **Redirect issues**
   - Make sure all redirect URIs are registered exactly as shown
   - Check for any typos in your config

3. **For more detailed diagnostics**:
   - Use the diagnostic tools:

     ```text
     http://localhost:8090/intranet/auth-fixer-azure.html
     http://localhost:8090/intranet/session-debug.html
     ```

Need more help? Refer to the detailed documentation in AZURE_INTEGRATION_SUMMARY.md or ENTRA_INTEGRATION_STEPS.md
