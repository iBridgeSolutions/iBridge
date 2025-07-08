# iBridge Custom Authentication System

This document explains the custom authentication system implemented for the iBridge portal, which uses employee codes in the format `IBD[Last Name Initials][Unique ID]` instead of Microsoft 365 authentication.

## Employee Code Format

Each employee is assigned a unique code with the following format:

```
IBD[Last Name Initials][Unique ID]
```

For example:
- `IBDG054` - Employee with last name starting with "G" (e.g., Gasela) and ID 054
- `IBDJ001` - Employee with last name starting with "J" (e.g., Johnson) and ID 001
- `IBDSM025` - Employee with last name starting with "SM" (e.g., Smith) and ID 025

## Authentication Methods

The portal supports two authentication methods:

1. **Employee Code Login**
   - Users can enter their employee code (e.g., `IBDG054`)
   - No password is required when using the employee code

2. **Username & Password Login**
   - Users can enter their email address or username
   - Default password is `iBridge2025` for all users
   - Password can be changed in the custom-authenticator.js file

## Access Control

Access to the portal can be restricted to specific users or employee codes:

- **Restricted Access**: When enabled, only users and employee codes listed in the allowed lists can access the portal
- **Open Access**: When disabled, any valid employee code or username/password combination can access the portal

## Configuration Files

The custom authentication system uses the following configuration files:

1. **settings.json**
   - Controls authentication settings like enabling/disabling authentication methods
   - Format: `useCustomAuth`, `employeeCodeLogin`, `credentialsLogin` properties

2. **employee-codes.json**
   - Maps employee codes to user information and permissions
   - Contains first name, last name, email, department, position, and permissions

3. **access-control.json**
   - Controls access restrictions to the portal
   - Lists allowed users and employee codes

## Management Tools

The following tools are provided to manage the custom authentication system:

1. **SETUP-CUSTOM-AUTH.bat**
   - Sets up the custom authentication system
   - Updates configuration files
   - Installs custom login page

2. **MANAGE-EMPLOYEE-CODES.bat**
   - Manages employee codes and user information
   - Features:
     - Add new employees
     - Update existing employees
     - Delete employees
     - Manage access control settings

## Implementation Details

The custom authentication system is implemented using:

- **custom-authenticator.js**: JavaScript module that handles authentication logic
- **login.html**: Custom login page with forms for both authentication methods
- **Client-side storage**: Uses sessionStorage to maintain authenticated sessions

## Security Considerations

This implementation focuses on providing a custom authentication experience similar to Microsoft 365, but has some limitations:

1. Passwords are stored and verified in plain text (in a production environment, these would be hashed)
2. Employee code authentication doesn't require a password (for convenience)
3. Authentication is handled entirely client-side (in a production environment, server-side validation would be used)

## Usage Instructions

1. **Setup**:
   - Run `SETUP-CUSTOM-AUTH.bat` to configure the portal for custom authentication

2. **Managing Users**:
   - Run `MANAGE-EMPLOYEE-CODES.bat` to add, update, or delete employees
   - Use the interactive menu to perform various management tasks

3. **Accessing the Portal**:
   - Start the server using `CHECK-AND-START-UNIFIED-SERVER.bat`
   - Navigate to http://localhost:8090/intranet/
   - Login using your employee code or username/password

4. **Default Admin Access**:
   - Employee Code: `IBDG054`
   - Username: `lwandile.gasela@ibridge.co.za`
   - Password: `iBridge2025`
