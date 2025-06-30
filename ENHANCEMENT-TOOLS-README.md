# iBridge Website Enhancement Tools

This folder contains various tools and scripts to enhance and optimize the iBridge website before switching the primary domain to point to it.

## Available Scripts

### 1. `optimize-images.ps1`
PowerShell script to optimize images for better web performance:
- Compresses PNG and JPG files
- Generates WebP versions of images
- Provides guidance on how to implement WebP with fallbacks

**Usage:**
```powershell
./optimize-images.ps1
```

**Requirements:**
- Either ImageMagick or Node.js installed

### 2. `minify-assets.ps1`
PowerShell script to minify CSS and JavaScript files:
- Creates minified versions with .min suffix
- Preserves original files for development
- Includes a helper script to update HTML references

**Usage:**
```powershell
./minify-assets.ps1
```

**Requirements:**
- Node.js installed

### 3. `deploy-enhancements.ps1`
PowerShell script to deploy all enhancements to the live server:
- Uploads enhanced files via FTP
- Verifies deployment by checking key URLs
- Pre-configured with server credentials

**Usage:**
```powershell
./deploy-enhancements.ps1
```

### 4. `upload-to-ftp.ps1`
PowerShell script for general file uploads to the FTP server:
- Uploads entire directory structure
- Creates directories as needed
- Handles recursive uploads

**Usage:**
```powershell
./upload-to-ftp.ps1
```

## Enhancement Plan

The file `enhancement-plan.md` contains a detailed plan for improving the website in the following areas:
- Performance optimization
- Accessibility improvements
- User experience enhancements
- SEO optimization
- Security hardening

## New Features Added

1. **Skip Link for Accessibility**: Added to the accessibility.js script to help keyboard users
2. **Custom Error Pages**: 404.html and 500.html pages for better user experience
3. **Enhanced .htaccess**: Improved caching, security headers, and performance configuration
4. **WebP Support**: Tools to create and implement more efficient image formats

## Testing the Enhancements

Before pointing the primary domain, you can test all enhancements by accessing the site via IP address:
```
http://129.232.246.250/
```

## Final Steps Before Domain Switch

1. Run all optimization scripts
2. Deploy all enhancements
3. Test thoroughly using the IP address
4. Update DNS settings to point domain to the server

## Support

For assistance with these enhancement tools, contact the development team.
