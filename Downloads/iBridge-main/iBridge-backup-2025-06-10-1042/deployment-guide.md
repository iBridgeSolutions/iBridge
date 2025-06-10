# iBridge Website Deployment Guide
## Deploying to ibridgesolutions.co.za via GoDaddy

### Prerequisites
- GoDaddy hosting account with cPanel access
- Domain: ibridgesolutions.co.za (active)
- FTP/SFTP credentials from GoDaddy
- Website files ready for deployment

### Deployment Options

#### Option 1: GoDaddy File Manager (Recommended for beginners)
1. **Access cPanel**
   - Log into your GoDaddy account
   - Navigate to "Web Hosting" → "Manage"
   - Click "cPanel Admin"

2. **Use File Manager**
   - In cPanel, find and click "File Manager"
   - Navigate to `public_html` folder (this is your website root)
   - Delete any existing files (like default GoDaddy pages)

3. **Upload Website Files**
   - Click "Upload" button
   - Select all your website files or create a ZIP file
   - If using ZIP: Upload → Extract → Delete ZIP file
   - Ensure `index.html` is in the root of `public_html`

#### Option 2: FTP Deployment (Recommended for developers)
1. **Get FTP Credentials**
   - In GoDaddy cPanel → "FTP Accounts"
   - Create new FTP user or use main account
   - Note: Server, Username, Password, Port (usually 21)

2. **FTP Client Setup**
   - Use FileZilla, WinSCP, or VS Code FTP extensions
   - Connect to your server
   - Navigate to `public_html` directory

3. **Upload Files**
   - Upload all website files to `public_html`
   - Maintain folder structure exactly as local

### Pre-Deployment Checklist

#### ✅ File Optimization
- [ ] Optimize images (compress PNG/JPG files)
- [ ] Minify CSS and JavaScript files
- [ ] Remove development files (.code-workspace, .md files)
- [ ] Verify all links are relative (not absolute paths)
- [ ] Test all pages locally first

#### ✅ Content Updates
- [ ] Update contact information (phone, email, address)
- [ ] Verify domain references in code
- [ ] Update meta tags with proper domain
- [ ] Check social media links
- [ ] Verify Google Analytics/tracking codes

#### ✅ Security & Performance
- [ ] Add .htaccess file for security headers
- [ ] Enable GZIP compression
- [ ] Set up SSL certificate (usually automatic with GoDaddy)
- [ ] Configure caching headers

### File Structure for Deployment
```
public_html/
├── index.html
├── about.html
├── services.html
├── contact.html
├── contact-center.html
├── it-support.html
├── ai-automation.html
├── css/
│   └── styles.css
├── js/
│   └── main.js
├── images/
│   ├── iBridge_Logo-removebg-preview.png
│   ├── iBridge_IMG_1.png
│   ├── iBridge_IMG_2.png
│   ├── iBridge_IMG_3.png
│   └── iBridge_IMG_4.png
└── .htaccess (optional)
```

### Post-Deployment Steps

#### 1. **DNS Configuration**
- Ensure domain points to GoDaddy nameservers
- Wait 24-48 hours for DNS propagation
- Test domain: http://ibridgesolutions.co.za

#### 2. **SSL Certificate**
- GoDaddy usually provides free SSL
- Force HTTPS redirects in .htaccess
- Test: https://ibridgesolutions.co.za

#### 3. **Testing**
- [ ] Test all pages load correctly
- [ ] Verify all navigation links work
- [ ] Test dropdown menus
- [ ] Check mobile responsiveness
- [ ] Verify contact forms (if applicable)
- [ ] Test all external links

#### 4. **SEO Setup**
- Submit sitemap to Google Search Console
- Set up Google Analytics
- Verify meta tags and descriptions
- Test site speed with Google PageSpeed Insights

### Common Issues & Solutions

#### Issue: Files not showing
- **Solution**: Clear browser cache, check file permissions (755 for folders, 644 for files)

#### Issue: CSS/JS not loading
- **Solution**: Verify file paths are relative, check case sensitivity

#### Issue: Images not displaying
- **Solution**: Check image file names match exactly (case-sensitive)

#### Issue: SSL certificate issues
- **Solution**: Wait 24 hours, contact GoDaddy support

### Performance Optimization

#### 1. **Image Optimization**
- Compress images to reduce file sizes
- Use WebP format where possible
- Implement lazy loading for images

#### 2. **Caching Setup**
Add to .htaccess file:
```apache
# Enable compression
<IfModule mod_deflate.c>
    AddOutputFilterByType DEFLATE text/plain
    AddOutputFilterByType DEFLATE text/html
    AddOutputFilterByType DEFLATE text/xml
    AddOutputFilterByType DEFLATE text/css
    AddOutputFilterByType DEFLATE application/xml
    AddOutputFilterByType DEFLATE application/xhtml+xml
    AddOutputFilterByType DEFLATE application/rss+xml
    AddOutputFilterByType DEFLATE application/javascript
    AddOutputFilterByType DEFLATE application/x-javascript
</IfModule>

# Leverage Browser Caching
<IfModule mod_expires.c>
    ExpiresActive on
    ExpiresByType text/css "access plus 1 year"
    ExpiresByType application/javascript "access plus 1 year"
    ExpiresByType image/png "access plus 1 year"
    ExpiresByType image/jpg "access plus 1 year"
    ExpiresByType image/jpeg "access plus 1 year"
</IfModule>
```

### Support & Maintenance

#### Regular Updates
- Keep content current
- Monitor site performance
- Regular backups via cPanel
- Update contact information as needed

#### Monitoring
- Set up Google Analytics
- Monitor site uptime
- Check for broken links monthly
- Review site speed quarterly

### Emergency Contacts
- **GoDaddy Support**: 1-480-624-2505
- **cPanel Documentation**: https://docs.cpanel.net/
- **Domain**: ibridgesolutions.co.za

---

**Last Updated**: June 6, 2025
**Version**: 1.0
**Contact**: iBridge Solutions Team