/**
 * iBridge Custom Authentication System
 * Provides authentication without Microsoft 365 dependency
 * Uses IBD[Last Name Initials][Unique ID] format for employee codes
 */

class CustomAuthenticator {
  constructor() {
    this.settings = null;
    this.accessControl = null;
    this.employeeCodes = null;
    this.currentUser = null;
    this.isAuthenticated = false;
    this.initComplete = false;
    this.securityManager = window.securityManager;
    this.tempPassword = 'IBr1dGE'; // Default temporary password
  }
  
  /**
   * Initialize the authenticator by loading required configuration
   */
  async initialize() {
    try {
      // Initialize security manager first
      await this.securityManager.initialize();
      
      // Load necessary configuration files
      const settingsResponse = await fetch('/intranet/data/settings.json');
      this.settings = await settingsResponse.json();
      
      const accessResponse = await fetch('/intranet/data/access-control.json');
      this.accessControl = await accessResponse.json();
      
      const codesResponse = await fetch('/intranet/data/employee-codes.json');
      this.employeeCodes = await codesResponse.json();
      
      // Check session storage for existing authentication
      this.checkExistingAuth();
      
      this.initComplete = true;
      console.log('Custom authenticator initialized successfully');
      
      return true;
    } catch (error) {
      console.error('Failed to initialize authenticator:', error);
      return false;
    }
  }
  
  /**
   * Check if user is already authenticated
   */
  checkExistingAuth() {
    try {
      const sessionData = JSON.parse(sessionStorage.getItem('secureSession'));
      if (sessionData && sessionData.user && Date.now() - sessionData.timestamp < 86400000) {
        this.currentUser = sessionData.user;
        this.isAuthenticated = true;
        return true;
      }
    } catch (e) {
      console.error('Error checking session:', e);
    }
    
    // Clear invalid session
    sessionStorage.removeItem('secureSession');
    this.currentUser = null;
    this.isAuthenticated = false;
    return false;
  }
  
  /**
   * Check if the user is using the temporary password
   * @param {string} employeeCode - The employee code to check
   * @param {string} password - The password to verify
   * @returns {boolean} True if using temporary password
   */
  isUsingTempPassword(employeeCode, password) {
    return password === this.tempPassword && !this.employeeCodes.find(e => e.code === employeeCode)?.passwordSet;
  }

  /**
   * Authenticate using employee code or email
   * @param {string} identifier - The employee code or email to authenticate
   * @param {string} password - The password to verify
   */
  async authenticateEmployee(identifier, password) {
    if (!this.initComplete) {
      await this.initialize();
    }

    try {
      // Check if identifier is email or employee code
      const isEmail = identifier.includes('@');
      
      // Find user data
      let employeeData = null;
      if (isEmail) {
        // Find by email in employee codes
        employeeData = this.employeeCodes.mappings.find(e => e.userPrincipalName.toLowerCase() === identifier.toLowerCase());
      } else {
        // Find by employee code
        employeeData = this.employeeCodes.mappings.find(e => e.employeeCode === identifier.toUpperCase());
      }

      if (!employeeData) {
        this.securityManager.logSecurityEvent('login_failed', {
          reason: 'invalid_credentials',
          identifier: identifier
        });
        return {
          success: false,
          error: 'Invalid credentials.'
        };
      }

      // Check credentials file
      const credentialsResponse = await fetch('/intranet/data/credentials.json');
      const credentials = await credentialsResponse.json();
      
      // Find user credentials
      const userCreds = credentials.users.find(u => 
        u.userPrincipalName === employeeData.userPrincipalName && 
        u.employeeCode === employeeData.employeeCode
      );

      if (!userCreds) {
        return {
          success: false,
          error: 'Invalid credentials.'
        };
      }

      // Verify password
      const pwUtils = new PasswordUtils();
      const isValid = await pwUtils.verifyPassword(password, userCreds.passwordHash, userCreds.salt);

      if (!isValid) {
        this.securityManager.logSecurityEvent('login_failed', {
          reason: 'invalid_password',
          identifier: identifier
        });
        return {
          success: false,
          error: 'Invalid credentials.'
        };
      }

      // Create session
      const sessionData = {
        displayName: employeeData.firstName + ' ' + employeeData.lastName,
        username: employeeData.userPrincipalName,
        employeeCode: employeeData.employeeCode,
        department: employeeData.department,
        position: employeeData.position,
        permissions: employeeData.permissions,
        lastLogin: new Date().toISOString()
      };

      // Store in session
      sessionStorage.setItem('secureSession', JSON.stringify({
        user: sessionData,
        timestamp: Date.now()
      }));
      
      // Set authentication cookie
      document.cookie = "user_authenticated=true; path=/intranet/; max-age=86400; SameSite=Strict";

      this.securityManager.logSecurityEvent('login_success', {
        identifier: identifier
      });

      return {
        success: true,
        user: sessionData
      };

    } catch (error) {
      console.error('Authentication error:', error);
      return {
        success: false,
        error: 'An error occurred during authentication.'
      };
    }
  }
  
  /**
   * Authenticate using employee code
   * @param {string} employeeCode - The employee code to authenticate
   */
  async authenticateWithEmployeeCode(employeeCode) {
    if (!this.initComplete) {
      await this.initialize();
    }
    
    // Check if employee code login is enabled
    if (!this.settings.employeeCodeLogin) {
      console.error('Employee code login is disabled');
      return {
        success: false,
        error: 'Employee code login is disabled'
      };
    }
    
    // Validate employee code format (IBD format)
    if (!this.validateEmployeeCodeFormat(employeeCode)) {
      this.securityManager.logSecurityEvent('login_failed', {
        reason: 'invalid_format',
        employeeCode: employeeCode
      });
      console.error('Invalid employee code format');
      return {
        success: false,
        error: 'Invalid employee code format. Please use the correct format.'
      };
    }
    
    // Check for lockout
    if (this.securityManager.isLockedOut(employeeCode)) {
      return {
        success: false,
        error: 'Account is temporarily locked. Please try again later.'
      };
    }
    
    // Check if portal is in exclusive mode and if this code is allowed
    if (this.accessControl.restrictedAccess && 
        !this.accessControl.allowedEmployeeCodes.includes(employeeCode)) {
      this.securityManager.logSecurityEvent('login_failed', {
        reason: 'unauthorized_access',
        employeeCode: employeeCode
      });
      this.securityManager.recordFailedAttempt(employeeCode);
      console.error('Access restricted. Employee code not authorized.');
      return {
        success: false,
        error: 'Access restricted. Employee code not authorized.'
      };
    }
    
    // Find user by employee code
    const userMapping = this.employeeCodes.mappings.find(m => 
      m.employeeCode === employeeCode
    );
    
    if (!userMapping) {
      this.securityManager.logSecurityEvent('login_failed', {
        reason: 'invalid_code',
        employeeCode: employeeCode
      });
      this.securityManager.recordFailedAttempt(employeeCode);
      console.error('Invalid employee code');
      return {
        success: false,
        error: 'Invalid employee code'
      };
    }
    
    // Create user object
    const user = {
      displayName: `${userMapping.firstName} ${userMapping.lastName}`,
      userPrincipalName: userMapping.userPrincipalName,
      mail: userMapping.userPrincipalName,
      employeeCode: employeeCode,
      department: userMapping.department,
      position: userMapping.position,
      permissions: userMapping.permissions || {
        isAdmin: false,
        isEditor: false,
        canViewAdminPanel: false,
        canManageUsers: false
      }
    };
    
    // Generate and send MFA code if enabled
    if (this.securityManager.config.session.requireMfa) {
      const mfaCode = this.securityManager.generateMfaCode(employeeCode);
      // In a real system, this would send the code via email/SMS
      console.log('MFA code generated:', mfaCode);
      
      // Store temporary auth data
      sessionStorage.setItem('pendingAuth', JSON.stringify({
        user,
        authMode: 'employee-code'
      }));
      
      return {
        success: true,
        requireMfa: true,
        user: {
          displayName: user.displayName,
          email: user.mail
        }
      };
    }
    
    // Complete authentication
    return this.completeAuthentication(user, 'employee-code');
  }
  
  /**
   * Complete the authentication process
   */
  completeAuthentication(user, authMode) {
    // Clear any failed login attempts
    this.securityManager.clearLoginAttempts(user.employeeCode || user.userPrincipalName);
    
    // Create secure session
    const session = this.securityManager.createSecureSession(user);
    
    // Set current user state
    this.currentUser = user;
    this.authMode = authMode;
    this.isAuthenticated = true;
    
    // For compatibility with old system
    sessionStorage.setItem('user', JSON.stringify({
      name: user.displayName,
      username: user.userPrincipalName,
      email: user.mail,
      isAdmin: user.permissions.isAdmin,
      lastLogin: new Date().toISOString(),
      authMethod: authMode
    }));
    
    this.securityManager.logSecurityEvent('login_success', {
      username: user.userPrincipalName,
      authMode: authMode
    });
    
    return {
      success: true,
      user: {
        displayName: user.displayName,
        email: user.mail
      }
    };
  }
  
  /**
   * Verify MFA code
   */
  async verifyMfaCode(code) {
    const pendingAuth = JSON.parse(sessionStorage.getItem('pendingAuth'));
    if (!pendingAuth) {
      return {
        success: false,
        error: 'No pending authentication found'
      };
    }
    
    const identifier = pendingAuth.user.employeeCode || pendingAuth.user.userPrincipalName;
    const result = this.securityManager.verifyMfaCode(identifier, code);
    
    if (result.success) {
      // Clear pending auth
      sessionStorage.removeItem('pendingAuth');
      
      // Complete authentication
      return this.completeAuthentication(pendingAuth.user, pendingAuth.authMode);
    }
    
    return result;
  }
  
  /**
   * Authenticate using username and password
   * @param {string} username - Username (email or employee code)
   * @param {string} password - Password
   */
  async authenticateWithCredentials(username, password) {
    if (!this.initComplete) {
      await this.initialize();
    }
    
    // Check for lockout
    if (this.securityManager.isLockedOut(username)) {
      return {
        success: false,
        error: 'Account is temporarily locked. Please try again later.'
      };
    }
    
    // First try employee code login if it matches the pattern
    if (this.validateEmployeeCodeFormat(username)) {
      return this.authenticateWithEmployeeCode(username);
    }
    
    // Try to find user by email
    const userMapping = this.employeeCodes.mappings.find(m => 
      m.userPrincipalName.toLowerCase() === username.toLowerCase()
    );
    
    if (!userMapping) {
      this.securityManager.logSecurityEvent('login_failed', {
        reason: 'invalid_username',
        username: username
      });
      this.securityManager.recordFailedAttempt(username);
      console.error('User not found');
      return {
        success: false,
        error: 'Invalid username or password'
      };
    }
    
    // In a real system, you would verify the password here
    // For this prototype, we're using a simple check
    // This should be replaced with proper password hashing and verification
    if (password !== "iBridge2025" && password !== "ibridge123") {
      this.securityManager.logSecurityEvent('login_failed', {
        reason: 'invalid_password',
        username: username
      });
      this.securityManager.recordFailedAttempt(username);
      console.error('Invalid password');
      return {
        success: false,
        error: 'Invalid username or password'
      };
    }
    
    // Create user object with credentials data
    const user = {
      displayName: `${userMapping.firstName} ${userMapping.lastName}`,
      userPrincipalName: userMapping.userPrincipalName,
      mail: userMapping.userPrincipalName,
      employeeCode: userMapping.employeeCode,
      department: userMapping.department,
      position: userMapping.position,
      permissions: userMapping.permissions || {
        isAdmin: false,
        isEditor: false,
        canViewAdminPanel: false,
        canManageUsers: false
      }
    };
    
    // Generate and send MFA code if enabled
    if (this.securityManager.config.session.requireMfa) {
      const mfaCode = this.securityManager.generateMfaCode(username);
      // In a real system, this would send the code via email/SMS
      console.log('MFA code generated:', mfaCode);
      
      // Store temporary auth data
      sessionStorage.setItem('pendingAuth', JSON.stringify({
        user,
        authMode: 'credentials'
      }));
      
      return {
        success: true,
        requireMfa: true,
        user: {
          displayName: user.displayName,
          email: user.mail
        }
      };
    }
    
    // Complete authentication
    return this.completeAuthentication(user, 'credentials');
  }
  
  /**
   * Authenticate using client ID
   * @param {string} clientId - The unique client ID to authenticate
   */
  async authenticateWithClientId(clientId) {
    if (!this.initComplete) {
      await this.initialize();
    }
    
    try {
      // Try to load client IDs from the data directory
      const clientsResponse = await fetch('/intranet/data/client-ids.json');
      const clientsData = await clientsResponse.json();
      
      // Find client by ID
      const clientInfo = clientsData.clients.find(c => c.clientId === clientId);
      
      if (!clientInfo) {
        console.error('Invalid client ID');
        return {
          success: false,
          error: 'Invalid client ID. Please check and try again.'
        };
      }
      
      // Set current user and auth mode using client data
      this.currentUser = {
        displayName: clientInfo.companyName,
        userPrincipalName: `client-${clientId}@ibridge.co.za`,
        mail: clientInfo.email,
        clientId: clientId,
        clientType: clientInfo.type,
        permissions: {
          isAdmin: false,
          isEditor: false,
          isClient: true,
          clientAccess: clientInfo.accessLevel || "standard"
        }
      };
      
      this.authMode = 'client-id';
      this.isAuthenticated = true;
      
      // Store authentication in session storage
      sessionStorage.setItem('portalUser', JSON.stringify(this.currentUser));
      sessionStorage.setItem('authMode', this.authMode);
      sessionStorage.setItem('clientAccess', 'true');
      
      // For compatibility with old system
      sessionStorage.setItem('user', JSON.stringify({
        name: this.currentUser.displayName,
        username: this.currentUser.userPrincipalName,
        email: this.currentUser.mail,
        isAdmin: false,
        isClient: true,
        lastLogin: new Date().toISOString(),
        authMethod: 'client-id'
      }));
      
      // Set authentication cookies for compatibility
      this._setAuthCookies();
      
      console.log('Authentication successful with client ID');
      
      return {
        success: true,
        user: this.currentUser
      };
    } catch (error) {
      console.error('Client ID authentication error:', error);
      
      // Fallback to check if it's a test client ID (for development purposes)
      if (clientId === 'CLIENT001' || clientId === 'TEST123' || clientId === 'DEMO456') {
        // Create a test client user
        this.currentUser = {
          displayName: 'Test Client',
          userPrincipalName: `client-${clientId}@ibridge.co.za`,
          mail: 'test.client@example.com',
          clientId: clientId,
          clientType: 'test',
          permissions: {
            isAdmin: false,
            isEditor: false,
            isClient: true,
            clientAccess: "standard"
          }
        };
        
        this.authMode = 'client-id';
        this.isAuthenticated = true;
        
        // Store authentication in session storage
        sessionStorage.setItem('portalUser', JSON.stringify(this.currentUser));
        sessionStorage.setItem('authMode', this.authMode);
        sessionStorage.setItem('clientAccess', 'true');
        
        // Set authentication cookies
        this._setAuthCookies();
        
        console.log('Authentication successful with test client ID');
        
        return {
          success: true,
          user: this.currentUser
        };
      }
      
      return {
        success: false,
        error: 'Client authentication failed. Please contact your account manager.'
      };
    }
  }
  
  /**
   * Set authentication cookies
   * This helps ensure compatibility with the existing authentication check system
   * @private
   */
  _setAuthCookies() {
    // Set cookies with path for the entire intranet
    document.cookie = `user_authenticated=true; path=/intranet/; secure; samesite=strict`;
    document.cookie = `intranet_session=active; path=/intranet/; secure; samesite=strict`;
  }
  
  /**
   * Clear authentication cookies
   * @private
   */
  _clearAuthCookies() {
    // Clear cookies by setting expiration to the past
    document.cookie = `user_authenticated=; path=/intranet/; expires=Thu, 01 Jan 1970 00:00:00 GMT; secure; samesite=strict`;
    document.cookie = `intranet_session=; path=/intranet/; expires=Thu, 01 Jan 1970 00:00:00 GMT; secure; samesite=strict`;
  }
  
  /**
   * Clear authentication data (used for invalid sessions)
   */
  clearAuthentication() {
    this.logout();
  }
  
  /**
   * Log out the current user
   */
  logout() {
    this.currentUser = null;
    this.isAuthenticated = false;
    this.authMode = null;
    
    // Clear session storage
    sessionStorage.removeItem('portalUser');
    sessionStorage.removeItem('authMode');
    sessionStorage.removeItem('user'); // Clear old format too
    
    // Clear pending authentication data
    sessionStorage.removeItem('pendingAuth');
    
    // Clear authentication cookies
    this._clearAuthCookies();
    
    return true;
  }
  
  /**
   * Validate employee code format (IBD[Last Name Initials][Unique ID])
   * @param {string} code - The employee code to validate
   */
  validateEmployeeCodeFormat(code) {
    // Basic format validation
    const regex = /^IBD[A-Z]{1,3}\d{2,4}$/;
    return regex.test(code);
  }
  
  /**
   * Generate a new employee code based on name
   * @param {string} firstName - User's first name
   * @param {string} lastName - User's last name
   */
  generateEmployeeCode(firstName, lastName) {
    // Get last name initials (up to 3 characters)
    const lastNameInitials = lastName.substring(0, Math.min(lastName.length, 3)).toUpperCase();
    
    // Find highest existing ID with same initials
    let highestId = 0;
    
    const codePrefix = `IBD${lastNameInitials}`;
    this.employeeCodes.mappings.forEach(mapping => {
      if (mapping.employeeCode.startsWith(codePrefix)) {
        const idPart = mapping.employeeCode.substring(codePrefix.length);
        const idNumber = parseInt(idPart, 10);
        if (!isNaN(idNumber) && idNumber > highestId) {
          highestId = idNumber;
        }
      }
    });
    
    // Generate new ID (increment highest existing ID)
    const newId = highestId + 1;
    
    // Format with leading zeros based on number of digits
    let idPart = newId.toString();
    if (newId < 10) {
      idPart = `0${newId}`;
    } else if (newId < 100) {
      idPart = `${newId}`;
    } else if (newId < 1000) {
      idPart = `${newId}`;
    }
    
    return `${codePrefix}${idPart}`;
  }
  
  /**
   * Check if current user has a specific permission
   * @param {string} permission - The permission to check
   */
  hasPermission(permission) {
    if (!this.isAuthenticated || !this.currentUser?.permissions) {
      return false;
    }
    
    return !!this.currentUser.permissions[permission];
  }
  
  /**
   * Check if current user is an admin
   */
  isAdmin() {
    return this.hasPermission('isAdmin');
  }
  
  /**
   * Check if this is the user's first login
   * @param {string} employeeCode - The employee code to check
   * @returns {boolean} True if this is the first login
   */
  async isFirstTimeLogin(employeeCode) {
    try {
      const employee = this.employeeCodes.find(e => e.code === employeeCode);
      return employee && !employee.passwordSet;
    } catch (error) {
      console.error('Error checking first time login:', error);
      return false;
    }
  }

  /**
   * Set up password for first-time login
   * @param {string} employeeCode - The employee code
   * @param {string} password - The new password to set
   * @returns {Promise<Object>} Result of the password setup
   */
  async setupFirstTimePassword(employeeCode, password) {
    try {
      // Validate password strength
      const passwordCheck = this.securityManager.validatePasswordStrength(password);
      if (!passwordCheck.isValid) {
        return {
          success: false,
          error: passwordCheck.error
        };
      }

      // Hash the password
      const hashedPassword = await this.securityManager.hashPassword(password);

      // Update employee record
      const employee = this.employeeCodes.find(e => e.code === employeeCode);
      if (!employee) {
        return {
          success: false,
          error: 'Employee not found'
        };
      }

      // Save the hashed password and mark as set
      employee.passwordHash = hashedPassword;
      employee.passwordSet = true;
      employee.lastPasswordChange = new Date().toISOString();

      // Save the updated employee codes
      await this.saveEmployeeCodes();

      // Log the event
      this.securityManager.logSecurityEvent('password_setup', {
        employeeCode: employeeCode,
        timestamp: new Date().toISOString()
      });

      return {
        success: true,
        message: 'Password set successfully'
      };
    } catch (error) {
      console.error('Error setting up password:', error);
      return {
        success: false,
        error: 'Failed to set up password. Please try again.'
      };
    }
  }

  /**
   * Save updated employee codes to storage
   * @private
   */
  async saveEmployeeCodes() {
    try {
      const response = await fetch('/intranet/data/employee-codes.json', {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(this.employeeCodes)
      });

      if (!response.ok) {
        throw new Error('Failed to save employee codes');
      }
    } catch (error) {
      console.error('Error saving employee codes:', error);
      throw error;
    }
  }
}

// Initialize authenticator and expose to window
window.customAuth = new CustomAuthenticator();
document.addEventListener('DOMContentLoaded', () => {
  window.customAuth.initialize();
});
