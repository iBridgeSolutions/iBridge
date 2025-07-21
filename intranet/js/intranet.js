/**
 * iBridge Intranet - Main JavaScript
 */

document.addEventListener('DOMContentLoaded', function() {
    // Check authentication state first
    if (!checkAuthentication()) {
        return; // Stop execution if not authenticated
    }
    
    // Load user information
    loadUserInfo();
    
    // Load header and footer
    loadPartials();
    
    // Set active navigation link
    setActiveNavLink();
    
    // Initialize components
    initializeComponents();
    
    // Initialize profile page if on profile.html
    if (window.location.pathname.includes('profile.html')) {
        initProfilePage();
    }
    
    // Initialize preferences page if on preferences.html
    if (window.location.pathname.includes('preferences.html')) {
        initPreferencesPage();
    }
    
    // Initialize admin panel if on admin-panel.html
    if (window.location.pathname.includes('admin-panel.html')) {
        initAdminPanel();
    }
    
    // Initialize security features if on security.html
    if (window.location.pathname.includes('security.html')) {
        initializeSecurityFeatures();
    }
});

/**
 * Check if user is authenticated
 * Redirects to login page if not authenticated
 */
function checkAuthentication() {
    // Skip auth check on login page and debug pages
    const currentPath = window.location.pathname.toLowerCase();
    if (currentPath.includes('login.html') || 
        currentPath.includes('session-debug.html') || 
        currentPath.includes('auth-fixer.html')) {
        console.log("On login or debug page - skipping authentication check");
        return true;
    }
    
    console.log("Checking authentication status...");
    
    try {
        // Use security manager to validate session
        if (!window.securityManager.validateSession()) {
            const loginPath = window.location.origin + (window.location.pathname.includes('/intranet/') ? '/intranet/login.html' : '/login.html');
            console.log("No valid session found. Redirecting to:", loginPath);
            window.location.replace(loginPath);
            return false;
        }

        return true;
    } catch (e) {
        console.error("Error checking authentication:", e);
        window.location.replace(window.location.origin + (window.location.pathname.includes('/intranet/') ? '/intranet/login.html' : '/login.html'));
        return false;
    }
}

/**
 * Load user information into the sidebar user info section
 */
function loadUserInfo() {
    // Check for both old and new authentication formats
    let userData = null;
    
    // Try to load from secure session
    const secureSession = sessionStorage.getItem('secureSession');
    if (secureSession) {
        const sessionData = JSON.parse(secureSession);
        userData = sessionData.user;
        console.log("Loading user info from secure session:", userData);
    } else {
        // Fall back to legacy format if needed
        userData = JSON.parse(sessionStorage.getItem('user') || '{}');
        console.log("Loading user info from legacy system:", userData);
    }
    
    // Find user info elements if they exist
    const userNameElement = document.querySelector('.user-name');
    const userRoleElement = document.querySelector('.user-role');
    
    // Handle different user data formats
    const userName = userData.displayName || userData.name || '';
    const isAdmin = userData.permissions?.isAdmin || userData.isAdmin || false;
    
    if (userNameElement && userName) {
        // Extract first name
        const firstName = userName.split(' ')[0];
        userNameElement.textContent = userName;
        
        // Add greeting to the dashboard if on index page
        if (window.location.pathname.endsWith('index.html') || window.location.pathname.endsWith('/intranet/')) {
            const greeting = document.querySelector('.greeting-name');
            if (greeting) {
                greeting.textContent = firstName;
            }
        }
    }
    
    if (userRoleElement) {
        let roleText = "Staff Member";
        if (isAdmin) {
            roleText = "Administrator";
        } else if (userData.position) {
            roleText = userData.position; // Use position from custom auth if available
        }
        userRoleElement.textContent = roleText;
    }
    
    // Add admin indicator if the user is an admin
    if (isAdmin) {
        document.body.classList.add('is-admin');
        
        // Show admin-only elements
        const adminElements = document.querySelectorAll('.admin-only');
        adminElements.forEach(el => {
            if (el.tagName === 'BUTTON' || el.tagName === 'A') {
                el.style.display = 'inline-block';
            } else {
                el.style.display = 'block';
            }
        });
        
        // Show admin menu items
        const adminMenuItems = document.querySelectorAll('.sidebar-menu-item--admin');
        adminMenuItems.forEach(item => {
            item.style.display = 'block';
        });
    }
}

// Add logout function
window.logout = function() {
    console.log("Logging out user...");
    
    // Clear all session storage
    sessionStorage.removeItem('user');
    sessionStorage.removeItem('secureSession');
    sessionStorage.removeItem('portalUser');
    
    // Clear authentication cookie required by .htaccess
    document.cookie = "user_authenticated=; path=/intranet/; expires=Thu, 01 Jan 1970 00:00:00 UTC; SameSite=Strict";
    console.log("Authentication cookie cleared");
    
    // Redirect to login page using absolute path
    const loginUrl = window.location.origin + (window.location.pathname.includes('/intranet/') ? '/intranet/login.html' : '/login.html');
    console.log("Redirecting to:", loginUrl);
    window.location.replace(loginUrl);
};

/**
 * Load header and footer partials
 */
function loadPartials() {
    // Base URL for partials - handle both root-level and subfolder URLs
    const basePath = window.location.pathname.includes('/intranet/') ? 
        window.location.origin + '/intranet/' : 
        './';
    console.log("Loading partials from base path:", basePath);
    
    // Load header
    const headerPlaceholder = document.getElementById('header-placeholder');
    if (headerPlaceholder) {
        fetch(basePath + 'partials/header.html')
            .then(response => {
                if (!response.ok) {
                    throw new Error('Failed to load header: ' + response.status);
                }
                return response.text();
            })
            .then(data => {
                headerPlaceholder.innerHTML = data;
                // After header is loaded, set active nav link
                setActiveNavLink();
            })
            .catch(error => {
                console.error('Error loading header:', error);
                headerPlaceholder.innerHTML = '<header class="intranet-header"><div class="container"><p>Error loading header</p></div></header>';
            });
    }
    
    // Load footer
    const footerPlaceholder = document.getElementById('footer-placeholder');
    if (footerPlaceholder) {
        fetch(basePath + 'partials/footer.html')
            .then(response => {
                if (!response.ok) {
                    throw new Error('Failed to load footer: ' + response.status);
                }
                return response.text();
            })
            .then(data => {
                footerPlaceholder.innerHTML = data;
            })
            .catch(error => {
                console.error('Error loading footer:', error);
                footerPlaceholder.innerHTML = '<footer class="footer"><div class="container"><p>Error loading footer</p></div></footer>';
            });
    }
}

/**
 * Set active navigation link based on current page
 */
function setActiveNavLink() {
    // Wait for the navigation to be loaded
    setTimeout(() => {
        const currentPage = window.location.pathname.split('/').pop() || 'index.html';
        const navLinks = document.querySelectorAll('.intranet-nav-link');
        
        navLinks.forEach(link => {
            const href = link.getAttribute('href');
            if (href === currentPage || 
                (currentPage === 'index.html' && href === 'index.html') ||
                (href !== 'index.html' && currentPage.includes(href.split('.')[0]))) {
                link.classList.add('active');
            }
        });
    }, 100);
}

/**
 * Initialize various components on the page
 */
function initializeComponents() {
    // Initialize search functionality
    initSearch();
    
    // Initialize category filters on news page
    initCategoryFilters();
    
    // Initialize team directory filters
    initTeamFilters();
    
    // Add click handlers for accordion elements
    initAccordions();
    
    // Initialize tooltips
    initTooltips();
    
    // Initialize charts on dashboard if present
    initDashboardCharts();
    
    // Initialize announcement form for admins
    if (isUserAdmin()) {
        initAnnouncementForm();
    }
}

/**
 * Initialize search functionality across the intranet
 */
function initSearch() {
    const searchBox = document.getElementById('intranet-search');
    const searchResults = document.getElementById('search-results');
    
    if (!searchBox) return;
    
    searchBox.addEventListener('input', debounce(function() {
        const query = this.value.trim();
        
        if (query.length < 2) {
            if (searchResults) {
                searchResults.innerHTML = '';
                searchResults.classList.remove('active');
            }
            return;
        }
        
        // Perform search
        searchIntranet(query);
    }, 300));
    
    // Close search results when clicking outside
    document.addEventListener('click', function(e) {
        if (searchResults && !searchBox.contains(e.target) && !searchResults.contains(e.target)) {
            searchResults.classList.remove('active');
        }
    });
}

/**
 * Search across the intranet content
 */
function searchIntranet(query) {
    const searchResults = document.getElementById('search-results');
    if (!searchResults) return;
    
    // In a real implementation, this would make an API call
    // For now, we'll just show some mock results
    const mockResults = [
        {
            title: 'Employee Handbook',
            type: 'document',
            url: 'resources.html#employee-handbook',
            excerpt: 'The official iBridge employee handbook with company policies and procedures.'
        },
        {
            title: 'New Microsoft Teams Integration',
            type: 'news',
            url: 'news.html#news-1',
            excerpt: 'Integration with Microsoft Teams starting next month...'
        },
        {
            title: 'IT Support Team',
            type: 'team',
            url: 'teams.html#it-team',
            excerpt: 'The IT support team provides technical assistance for all employees.'
        }
    ];
    
    // Filter mock results by query
    const filteredResults = mockResults.filter(result => 
        result.title.toLowerCase().includes(query.toLowerCase()) || 
        result.excerpt.toLowerCase().includes(query.toLowerCase())
    );
    
    // Display results
    searchResults.innerHTML = '';
    
    if (filteredResults.length === 0) {
        searchResults.innerHTML = '<div class="search-no-results">No results found</div>';
    } else {
        filteredResults.forEach(result => {
            const resultElement = document.createElement('div');
            resultElement.className = 'search-result-item';
            resultElement.innerHTML = `
                <a href="${result.url}">
                    <div class="search-result-title">${result.title}</div>
                    <div class="search-result-type">${result.type}</div>
                    <div class="search-result-excerpt">${result.excerpt}</div>
                </a>
            `;
            searchResults.appendChild(resultElement);
        });
    }
    
    searchResults.classList.add('active');
}

/**
 * Initialize news category filters
 */
function initCategoryFilters() {
    const newsCategory = document.getElementById('newsCategory');
    const newsItems = document.querySelectorAll('.news-grid-item, .featured-news-card');
    
    if (newsCategory && newsItems.length > 0) {
        newsCategory.addEventListener('change', function() {
            const category = this.value;
            
            newsItems.forEach(item => {
                const itemCategory = item.querySelector('.news-category');
                
                if (category === 'all' || (itemCategory && itemCategory.classList.contains(category))) {
                    item.style.display = '';
                } else {
                    item.style.display = 'none';
                }
            });
        });
    }
    
    // Initialize sort functionality
    const newsSort = document.getElementById('newsSort');
    
    if (newsSort && newsItems.length > 0) {
        newsSort.addEventListener('change', function() {
            // In a real implementation, this would re-sort the news items
            // For this demo, we'll just show a message
            console.log('Sorting news by: ' + this.value);
        });
    }
}

/**
 * Initialize tooltips
 */
function initTooltips() {
    const tooltips = document.querySelectorAll('[data-tooltip]');
    
    tooltips.forEach(tooltip => {
        tooltip.addEventListener('mouseenter', function() {
            const tooltipText = this.getAttribute('data-tooltip');
            
            const tooltipElement = document.createElement('div');
            tooltipElement.className = 'tooltip';
            tooltipElement.textContent = tooltipText;
            
            document.body.appendChild(tooltipElement);
            
            const rect = this.getBoundingClientRect();
            tooltipElement.style.top = (rect.top - tooltipElement.offsetHeight - 10) + 'px';
            tooltipElement.style.left = (rect.left + (rect.width / 2) - (tooltipElement.offsetWidth / 2)) + 'px';
            tooltipElement.classList.add('active');
            
            this.addEventListener('mouseleave', function() {
                tooltipElement.remove();
            }, { once: true });
        });
    });
}

/**
 * Initialize chart visualizations on dashboard
 */
function initDashboardCharts() {
    // This would use a chart library like Chart.js in a real implementation
    // For this demo, we'll just add a placeholder message
    const chartContainers = document.querySelectorAll('.chart-container');
    
    if (chartContainers.length > 0) {
        chartContainers.forEach(container => {
            container.innerHTML = '<div class="chart-placeholder">Chart visualization would appear here</div>';
        });
    }
}

/**
 * Initialize the announcement form for admins
 */
function initAnnouncementForm() {
    const announcementForm = document.getElementById('announcement-form');
    
    if (announcementForm) {
        announcementForm.addEventListener('submit', function(e) {
            e.preventDefault();
            
            const title = this.querySelector('#announcement-title').value;
            const content = this.querySelector('#announcement-content').value;
            
            if (title && content) {
                // In a real implementation, this would submit to a server
                // For this demo, we'll just show a success message
                showNotification('Announcement posted successfully!', 'success');
                this.reset();
            } else {
                showNotification('Please fill in all fields', 'error');
            }
        });
    }
}

/**
 * Show notification message
 */
function showNotification(message, type = 'info') {
    const notification = document.createElement('div');
    notification.className = `notification ${type}`;
    notification.innerHTML = `
        <div class="notification-content">
            <span>${message}</span>
            <button class="notification-close">&times;</button>
        </div>
    `;
    
    document.body.appendChild(notification);
    
    // Add active class after a small delay to trigger animation
    setTimeout(() => {
        notification.classList.add('active');
    }, 10);
    
    // Close button functionality
    notification.querySelector('.notification-close').addEventListener('click', function() {
        notification.classList.remove('active');
        setTimeout(() => {
            notification.remove();
        }, 300);
    });
    
    // Auto-remove after 5 seconds
    setTimeout(() => {
        notification.classList.remove('active');
        setTimeout(() => {
            notification.remove();
        }, 300);
    }, 5000);
}

/**
 * Check if the current user is an admin
 */
function isUserAdmin() {
    const userData = JSON.parse(sessionStorage.getItem('user') || '{}');
    return userData.isAdmin === true;
}

/**
 * Simple debounce function to limit function calls
 */
function debounce(func, wait) {
    let timeout;
    return function(...args) {
        const context = this;
        clearTimeout(timeout);
        timeout = setTimeout(() => func.apply(context, args), wait);
    };
}

/**
 * Initialize the profile page functionality
 */
function initProfilePage() {
    console.log('Initializing profile page');
    const userData = JSON.parse(sessionStorage.getItem('user') || '{}');
    
    // Populate user data in profile form
    const nameField = document.getElementById('profile-name');
    const emailField = document.getElementById('profile-email');
    const jobTitleField = document.getElementById('profile-job-title');
    const departmentField = document.getElementById('profile-department');
    const userAvatar = document.getElementById('profile-avatar');
    
    if (nameField && userData.name) {
        nameField.value = userData.name;
    }
    
    if (emailField && userData.username) {
        emailField.value = userData.username;
    }
    
    // Handle form submission
    const profileForm = document.getElementById('profile-form');
    if (profileForm) {
        profileForm.addEventListener('submit', function(e) {
            e.preventDefault();
            
            // Display success message
            const alert = document.createElement('div');
            alert.className = 'alert alert-success alert-dismissible fade show';
            alert.innerHTML = `
                <strong>Success!</strong> Your profile has been updated.
                <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
            `;
            
            profileForm.prepend(alert);
            
            // In a real implementation, this would save to a database
            // For demo, we'll update the session storage
            const updatedUserData = {
                ...userData,
                name: nameField.value,
                department: departmentField.value,
                jobTitle: jobTitleField.value
            };
            
            sessionStorage.setItem('user', JSON.stringify(updatedUserData));
            
            // Auto-dismiss the alert after 3 seconds
            setTimeout(() => {
                alert.classList.remove('show');
                setTimeout(() => alert.remove(), 300);
            }, 3000);
        });
    }
    
    // Handle avatar change
    const avatarInput = document.getElementById('avatar-upload');
    if (avatarInput && userAvatar) {
        avatarInput.addEventListener('change', function(e) {
            const file = e.target.files[0];
            if (file && file.type.match('image.*')) {
                const reader = new FileReader();
                reader.onload = function(e) {
                    userAvatar.src = e.target.result;
                    
                    // In a real implementation, this would upload to a server
                    // For demo, store in session storage
                    sessionStorage.setItem('userAvatar', e.target.result);
                };
                reader.readAsDataURL(file);
            }
        });
    }
}

/**
 * Initialize the preferences page functionality
 */
function initPreferencesPage() {
    console.log('Initializing preferences page');
    
    // Load saved preferences from localStorage
    const savedPreferences = JSON.parse(localStorage.getItem('userPreferences') || '{}');
    
    // Theme preference
    const themeOptions = document.querySelectorAll('input[name="theme"]');
    if (themeOptions.length && savedPreferences.theme) {
        themeOptions.forEach(option => {
            if (option.value === savedPreferences.theme) {
                option.checked = true;
            }
        });
    }
    
    // Notification preferences
    const emailNotifications = document.getElementById('email-notifications');
    if (emailNotifications && savedPreferences.emailNotifications !== undefined) {
        emailNotifications.checked = savedPreferences.emailNotifications;
    }
    
    const browserNotifications = document.getElementById('browser-notifications');
    if (browserNotifications && savedPreferences.browserNotifications !== undefined) {
        browserNotifications.checked = savedPreferences.browserNotifications;
    }
    
    // Widget preferences
    const newsWidget = document.getElementById('news-widget');
    if (newsWidget && savedPreferences.newsWidget !== undefined) {
        newsWidget.checked = savedPreferences.newsWidget;
    }
    
    const calendarWidget = document.getElementById('calendar-widget');
    if (calendarWidget && savedPreferences.calendarWidget !== undefined) {
        calendarWidget.checked = savedPreferences.calendarWidget;
    }
    
    const resourcesWidget = document.getElementById('resources-widget');
    if (resourcesWidget && savedPreferences.resourcesWidget !== undefined) {
        resourcesWidget.checked = savedPreferences.resourcesWidget;
    }
    
    // Language preference
    const languageSelect = document.getElementById('language-preference');
    if (languageSelect && savedPreferences.language) {
        languageSelect.value = savedPreferences.language;
    }
    
    // Handle form submission
    const preferencesForm = document.getElementById('preferences-form');
    if (preferencesForm) {
        preferencesForm.addEventListener('submit', function(e) {
            e.preventDefault();
            
            // Gather all preferences
            const preferences = {
                theme: document.querySelector('input[name="theme"]:checked')?.value || 'light',
                emailNotifications: emailNotifications?.checked || false,
                browserNotifications: browserNotifications?.checked || false,
                newsWidget: newsWidget?.checked || false,
                calendarWidget: calendarWidget?.checked || false,
                resourcesWidget: resourcesWidget?.checked || false,
                language: languageSelect?.value || 'en'
            };
            
            // Save to localStorage
            localStorage.setItem('userPreferences', JSON.stringify(preferences));
            
            // Apply theme if changed
            if (preferences.theme !== savedPreferences.theme) {
                applyTheme(preferences.theme);
            }
            
            // Show success message
            const alert = document.createElement('div');
            alert.className = 'alert alert-success alert-dismissible fade show';
            alert.innerHTML = `
                <strong>Success!</strong> Your preferences have been saved.
                <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
            `;
            
            preferencesForm.prepend(alert);
            
            // Auto-dismiss the alert after 3 seconds
            setTimeout(() => {
                alert.classList.remove('show');
                setTimeout(() => alert.remove(), 300);
            }, 3000);
        });
    }
}

/**
 * Apply theme based on user preference
 */
function applyTheme(theme) {
    if (theme === 'dark') {
        document.body.classList.add('dark-theme');
        document.body.classList.remove('light-theme');
    } else if (theme === 'light') {
        document.body.classList.add('light-theme');
        document.body.classList.remove('dark-theme');
    } else if (theme === 'system') {
        // Check system preference
        if (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches) {
            document.body.classList.add('dark-theme');
            document.body.classList.remove('light-theme');
        } else {
            document.body.classList.add('light-theme');
            document.body.classList.remove('dark-theme');
        }
    }
}

/**
 * Initialize the admin panel functionality
 */
function initAdminPanel() {
    console.log('Initializing admin panel');
    const userData = JSON.parse(sessionStorage.getItem('user') || '{}');
    
    // Only allow access if user is admin
    if (!userData.isAdmin) {
        // Redirect to dashboard with error message
        sessionStorage.setItem('errorMessage', 'You do not have permission to access the admin panel');
        window.location.href = 'index.html';
        return;
    }
    
    // Handle tab switching
    const tabLinks = document.querySelectorAll('.admin-nav-tabs .nav-link');
    const tabContents = document.querySelectorAll('.tab-pane');
    
    tabLinks.forEach(link => {
        link.addEventListener('click', function(e) {
            e.preventDefault();
            
            // Remove active class from all tabs
            tabLinks.forEach(tab => tab.classList.remove('active'));
            tabContents.forEach(content => content.classList.remove('show', 'active'));
            
            // Add active class to clicked tab
            this.classList.add('active');
            
            // Show corresponding content
            const target = document.querySelector(this.getAttribute('href'));
            if (target) {
                target.classList.add('show', 'active');
            }
        });
    });
    
    // Handle user management
    initUserManagement();
    
    // Handle content management
    initContentManagement();
    
    // Initialize system logs
    initSystemLogs();
}

/**
 * Initialize user management in admin panel
 */
function initUserManagement() {
    const userStatusToggles = document.querySelectorAll('.user-status-toggle');
    
    userStatusToggles.forEach(toggle => {
        toggle.addEventListener('change', function() {
            const userId = this.getAttribute('data-user-id');
            const isActive = this.checked;
            
            console.log(`User ${userId} status changed to ${isActive ? 'active' : 'inactive'}`);
            
            // Show notification
            showAdminNotification('User status updated successfully');
        });
    });
}

/**
 * Initialize content management in admin panel
 */
function initContentManagement() {
    const contentForm = document.getElementById('content-form');
    
    if (contentForm) {
        contentForm.addEventListener('submit', function(e) {
            e.preventDefault();
            
            // Show notification
            showAdminNotification('Content saved successfully');
            
            // Reset form
            this.reset();
        });
    }
}

/**
 * Initialize system logs in admin panel
 */
function initSystemLogs() {
    const logLevelFilter = document.getElementById('log-level-filter');
    const logEntries = document.querySelectorAll('.log-entry');
    
    if (logLevelFilter) {
        logLevelFilter.addEventListener('change', function() {
            const level = this.value;
            
            logEntries.forEach(entry => {
                const entryLevel = entry.getAttribute('data-level');
                
                if (level === 'all' || entryLevel === level) {
                    entry.style.display = '';
                } else {
                    entry.style.display = 'none';
                }
            });
        });
    }
}

/**
 * Show notification in admin panel
 */
function showAdminNotification(message) {
    const notification = document.createElement('div');
    notification.className = 'admin-notification';
    notification.textContent = message;
    
    document.body.appendChild(notification);
    
    setTimeout(() => {
        notification.classList.add('show');
    }, 10);
    
    setTimeout(() => {
        notification.classList.remove('show');
        setTimeout(() => notification.remove(), 300);
    }, 3000);
}

/**
 * Initialize security features on the security page
 */
function initializeSecurityFeatures() {
    // Password strength checker
    const newPasswordInput = document.getElementById('newPassword');
    const confirmPasswordInput = document.getElementById('confirmPassword');
    const progressBar = document.querySelector('.password-strength .progress-bar');
    const savePasswordBtn = document.getElementById('savePasswordBtn');
    const passwordError = document.getElementById('passwordError');

    if (newPasswordInput) {
        newPasswordInput.addEventListener('input', function() {
            const result = window.securityManager.checkPasswordStrength(this.value);
            updatePasswordStrengthIndicator(progressBar, result);
            
            // Show feedback
            const feedback = document.querySelector('.password-strength small');
            if (feedback) {
                feedback.textContent = result.feedback || result.isStrong ? 
                    'Password strength: Good' : 
                    'Password is not strong enough. ' + result.feedback;
            }
        });
    }

    if (savePasswordBtn) {
        savePasswordBtn.addEventListener('click', async function() {
            const newPassword = newPasswordInput.value;
            const confirmPassword = confirmPasswordInput.value;

            if (newPassword !== confirmPassword) {
                showError(passwordError, 'Passwords do not match');
                return;
            }

            const strength = window.securityManager.checkPasswordStrength(newPassword);
            if (!strength.isStrong) {
                showError(passwordError, 'Password is not strong enough. ' + strength.feedback);
                return;
            }

            try {
                // Save new password
                const result = await window.customAuth.changePassword(newPassword);
                if (result.success) {
                    window.securityManager.logSecurityEvent('password_change', {
                        success: true
                    });
                    const modal = bootstrap.Modal.getInstance(document.getElementById('passwordChangeModal'));
                    modal.hide();
                    showToast('Password updated successfully', 'success');
                } else {
                    showError(passwordError, result.error);
                }
            } catch (error) {
                window.securityManager.logSecurityEvent('password_change', {
                    success: false,
                    error: error.message
                });
                showError(passwordError, 'Failed to update password. Please try again.');
            }
        });
    }

    // MFA handling
    const mfaCodeInput = document.getElementById('mfaCode');
    const verifyMfaBtn = document.getElementById('verifyMfaBtn');
    const mfaError = document.getElementById('mfaError');
    const resendMfaBtn = document.getElementById('resendMfaCode');

    if (mfaCodeInput) {
        mfaCodeInput.addEventListener('input', function() {
            // Only allow numbers and limit to 6 digits
            this.value = this.value.replace(/\D/g, '').substring(0, 6);
        });
    }

    if (verifyMfaBtn) {
        verifyMfaBtn.addEventListener('click', async function() {
            const code = mfaCodeInput.value;
            if (code.length !== 6) {
                showError(mfaError, 'Please enter a valid 6-digit code');
                return;
            }

            try {
                const result = await window.customAuth.verifyMfaCode(code);
                if (result.success) {
                    window.securityManager.logSecurityEvent('mfa_success', {
                        method: 'email'
                    });
                    // Hide MFA modal and redirect to dashboard
                    const modal = bootstrap.Modal.getInstance(document.getElementById('mfaModal'));
                    modal.hide();
                    window.location.href = 'index.html';
                } else {
                    window.securityManager.logSecurityEvent('mfa_failed', {
                        reason: result.error
                    });
                    showError(mfaError, result.error);
                }
            } catch (error) {
                window.securityManager.logSecurityEvent('mfa_error', {
                    error: error.message
                });
                showError(mfaError, 'Failed to verify code. Please try again.');
            }
        });
    }

    if (resendMfaBtn) {
        resendMfaBtn.addEventListener('click', async function(e) {
            e.preventDefault();
            try {
                await window.customAuth.resendMfaCode();
                window.securityManager.logSecurityEvent('mfa_resend', {
                    success: true
                });
                showToast('New verification code sent', 'success');
                startMfaTimer();
            } catch (error) {
                window.securityManager.logSecurityEvent('mfa_resend', {
                    success: false,
                    error: error.message
                });
                showToast('Failed to send new code', 'error');
            }
        });
    }
}

// Initialize security features
window.initializeSecurityFeatures = function() {
    // Add MFA timer initialization
    startMfaTimer();
    
    // Initialize other security features
    checkAuthentication();
};

/**
 * Update password strength indicator
 */
function updatePasswordStrengthIndicator(progressBar, strength) {
    if (!progressBar) return;
    
    const score = strength.score;
    let color, width;
    
    switch (score) {
        case 0:
            color = '#dc3545'; // red
            width = '20%';
            break;
        case 1:
            color = '#dc3545'; // red
            width = '20%';
            break;
        case 2:
            color = '#ffc107'; // yellow
            width = '40%';
            break;
        case 3:
            color = '#20c997'; // teal
            width = '60%';
            break;
        case 4:
            color = '#198754'; // green
            width = '80%';
            break;
        case 5:
            color = '#198754'; // green
            width = '100%';
            break;
    }
    
    progressBar.style.backgroundColor = color;
    progressBar.style.width = width;
}

/**
 * Start MFA verification timer
 */
function startMfaTimer() {
    const timerEl = document.getElementById('mfaTimer');
    if (!timerEl) return;
    
    const timeout = window.securityManager.config.session.mfaTimeout;
    let timeLeft = timeout * 60;
    
    const timer = setInterval(() => {
        const minutes = Math.floor(timeLeft / 60);
        const seconds = timeLeft % 60;
        timerEl.textContent = `${minutes}:${seconds.toString().padStart(2, '0')}`;
        
        if (--timeLeft < 0) {
            clearInterval(timer);
            const modal = bootstrap.Modal.getInstance(document.getElementById('mfaModal'));
            modal.hide();
            showToast('Verification code expired. Please try again.', 'error');
        }
    }, 1000);
}
