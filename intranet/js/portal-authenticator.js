// Employee Code & Microsoft 365 Authentication Module
// For exclusive use with iBridge Portal
// Configured for lwandile.gasela@ibridge.co.za (IBDG054)

class PortalAuthenticator {
  constructor() {
    this.settings = null;
    this.accessControl = null;
    this.employeeCodes = null;
    this.currentUser = null;
    this.isAuthenticated = false;
    this.authMode = null; // "m365", "employee-code", or null
    this.initComplete = false;
  }
  
  /**
   * Initialize the authenticator by loading required configuration
   */
  async initialize() {
    try {
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
      console.log('Portal authenticator initialized successfully');
      
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
    const storedUser = sessionStorage.getItem('portalUser');
    const storedAuthMode = sessionStorage.getItem('authMode');
    
    if (storedUser && storedAuthMode) {
      try {
        this.currentUser = JSON.parse(storedUser);
        this.authMode = storedAuthMode;
        this.isAuthenticated = true;
        console.log('Existing authentication found');
        
        return true;
      } catch (error) {
        console.error('Error parsing stored authentication:', error);
        this.clearAuthentication();
      }
    }
    
    return false;
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
    
    // Check if portal is in exclusive mode and if this code is allowed
    if (this.accessControl.restrictedAccess && 
        !this.accessControl.allowedEmployeeCodes.includes(employeeCode)) {
      console.error('Access restricted. Employee code not authorized.');
      return {
        success: false,
        error: 'Access restricted. Employee code not authorized.'
      };
    }
    
    // Find user by employee code
    const userMatch = this.employeeCodes.mappings.find(m => 
      m.employeeCode === employeeCode
    );
    
    if (!userMatch) {
      console.error('Invalid employee code');
      return {
        success: false,
        error: 'Invalid employee code'
      };
    }
    
    // Get user details from users.json
    try {
      const usersResponse = await fetch('/intranet/data/users.json');
      const users = await usersResponse.json();
      
      const user = users.find(u => u.userPrincipalName === userMatch.userPrincipalName);
      
      if (!user) {
        console.error('User not found in directory');
        return {
          success: false,
          error: 'User not found in directory'
        };
      }
      
      // Check if the user account is enabled
      if (user.accountEnabled === false) {
        console.error('User account is disabled');
        return {
          success: false,
          error: 'User account is disabled'
        };
      }
      
      // Set current user and auth mode
      this.currentUser = {
        ...user,
        employeeCode: employeeCode
      };
      this.authMode = 'employee-code';
      this.isAuthenticated = true;
      
      // Store authentication in session storage
      sessionStorage.setItem('portalUser', JSON.stringify(this.currentUser));
      sessionStorage.setItem('authMode', this.authMode);
      
      // Calculate user permissions
      const isAdmin = this.settings.adminUsers.includes(user.userPrincipalName);
      const isEditor = this.settings.editorUsers.includes(user.userPrincipalName);
      
      this.currentUser.permissions = {
        isAdmin,
        isEditor,
        canEditContent: isAdmin || isEditor,
        canViewAdminPanel: isAdmin,
        canManageUsers: isAdmin
      };
      
      console.log('Authentication successful with employee code');
      
      return {
        success: true,
        user: this.currentUser
      };
    } catch (error) {
      console.error('Error during employee code authentication:', error);
      return {
        success: false,
        error: 'Error retrieving user details'
      };
    }
  }
  
  /**
   * Authenticate using Microsoft 365 account
   * @param {string} accessToken - Microsoft 365 access token
   * @param {object} msalUser - MSAL user object
   */
  async authenticateWithM365(accessToken, msalUser) {
    if (!this.initComplete) {
      await this.initialize();
    }
    
    // Check if Microsoft integration is enabled
    if (!this.settings.useM365Data || !this.settings.features.microsoftIntegration) {
      console.error('Microsoft 365 integration is disabled');
      return {
        success: false,
        error: 'Microsoft 365 integration is disabled'
      };
    }
    
    // Check domain restriction
    const userDomain = msalUser.userPrincipalName.split('@')[1].toLowerCase();
    const allowedDomains = this.settings.allowedDomains || [];
    
    if (allowedDomains.length > 0 && !allowedDomains.includes(userDomain)) {
      console.error('Email domain not authorized');
      return {
        success: false,
        error: 'Email domain not authorized'
      };
    }
    
    // Check if portal is in exclusive mode and if this user is allowed
    if (this.accessControl.restrictedAccess && 
        !this.accessControl.allowedUsers.includes(msalUser.userPrincipalName)) {
      console.error('Access restricted. User not authorized.');
      return {
        success: false,
        error: 'Access restricted. User not authorized.'
      };
    }
    
    // If in dev mode, we'll just use the passed user info directly
    if (this.settings.devMode) {
      // Set current user and auth mode
      this.currentUser = {
        id: msalUser.localAccountId,
        displayName: msalUser.name,
        userPrincipalName: msalUser.userPrincipalName,
        givenName: msalUser.givenName || msalUser.name.split(' ')[0],
        surname: msalUser.surname || msalUser.name.split(' ').slice(1).join(' '),
        mail: msalUser.userPrincipalName
      };
      this.authMode = 'm365';
      this.isAuthenticated = true;
      
      // Store authentication in session storage
      sessionStorage.setItem('portalUser', JSON.stringify(this.currentUser));
      sessionStorage.setItem('authMode', this.authMode);
      
      // Calculate user permissions
      const isAdmin = this.settings.adminUsers.includes(msalUser.userPrincipalName);
      const isEditor = this.settings.editorUsers.includes(msalUser.userPrincipalName);
      
      this.currentUser.permissions = {
        isAdmin,
        isEditor,
        canEditContent: isAdmin || isEditor,
        canViewAdminPanel: isAdmin,
        canManageUsers: isAdmin
      };
      
      console.log('Authentication successful with Microsoft 365 (Dev Mode)');
      
      return {
        success: true,
        user: this.currentUser
      };
    }
    
    // For real mode, use the pre-extracted user data
    try {
      const usersResponse = await fetch('/intranet/data/users.json');
      const users = await usersResponse.json();
      
      const user = users.find(u => 
        u.userPrincipalName.toLowerCase() === msalUser.userPrincipalName.toLowerCase()
      );
      
      if (!user) {
        console.error('User not found in directory');
        return {
          success: false,
          error: 'User not found in directory'
        };
      }
      
      // Check if the user account is enabled
      if (user.accountEnabled === false) {
        console.error('User account is disabled');
        return {
          success: false,
          error: 'User account is disabled'
        };
      }
      
      // Find associated employee code if any
      let employeeCode = null;
      const codeMapping = this.employeeCodes.mappings.find(m => 
        m.userPrincipalName.toLowerCase() === user.userPrincipalName.toLowerCase()
      );
      
      if (codeMapping) {
        employeeCode = codeMapping.employeeCode;
      }
      
      // Set current user and auth mode
      this.currentUser = {
        ...user,
        employeeCode
      };
      this.authMode = 'm365';
      this.isAuthenticated = true;
      
      // Store authentication in session storage
      sessionStorage.setItem('portalUser', JSON.stringify(this.currentUser));
      sessionStorage.setItem('authMode', this.authMode);
      
      // Calculate user permissions
      const isAdmin = this.settings.adminUsers.includes(user.userPrincipalName);
      const isEditor = this.settings.editorUsers.includes(user.userPrincipalName);
      
      this.currentUser.permissions = {
        isAdmin,
        isEditor,
        canEditContent: isAdmin || isEditor,
        canViewAdminPanel: isAdmin,
        canManageUsers: isAdmin
      };
      
      console.log('Authentication successful with Microsoft 365');
      
      return {
        success: true,
        user: this.currentUser
      };
    } catch (error) {
      console.error('Error during Microsoft 365 authentication:', error);
      return {
        success: false,
        error: 'Error retrieving user details'
      };
    }
  }
  
  /**
   * Clear current authentication
   */
  clearAuthentication() {
    this.currentUser = null;
    this.isAuthenticated = false;
    this.authMode = null;
    
    sessionStorage.removeItem('portalUser');
    sessionStorage.removeItem('authMode');
    
    console.log('Authentication cleared');
  }
  
  /**
   * Check if current user is an admin
   */
  isAdmin() {
    if (!this.isAuthenticated || !this.currentUser) {
      return false;
    }
    
    return this.currentUser.permissions && this.currentUser.permissions.isAdmin;
  }
  
  /**
   * Get current authenticated user
   */
  getUser() {
    return this.currentUser;
  }
  
  /**
   * Check if portal is in exclusive access mode
   */
  isExclusiveMode() {
    return this.accessControl && this.accessControl.restrictedAccess;
  }
}

// Create global instance
window.portalAuth = new PortalAuthenticator();

// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
  window.portalAuth.initialize();
});
