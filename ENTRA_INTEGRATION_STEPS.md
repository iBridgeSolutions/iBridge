# Microsoft Entra ID Integration Steps (For iBridge Portal)

## STEP 1: Access Microsoft Entra Admin Center

1. From the Microsoft 365 admin center (where you are now)
2. Click on **Microsoft Entra** in the admin centers list (the blue key icon)
3. This will open the Microsoft Entra admin center (formerly Azure AD)

## STEP 2: Register Your Application

1. In the Microsoft Entra admin center:
2. Click on **App registrations** in the left menu
3. Click **+ New registration** at the top
4. Complete the registration form:
   - **Name:** iBridge Portal
   - **Supported account types:** Accounts in this organizational directory only
   - **Redirect URI:** Web - http://localhost:8090/intranet/login.html
5. Click **Register**

## STEP 3: Configure Authentication

1. In your newly registered app:
2. Click on **Authentication** in the left menu
3. Under **Platform configurations**, you'll see the Web platform you added
4. Click **Add URI** and add these additional URIs (one at a time):
   ```
   http://localhost:8090/intranet/
   http://localhost:8090/intranet/index.html
   http://localhost:8090/login.html
   ```
5. Under **Implicit grant and hybrid flows**, check both:
   - ✓ Access tokens
   - ✓ ID tokens
6. Click **Save** at the top

## STEP 4: Add API Permissions

1. Click on **API permissions** in the left menu
2. Click **+ Add a permission**
3. Select **Microsoft Graph**
4. Select **Delegated permissions**
5. Search for and select **User.Read**
6. Click **Add permissions**
7. Click **Grant admin consent for [your organization]** at the top

## STEP 5: Get Your Application IDs

1. Go back to **Overview** in the left menu
2. Copy the **Application (client) ID** - This is your client ID
3. Copy the **Directory (tenant) ID** - This is your tenant ID
4. Update these in your application if they don't match

## STEP 6: Test Your Authentication

1. Run your local server:
   ```
   .\intranet\serve-intranet.ps1
   ```
2. Open http://localhost:8090/intranet/login.html
3. Click "Sign in with Microsoft 365"
4. Use your iBridge credentials to sign in

## Troubleshooting

If you encounter any issues:

1. Check that the client ID and tenant ID in login.html match the ones from Step 5
2. Ensure all redirect URIs are correctly added in Step 3
3. Make sure implicit grant is enabled in Step 3
4. Wait 5-15 minutes after making changes (Microsoft Entra can take time to propagate changes)
5. Use the auth-fixer-azure.html tool to diagnose issues

---

**Note:** Microsoft Entra ID is the new name for Azure Active Directory. The functionality is the same, but the branding has changed.
