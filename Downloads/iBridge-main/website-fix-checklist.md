# iBridgeSolutions Website Fix Checklist

## DNS Configuration
- [ ] Log in to GoDaddy account
- [ ] Navigate to DNS settings for ibridgesolutions.co.za
- [ ] Delete existing A records (76.223.105.230, 13.248.243.5)
- [ ] Add A record: @ → 185.199.108.153
- [ ] Add A record: @ → 185.199.109.153
- [ ] Add A record: @ → 185.199.110.153
- [ ] Add A record: @ → 185.199.111.153
- [ ] Update CNAME record: www → ibridgesolutions.github.io

## GoDaddy Website Settings
- [ ] Disable any website redirect settings
- [ ] Turn off any "Coming Soon" page
- [ ] Make sure domain is not using GoDaddy hosting (only DNS)

## GitHub Pages Verification
- [ ] Ensure CNAME file contains only ibridgesolutions.co.za
- [ ] Ensure .nojekyll file exists in repository
- [ ] Check index.html has anti-redirect code

## Testing
- [ ] Wait 24-48 hours for DNS propagation
- [ ] Run simple-dns-check.ps1 to verify DNS settings
- [ ] Test https://ibridgesolutions.co.za 
- [ ] Test https://www.ibridgesolutions.co.za
- [ ] Verify no redirect to /lander is happening

## Additional Verification
- [ ] Use browser developer tools (F12) to check for redirect issues
- [ ] Clear browser cache and try in incognito mode
- [ ] Try accessing from a different device/network

## If Issues Persist
- [ ] Contact GoDaddy support
- [ ] Ask about hidden forwarding rules
- [ ] Check for any GoDaddy Website Builder products attached to domain
