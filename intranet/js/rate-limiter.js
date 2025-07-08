/**
 * Rate Limiting Utility for iBridge Intranet
 * Prevents brute force and DoS attacks by limiting request frequency
 */

class RateLimiter {
    constructor() {
        this.limits = {
            'login': { maxAttempts: 5, timeWindow: 60000, blockDuration: 600000 }, // 5 attempts per minute, 10 min block
            'api': { maxAttempts: 60, timeWindow: 60000, blockDuration: 300000 },  // 60 requests per minute, 5 min block
            'default': { maxAttempts: 100, timeWindow: 60000, blockDuration: 60000 } // 100 requests per minute, 1 min block
        };
        
        this.attempts = {};
        this.blocked = {};
        
        // Clean up expired records periodically
        setInterval(() => this.cleanupExpired(), 60000);
    }
    
    /**
     * Check if a request should be rate limited
     * @param {string} identifier - Unique identifier (IP, user ID, etc.)
     * @param {string} action - Action type (login, api, etc.)
     * @returns {Object} Result with allowed flag and status message
     */
    checkLimit(identifier, action = 'default') {
        const now = Date.now();
        const key = `${identifier}:${action}`;
        
        // Get appropriate limits
        const limit = this.limits[action] || this.limits.default;
        
        // Check if blocked
        if (this.blocked[key] && this.blocked[key] > now) {
            const remainingSeconds = Math.ceil((this.blocked[key] - now) / 1000);
            return { 
                allowed: false, 
                message: `Too many requests. Try again in ${remainingSeconds} seconds.`,
                remainingTime: remainingSeconds
            };
        }
        
        // Initialize tracking if needed
        if (!this.attempts[key]) {
            this.attempts[key] = {
                count: 0,
                firstAttempt: now
            };
        }
        
        // Reset if time window passed
        if ((now - this.attempts[key].firstAttempt) > limit.timeWindow) {
            this.attempts[key] = {
                count: 1,
                firstAttempt: now
            };
            return { allowed: true };
        }
        
        // Increment attempt count
        this.attempts[key].count++;
        
        // Check if over limit
        if (this.attempts[key].count > limit.maxAttempts) {
            this.blocked[key] = now + limit.blockDuration;
            const remainingSeconds = Math.ceil(limit.blockDuration / 1000);
            return { 
                allowed: false, 
                message: `Rate limit exceeded. Try again in ${remainingSeconds} seconds.`,
                remainingTime: remainingSeconds
            };
        }
        
        return { allowed: true };
    }
    
    /**
     * Record a failed attempt and check if blocked
     * @param {string} identifier - Unique identifier
     * @param {string} action - Action type
     * @returns {Object} Result with blocked status
     */
    recordFailure(identifier, action = 'default') {
        const result = this.checkLimit(identifier, action);
        return result;
    }
    
    /**
     * Reset attempts for an identifier (e.g. after successful login)
     * @param {string} identifier - Identifier to reset
     * @param {string} action - Action type
     */
    reset(identifier, action = 'default') {
        const key = `${identifier}:${action}`;
        delete this.attempts[key];
        delete this.blocked[key];
    }
    
    /**
     * Clean up expired records
     */
    cleanupExpired() {
        const now = Date.now();
        
        // Clean expired blocks
        Object.keys(this.blocked).forEach(key => {
            if (this.blocked[key] <= now) {
                delete this.blocked[key];
            }
        });
        
        // Clean expired attempts
        Object.keys(this.attempts).forEach(key => {
            const [, action] = key.split(':');
            const limit = this.limits[action] || this.limits.default;
            
            if ((now - this.attempts[key].firstAttempt) > limit.timeWindow) {
                delete this.attempts[key];
            }
        });
    }
    
    /**
     * Get current status for an identifier
     * @param {string} identifier - Identifier to check
     * @param {string} action - Action type
     * @returns {Object} Current status
     */
    getStatus(identifier, action = 'default') {
        const now = Date.now();
        const key = `${identifier}:${action}`;
        const limit = this.limits[action] || this.limits.default;
        
        if (this.blocked[key] && this.blocked[key] > now) {
            const remainingSeconds = Math.ceil((this.blocked[key] - now) / 1000);
            return {
                status: 'blocked',
                remainingTime: remainingSeconds,
                message: `Blocked for ${remainingSeconds} more seconds`
            };
        }
        
        if (!this.attempts[key]) {
            return {
                status: 'ok',
                attempts: 0,
                limit: limit.maxAttempts
            };
        }
        
        const timeElapsed = now - this.attempts[key].firstAttempt;
        if (timeElapsed > limit.timeWindow) {
            return {
                status: 'ok',
                attempts: 0,
                limit: limit.maxAttempts
            };
        }
        
        const timeRemaining = Math.ceil((limit.timeWindow - timeElapsed) / 1000);
        return {
            status: 'active',
            attempts: this.attempts[key].count,
            limit: limit.maxAttempts,
            remaining: limit.maxAttempts - this.attempts[key].count,
            resetsIn: timeRemaining,
            message: `${this.attempts[key].count} of ${limit.maxAttempts} attempts in the last minute`
        };
    }
    
    /**
     * Configure rate limits
     * @param {string} action - Action type
     * @param {Object} config - Rate limit configuration
     */
    configure(action, config) {
        if (!action || !config) return;
        
        this.limits[action] = {
            maxAttempts: config.maxAttempts || this.limits.default.maxAttempts,
            timeWindow: config.timeWindow || this.limits.default.timeWindow,
            blockDuration: config.blockDuration || this.limits.default.blockDuration
        };
    }
}

// Initialize rate limiter globally
window.RateLimiter = new RateLimiter();
