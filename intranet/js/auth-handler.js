/**
 * Authentication Handler for iBridge Intranet
 */

class AuthHandler {
    constructor() {
        // Ensure CryptoJS is available
        if (typeof CryptoJS === 'undefined') {
            throw new Error('CryptoJS is not loaded. Authentication cannot proceed.');
        }
        
        this.pwUtils = new PasswordUtils();
        this.baseUrl = window.location.pathname.includes('/intranet/') ? '/intranet' : '';
        
        // Test the password utils
        const testHash = this.pwUtils.hashPassword('@Dopeboi24', 'Db2');
        console.log('Test hash on init:', testHash);
    }

    async validateCredentials(employeeCode, password) {
        if (!employeeCode || !password) {
            console.error('Missing credentials:', { employeeCode: !!employeeCode, password: !!password });
            return { success: false, error: 'Employee code and password are required.' };
        }
        try {
            console.log('Starting authentication for:', employeeCode);
            
            // Add rate limiting check
            const attempts = this.getRateLimitCount(employeeCode);
            if (attempts >= 5) {
                const waitTime = this.getRateLimitWaitTime(employeeCode);
                if (waitTime > 0) {
                    return {
                        success: false,
                        error: `Too many login attempts. Please wait ${Math.ceil(waitTime / 60000)} minutes before trying again.`
                    };
                }
                // Reset attempts after wait time
                this.resetRateLimit(employeeCode);
            }
            
            // Fetch credentials using dynamic base path
            const credentialsPath = `${this.baseUrl}/data/credentials.json`;
            const response = await fetch(credentialsPath, {
                method: 'GET',
                headers: {
                    'Cache-Control': 'no-cache',
                    'Pragma': 'no-cache'
                },
                credentials: 'same-origin'
            });
            
            if (!response.ok) {
                this.incrementRateLimit(employeeCode);
                throw new Error('Failed to fetch credentials');
            }
            
            const credentials = await response.json();
            const user = credentials.users.find(u => u.employeeCode === employeeCode);
            
            if (!user) {
                this.incrementRateLimit(employeeCode);
                return {
                    success: false,
                    error: 'Invalid credentials.'
                };
            }

            const isValid = this.pwUtils.verifyPassword(password, user.passwordHash, user.salt);
            
            if (!isValid) {
                this.incrementRateLimit(employeeCode);
                return {
                    success: false,
                    error: 'Invalid credentials.'
                };
            }
            
            // Clear rate limit on successful login
            this.resetRateLimit(employeeCode);
            
            // Set secure session cookie with HttpOnly and SameSite
            const expirationDate = new Date();
            expirationDate.setHours(expirationDate.getHours() + 8); // 8-hour session
            
            document.cookie = `user_authenticated=true; path=/intranet/; expires=${expirationDate.toUTCString()}; SameSite=Strict; ${location.protocol === 'https:' ? 'Secure;' : ''} HttpOnly`;
            
            // Store minimal session data
            sessionStorage.setItem('secureSession', 'active');
            sessionStorage.setItem('sessionStart', Date.now().toString());
            
            return {
                success: true,
                user: {
                    employeeCode: user.employeeCode,
                    email: user.userPrincipalName,
                    lastPasswordChange: user.lastPasswordChange,
                    requiresPasswordChange: user.requiresPasswordChange
                }
            };
        } catch (error) {
            console.error('Authentication error:', error);
            return {
                success: false,
                error: 'An error occurred during authentication.'
            };
        }
    }
    
    // Rate limiting methods
    getRateLimitCount(employeeCode) {
        const attempts = sessionStorage.getItem(`login_attempts_${employeeCode}`);
        return attempts ? parseInt(attempts, 10) : 0;
    }
    
    incrementRateLimit(employeeCode) {
        const attempts = this.getRateLimitCount(employeeCode) + 1;
        sessionStorage.setItem(`login_attempts_${employeeCode}`, attempts.toString());
        if (attempts === 1) {
            sessionStorage.setItem(`login_attempt_start_${employeeCode}`, Date.now().toString());
        }
    }
    
    getRateLimitWaitTime(employeeCode) {
        const startTime = parseInt(sessionStorage.getItem(`login_attempt_start_${employeeCode}`) || '0', 10);
        const waitTime = 15 * 60 * 1000; // 15 minutes
        const timeElapsed = Date.now() - startTime;
        return Math.max(0, waitTime - timeElapsed);
    }
    
    resetRateLimit(employeeCode) {
        sessionStorage.removeItem(`login_attempts_${employeeCode}`);
        sessionStorage.removeItem(`login_attempt_start_${employeeCode}`);
    }
}

// Initialize auth handler
window.authHandler = new AuthHandler();
