# Fixing the GoDaddy Lander Page Redirect

If your website hosted on GitHub Pages through a GoDaddy domain is redirecting to `/lander`, this is likely due to GoDaddy's default forwarding settings. Here's how to fix it:

## Step 1: Fix Your GitHub Pages Repository

1. Replace your current `index.html` with the `fixed-index.html` I've created
2. Add the `.nojekyll` file to the root of your repository
3. Make sure your `CNAME` file contains only `ibridgesolutions.co.za` (no other text)

## Step 2: Disable GoDaddy's Forwarding

1. Log in to your GoDaddy account
2. Navigate to **My Products** → **Domains**
3. Select **ibridgesolutions.co.za**
4. Look for **Forwarding** or **Redirect** settings:
   - Click on **DNS** or **Domain Settings**
   - Find any section labeled **Forwarding**, **Website Redirect**, or **Website**
   - Make sure no forwarding is enabled
   - Disable any redirects that point to `/lander`

## Step 3: Configure DNS Correctly

Make sure your DNS settings are configured correctly for GitHub Pages:

1. In GoDaddy, go to **DNS Management** for ibridgesolutions.co.za
2. Ensure you have:
   - Four A records pointing to GitHub Pages IPs (185.199.108.153, 185.199.109.153, 185.199.110.153, 185.199.111.153)
   - A CNAME record for www pointing to `blxckukno.github.io`
3. Remove any other A records or CNAME records that might be conflicting

## Step 4: Check for GoDaddy Website Builder

If you've ever used GoDaddy Website Builder:

1. Navigate to **My Products** → **Web Hosting** or **Website Builder**
2. Check if there's an active site for ibridgesolutions.co.za
3. If there is, either:
   - Disconnect it from your domain, or
   - Delete the website if you're not using it

## Step 5: Verify Domain Connection Settings

In GitHub Pages:

1. Go to your repository → **Settings** → **Pages**
2. Make sure Custom Domain is set to `ibridgesolutions.co.za`
3. If you had to change any settings, wait for GitHub to verify the domain (may take a few hours)

## Common GoDaddy Issues with GitHub Pages

1. **"Under Construction" or "Coming Soon" pages**: GoDaddy often shows these by default
   - Solution: Turn off "Temporary pages" or "Parked page" in your domain settings

2. **GoDaddy Forward-Only Hosting**: Sometimes GoDaddy activates a basic hosting plan
   - Solution: Make sure your domain is only using DNS services, not hosting

3. **GoDaddy Website Redirect Service**: Check if you have this service activated
   - Solution: Disable any redirect service in your GoDaddy dashboard

These steps should resolve the redirection to /lander which is most likely caused by GoDaddy's default settings rather than an issue in your website code.
