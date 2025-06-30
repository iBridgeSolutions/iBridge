# iBridge Intranet Portal

This is the internal staff portal for iBridge Contact Solutions employees. The intranet provides access to company resources, news, team information, and more.

## Features

- **News Board**: Company announcements and updates
- **Team Directory**: Organization structure and team information
- **Resources**: Access to company documents, forms, and resources
- **User Profile**: Personal profile management and settings
- **Admin Panel**: Administrative features for authorized users
- **Microsoft 365 Authentication**: Secure access using company credentials

## Local Development

To run the intranet portal locally:

1. Ensure you have Node.js installed
2. Run the intranet server script: `.\serve-intranet.ps1`
3. Open your browser and navigate to http://localhost:8080

## Authentication

The intranet portal uses Microsoft 365 for authentication. Users must sign in with their iBridge email address to access the portal.

For development, a testing mode is available that allows login without Microsoft authentication.

For administrators, see the `AZURE_AUTH_SETUP.md` file for instructions on setting up and configuring authentication.

## Structure

- `/css` - Stylesheets for the intranet portal
  - `intranet-styles.css` - Core styles
  - `intranet-enhanced.css` - Enhanced styles for main pages
  - `admin-enhanced.css` - Admin panel specific styles
  - `user-enhanced.css` - Profile and preferences specific styles
- `/js` - JavaScript functionality
  - `intranet.js` - Main functionality including authentication and page-specific functions
- `/partials` - Header and footer components
- `/images` - Images and icons
  - `/news` - News images
  - `/users` - User avatars
- `/resources` - Document resources available to staff
- `/pages` - Additional page templates and content

## User Roles

- **Standard Users**: Can access the dashboard, news, teams, directory, resources, calendar, and help
- **Administrators**: Can access all standard features plus the Admin Panel, Insights, and content management

## Security

This portal is for internal use only. All access is authenticated through Microsoft 365, and user activities are logged.

## Implementation Status

- ✅ Basic page structure and navigation
- ✅ Authentication system with Microsoft integration
- ✅ User profile and preferences pages
- ✅ Admin panel with user, content, and settings management
- ✅ Error pages (404, 500)
- ⏳ Data integration with backend services
- ⏳ Real-time notifications
- ⏳ Advanced search functionality

## Notes

- For setup of Microsoft authentication, see AZURE_AUTH_SETUP.md
- Admin access is granted to specified iBridge email addresses in the login configuration
- Currently configured admins: lwandile.gasela@ibridge.co.za
