class PasswordResetManager {
    static RESET_CODE_LENGTH = 6;
    static RESET_CODE_EXPIRY = 10 * 60 * 1000; // 10 minutes in milliseconds
    static RESET_TOKENS = new Map(); // Store reset tokens in memory (in production, use a secure database)

    /**
     * Initiates the password reset process for an employee
     * @param {string} employeeCode 
     * @returns {Promise<{success: boolean, error?: string, employee?: object}>}
     */
    static async initiateReset(employeeCode) {
        try {
            // Load current credentials
            const credentials = await SecurityManager.loadCredentials();
            const user = credentials.users.find(u => u.employeeCode === employeeCode);

            if (!user) {
                return { success: false, error: 'Employee code not found' };
            }

            // Generate verification code
            const code = this.generateVerificationCode();
            
            // Store the code with timestamp
            this.RESET_TOKENS.set(employeeCode, {
                code,
                timestamp: Date.now()
            });

            // In a real application, send this code via email
            // For demo purposes, we'll log it to console
            console.log(`Reset code for ${employeeCode}: ${code}`);

            // Send verification code via email (mock implementation)
            await this.sendVerificationEmail(user.userPrincipalName, code);

            return {
                success: true,
                employee: {
                    employeeCode: user.employeeCode,
                    email: user.userPrincipalName
                }
            };
        } catch (error) {
            console.error('Error initiating password reset:', error);
            return { success: false, error: 'An error occurred while initiating password reset' };
        }
    }

    /**
     * Verifies the reset code for an employee
     * @param {string} employeeCode 
     * @param {string} code 
     * @returns {Promise<{success: boolean, error?: string, token?: string}>}
     */
    static async verifyCode(employeeCode, code) {
        const resetData = this.RESET_TOKENS.get(employeeCode);

        if (!resetData) {
            return { success: false, error: 'No reset code found. Please request a new code.' };
        }

        if (Date.now() - resetData.timestamp > this.RESET_CODE_EXPIRY) {
            this.RESET_TOKENS.delete(employeeCode);
            return { success: false, error: 'Reset code has expired. Please request a new code.' };
        }

        if (resetData.code !== code) {
            return { success: false, error: 'Invalid reset code' };
        }

        // Generate a one-time token for password reset
        const token = SecurityManager.generateToken();
        resetData.token = token;
        resetData.tokenTimestamp = Date.now();

        return { success: true, token };
    }

    /**
     * Completes the password reset process
     * @param {string} employeeCode 
     * @param {string} token 
     * @param {string} newPassword 
     * @returns {Promise<{success: boolean, error?: string}>}
     */
    static async completeReset(employeeCode, token, newPassword) {
        try {
            const resetData = this.RESET_TOKENS.get(employeeCode);

            if (!resetData || resetData.token !== token) {
                return { success: false, error: 'Invalid or expired reset token' };
            }

            if (Date.now() - resetData.tokenTimestamp > this.RESET_CODE_EXPIRY) {
                this.RESET_TOKENS.delete(employeeCode);
                return { success: false, error: 'Reset token has expired' };
            }

            // Load current credentials
            const credentials = await SecurityManager.loadCredentials();
            const userIndex = credentials.users.findIndex(u => u.employeeCode === employeeCode);

            if (userIndex === -1) {
                return { success: false, error: 'Employee not found' };
            }

            // Generate new salt and hash
            const salt = SecurityManager.generateSalt();
            const hash = await SecurityManager.hashPassword(newPassword, salt);

            // Update user's password
            credentials.users[userIndex] = {
                ...credentials.users[userIndex],
                passwordHash: hash,
                salt,
                lastPasswordChange: new Date().toISOString(),
                requiresPasswordChange: false
            };

            // Save updated credentials
            await SecurityManager.saveCredentials(credentials);

            // Clean up reset data
            this.RESET_TOKENS.delete(employeeCode);

            return { success: true };
        } catch (error) {
            console.error('Error completing password reset:', error);
            return { success: false, error: 'An error occurred while resetting password' };
        }
    }

    /**
     * Generates a random verification code
     * @returns {string}
     */
    static generateVerificationCode() {
        return Array.from(
            { length: this.RESET_CODE_LENGTH },
            () => Math.floor(Math.random() * 10)
        ).join('');
    }

    /**
     * Mock implementation of email sending
     * In production, implement actual email sending logic
     * @param {string} email 
     * @param {string} code 
     */
    static async sendVerificationEmail(email, code) {
        console.log(`Sending verification code ${code} to ${email}`);
        // In production, implement actual email sending logic here
        return new Promise(resolve => setTimeout(resolve, 1000));
    }
}

// Set up API endpoints for password reset
async function setupPasswordResetApi() {
    const router = new Router();

    // Start password reset process
    router.post('/api/password-reset/start', async (req, res) => {
        const { employeeCode } = req.body;
        const result = await PasswordResetManager.initiateReset(employeeCode);
        res.json(result);
    });

    // Verify reset code
    router.post('/api/password-reset/verify', async (req, res) => {
        const { employeeCode, code } = req.body;
        const result = await PasswordResetManager.verifyCode(employeeCode, code);
        res.json(result);
    });

    // Complete password reset
    router.post('/api/password-reset/complete', async (req, res) => {
        const { employeeCode, token, newPassword } = req.body;
        const result = await PasswordResetManager.completeReset(employeeCode, token, newPassword);
        res.json(result);
    });

    // Handle resend code request
    router.post('/api/password-reset/resend', async (req, res) => {
        const { employeeCode } = req.body;
        const result = await PasswordResetManager.initiateReset(employeeCode);
        res.json(result);
    });
}

// Initialize password reset API endpoints
setupPasswordResetApi();
