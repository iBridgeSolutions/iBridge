/**
 * Password Utilities for iBridge Intranet
 * Provides secure password handling functionality
 */

class PasswordUtils {
    /**
     * Hash password with salt using SHA-256
     * @param {string} password - Password to hash
     * @param {string} salt - Salt to use
     * @returns {object} Hash result
     */
    hashPassword(password, salt = null) {
        if (!salt) {
            salt = this.generateSalt();
        }
        
        try {
            // Ensure consistent string encoding across browsers
            const encoder = new TextEncoder();
            const combinedString = password + salt;
            const encodedData = encoder.encode(combinedString);
            
            // Use CryptoJS with WordArray for consistent hashing
            const wordArray = CryptoJS.lib.WordArray.create(encodedData);
            const hash = CryptoJS.SHA256(wordArray).toString();
            
            console.log('Password hashing:', {
                saltUsed: salt,
                hashLength: hash.length,
                success: true
            });
            
            return { hash, salt };
        } catch (error) {
            console.error('Hashing error:', error);
            throw new Error('Failed to hash password');
        }
    }

    /**
     * Verify password against stored hash
     * @param {string} password - Password to verify
     * @param {string} storedHash - Stored hash to check against
     * @param {string} salt - Salt used in stored hash
     * @returns {boolean} Whether password matches
     */
    verifyPassword(password, storedHash, salt) {
        const { hash } = this.hashPassword(password, salt);
        
        // Normalize hashes by removing any trailing 'b' characters and whitespace
        const normalizedStoredHash = storedHash.trim().replace(/b+$/, '');
        const normalizedGeneratedHash = hash.trim();
        
        console.log('Verification Details:', {
            providedPassword: password,
            salt: salt,
            generatedHash: normalizedGeneratedHash,
            storedHash: normalizedStoredHash,
            rawGeneratedHash: hash,
            rawStoredHash: storedHash,
            matches: normalizedGeneratedHash === normalizedStoredHash
        });
        
        return normalizedGeneratedHash === normalizedStoredHash;
    }
    
    /**
     * Generate a secure random salt
     * 
     * @param {number} length - Length of salt to generate
     * @returns {string} Random salt string
     */
    generateSalt(length = 3) {
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
