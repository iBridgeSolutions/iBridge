# Setting Up ibridgesolutions.co.za as a Custom Domain for GitHub Pages

## Step 1: Create a CNAME File

1. Create a file named `CNAME` (no file extension) in the root directory of your GitHub repository
2. The file should contain only the domain name: `ibridgesolutions.co.za`
3. Save the file

## Step 2: Push the CNAME File to GitHub

### If using Git Command Line:

```bash
# Navigate to your repository directory
cd path/to/your/repo

# Create the CNAME file
echo "ibridgesolutions.co.za" > CNAME

# Add and commit the file
git add CNAME
git commit -m "Add custom domain configuration"

# Push to GitHub
git push origin main
```

### If using GitHub Web Interface:

1. Go to your repository: https://github.com/iBridgeSolutions/iBridge
2. Click "Add file" > "Create new file"
3. Name the file: `CNAME`
4. Enter your domain: `ibridgesolutions.co.za`
5. Scroll down and click "Commit new file"

## Step 3: Configure GitHub Pages Settings

1. Go to your repository settings: https://github.com/iBridgeSolutions/iBridge/settings/pages
2. Under "Custom domain", enter: `ibridgesolutions.co.za`
3. Click "Save"
4. Wait for GitHub to verify your domain (this may take some time)
5. Once verified, check the "Enforce HTTPS" option

## Step 4: Configure DNS Settings at Your Domain Provider

Log in to your domain registrar (where you registered ibridgesolutions.co.za) and add these DNS records:

### A Records

Add these four A records pointing to GitHub Pages' IP addresses:

```
A  @  185.199.108.153
A  @  185.199.109.153
A  @  185.199.110.153
A  @  185.199.111.153
```

### CNAME Record for www Subdomain (Optional but Recommended)

```
CNAME  www  ibridgesolutions.github.io
```

## Step 5: Wait for DNS Propagation

DNS changes can take 24-48 hours to fully propagate. You can check propagation status using:
- https://www.whatsmydns.net/
- https://dnschecker.org/

## Step 6: Verify Setup

1. After DNS propagation, visit your domain: `https://ibridgesolutions.co.za`
2. Verify that your website loads correctly
3. Verify that HTTPS is working properly

## Troubleshooting

If your site doesn't load after 48 hours:

1. Verify your DNS settings are correct
2. Check that the CNAME file only contains the domain name
3. Make sure your repository is public
4. Check for any error messages in the GitHub Pages section of your repository settings

## Additional Resources

- [GitHub Pages Custom Domain Documentation](https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site)
- [Troubleshooting Custom Domains](https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site/troubleshooting-custom-domains-and-github-pages)
