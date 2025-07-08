# iBridge Portal - Microsoft 365 Mirror Configuration Guide

This document explains how the iBridge intranet portal has been configured to mirror Microsoft 365 functionality with exclusive access for Lwandile Gasela.

## Configuration Overview

The portal has been configured with the following settings:

- **Exclusive Access**: Only Lwandile Gasela (lwandile.gasela@ibridge.co.za) has access
- **Employee Code**: IBDG054 can be used to login
- **Real Data**: Using actual Microsoft 365 data (not simulated)
- **Dev Mode**: Disabled (production mode enabled)

## Features Mirroring Microsoft 365

The portal now mirrors the following Microsoft services:

### 1. Microsoft 365 Admin Center

- User Management
- Group Management
- License Management
- Settings Configuration
- Security & Compliance
- Billing & Subscriptions

### 2. Microsoft Entra ID / Azure AD

- Application Management
- Enterprise Applications
- App Registrations
- Identity Governance
- Security & Compliance
- Conditional Access
- Authentication Methods

### 3. Exchange Admin Center

- Mail Flow
- Mailbox Management
- Distribution Groups
- Resources
- Sharing & Permissions

### 4. SharePoint Admin Center

- Site Management
- Content Services
- Sharing & Permissions
- Access Control

### 5. Teams Admin Center

- Team Management
- Meeting Policies
- Messaging Policies
- User Management

## Data Integration

The portal uses data extracted from the following Microsoft Graph API endpoints:

- Users & Groups
- Organization Information
- Applications & Service Principals
- Roles & Permissions
- Policies & Settings
- Audit Logs
- Directory Objects

## Authentication Methods

Two authentication methods are supported:

1. **Microsoft 365 Login**: Using Microsoft identity platform
2. **Employee Code Login**: Using code IBDG054 for Lwandile Gasela

## Accessing the Portal

To access the iBridge portal:

1. Start the unified server: `START-UNIFIED-SERVER.bat`
2. Navigate to http://localhost:8090/intranet/
3. Login using employee code IBDG054 or Microsoft 365 credentials (lwandile.gasela@ibridge.co.za)

## Configuration Files

The following files have been updated to enable this functionality:

- `intranet/data/settings.json`: Main configuration with dev mode disabled
- `intranet/data/access-control.json`: Exclusive access control settings
- `intranet/data/employee-codes.json`: Employee code mapping
- `intranet/login.html`: Enhanced login page with employee code support
- `intranet/js/portal-authenticator.js`: Authentication module for Microsoft 365 and employee codes

## URLs & Resources

Microsoft Admin Centers mirrored in the portal:

- Microsoft 365 Admin Center: https://admin.microsoft.com
- Microsoft Entra ID: https://entra.microsoft.com
- Exchange Admin Center: https://admin.exchange.microsoft.com
- SharePoint Admin Center: https://admin.microsoft.com/sharepoint
- Teams Admin Center: https://admin.teams.microsoft.com

## Security Considerations

The portal implements the following security measures:

1. **Exclusive Access Control**: Only lwandile.gasela@ibridge.co.za can access the portal
2. **Employee Code Validation**: Only IBDG054 is recognized
3. **Secure Authentication**: Using Microsoft identity platform for M365 login
4. **Session Management**: Sessions expire after inactivity

## Microsoft Graph Permissions

The portal mirrors functionality using these Microsoft Graph permissions:

- User.Read.All
- Directory.Read.All
- Group.Read.All
- Application.Read.All
- AuditLog.Read.All
- Organization.Read.All
- Policy.Read.All

## Contact

For support with this configuration, please contact:

- Lwandile Gasela (lwandile.gasela@ibridge.co.za)
