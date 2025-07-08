/**
 * Password Utilities for iBridge Intranet
 * Provides secure password handling functionality
 */

class PasswordUtils {
    /**
     * Generate a secure hash of a password using SHA-256
     * In a production environment, consider using a dedicated hashing library
     * with salting and stronger algorithms like bcrypt, Argon2, or PBKDF2
     * 
     * @param {string} password - The password to hash
     * @param {string} salt - Optional salt to use (will generate if not provided)
     * @returns {Promise<object>} Object containing hash and salt
     */
    static async hashPassword(password, salt = null) {
        // Generate salt if not provided
        if (!salt) {
            salt = this.generateSalt();
        }
        
        // Combine password with salt
        const passwordWithSalt = password + salt;
        
        // Convert to buffer
        const encoder = new TextEncoder();
        const data = encoder.encode(passwordWithSalt);
        
        // Hash using SHA-256
        const hashBuffer = await crypto.subtle.digest('SHA-256', data);
        
        // Convert to hex string
        const hashArray = Array.from(new Uint8Array(hashBuffer));
        const hashHex = hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
        
        return {
            hash: hashHex,
            salt: salt
        };
    }
    
    /**
     * Verify a password against a stored hash and salt
     * 
     * @param {string} password - The password to verify
     * @param {string} storedHash - The stored hash to check against
     * @param {string} salt - The salt used for the stored hash
     * @returns {Promise<boolean>} True if password is valid
     */
    static async verifyPassword(password, storedHash, salt) {
        const hashResult = await this.hashPassword(password, salt);
        return hashResult.hash === storedHash;
    }
    
    /**
     * Generate a secure random salt
     * 
     * @param {number} length - Length of salt to generate
     * @returns {string} Random salt string
     */
    static generateSalt(length = 16) {
        const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*()';
        const randomValues = new Uint8Array(length);
        window.crypto.getRandomValues(randomValues);
        
        let salt = '';
        for (let i = 0; i < length; i++) {
            salt += characters.charAt(randomValues[i] % characters.length);
        }
        
        return salt;
    }
    
    /**
     * Check password strength
     * 
     * @param {string} password - Password to check
     * @returns {object} Strength assessment
     */
    static checkPasswordStrength(password) {
        let strength = 0;
        let feedback = [];
        
        // Length check
        if (password.length < 8) {
            feedback.push('Password should be at least 8 characters long');
        } else {
            strength += 1;
        }
        
        // Contains uppercase
        if (!/[A-Z]/.test(password)) {
            feedback.push('Add uppercase letters');
        } else {
            strength += 1;
        }
        
        // Contains lowercase
        if (!/[a-z]/.test(password)) {
            feedback.push('Add lowercase letters');
        } else {
            strength += 1;
        }
        
        // Contains numbers
        if (!/[0-9]/.test(password)) {
            feedback.push('Add numbers');
        } else {
            strength += 1;
        }
        
        // Contains special characters
        if (!/[^A-Za-z0-9]/.test(password)) {
            feedback.push('Add special characters');
        } else {
            strength += 1;
        }
        
        let strengthLevel = 'weak';
        if (strength >= 5) {
            strengthLevel = 'strong';
        } else if (strength >= 3) {
            strengthLevel = 'medium';
        }
        
        return {
            score: strength,
            level: strengthLevel,
            feedback: feedback
        };
    }
}

// Make available globally
window.PasswordUtils = PasswordUtils;
