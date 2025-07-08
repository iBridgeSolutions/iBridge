/**
 * SecurityManager class for handling security-related functionality
 */
class SecurityManager {
    constructor() {
        this.config = null;
        this.loginAttempts = new Map();
        this.mfaCodes = new Map();
        this.initComplete = false;
    }

    /**
     * Initialize security manager
     */
    async initialize() {
        try {
            const response = await fetch('/intranet/config/security-config.json');
            this.config = await response.json();
            this.initComplete = true;
            return true;
        } catch (error) {
            console.error('Failed to initialize security manager:', error);
            return false;
        }
    }

    /**
     * Check if a user is locked out
     */
    isLockedOut(username) {
        const attempts = this.loginAttempts.get(username);
        if (!attempts) return false;

        const now = Date.now();
        // Clean up old attempts
        attempts.attempts = attempts.attempts.filter(time => 
            now - time < this.config.password.lockoutDuration * 60 * 1000
        );

        if (attempts.attempts.length >= this.config.password.lockoutThreshold) {
            const oldestAttempt = attempts.attempts[0];
            const lockoutEnds = oldestAttempt + (this.config.password.lockoutDuration * 60 * 1000);
            if (now < lockoutEnds) {
                return true;
            }
            // Reset if lockout period has passed
            this.loginAttempts.delete(username);
        }
        return false;
    }

    /**
     * Record a failed login attempt
     */
    recordFailedAttempt(username) {
        const now = Date.now();
        const attempts = this.loginAttempts.get(username) || { attempts: [] };
        attempts.attempts.push(now);
        this.loginAttempts.set(username, attempts);
    }

    /**
     * Clear login attempts for a user
     */
    clearLoginAttempts(username) {
        this.loginAttempts.delete(username);
    }

    /**
     * Check password strength
     */
    checkPasswordStrength(password) {
        let score = 0;
        const feedback = [];
        
        // Length check
        if (password.length < this.config.password.minLength) {
            feedback.push(`Password must be at least ${this.config.password.minLength} characters`);
        } else {
            score += password.length >= this.config.password.minLength + 4 ? 2 : 1;
        }
        
        // Character type checks
        if (this.config.password.requireUppercase && !/[A-Z]/.test(password)) {
            feedback.push('Add uppercase letters');
        } else {
            score += 1;
        }
        
        if (this.config.password.requireLowercase && !/[a-z]/.test(password)) {
            feedback.push('Add lowercase letters');
        } else {
            score += 1;
        }
        
        if (this.config.password.requireNumbers && !/[0-9]/.test(password)) {
            feedback.push('Add numbers');
        } else {
            score += 1;
        }
        
        if (this.config.password.requireSpecial && !/[^A-Za-z0-9]/.test(password)) {
            feedback.push('Add special characters');
        } else {
            score += 1;
        }
        
        // Pattern checks
        if (/(.)\1{2,}/.test(password)) {
            score -= 1;
            feedback.push('Avoid repeated characters');
        }
        
        if (/^(123|abc|qwerty|password|admin)/i.test(password)) {
            score -= 1;
            feedback.push('Avoid common patterns');
        }
        
        return {
            score: Math.max(0, Math.min(5, score)),
            isStrong: score >= 4 && password.length >= this.config.password.minLength,
            feedback: feedback.join('. ')
        };
    }

    /**
     * Generate and store MFA code for a user
     */
    generateMfaCode(username) {
        const code = Math.floor(100000 + Math.random() * 900000).toString();
        const expiry = Date.now() + (this.config.session.mfaTimeout * 60 * 1000);
        
        this.mfaCodes.set(username, {
            code,
            expiry,
            attempts: 0
        });
        
        return code;
    }

    /**
     * Verify MFA code
     */
    verifyMfaCode(username, code) {
        const mfaData = this.mfaCodes.get(username);
        if (!mfaData) {
            return { success: false, error: 'No MFA code found. Please request a new code.' };
        }

        // Check expiry
        if (Date.now() > mfaData.expiry) {
            this.mfaCodes.delete(username);
            return { success: false, error: 'Code has expired. Please request a new code.' };
        }

        // Check attempts
        if (mfaData.attempts >= 3) {
            this.mfaCodes.delete(username);
            return { success: false, error: 'Too many attempts. Please request a new code.' };
        }

        // Verify code
        if (mfaData.code !== code) {
            mfaData.attempts++;
            this.mfaCodes.set(username, mfaData);
            return { success: false, error: 'Invalid code. Please try again.' };
        }

        // Success
        this.mfaCodes.delete(username);
        return { success: true };
    }

    /**
     * Create secure session
     */
    createSecureSession(user) {
        const sessionData = {
            id: crypto.randomUUID(),
            created: Date.now(),
            lastAccessed: Date.now(),
            expiresAt: Date.now() + (this.config.session.timeout * 60 * 1000),
            user: {
                username: user.username,
                displayName: user.displayName,
                email: user.email,
                permissions: user.permissions
            }
        };

        // Store session
        sessionStorage.setItem('secureSession', JSON.stringify(sessionData));

        // Set secure cookies
        this.setSecureCookies(sessionData.id);

        return sessionData;
    }

    /**
     * Set secure cookies
     */
    setSecureCookies(sessionId) {
        const cookieOptions = this.config.cookies;
        const expires = new Date(Date.now() + cookieOptions.maxAge * 1000).toUTCString();
        
        document.cookie = `session_id=${sessionId}; path=${cookieOptions.path}; expires=${expires}; SameSite=${cookieOptions.sameSite}${cookieOptions.secure ? '; Secure' : ''}${cookieOptions.httpOnly ? '; HttpOnly' : ''}`;
        document.cookie = `authenticated=true; path=${cookieOptions.path}; expires=${expires}; SameSite=${cookieOptions.sameSite}${cookieOptions.secure ? '; Secure' : ''}${cookieOptions.httpOnly ? '; HttpOnly' : ''}`;
    }

    /**
     * Validate session
     */
    validateSession() {
        try {
            const sessionData = JSON.parse(sessionStorage.getItem('secureSession'));
            if (!sessionData) return false;

            // Check expiry
            if (Date.now() > sessionData.expiresAt) {
                this.clearSession();
                return false;
            }

            // Check if session needs renewal
            const renewalTime = sessionData.expiresAt - (this.config.session.renewalThreshold * 60 * 1000);
            if (Date.now() > renewalTime) {
                this.renewSession(sessionData);
            }

            return true;
        } catch (error) {
            console.error('Session validation error:', error);
            this.clearSession();
            return false;
        }
    }

    /**
     * Renew session
     */
    renewSession(sessionData) {
        sessionData.lastAccessed = Date.now();
        sessionData.expiresAt = Date.now() + (this.config.session.timeout * 60 * 1000);
        sessionStorage.setItem('secureSession', JSON.stringify(sessionData));
        this.setSecureCookies(sessionData.id);
    }

    /**
     * Clear session
     */
    clearSession() {
        sessionStorage.removeItem('secureSession');
        document.cookie = `session_id=; path=${this.config.cookies.path}; expires=Thu, 01 Jan 1970 00:00:00 GMT`;
        document.cookie = `authenticated=; path=${this.config.cookies.path}; expires=Thu, 01 Jan 1970 00:00:00 GMT`;
    }

    /**
     * Log security event
     */
    logSecurityEvent(eventType, details) {
        if (!this.config.logSettings.auditEvents.includes(eventType)) return;

        const event = {
            type: eventType,
            timestamp: new Date().toISOString(),
            details: details
        };

        // In a real system, this would send to a server
        console.log('Security Event:', event);
    }
}

// Export for use in other modules
window.securityManager = new SecurityManager();
