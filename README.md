# iBridge Website & Intranet Portal

This repository contains the iBridge website and intranet portal codebase with enhanced features for accessibility, performance, and user experience. The system now uses a unified server approach to serve both the main website and intranet from a single port.

## Major Updates (July 2025)

### Enhanced Security Features

- **Password Hashing**: All passwords now stored using secure SHA-256 hashing with unique salts
- **Two-Factor Authentication**: Added email verification code system for enhanced login security
- **Rate Limiting**: Implemented protection against brute force attacks and DoS attempts
- **CSRF Protection**: Added anti-forgery tokens for all forms and API requests
- **Account Lockout**: Temporary account lockout after multiple failed login attempts
- **Password Strength**: Enforcement of strong password requirements with visual feedback
- **Session Security**: Improved session management with secure cookies

### Microsoft 365 Independence

- **Custom Authentication**: Removed all Microsoft dependencies for authentication
- **Local Data Storage**: All data now stored locally without cloud dependencies
- **Calendar System**: Calendar data extracted and stored locally
- **Files System**: File data extracted and stored locally

## Implemented Enhancements

### Performance Improvements

- **Lazy Loading**: Images now use the `loading="lazy"` attribute for better page load performance.
- **Optimized CSS**: Styles have been consolidated and optimized.
- **Script Loading**: JavaScript files are loaded at the end of the document.

### Accessibility Enhancements

- **ARIA Attributes**: Added proper ARIA roles, labels, and states to interactive elements.
- **Keyboard Navigation**: Improved keyboard navigation throughout the site.
- **Skip to Content**: Added a skip to main content link for screen readers.
- **Form Validation**: Enhanced form validation with clear error messages and focus management.
- **Color Contrast**: Ensured text colors have sufficient contrast with backgrounds.

### User Experience Improvements

- **Consistent Navigation**: Standardized navigation across all pages.
- **White Header**: Implemented a clean white header with dark navigation links.
- **Hero Section**: Optimized hero sections with proper overlay and responsive sizing.
- **Form Feedback**: Added enhanced validation and feedback for form submissions.
- **Address Updates**: Corrected office address throughout the site (332 Kent Ave, Ferndale, Randburg, 2194).

### Design and Style

- **Logo Placement**: Standardized logo placement in header and footer.
- **Favicon**: Updated to use the iBridge logo as favicon.
- **Typography**: Improved readability with consistent font sizing and weights.
- **Visual Hierarchy**: Enhanced visual hierarchy for important elements.
- **Responsive Design**: Improved mobile and tablet experience.

### Microsoft 365 Integration Integration

- **Employee Directory**: Syncs employee data from Microsoft 365 to populate the intranet directory.ta from Microsoft 365 to populate the intranet directory.
- **Company Profile**: Pulls company information from Microsoft 365 tenant for the intranet's company profile section.rmation from Microsoft 365 tenant for the intranet's company profile section.
- **Dev Mode**: Includes a development mode that simulates Microsoft 365 data for testing and development.pment mode that simulates Microsoft 365 data for testing and development.
- **Admin Access**: Special privileges for administrators (<lwandile.gasela@ibridge.co.za>) for content management.
- **Profile Photos**: Automatically generates profile photos for employees using their initials.atically generates profile photos for employees using their initials.

## File Structure

- **HTML Files**: Main pages of the websitete
- **css/**: Contains all stylesheet filesins all stylesheet files
  - `styles.css`: Main stylesheet Main stylesheet
  - `style-enhancements.css`: Additional style improvements  - `style-enhancements.css`: Additional style improvements
- **js/**: JavaScript fileses
  - `main.js`: Main functionality  - `main.js`: Main functionality
  - `accessibility.js`: Accessibility enhancementss`: Accessibility enhancements
- **images/**: All website images- **images/**: All website images
- **partials/**: Reusable HTML componentsnts
  - `header.html`
  - `footer.html`

## Maintenance Guidelines## Maintenance Guidelines

### Adding New Pages### Adding New Pages

1. Copy an existing page as a template
2. Update meta tags, title, and content
3. Ensure all scripts and stylesheets are included3. Ensure all scripts and stylesheets are included
4. Add the page to navigation menusvigation menus

### Updating Images

1. Optimize images before uploading (compress without quality loss)mpress without quality loss)
2. Use descriptive alt text for accessibility2. Use descriptive alt text for accessibility
3. Add `loading="lazy"` attribute for better performanceribute for better performance

### CSS Modifications

1. Use `style-enhancements.css` for new styles styles
2. Follow existing naming conventions2. Follow existing naming conventions
3. Test changes across all screen sizes all screen sizes

### JavaScript Enhancements

1. Add new functionality to the appropriate JS file
2. Test thoroughly for accessibility and performance
3. Use unobtrusive JavaScript practices

## Future Enhancements

- **SEO Optimization**: Further meta tag improvements and structured dataon**: Further meta tag improvements and structured data
- **Analytics Integration**: Add detailed event tracking- **Analytics Integration**: Add detailed event tracking
- **Testimonials Carousel**: Implement dynamic testimonials sectionamic testimonials section
- **Newsletter Integration**: Add subscription functionality- **Newsletter Integration**: Add subscription functionality
- **Case Studies Section**: Showcase detailed client success storiesled client success stories
- **Blog/Resources**: Add a content marketing section- **Blog/Resources**: Add a content marketing section
- **Live Chat**: Integrate customer support chat functionality

## Getting Started

### Running the Website & Intranet Locally

#### Unified Server Approach (Recommended)#### Unified Server Approach (Recommended)

The recommended way to run both the main website and intranet portal is using the unified server approach:The recommended way to run both the main website and intranet portal is using the unified server approach:

1. **Using the Check and Start Script**sing the Check and Start Script**
   ```bash
   Double-click on CHECK-AND-START-UNIFIED-SERVER.batble-click on CHECK-AND-START-UNIFIED-SERVER.bat
   ```

   This will check your configuration and start the unified server. start the unified server.

2. **Using the PowerShell Script**2. **Using the PowerShell Script**
   ```
   ./start-unified-server.ps1   ./start-unified-server.ps1
   ```

   This will serve both the main website and intranet portal from a single port (8090):main website and intranet portal from a single port (8090):
   - Main Website: http://localhost:8090/ain Website: http://localhost:8090/
   - Intranet Portal: http://localhost:8090/intranet/   - Intranet Portal: http://localhost:8090/intranet/

#### Alternative Approacheslternative Approaches

1. **Running Only the Intranet Portal**unning Only the Intranet Portal**
   ```   ```
   ./run-intranet-server.ps1
   ```   ```

2. **Running Only the Main Website**2. **Running Only the Main Website**
   ``````
   ./start-website-server.ps1s1
   ``````

### Verification and Troubleshooting

To verify your setup and ensure all files are properly configured:

```powershell
./verify-intranet-files.ps1
```

This will check for required files, navigation paths, and server port consistency.

### Microsoft 365 Integration Tools

The intranet portal integrates with Microsoft 365 to provide employee directory, company profile, and other organizational data. The following tools are available to manage this integration:

#### Syncing Microsoft 365 Data

To synchronize data from Microsoft 365 with your intranet:

```powershell
./SYNC-M365-DATA.bat
```

Or directly using PowerShell:

```powershell
./sync-m365-dev-data.ps1
```

This will:

- Generate profile images for employees
- Create organization data (company profile)
- Populate employee directory
- Set up department information
- Configure intranet settings

#### Verifying Microsoft 365 Integration

To verify that Microsoft 365 integration is working correctly:

```powershell
./VERIFY-M365-INTEGRATION.bat
```

Or directly using PowerShell:

```powershell
./verify-m365-integration.ps1
```

This will check that all required data files and profile images have been properly created.

#### Data Validation and Enrichment

To validate all intranet data files for consistency:

```powershell
./VALIDATE-INTRANET-DATA.bat
```

Or directly using PowerShell:

```powershell
./validate-intranet-data.ps1
```

This will check that all data files have consistent structure and required properties.

To enrich employee data and ensure all records have consistent properties:

```powershell
./ENRICH-EMPLOYEE-DATA.bat
```

Or directly using PowerShell:

```powershell
./enrich-employee-data.ps1
```

This will add missing properties to employee records based on a reference template.

#### Development Mode

The intranet includes a development mode that simulates Microsoft 365 data. This is enabled by default in the `settings.json` file. In development mode:

- Admin access is granted to `lwandile.gasela@ibridge.co.za`
- Sample employee and department data is generated
- Profile photos are created automatically
- The source is marked as "Microsoft 365 Admin Center (Dev Mode)"

To use real Microsoft 365 data, you'll need to:

1. Register an app in Microsoft Entra ID (Azure AD)
2. Grant appropriate permissions
3. Update the `clientId` and `tenantId` in the `settings.json` file
4. Set `devMode` to `false` in `settings.json`

Detailed instructions for setting up real Microsoft 365 integration are available in the `ENTRA_INTEGRATION_STEPS.md` file.
