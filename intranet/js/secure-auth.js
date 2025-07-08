/**
 * Enhanced Secure Authentication System for iBridge Intranet
 * Provides robust authentication without Microsoft dependencies
 * Implements password hashing, session management, and security features
 */

class SecureAuthenticator {
    constructor() {
        // Configuration
        this.sessionDuration = 8 * 60 * 60 * 1000; // 8 hours in milliseconds
        this.maxLoginAttempts = 5;
        this.lockoutDuration = 15 * 60 * 1000; // 15 minutes in milliseconds
        this.csrfTokenEnabled = true; // Enable CSRF protection
        this.requireStrongPasswords = true; // Require strong passwords
        
        // Initialize
        this.employeeCodes = null;
        this.accessControl = null;
        this.failedAttempts = {};
        this.lockedAccounts = {};
        
        // Session token generator
        this.tokenGenerator = new TokenGenerator();
        
        // Initialize on DOM ready
        document.addEventListener('DOMContentLoaded', () => {
            this.initialize();
            this.setupPasswordStrengthMeter();
        });
    }
    
    /**
     * Initialize the authenticator
     * Loads employee codes and access control data
     */
    async initialize() {
        try {
            console.log('Initializing secure authenticator');
            await this.loadEmployeeCodes();
            await this.loadAccessControl();
            
            // Check if user is logged in
            const isLoggedIn = this.checkSession();
            
            // Setup login form if on login page
            if (window.location.pathname.includes('login')) {
                this.setupLoginForm();
            } else if (!isLoggedIn) {
                // Redirect to login if not logged in and not on login page
                this.redirectToLogin();
            } else {
                // User is logged in and not on login page, update UI
                this.loadUserInfo();
            }
        } catch (error) {
            console.error('Error initializing secure authenticator:', error);
        }
    }
    
    /**
     * Load employee codes from JSON file
     */
    async loadEmployeeCodes() {
        try {
            const response = await fetch('/intranet/data/employee-codes.json');
            if (!response.ok) throw new Error('Failed to load employee codes');
            
            this.employeeCodes = await response.json();
            console.log('Employee codes loaded');
        } catch (error) {
            console.error('Error loading employee codes:', error);
            this.employeeCodes = {};
        }
    }
    
    /**
     * Load access control settings from JSON file
     */
    async loadAccessControl() {
        try {
            const response = await fetch('/intranet/data/access-control.json');
            if (!response.ok) throw new Error('Failed to load access control');
            
            this.accessControl = await response.json();
            console.log('Access control loaded');
        } catch (error) {
            console.error('Error loading access control:', error);
            this.accessControl = { restrictAccess: false, allowedUsers: [] };
        }
    }
    
    /**
     * Setup the login form event listeners
     */
    setupLoginForm() {
        const loginForm = document.getElementById('login-form');
        if (!loginForm) return;
        
        loginForm.addEventListener('submit', async (event) => {
            event.preventDefault();
            
            const employeeCode = document.getElementById('employee-code').value;
            const password = document.getElementById('password').value;
            
            const loginResult = await this.login(employeeCode, password);
            if (loginResult.success) {
                window.location.href = '/intranet/';
            } else {
                // Show error message
                const errorElement = document.getElementById('login-error');
                if (errorElement) {
                    errorElement.textContent = loginResult.message;
                    errorElement.style.display = 'block';
                }
            }
        });
    }
    
    /**
     * Login using employee code and password
     * @param {string} employeeCode - Employee code (e.g., IBDG054)
     * @param {string} password - User password
     * @returns {object} Login result with success flag and message
     */
    async login(employeeCode, password) {
        // Check if code is provided
        if (!employeeCode) {
            return { success: false, message: 'Employee code is required' };
        }
        
        // Check if account is locked
        if (this.isAccountLocked(employeeCode)) {
            const remainingTime = Math.ceil((this.lockedAccounts[employeeCode] - Date.now()) / 60000);
            return { 
                success: false, 
                message: `Account is temporarily locked. Try again in ${remainingTime} minutes` 
            };
        }
        
        // Check if employee code exists
        const user = this.findUserByCode(employeeCode);
        if (!user) {
            this.recordFailedAttempt(employeeCode);
            return { success: false, message: 'Invalid employee code or password' };
        }
        
        // Check if access is restricted and user is allowed
        if (this.accessControl?.restrictAccess && 
            !this.accessControl.allowedUsers.includes(user.email) &&
            !this.accessControl.allowedUsers.includes(employeeCode)) {
            return { success: false, message: 'Access denied. You are not authorized to access this portal' };
        }
        
        // Verify password with secure hash checking if available
        let passwordValid = false;
        
        if (user.passwordHash && user.salt) {
            // Use secure password verification
            passwordValid = await PasswordUtils.verifyPassword(password, user.passwordHash, user.salt);
        } else {
            // Legacy verification (plaintext) - for backward compatibility
            passwordValid = (password === user.password);
        }
        
        if (!passwordValid) {
            this.recordFailedAttempt(employeeCode);
            return { success: false, message: 'Invalid employee code or password' };
        }
        
        // Reset failed attempts
        this.resetFailedAttempts(employeeCode);
        
        // Check if 2FA is enabled for this user
        const twoFactorEnabled = user.twoFactorEnabled === true;
        
        if (twoFactorEnabled && window.TwoFactorAuth) {
            // Start 2FA process
            const twoFaStarted = await window.TwoFactorAuth.startVerification(userIdentifier, user.email);
            
            if (twoFaStarted) {
                // Store partial session data for completion after 2FA
                sessionStorage.setItem('pending_2fa_session', JSON.stringify({
                    userData: {
                        employeeCode: user.code,
                        name: user.name,
                        email: user.email,
                        role: user.role,
                        department: user.department,
                        permissions: user.permissions || []
                    }
                }));
                
                return {
                    success: true,
                    requireTwoFactor: true,
                    message: 'Please enter the verification code sent to your email'
                };
            } else {
                return {
                    success: false,
                    message: 'Failed to send verification code. Please try again.'
                };
            }
        }
        
        // Standard login flow (no 2FA)
        // Generate session
        const sessionToken = this.tokenGenerator.generateToken();
        const session = {
            token: sessionToken,
            expires: Date.now() + this.sessionDuration,
            userData: {
                employeeCode: user.code,
                name: user.name,
                email: user.email,
                role: user.role,
                department: user.department,
                permissions: user.permissions || []
            }
        };
        
        // Store session in local storage and cookies
        this.storeSession(session);
        
        return { 
            success: true, 
            message: 'Login successful',
            user: session.userData
        };
    }
    
    /**
     * Find a user by their employee code
     * @param {string} code - Employee code to search for
     * @returns {object|null} User object or null if not found
     */
    findUserByCode(code) {
        if (!this.employeeCodes || !this.employeeCodes.employees) return null;
        
        return this.employeeCodes.employees.find(emp => emp.code === code);
    }
    
    /**
     * Record a failed login attempt
     * @param {string} employeeCode - Employee code that failed login
     */
    recordFailedAttempt(employeeCode) {
        if (!this.failedAttempts[employeeCode]) {
            this.failedAttempts[employeeCode] = 0;
        }
        
        this.failedAttempts[employeeCode]++;
        
        // Lock account if too many attempts
        if (this.failedAttempts[employeeCode] >= this.maxLoginAttempts) {
            this.lockAccount(employeeCode);
        }
    }
    
    /**
     * Reset failed attempts counter for an account
     * @param {string} employeeCode - Employee code to reset
     */
    resetFailedAttempts(employeeCode) {
        this.failedAttempts[employeeCode] = 0;
    }
    
    /**
     * Lock an account after too many failed attempts
     * @param {string} employeeCode - Employee code to lock
     */
    lockAccount(employeeCode) {
        this.lockedAccounts[employeeCode] = Date.now() + this.lockoutDuration;
        console.warn(`Account ${employeeCode} locked for ${this.lockoutDuration/60000} minutes`);
    }
    
    /**
     * Check if an account is currently locked
     * @param {string} employeeCode - Employee code to check
     * @returns {boolean} True if account is locked
     */
    isAccountLocked(employeeCode) {
        const lockExpiry = this.lockedAccounts[employeeCode];
        if (!lockExpiry) return false;
        
        if (Date.now() < lockExpiry) {
            return true;
        } else {
            // Lock expired
            delete this.lockedAccounts[employeeCode];
            return false;
        }
    }
    
    /**
     * Store user session in localStorage and cookies
     * @param {object} session - Session object with token and user data
     */
    storeSession(session) {
        // Store in localStorage (for JS access)
        localStorage.setItem('intranet_session', JSON.stringify(session));
        
        // Store in cookies for backend compatibility
        this.setCookie('intranet_token', session.token, session.expires);
        this.setCookie('intranet_user', JSON.stringify(session.userData), session.expires);
        this.setCookie('portalUser', JSON.stringify(session.userData), session.expires); // Legacy compatibility
        
        // Also store in sessionStorage for extra redundancy
        sessionStorage.setItem('intranet_session', JSON.stringify(session));
        sessionStorage.setItem('portalUser', JSON.stringify(session.userData)); // Legacy compatibility
    }
    
    /**
     * Set a cookie with expiration
     * @param {string} name - Cookie name
     * @param {string} value - Cookie value
     * @param {number} expires - Expiration timestamp
     */
    setCookie(name, value, expires) {
        const date = new Date(expires);
        const cookieValue = encodeURIComponent(value) + 
                           "; expires=" + date.toUTCString() + 
                           "; path=/; SameSite=Strict";
        document.cookie = name + "=" + cookieValue;
    }
    
    /**
     * Get a cookie by name
     * @param {string} name - Cookie name
     * @returns {string|null} Cookie value or null if not found
     */
    getCookie(name) {
        const cookies = document.cookie.split(';');
        for (const cookieString of cookies) {
            const cookie = cookieString.trim();
            if (cookie.startsWith(name + '=')) {
                return decodeURIComponent(cookie.substring(name.length + 1));
            }
        }
        return null;
    }
    
    /**
     * Check if user has a valid session
     * @returns {boolean} True if session is valid
     */
    checkSession() {
        try {
            // Try localStorage first
            let session = JSON.parse(localStorage.getItem('intranet_session') || 'null');
            
            // If not in localStorage, try cookies
            if (!session) {
                const tokenCookie = this.getCookie('intranet_token');
                const userCookie = this.getCookie('intranet_user');
                
                if (tokenCookie && userCookie) {
                    session = {
                        token: tokenCookie,
                        userData: JSON.parse(userCookie)
                    };
                }
            }
            
            // If still no session, try legacy format
            if (!session) {
                const legacyCookie = this.getCookie('portalUser');
                if (legacyCookie) {
                    const userData = JSON.parse(legacyCookie);
                    session = {
                        token: 'legacy',
                        userData: userData
                    };
                }
            }
            
            // If no session found anywhere
            if (!session) {
                return false;
            }
            
            // Check if session is expired
            if (session.expires && session.expires < Date.now()) {
                this.logout();
                return false;
            }
            
            // Check if user is allowed (in case access control changed since login)
            if (this.accessControl?.restrictAccess) {
                const isAllowed = this.accessControl.allowedUsers.includes(session.userData.email) || 
                                this.accessControl.allowedUsers.includes(session.userData.employeeCode);
                
                if (!isAllowed) {
                    this.logout();
                    return false;
                }
            }
            
            return true;
        } catch (error) {
            console.error('Error checking session:', error);
            return false;
        }
    }
    
    /**
     * Load user info into the UI
     */
    loadUserInfo() {
        try {
            // Get user data from session
            const session = JSON.parse(localStorage.getItem('intranet_session') || 'null');
            if (!session) return;
            
            const userData = session.userData;
            
            // Update sidebar user info
            const nameElement = document.querySelector('.sidebar-user-name');
            const roleElement = document.querySelector('.sidebar-user-role');
            
            if (nameElement) {
                nameElement.textContent = userData.name || 'Unknown User';
            }
            
            if (roleElement) {
                roleElement.textContent = userData.role || 'Staff Member';
            }
            
            // Set up logout button
            const logoutButton = document.querySelector('.sidebar-logout');
            if (logoutButton) {
                logoutButton.addEventListener('click', () => this.logout());
            }
            
            // Update admin visibility based on permissions
            this.updateAdminVisibility(userData.permissions || []);
        } catch (error) {
            console.error('Error loading user info:', error);
        }
    }
    
    /**
     * Show/hide admin features based on user permissions
     * @param {string[]} permissions - Array of user permissions
     */
    updateAdminVisibility(permissions) {
        const isAdmin = permissions.includes('admin');
        const adminElements = document.querySelectorAll('.admin-only');
        
        adminElements.forEach(el => {
            el.style.display = isAdmin ? '' : 'none';
        });
    }
    
    /**
     * Redirect to login page
     */
    redirectToLogin() {
        window.location.href = '/intranet/login-custom.html';
    }
    
    /**
     * Log out the current user
     */
    logout() {
        // Clear localStorage
        localStorage.removeItem('intranet_session');
        
        // Clear cookies
        const pastDate = new Date(0).toUTCString();
        document.cookie = 'intranet_token=; expires=' + pastDate + '; path=/; SameSite=Strict';
        document.cookie = 'intranet_user=; expires=' + pastDate + '; path=/; SameSite=Strict';
        document.cookie = 'portalUser=; expires=' + pastDate + '; path=/; SameSite=Strict';
        
        // Clear sessionStorage
        sessionStorage.removeItem('intranet_session');
        sessionStorage.removeItem('portalUser');
        
        // Redirect to login
        window.location.href = '/intranet/login-custom.html';
    }
    /**
     * Setup the password strength meter
     */
    setupPasswordStrengthMeter() {
        const passwordField = document.getElementById('password');
        const strengthMeter = document.getElementById('password-strength-meter');
        const strengthText = document.getElementById('password-strength-text');
        
        if (!passwordField || !strengthMeter) return;
        
        passwordField.addEventListener('input', () => {
            const password = passwordField.value;
            const result = window.PasswordUtils.checkPasswordStrength(password);
            
            // Update meter
            strengthMeter.value = result.score;
            
            // Update color
            let color = 'red';
            if (result.level === 'medium') color = 'orange';
            if (result.level === 'strong') color = 'green';
            strengthMeter.style.accentColor = color;
            
            // Update text
            if (strengthText) {
                strengthText.textContent = `Password strength: ${result.level}`;
                strengthText.style.color = color;
            }
        });
    }
    
    /**
     * Generate a CSRF token for form submission
     * @returns {string} CSRF token
     */
    generateCsrfToken() {
        const token = this.tokenGenerator.generateToken();
        sessionStorage.setItem('csrf_token', token);
        return token;
    }
    
    /**
     * Verify a CSRF token
     * @param {string} token - Token to verify
     * @returns {boolean} True if token is valid
     */
    verifyCsrfToken(token) {
        const storedToken = sessionStorage.getItem('csrf_token');
        return token === storedToken;
    }
}

/**
 * Token Generator for secure session tokens
 */

class TokenGenerator {
    /**
     * Generate a secure random token
     * @returns {string} Random token string
     */
    generateToken() {
        // Generate a cryptographically secure random string
        const tokenLength = 64;
        const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';
        let token = '';
        
        const randomValues = new Uint8Array(tokenLength);
        window.crypto.getRandomValues(randomValues);
        
        for (let i = 0; i < tokenLength; i++) {
            token += characters.charAt(randomValues[i] % characters.length);
        }
        
        return token;
    }
}

// Initialize the secure authenticator
window.secureAuth = new SecureAuthenticator();