# GoDaddy DNS Configuration Guide for ibridgesolutions.co.za

This guide provides step-by-step instructions specifically for GoDaddy users to configure DNS settings for GitHub Pages.

## Step 1: Log in to GoDaddy

1. Go to [GoDaddy.com](https://www.godaddy.com/) and log in to your account
2. Click on **My Products**

## Step 2: Access DNS Settings

1. In the **Domains** section, find **ibridgesolutions.co.za**
2. Click on the **DNS** button (or select **Manage** then **DNS**)

## Step 3: Remove Any Existing Forwarding

Before setting up your DNS records, check for any forwarding:

1. In your domain dashboard, look for **Forwarding** or **Website Redirect**
2. If any forwarding is enabled (especially to `/lander`), disable it

## Step 4: Configure A Records for GitHub Pages

1. In the **DNS Records** section, look for any existing A records and remove them
2. Add these four A records:

| Type | Name/Host | Value/Points to | TTL |
|------|-----------|----------------|-----|
| A    | @         | 185.199.108.153 | 1 Hour |
| A    | @         | 185.199.109.153 | 1 Hour |
| A    | @         | 185.199.110.153 | 1 Hour |
| A    | @         | 185.199.111.153 | 1 Hour |

## Step 5: Configure CNAME Record for www Subdomain

1. In the **DNS Records** section, find any existing CNAME records for **www** and remove them
2. Add a new CNAME record:

| Type  | Name/Host | Value/Points to | TTL |
|-------|-----------|----------------|-----|
| CNAME | www       | blxckukno.github.io | 1 Hour |

## Step 6: Remove GoDaddy Parking Page

GoDaddy often displays a default "Coming Soon" or parking page:

1. In your domain dashboard, look for **Website** or **Website Builder**
2. Find any setting labeled **Parked page**, **Coming Soon page**, or **Temporary page**
3. Disable or turn off these features

## Step 7: Check Website Redirect Settings

GoDaddy has a separate "Website Redirect" feature that could cause issues:

1. In your domain dashboard, click on **Additional Settings** or similar
2. Look for **Website Redirect** or **URL Forwarding**
3. Make sure it's set to "Off" or "No redirect"

## Step 8: Save Your Changes

1. Click **Save** to apply your changes
2. DNS changes can take 24-48 hours to fully propagate

## Step 9: Verify Settings in GitHub

1. Go to your GitHub repository: https://github.com/Blxckukno/iBridge
2. Navigate to **Settings** → **Pages**
3. Ensure your custom domain is set to **ibridgesolutions.co.za**
4. After GitHub verifies your domain, check **Enforce HTTPS**

## Troubleshooting

If you continue to see the `/lander` redirection:

1. Check for any GoDaddy Website Builder or Web Hosting products attached to your domain
2. Contact GoDaddy support to ensure there are no redirects or forwarding rules active
3. Ask them specifically about the "/lander" redirection, as this is a common GoDaddy default page

You can run the following PowerShell script to check your DNS configuration:

```powershell
cd "c:\Users\Lwandile Gasela\Downloads\iBridge-main"
.\simple-dns-check.ps1
```
