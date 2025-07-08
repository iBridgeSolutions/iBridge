# Microsoft Entra ID App Registration Guide

## Overview
This guide will help you manually set up an app registration in Microsoft Entra ID (formerly Azure AD) for your iBridge intranet portal. This is essential for authenticating users and accessing Microsoft 365 data.

## Prerequisites
- A Microsoft 365 administrator account (lwandile.gasela@ibridge.co.za)
- Access to the Microsoft Entra admin center

## Step 1: Access the Microsoft Entra Admin Center
1. Open your web browser and go to [https://entra.microsoft.com](https://entra.microsoft.com)
2. Sign in with your administrator account (lwandile.gasela@ibridge.co.za)
3. Once signed in, you'll see the Microsoft Entra admin center dashboard

## Step 2: Register a New Application
1. In the left navigation menu, click on **App registrations**
2. Click on **+ New registration** at the top of the page
3. Enter the following details:
   - **Name**: iBridge Portal
   - **Supported account types**: Accounts in this organizational directory only - Single tenant
   - **Redirect URI**: Web - http://localhost:8090/intranet/login.html
4. Click **Register** to create the app

## Step 3: Note Down Important Information
After registering the app, you'll be taken to the app's overview page. Note down:
1. **Application (client) ID** - You'll need this for your intranet settings
2. **Directory (tenant) ID** - You'll also need this for your settings

## Step 4: Configure Authentication Settings
1. In the left menu of your app registration, click on **Authentication**
2. Under **Platform configurations**, click **Add a platform** if Web is not already added
3. Select **Web** and add these redirect URIs:
   - http://localhost:8090/intranet/login.html
   - http://localhost:8090/intranet/
   - http://localhost:8090/intranet/index.html
   - http://localhost:8090/auth-callback.html
4. Under **Implicit grant and hybrid flows**, check both:
   - **Access tokens**
   - **ID tokens**
5. Click **Configure** or **Save** to apply these settings

## Step 5: Configure API Permissions
1. In the left menu, click on **API permissions**
2. Click **+ Add a permission**
3. Select **Microsoft Graph**
4. Choose **Delegated permissions**
5. Search for and select the following permissions:
   - User.Read
   - User.ReadBasic.All
   - Directory.Read.All
   - Organization.Read.All
   - Group.Read.All
6. Click **Add permissions** to add these to your app
7. Back on the API permissions page, click **Grant admin consent for [your organization]**
8. Confirm the action when prompted

## Step 6: Update Your Intranet Settings
1. Return to your iBridge website folder
2. Run the script `quick-switch-to-real-data.ps1` by double-clicking on `QUICK-SWITCH-TO-REAL-DATA.bat`
3. When prompted, enter the Client ID and Tenant ID you noted down earlier
4. This will update your settings to use real Microsoft 365 data

## Step 7: Start Your Intranet Server
1. Run `START-UNIFIED-SERVER.bat` to start the intranet server
2. Open your browser and navigate to http://localhost:8090/intranet/
3. You should now be able to log in with your Microsoft 365 account and see real company data

## Troubleshooting
If you encounter issues:
1. Verify that all redirect URIs are correctly configured
2. Make sure admin consent has been granted for all API permissions
3. Check that the Client ID and Tenant ID in your settings match those in the app registration
4. Try restarting the intranet server after making changes

## Security Considerations
- This app registration uses delegated permissions, meaning it can only access data when a user is signed in
- The app is configured as single-tenant, so only users from your organization can sign in
- Review and update API permissions regularly to follow the principle of least privilege
