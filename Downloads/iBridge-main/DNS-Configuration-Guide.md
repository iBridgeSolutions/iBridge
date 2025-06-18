# DNS Configuration Guide for ibridgesolutions.co.za

This guide provides step-by-step instructions for configuring your custom domain to work with GitHub Pages.

## DNS Configuration Steps

### For GoDaddy Users

1. Log in to your GoDaddy account
2. Navigate to **My Products** → **Domains**
3. Find **ibridgesolutions.co.za** and click on **DNS**
4. In the DNS Management page, you need to add records:

#### Adding A Records

1. Find the **Records** section
2. Look for any existing A records for **@** (represents the root domain) and remove them
3. Add four new A records:

| Type | Name | Value | TTL |
|------|------|-------|-----|
| A | @ | 185.199.108.153 | 1 Hour |
| A | @ | 185.199.109.153 | 1 Hour |
| A | @ | 185.199.110.153 | 1 Hour |
| A | @ | 185.199.111.153 | 1 Hour |

#### Adding CNAME Record

1. Find existing CNAME records for **www** and remove them
2. Add a new CNAME record:

| Type | Name | Value | TTL |
|------|------|-------|-----|
| CNAME | www | blxckukno.github.io | 1 Hour |

**Important**: Your repository is at Blxckukno/iBridge, so you must use `blxckukno.github.io`

3. Save your changes

### For Namecheap Users

1. Log in to your Namecheap account
2. Go to **Domain List** → **Manage** next to ibridgesolutions.co.za
3. Navigate to the **Advanced DNS** tab
4. Remove any existing A records for @ (root domain)
5. Add the GitHub Pages A records:

| Type | Host | Value | TTL |
|------|------|-------|-----|
| A Record | @ | 185.199.108.153 | Automatic |
| A Record | @ | 185.199.109.153 | Automatic |
| A Record | @ | 185.199.110.153 | Automatic |
| A Record | @ | 185.199.111.153 | Automatic |
| CNAME Record | www | blxckukno.github.io | Automatic |

6. Save your changes

## Verifying GitHub Pages Configuration

1. Go to your GitHub repository at https://github.com/iBridgeSolutions/iBridge (or https://github.com/Blxckukno/iBridge)
2. Navigate to **Settings** → **Pages**
3. Under **Custom domain**, ensure **ibridgesolutions.co.za** is entered
4. Once GitHub verifies your domain (may take a few hours), check **Enforce HTTPS**

## Checking DNS Propagation

After configuring DNS settings, it can take 24-48 hours for changes to fully propagate.

1. Run the provided `check-dns-propagation.ps1` script to verify your settings
2. You can also use online tools:
   - [whatsmydns.net](https://www.whatsmydns.net/)
   - [dnschecker.org](https://dnschecker.org/)

## Testing Your Domain

1. After DNS propagation, visit `https://ibridgesolutions.co.za`
2. You can also use the provided `domain-test.html` page to check the configuration

## Troubleshooting

If your site doesn't load after 48 hours:

1. Verify your DNS settings using the check-dns-propagation.ps1 script
2. Ensure the CNAME file only contains `ibridgesolutions.co.za` (no other text)
3. Check GitHub repository settings to ensure Pages is properly configured
4. Ensure the repository is public
5. Check that the repository contains your website files in the root directory
