/**
 * Two-Factor Authentication (2FA) for iBridge Intranet
 * Provides email-based verification code system
 */

class TwoFactorAuth {
    constructor() {
        this.codeLength = 6;
        this.codeExpiration = 10 * 60 * 1000; // 10 minutes in milliseconds
        this.storageKey = 'intranet_2fa_data';
        this.verificationCodes = this.loadCodes();
    }
    
    /**
     * Load stored verification codes
     * @returns {Object} Stored codes or empty object
     */
    loadCodes() {
        const stored = sessionStorage.getItem(this.storageKey);
        return stored ? JSON.parse(stored) : {};
    }
    
    /**
     * Save verification codes
     */
    saveCodes() {
        sessionStorage.setItem(this.storageKey, JSON.stringify(this.verificationCodes));
    }
    
    /**
     * Generate a verification code for a user
     * @param {string} userIdentifier - Unique identifier for the user (email or employee code)
     * @returns {string} The generated verification code
     */
    generateCode(userIdentifier) {
        // Generate a random 6-digit code
        const code = Math.floor(100000 + Math.random() * 900000).toString();
        
        // Store the code with expiration
        this.verificationCodes[userIdentifier] = {
            code: code,
            expires: Date.now() + this.codeExpiration
        };
        
        this.saveCodes();
        return code;
    }
    
    /**
     * Verify a code entered by a user
     * @param {string} userIdentifier - Unique identifier for the user
     * @param {string} code - The code entered by the user
     * @returns {boolean} True if code is valid
     */
    verifyCode(userIdentifier, code) {
        const storedData = this.verificationCodes[userIdentifier];
        
        // Check if there is a stored code for this user
        if (!storedData) {
            return false;
        }
        
        // Check if code has expired
        if (Date.now() > storedData.expires) {
            // Clean up expired code
            delete this.verificationCodes[userIdentifier];
            this.saveCodes();
            return false;
        }
        
        // Check if code matches
        const isValid = (storedData.code === code);
        
        // If valid, remove the code to prevent reuse
        if (isValid) {
            delete this.verificationCodes[userIdentifier];
            this.saveCodes();
        }
        
        return isValid;
    }
    
    /**
     * Send verification code via email
     * In a real implementation, this would connect to an email service
     * This is a mock implementation that simulates sending an email
     * 
     * @param {string} email - User's email address
     * @param {string} code - Verification code to send
     * @returns {Promise<boolean>} True if email was sent successfully
     */
    async sendCodeByEmail(email, code) {
        // In a real implementation, you would call your email service here
        console.log(`[MOCK] Sending verification code ${code} to ${email}`);
        
        // This is where you would integrate with your actual email sending system
        // For example:
        // return await emailService.send({
        //     to: email,
        //     subject: 'iBridge Portal Verification Code',
        //     body: `Your verification code is: ${code}. It will expire in 10 minutes.`
        // });
        
        // For demo purposes, we'll just simulate a successful send
        return new Promise((resolve) => {
            setTimeout(() => {
                // Show code in console for testing purposes
                console.log(`Verification code for ${email}: ${code}`);
                resolve(true);
            }, 1000);
        });
    }
    
    /**
     * Setup the 2FA UI elements
     * @param {HTMLElement} container - Container for the 2FA UI
     * @param {Function} onSuccess - Callback for successful verification
     */
    setupUI(container, onSuccess) {
        if (!container) return;
        
        // Create the 2FA form
        const form = document.createElement('div');
        form.className = 'two-factor-form';
        form.innerHTML = `
            <h4>Two-Factor Authentication</h4>
            <p>Please enter the verification code sent to your email</p>
            <div class="code-input-group">
                <input type="text" class="verification-code-input" placeholder="Enter 6-digit code" maxlength="6" autocomplete="one-time-code">
                <button type="button" class="btn btn-primary verify-code-btn">Verify</button>
            </div>
            <div class="mt-2">
                <button type="button" class="btn btn-link resend-code-btn">Resend Code</button>
                <div class="countdown small text-muted mt-1"></div>
            </div>
            <div class="verification-message mt-2"></div>
        `;
        
        container.appendChild(form);
        
        // Get elements
        const codeInput = form.querySelector('.verification-code-input');
        const verifyButton = form.querySelector('.verify-code-btn');
        const resendButton = form.querySelector('.resend-code-btn');
        const countdownEl = form.querySelector('.countdown');
        const messageEl = form.querySelector('.verification-message');
        
        // Store user data for this session
        const userIdentifier = sessionStorage.getItem('2fa_pending_user');
        let countdownInterval = null;
        
        // Setup verification button
        verifyButton.addEventListener('click', () => {
            const code = codeInput.value.trim();
            if (!code || code.length !== this.codeLength) {
                messageEl.textContent = 'Please enter a valid 6-digit code';
                messageEl.className = 'verification-message mt-2 text-danger';
                return;
            }
            
            const isValid = this.verifyCode(userIdentifier, code);
            if (isValid) {
                messageEl.textContent = 'Verification successful!';
                messageEl.className = 'verification-message mt-2 text-success';
                
                // Clear countdown
                if (countdownInterval) {
                    clearInterval(countdownInterval);
                }
                
                // Call success callback after a short delay
                setTimeout(() => {
                    if (typeof onSuccess === 'function') {
                        onSuccess();
                    }
                }, 1000);
            } else {
                messageEl.textContent = 'Invalid or expired code. Please try again.';
                messageEl.className = 'verification-message mt-2 text-danger';
            }
        });
        
        // Setup resend button
        resendButton.addEventListener('click', () => {
            this.startVerification(userIdentifier);
            
            messageEl.textContent = 'A new code has been sent to your email';
            messageEl.className = 'verification-message mt-2 text-info';
            
            // Disable resend button temporarily
            resendButton.disabled = true;
            setTimeout(() => {
                resendButton.disabled = false;
            }, 30000); // 30 second cooldown
            
            // Start countdown
            this.startCountdown(countdownEl);
        });
        
        // Start countdown on load
        this.startCountdown(countdownEl);
    }
    
    /**
     * Start the countdown display
     * @param {HTMLElement} element - Element to show countdown in
     */
    startCountdown(element) {
        const userIdentifier = sessionStorage.getItem('2fa_pending_user');
        const storedData = this.verificationCodes[userIdentifier];
        
        if (!storedData) return;
        
        // Clear existing interval
        if (this._countdownInterval) {
            clearInterval(this._countdownInterval);
        }
        
        // Update countdown every second
        this._countdownInterval = setInterval(() => {
            const now = Date.now();
            const remaining = Math.max(0, storedData.expires - now);
            const minutes = Math.floor(remaining / 60000);
            const seconds = Math.floor((remaining % 60000) / 1000);
            
            element.textContent = `Code expires in ${minutes}:${seconds.toString().padStart(2, '0')}`;
            
            if (remaining <= 0) {
                clearInterval(this._countdownInterval);
                element.textContent = 'Code has expired';
            }
        }, 1000);
    }
    
    /**
     * Start the 2FA verification process for a user
     * @param {string} userIdentifier - User email or employee code
     * @param {string} email - User's email address
     * @returns {Promise<boolean>} True if process started successfully
     */
    async startVerification(userIdentifier, email = null) {
        // Store the user ID for the verification process
        sessionStorage.setItem('2fa_pending_user', userIdentifier);
        
        // Generate a code
        const code = this.generateCode(userIdentifier);
        
        // If email is provided, send the code
        if (email) {
            return await this.sendCodeByEmail(email, code);
        }
        
        return true;
    }
}

// Make available globally
window.TwoFactorAuth = new TwoFactorAuth();
