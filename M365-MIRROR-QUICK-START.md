# iBridge Microsoft 365 Complete Mirror - Quick Setup Guide

This guide provides step-by-step instructions to set up the Microsoft 365 Complete Mirror Portal with exclusive access for lwandile.gasela@ibridge.co.za (IBDG054).

## Quick Start Guide

### Step 1: Configure Exclusive Access

1. Double-click on `CONFIGURE-EXCLUSIVE-ACCESS.bat`
2. Wait for the configuration to complete
3. Choose whether to extract Microsoft 365 data now or later

### Step 2: Extract Microsoft 365 Data

1. Double-click on `EXTRACT-COMPLETE-M365-MIRROR.bat`
2. Sign in with your Microsoft 365 admin credentials when prompted
3. Wait for the data extraction to complete (this may take several minutes)

### Step 3: Start the Portal

1. Double-click on `START-MIRROR-PORTAL.bat` or `CHECK-AND-START-UNIFIED-SERVER.bat`
2. The server will start and open a browser window

### Step 4: Access the Portal

1. Navigate to http://localhost:8090/intranet/ in your browser
2. Login using either:
   - Microsoft 365 account: lwandile.gasela@ibridge.co.za
   - Employee code: IBDG054

## Verifying Your Setup

To ensure the portal is correctly configured for exclusive access:

1. Double-click on `VERIFY-EXCLUSIVE-ACCESS.bat`
2. Review the verification results
3. If any issues are found, follow the prompts to fix them

## Features Available

The Microsoft 365 Mirror Portal provides complete access to:

- User management and directory features
- Group and team management
- Application management
- Security and compliance features
- Identity and access management
- Exchange, SharePoint, and Teams administration
- Reporting and analytics
- Policy management

## Support and Troubleshooting

If you encounter issues with the portal:

1. Check that the server is running
2. Verify exclusive access configuration with `VERIFY-EXCLUSIVE-ACCESS.bat`
3. Ensure Microsoft 365 data has been extracted
4. Check network connectivity to localhost on port 8090

For detailed information about the mirror portal, see `M365-COMPLETE-MIRROR-GUIDE.md`.

---

**Note**: This portal is configured exclusively for lwandile.gasela@ibridge.co.za (IBDG054)
