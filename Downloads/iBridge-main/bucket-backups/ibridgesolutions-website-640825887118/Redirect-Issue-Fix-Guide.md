# Fixing the /lander Redirect Issue on ibridgesolutions.co.za

## The Problem

Your website at ibridgesolutions.co.za is redirecting to `/lander`, which doesn't exist, resulting in a white screen. This is likely due to one of these issues:

1. A misconfiguration in GitHub Pages
2. A redirect in your HTML/JS files
3. A custom 404.html page with a redirect

## Quick Fix

I've created a temporary solution to immediately fix this problem:

1. Run the `fix-redirect-issue.ps1` script I provided, which will:
   - Replace the current index.html with a simple temporary page
   - Push the changes to your GitHub repository
   - Optionally add a redirect fix for www subdomain

```powershell
# Run this from PowerShell
cd "c:\Users\Lwandile Gasela\Downloads\iBridge-main"
.\fix-redirect-issue.ps1
```

2. Wait 5-10 minutes for GitHub Pages to update
3. Visit https://ibridgesolutions.co.za to confirm it's working

## Long-term Solution

Once the immediate issue is fixed, you should:

1. Examine why the redirect was happening:
   - Check if there's a `_redirects` file in your repository
   - Make sure there's no JavaScript code redirecting to `/lander`
   - Check GitHub Pages settings for any custom routing

2. Fix your original index.html:
   - Remove any redirection code
   - Update the file structure if needed
   - Ensure all links are relative and working

3. Test thoroughly:
   - Test all pages
   - Check both www and non-www versions
   - Verify mobile and desktop display

## Common Causes of This Issue

1. **Jekyll Processing**: GitHub Pages uses Jekyll by default, which might be processing your files unexpectedly.
   - Solution: Add an empty `.nojekyll` file to your repository

2. **404 Page Redirects**: A custom 404.html file might be redirecting to /lander.
   - Solution: Check and update your 404.html file

3. **GitHub Pages Configuration**: Your GitHub Pages might be set to serve from a specific folder.
   - Solution: Check the GitHub Pages section in your repository settings

4. **JavaScript Redirects**: A script might be redirecting based on browser info or other conditions.
   - Solution: Review all JavaScript files for redirect code

## Testing After Fix

After applying the fix, use these resources to test your site:

1. The redirect-checker.html tool I provided
2. Visit https://ibridgesolutions.co.za directly
3. Check your browser's developer tools (F12) to see if any redirects are happening

## Need More Help?

If this fix doesn't resolve your issue, you might need to:

1. Check GitHub Pages documentation for any recent changes
2. Look at your domain registrar settings for any URL forwarding rules
3. Consider temporarily disabling any CDN or caching services
