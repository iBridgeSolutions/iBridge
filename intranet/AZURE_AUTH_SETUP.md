# Setting Up Microsoft 365 Authentication for iBridge Intranet

This guide will help you configure Microsoft Azure Active Directory authentication for the iBridge intranet portal, allowing users to sign in with their iBridge email accounts.

## Application Registration Details

The iBridge Portal application has been registered in Azure AD with the following details:

- **Display name**: iBridge Portal
- **Application (client) ID**: 2f833c55-f976-4d6c-ad96-fa357119f0ee
- **Object ID**: 9c277eee-ffae-4ca4-ad55-54124879b9db
- **Directory (tenant) ID**: feeb9a78-4032-4b89-ae79-2100a5dc16a8
- **Supported account types**: Single tenant (My organization only)
- **Authentication type**: Web application

## Prerequisites

1. An Azure account with administrator access
2. Access to your Microsoft 365 tenant administration
3. The iBridge domain registered in Azure Active Directory

## Step 1: Application Registration in Azure AD

The application has already been registered with the name "iBridge Portal" and configured for single-tenant access. If you need to make changes:

1. Sign in to the [Azure Portal](https://portal.azure.com) with an administrator account
2. Navigate to **Azure Active Directory** > **App registrations** 
3. Search for "iBridge Portal" or use the client ID: `2f833c55-f976-4d6c-ad96-fa357119f0ee`
4. Select the application to view or edit its settings

> **Note**: For testing purposes, you can use the development mode login option that appears on the login page. This allows you to test the intranet functionality without setting up Azure AD integration.

## Step 2: Configure Authentication

1. In your app registration, navigate to **Authentication**
2. Under **Implicit grant and hybrid flows**, select:
   - Access tokens
   - ID tokens
3. Click **Save**

## Step 3: Configure API Permissions

1. Navigate to **API permissions**
2. Click **Add a permission**
3. Choose **Microsoft Graph** > **Delegated permissions**
4. Add the following permissions:
   - `User.Read` (to read the user's profile)
5. Click **Add permissions**
6. Click **Grant admin consent**

## Step 4: Update the Client ID in Your Application

1. In your app registration, copy the **Application (client) ID**
2. Open the file `intranet/login.html` in your website
3. Replace the client ID in the msalConfig object with your Application ID:

```javascript
const msalConfig = {
    auth: {
        clientId: "2f833c55-f976-4d6c-ad96-fa357119f0ee", // Your Azure AD Application (client) ID
        authority: "https://login.microsoftonline.com/feeb9a78-4032-4b89-ae79-2100a5dc16a8", // iBridge tenant ID
        redirectUri: window.location.origin + window.location.pathname.replace("login.html", ""),
    },
    // ...
};
```

4. The authority URL has been configured with your iBridge Contact Solutions tenant ID (feeb9a78-4032-4b89-ae79-2100a5dc16a8)

## Step 5: Configure Redirect URIs

The following redirect URIs MUST be configured for the application to prevent "No reply address is registered" errors:

1. For local development:
   - `http://localhost:8090/intranet/login.html`
   - `http://localhost:8090/intranet/`
   - `http://localhost:8090/intranet/index.html`

2. For production (update these with your actual domain):
   - `https://your-production-domain.com/intranet/login.html`
   - `https://your-production-domain.com/intranet/`
   - `https://your-production-domain.com/intranet/index.html`

To add these redirect URIs:

1. Sign in to the [Azure Portal](https://portal.azure.com/)
2. Go to **Azure Active Directory** > **App registrations**
3. Select the "iBridge Portal" application (or search by client ID: `2f833c55-f976-4d6c-ad96-fa357119f0ee`)
4. Click on **Authentication** in the left menu
5. Under **Platform configurations**, click **Add a platform** if Web isn't configured yet, otherwise click on the Web configuration
6. In the **Redirect URIs** section, add all the URIs listed above
7. Make sure **Access tokens** and **ID tokens** are checked under "Implicit grant and hybrid flows"
8. Click **Configure** (or **Save** if you're editing an existing configuration)
9. After saving, verify all URIs appear in your list

**IMPORTANT**: 
- The error "AADSTS500113: No reply address is registered for the application" means the redirect URI in your code doesn't match any of the URIs registered in Azure AD
- The redirect URI must match EXACTLY (including protocol, domain, path, and case sensitivity)
- After updating URIs in Azure, it may take up to 15 minutes for changes to propagate

## Step 6: Test Authentication

1. Run the intranet site locally using `serve-intranet.ps1`
2. Navigate to `http://localhost:8080/login.html`
3. Try to sign in with your Microsoft 365 account
4. Check the developer console for any errors

## Configuring Admin Access

The intranet is currently configured to recognize `lwandile.gasela@ibridge.co.za` as an administrator.

To add additional administrators:

1. Open the file `intranet/login.html`
2. Find the `adminUsers` array:

```javascript
const adminUsers = [
    "lwandile.gasela@ibridge.co.za"
];
```

3. Add additional email addresses to this array:

```javascript
const adminUsers = [
    "lwandile.gasela@ibridge.co.za",
    "another.admin@ibridge.co.za",
    "third.admin@ibridge.co.za"
];
```

## Security Considerations

- For production deployment, consider enabling Conditional Access policies in Azure AD
- Review app permissions regularly
- Configure proper HTTPS for your intranet site in production
- Set up audit logs for authentication activities

## Troubleshooting

If you encounter authentication issues:

1. Check the browser console for error messages
2. Verify the client ID is correct
3. Confirm redirect URIs are properly configured
4. Make sure the user has appropriate permissions
5. Check that your domain is properly configured in Azure AD

### Common Authentication Errors

#### Interaction in Progress Error

If you see the error "interaction_in_progress: Interaction is currently in progress":

1. This typically happens when there's already an authentication flow happening
2. Try clearing your browser cache and cookies
3. Close any other tabs that may be attempting authentication
4. Try using private/incognito mode for testing
5. You can also try the development login option to access the intranet while troubleshooting
