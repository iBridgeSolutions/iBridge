# GitHub Pages Deployment Guide for iBridge Website

This guide provides step-by-step instructions for deploying the iBridge website to GitHub Pages.

## Option 1: Using the Automated Script

The easiest way to deploy is using the included PowerShell script:

1. Open PowerShell as an administrator
2. Navigate to the iBridge-consolidated folder:
   ```powershell
   cd "c:\Users\Lwandile Gasela\Downloads\iBridge-consolidated"
   ```
3. Run the GitHub deployment script:
   ```powershell
   .\deploy-to-github.ps1
   ```
4. Follow the on-screen instructions, providing your GitHub username when prompted
5. The script will:
   - Create a new GitHub repository
   - Upload all necessary website files
   - Configure GitHub Pages for hosting
   - Provide you with the public URL for your website

## Option 2: Manual Deployment

If you prefer to deploy manually:

### Prerequisites

- [Git](https://git-scm.com/downloads) installed on your computer
- A GitHub account

### Step 1: Create a GitHub Repository

1. Log in to [GitHub](https://github.com/)
2. Click the "+" icon in the top-right corner and select "New repository"
3. Name your repository (e.g., "iBridge")
4. Choose "Public" visibility
5. Do not initialize the repository with any files
6. Click "Create repository"

### Step 2: Prepare Your Local Files

1. Open Command Prompt or PowerShell
2. Navigate to your consolidated iBridge website folder:
   ```
   cd "c:\Users\Lwandile Gasela\Downloads\iBridge-consolidated"
   ```
3. Initialize a Git repository:
   ```
   git init
   ```
4. Create a `.gitignore` file with the following content:
   ```
   # Windows-specific files
   Thumbs.db
   desktop.ini

   # Development files
   *.ps1
   *.bat
   *.code-workspace
   *.md
   !README.md

   # IDE-specific files
   .vscode/
   .idea/
   ```
5. Stage all your files:
   ```
   git add .
   ```
6. Commit the files:
   ```
   git commit -m "Initial commit of iBridge website"
   ```

### Step 3: Push to GitHub

1. Add your GitHub repository as a remote:
   ```
   git remote add origin https://github.com/YOUR-USERNAME/YOUR-REPOSITORY.git
   ```
   (Replace `YOUR-USERNAME` and `YOUR-REPOSITORY` with your GitHub username and repository name)

2. Push your files to GitHub:
   ```
   git branch -M main
   git push -u origin main
   ```

### Step 4: Configure GitHub Pages

1. Go to your repository on GitHub
2. Click on "Settings"
3. In the left sidebar, click on "Pages"
4. Under "Source", select "main" branch and root folder (/)
5. Click "Save"
6. Wait a few minutes for deployment to complete
7. Your website will be available at `https://YOUR-USERNAME.github.io/YOUR-REPOSITORY/`

## Verifying Your Deployment

After deployment, verify that:

1. Your website is accessible at the GitHub Pages URL
2. All pages load correctly
3. All images and styles are displaying properly
4. All links work correctly
5. The site is responsive across different devices

## Troubleshooting

If you encounter issues with your GitHub Pages deployment:

1. **404 Error**: Make sure your repository is public and GitHub Pages is correctly enabled
2. **Missing Images/CSS**: Check relative paths in your HTML files
3. **Custom Domain Issues**: If using a custom domain, ensure DNS records are properly configured
4. **Deployment Delays**: GitHub Pages may take a few minutes to update after pushing changes

## Updating Your Website

To update your website after making changes:

1. Make your changes to the local files
2. Stage the changes:
   ```
   git add .
   ```
3. Commit the changes:
   ```
   git commit -m "Update website with [description of changes]"
   ```
4. Push to GitHub:
   ```
   git push
   ```
5. GitHub Pages will automatically update with your changes
