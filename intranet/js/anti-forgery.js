/**
 * Anti-CSRF Protection for iBridge Intranet
 * This utility helps protect forms against Cross-Site Request Forgery attacks
 */

class AntiForgery {
    constructor() {
        this.tokenName = 'csrf_token';
        this.headerName = 'X-CSRF-Token';
        this.formFieldName = '_csrf';
        this.tokenLength = 64;
        this.autoProtectForms = true;
        
        // Auto-initialize on DOM ready
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', () => this.initialize());
        } else {
            this.initialize();
        }
    }
    
    /**
     * Initialize CSRF protection
     */
    initialize() {
        // Generate token if not exists
        this.getToken();
        
        // Set up Ajax request interception to add CSRF token
        this.setupAjaxInterception();
        
        // Automatically protect forms if enabled
        if (this.autoProtectForms) {
            this.protectAllForms();
        }
    }
    
    /**
     * Generate or get an existing CSRF token
     * @returns {string} The CSRF token
     */
    getToken() {
        let token = sessionStorage.getItem(this.tokenName);
        
        if (!token) {
            token = this.generateToken();
            sessionStorage.setItem(this.tokenName, token);
        }
        
        return token;
    }
    
    /**
     * Generate a new CSRF token
     * @returns {string} A new random token
     */
    generateToken() {
        const array = new Uint8Array(this.tokenLength);
        window.crypto.getRandomValues(array);
        
        // Convert to base64 and make URL-safe
        return btoa(String.fromCharCode.apply(null, array))
            .replace(/\+/g, '-')
            .replace(/\//g, '_')
            .replace(/=/g, '');
    }
    
    /**
     * Protect a specific form with CSRF token
     * @param {HTMLFormElement} form - The form to protect
     */
    protectForm(form) {
        if (!form) return;
        
        // Check if form is already protected
        if (form.querySelector(`input[name="${this.formFieldName}"]`)) {
            return;
        }
        
        // Create hidden input for token
        const tokenInput = document.createElement('input');
        tokenInput.type = 'hidden';
        tokenInput.name = this.formFieldName;
        tokenInput.value = this.getToken();
        
        // Add to form
        form.appendChild(tokenInput);
        
        // Add submit event to update token value
        form.addEventListener('submit', () => {
            const input = form.querySelector(`input[name="${this.formFieldName}"]`);
            if (input) {
                input.value = this.getToken();
            }
        });
    }
    
    /**
     * Protect all forms in the document
     */
    protectAllForms() {
        const forms = document.querySelectorAll('form');
        forms.forEach(form => this.protectForm(form));
    }
    
    /**
     * Set up interception for Ajax requests to add CSRF token
     */
    setupAjaxInterception() {
        const originalOpen = XMLHttpRequest.prototype.open;
        const originalSend = XMLHttpRequest.prototype.send;
        const headerName = this.headerName;
        const getToken = this.getToken.bind(this);
        
        // Intercept XHR open
        XMLHttpRequest.prototype.open = function() {
            const method = arguments[0];
            const url = arguments[1];
            
            // Remember if this is a modifying request
            this._isModifying = ['POST', 'PUT', 'DELETE', 'PATCH'].includes(method.toUpperCase());
            
            // Check if this is a same-origin request
            try {
                const requestUrl = new URL(url, window.location.href);
                this._isSameOrigin = requestUrl.origin === window.location.origin;
            } catch (e) {
                this._isSameOrigin = true; // Assume same origin for relative URLs
            }
            
            return originalOpen.apply(this, arguments);
        };
        
        // Intercept XHR send
        XMLHttpRequest.prototype.send = function() {
            // Add CSRF header for modifying same-origin requests
            if (this._isModifying && this._isSameOrigin) {
                this.setRequestHeader(headerName, getToken());
            }
            
            return originalSend.apply(this, arguments);
        };
        
        // Add CSRF token to fetch requests as well
        const originalFetch = window.fetch;
        window.fetch = function(resource, init = {}) {
            // Only modify same-origin requests
            let url;
            try {
                url = new URL(resource.toString(), window.location.href);
            } catch (e) {
                return originalFetch.apply(this, arguments);
            }
            
            // Check if this is a same-origin modifying request
            if (url.origin === window.location.origin && 
                init.method && 
                ['POST', 'PUT', 'DELETE', 'PATCH'].includes(init.method.toUpperCase())) {
                
                // Create headers if not exists
                if (!init.headers) {
                    init.headers = {};
                }
                
                // Add token to headers
                if (init.headers instanceof Headers) {
                    init.headers.append(headerName, getToken());
                } else {
                    init.headers[headerName] = getToken();
                }
            }
            
            return originalFetch.call(this, resource, init);
        };
    }
    
    /**
     * Validate a token against the stored token
     * @param {string} token - The token to validate
     * @returns {boolean} True if token is valid
     */
    validateToken(token) {
        const storedToken = this.getToken();
        return token === storedToken;
    }
    
    /**
     * Refresh the CSRF token
     * @returns {string} The new token
     */
    refreshToken() {
        const token = this.generateToken();
        sessionStorage.setItem(this.tokenName, token);
        return token;
    }
}

// Initialize Anti-CSRF protection
window.AntiForgery = new AntiForgery();
