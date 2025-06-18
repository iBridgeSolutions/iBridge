# iBridge Website Management Guide

## Website Structure Overview

The iBridge website consists of the following key pages:

- `index.html` - Home page
- `about.html` - About Us page
- `services.html` - Main Services overview page
- `contact.html` - Contact information page
- `contact-center.html` - Dedicated Contact Center Solutions page
- `it-support.html` - Dedicated IT Support & Cloud Services page 
- `ai-automation.html` - Dedicated AI & Automation page

## Useful Scripts

This repository includes several useful scripts for managing and deploying the website:

### Preview Website
```
.\preview-website.ps1
```
Starts a local web server to preview the website before deploying. Opens the website in your default browser.

### Validate Contact Center Page
```
.\validate-contact-center.ps1
```
Validates that the Contact Center Solutions page is properly set up, with all links correctly pointing to the dedicated page.

### Deploy Website
```
.\github-aws-deploy.ps1
```
Combined script that handles:
1. Committing and pushing changes to GitHub
2. Deploying the website files to AWS S3
3. Invalidating the CloudFront cache to update the CDN

## Deployment Process

1. Make and test your changes locally using the preview script
2. Run the validation script if you've made changes to page structure or navigation
3. Deploy the changes using the deployment script

## AWS Deployment Details

The website is hosted on AWS using the following components:
- **S3 bucket**: `ibridgesolutions-website-6408258887118`
- **CloudFront distribution**: For CDN delivery (the script will help you select the right distribution)
- **Route 53**: For DNS management

## Common Tasks

### Adding a New Page
1. Create the new HTML file in the root directory
2. Update navigation links in all pages as needed
3. Preview and test the changes locally
4. Deploy using the deployment script

### Updating Content
1. Edit the relevant HTML files
2. Preview changes locally
3. Deploy using the deployment script

### Updating CSS or JavaScript
1. Make changes to files in the `css/` or `js/` directories
2. Preview and test locally
3. Deploy using the deployment script

## Contact

For questions or issues regarding website management, please contact the iBridge IT team.
