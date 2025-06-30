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
    console.log("Current URL:", window.location.href);
    console.log("Current path:", window.location.pathname);
    
    try {
        // Check for multiple auth indicators - session and cookies
        const hasUserSession = !!sessionStorage.getItem('user');
        const hasAuthCookie = document.cookie.includes('user_authenticated=true');
        const hasBackupCookie = document.cookie.includes('intranet_session=active');
        
        console.log("Auth check - Session:", hasUserSession, "AuthCookie:", hasAuthCookie, "BackupCookie:", hasBackupCookie);
        
        // First scenario: No user session at all - clear redirect to login
        if (!hasUserSession && !hasAuthCookie && !hasBackupCookie) {
            console.error("No authentication found - redirecting to login");
            
            // Redirect to login with proper path handling
            const loginPath = window.location.origin + '/intranet/login.html';
            console.log("Redirecting to login:", loginPath);
            window.location.replace(loginPath);
            return false;
        }
        
        // Second scenario: Has cookie but no session - attempt to recover
        if (!hasUserSession && (hasAuthCookie || hasBackupCookie)) {
            console.log("Found auth cookie but no session - attempting to create mock session");
            
            // Create a temporary session to prevent redirect loops
            const mockUserData = {
                name: "Authenticated User",
                username: "authenticated@ibridge.co.za",
                email: "authenticated@ibridge.co.za",
                isAdmin: false,
                lastLogin: new Date().toISOString(),
                authMethod: "cookie-recovery"
            };
            
            sessionStorage.setItem('user', JSON.stringify(mockUserData));
            console.log("Created recovery session");
            return true;
        }
        
        // Try to parse the user data
        const userData = JSON.parse(sessionStorage.getItem('user') || '{}');
        console.log("Session user data:", userData);
        
        // If no user data, redirect to login using absolute path
        if (!userData.username) {
            console.error("No username in user data, redirecting to login");
            window.location.replace(window.location.origin + '/intranet/login.html');
            return false;
        }
        
        // Special check for Lwandile's account - ensure admin status
        if (userData.email && userData.email.toLowerCase() === "lwandile.gasela@ibridge.co.za" && !userData.isAdmin) {
            console.log("Fixing admin status for Lwandile Gasela");
            userData.isAdmin = true;
            sessionStorage.setItem('user', JSON.stringify(userData));
        }
        
        console.log("User authenticated successfully:", userData.username);
        return true;
    } catch (e) {
        console.error("Error checking authentication:", e);
        window.location.replace(window.location.origin + '/intranet/login.html');
        return false;
    }
}

/**
 * Load user information into the sidebar user info section
 */
function loadUserInfo() {
    const userData = JSON.parse(sessionStorage.getItem('user') || '{}');
    
    // Find user info elements if they exist
    const userNameElement = document.querySelector('.user-name');
    const userRoleElement = document.querySelector('.user-role');
    
    if (userNameElement && userData.name) {
        // Extract first name
        const firstName = userData.name.split(' ')[0];
        userNameElement.textContent = userData.name;
        
        // Add greeting to the dashboard if on index page
        if (window.location.pathname.endsWith('index.html') || window.location.pathname.endsWith('/intranet/')) {
            const greeting = document.querySelector('.greeting-name');
            if (greeting) {
                greeting.textContent = firstName;
            }
        }
    }
    
    if (userRoleElement) {
        userRoleElement.textContent = userData.isAdmin ? 'Administrator' : 'Staff Member';
    }
    
    // Add admin indicator if the user is an admin
    if (userData.isAdmin) {
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
    
    // Clear session storage
    sessionStorage.removeItem('user');
    
    // Clear authentication cookie required by .htaccess
    document.cookie = "user_authenticated=; path=/intranet/; expires=Thu, 01 Jan 1970 00:00:00 UTC; SameSite=Strict";
    console.log("Authentication cookie cleared");
    
    // Redirect to login page using absolute path
    const loginUrl = window.location.origin + '/intranet/login.html';
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
