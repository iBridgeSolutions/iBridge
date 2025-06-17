# iBridge Website

This is the consolidated structure for the iBridge website providing BPO & BPaaS solutions.

## Folder Structure

- `css/`: Contains the stylesheet files
- `images/`: Contains the image files used across the website
- `js/`: Contains JavaScript files
- `partials/`: Contains reusable header and footer components
- `deployment-instructions.md`: Instructions for general website deployment
- `github-deployment-guide.md`: Specific instructions for GitHub Pages deployment
- `deploy-github.bat`: Easy deployment script for GitHub Pages

## Key Features

- Consistent header and footer across all pages, loaded dynamically via JavaScript
- Modern responsive design
- Valid HTML5 and CSS3
- Dedicated pages for specific services

## Pages

- `index.html`: Home page
- `about.html`: About page
- `services.html`: Services overview page
- `contact-center.html`: Dedicated page for Contact Center Solutions
- `it-support.html`: Dedicated page for IT Support & Cloud Services
- `ai-automation.html`: Dedicated page for AI & Automation
- `contact.html`: Contact page

## Development

This project uses vanilla HTML, CSS, and JavaScript. To run locally, simply open any HTML file in your browser or use Live Server in VS Code.

## Deployment Options

The website can be deployed in multiple ways:

1. **Traditional Web Hosting**: Follow instructions in `deployment-instructions.md`
2. **GitHub Pages**: Use `deploy-github.bat` or follow the steps in `github-deployment-guide.md`

### Quick GitHub Deployment

To quickly deploy to GitHub Pages:
1. Double-click on `deploy-github.bat` or run `.\deploy-to-github.ps1` in PowerShell
2. Enter your GitHub username when prompted
3. The script will create a repository and set up GitHub Pages automatically

## VS Code Setup

Open the `iBridge.code-workspace` file in VS Code to ensure all the recommended extensions and settings are applied.
