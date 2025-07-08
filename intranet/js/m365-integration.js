/**
 * Microsoft 365 Integration for iBridge Intranet
 * This script handles Microsoft Graph API integration and data fetching
 */

// Global settings
let intranetSettings = null;
let isDevMode = false;
let isAdmin = false;
let currentUser = null;

// Initialize M365 integration
document.addEventListener('DOMContentLoaded', async function() {
    console.log("Initializing Microsoft 365 Integration...");
    
    try {
        // Load settings
        await loadSettings();
        
        // Check dev mode and current user
        checkDevMode();
        
        // If using M365 data in dev mode, set up the interface
        if (intranetSettings.devMode && intranetSettings.useM365Data) {
            setupDevModeInterface();
        }
    } catch (error) {
        console.error("Error initializing M365 integration:", error);
    }
});

/**
 * Load intranet settings
 */
async function loadSettings() {
    try {
        const response = await fetch('/data/settings.json');
        intranetSettings = await response.json();
        console.log("Settings loaded:", intranetSettings);
    } catch (error) {
        console.error("Error loading settings:", error);
        throw error;
    }
}

/**
 * Check if dev mode is enabled and if current user is an admin
 */
function checkDevMode() {
    isDevMode = intranetSettings?.devMode || false;
    
    // Get current user from session storage or default to admin in dev mode
    const userJson = sessionStorage.getItem('currentUser');
    if (userJson) {
        currentUser = JSON.parse(userJson);
    } else if (isDevMode) {
        // In dev mode, default to the first admin user
        currentUser = {
            email: intranetSettings.adminUsers[0],
            isAdmin: true
        };
        sessionStorage.setItem('currentUser', JSON.stringify(currentUser));
    }
    
    // Check if current user is an admin
    isAdmin = currentUser && intranetSettings.adminUsers.includes(currentUser.email);
    
    console.log("Dev mode:", isDevMode);
    console.log("Current user:", currentUser);
    console.log("Is admin:", isAdmin);
}

/**
 * Set up dev mode interface elements
 */
function setupDevModeInterface() {
    // Add dev mode indicator to the page
    const devModeIndicator = document.createElement('div');
    devModeIndicator.className = 'dev-mode-indicator';
    devModeIndicator.innerHTML = 'DEV MODE';
    document.body.appendChild(devModeIndicator);
    
    // Add dev mode styles
    const devModeStyle = document.createElement('style');
    devModeStyle.textContent = `
        .dev-mode-indicator {
            position: fixed;
            bottom: 10px;
            right: 10px;
            background-color: rgba(255, 0, 0, 0.7);
            color: white;
            padding: 5px 10px;
            font-size: 12px;
            font-weight: bold;
            z-index: 9999;
            border-radius: 4px;
        }
        
        .admin-controls {
            background-color: #f8f9fa;
            border: 1px solid #ddd;
            border-radius: 5px;
            padding: 15px;
            margin-bottom: 20px;
        }
        
        .admin-only {
            display: block !important;
        }
    `;
    document.head.appendChild(devModeStyle);
    
    // Add admin controls if user is an admin
    if (isAdmin) {
        setupAdminControls();
    }
}

/**
 * Set up admin controls for admin users
 */
function setupAdminControls() {
    // Show admin panel link
    const adminElements = document.querySelectorAll('.admin-only');
    adminElements.forEach(el => {
        el.style.display = 'block';
    });
    
    // Add refresh data button on relevant pages
    if (window.location.pathname.includes('directory.html') ||
        window.location.pathname.includes('company.html')) {
        
        const controlsContainer = document.createElement('div');
        controlsContainer.className = 'admin-controls';
        controlsContainer.innerHTML = `
            <h4>Admin Controls (Dev Mode)</h4>
            <p>Current user: ${currentUser.email} (Admin)</p>
            <button class="btn btn-primary refresh-data-btn">
                <i class="fas fa-sync-alt"></i> Refresh Data from M365
            </button>
        `;
        
        // Insert at the beginning of main content
        const mainContent = document.querySelector('.main-content') || document.querySelector('main');
        if (mainContent?.firstChild) {
            mainContent.insertBefore(controlsContainer, mainContent.firstChild);
        }
        
        // Add event listener
        document.querySelector('.refresh-data-btn').addEventListener('click', function() {
            simulateM365DataRefresh();
        });
    }
}

/**
 * Simulate data refresh from Microsoft 365
 * In a real implementation, this would use Microsoft Graph API
 */
function simulateM365DataRefresh() {
    const loadingToast = showToast("Refreshing data from Microsoft 365...", "info");
    
    // Simulate API call delay
    setTimeout(() => {
        dismissToast(loadingToast);
        showToast("Data successfully refreshed from Microsoft 365", "success");
        
        // Reload the page to show refreshed data
        setTimeout(() => {
            window.location.reload();
        }, 1500);
    }, 2000);
}

/**
 * Show toast notification
 */
function showToast(message, type = 'info') {
    const toast = document.createElement('div');
    toast.className = `toast toast-${type}`;
    toast.innerHTML = `
        <div class="toast-content">
            <i class="fas ${type === 'success' ? 'fa-check-circle' : 'fa-info-circle'}"></i>
            <span>${message}</span>
        </div>
    `;
    
    const toastContainer = document.querySelector('.toast-container');
    if (!toastContainer) {
        const newContainer = document.createElement('div');
        newContainer.className = 'toast-container';
        document.body.appendChild(newContainer);
        newContainer.appendChild(toast);
    } else {
        toastContainer.appendChild(toast);
    }
    
    // Add styles if not already present
    if (!document.getElementById('toast-styles')) {
        const style = document.createElement('style');
        style.id = 'toast-styles';
        style.textContent = `
            .toast-container {
                position: fixed;
                top: 20px;
                right: 20px;
                z-index: 9999;
            }
            .toast {
                background: white;
                border-radius: 4px;
                box-shadow: 0 2px 10px rgba(0,0,0,0.1);
                margin-bottom: 10px;
                min-width: 250px;
                max-width: 350px;
                overflow: hidden;
                animation: slide-in 0.3s ease-out;
            }
            .toast-content {
                padding: 12px 15px;
                display: flex;
                align-items: center;
            }
            .toast i {
                margin-right: 10px;
            }
            .toast-success {
                border-left: 4px solid #28a745;
            }
            .toast-info {
                border-left: 4px solid #17a2b8;
            }
            .toast-warning {
                border-left: 4px solid #ffc107;
            }
            .toast-error {
                border-left: 4px solid #dc3545;
            }
            @keyframes slide-in {
                from { transform: translateX(100%); opacity: 0; }
                to { transform: translateX(0); opacity: 1; }
            }
        `;
        document.head.appendChild(style);
    }
    
    setTimeout(() => {
        dismissToast(toast);
    }, 5000);
    
    return toast;
}

/**
 * Dismiss toast notification
 */
function dismissToast(toast) {
    toast.style.opacity = '0';
    toast.style.transform = 'translateX(100%)';
    toast.style.transition = 'opacity 0.3s ease, transform 0.3s ease';
    
    setTimeout(() => {
        if (toast.parentNode) {
            toast.parentNode.removeChild(toast);
        }
    }, 300);
}
