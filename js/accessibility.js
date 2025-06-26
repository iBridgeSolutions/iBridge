/**
 * iBridge Website - Accessibility Enhancements
 */

document.addEventListener('DOMContentLoaded', function() {
    // Add ARIA attributes to elements that need them
    enhanceAccessibility();
    
    // Add keyboard navigation support
    addKeyboardSupport();
    
    // Add skip to content functionality
    setupSkipToContent();
});

/**
 * Enhance accessibility by adding ARIA attributes to elements
 */
function enhanceAccessibility() {
    // Add role="navigation" to nav elements without it
    document.querySelectorAll('nav:not([role])').forEach(nav => {
        nav.setAttribute('role', 'navigation');
    });
    
    // Add aria-label to links that only contain icons
    document.querySelectorAll('a:not([aria-label])').forEach(link => {
        if (link.textContent.trim() === '' && link.querySelector('i, .icon, img')) {
            const imgAlt = link.querySelector('img')?.getAttribute('alt');
            const iconClass = link.querySelector('i, .icon')?.className || '';
            let label = '';
            
            if (imgAlt) {
                label = imgAlt;
            } else if (iconClass.includes('facebook')) {
                label = 'Follow us on Facebook';
            } else if (iconClass.includes('twitter')) {
                label = 'Follow us on Twitter';
            } else if (iconClass.includes('linkedin')) {
                label = 'Follow us on LinkedIn';
            } else if (iconClass.includes('instagram')) {
                label = 'Follow us on Instagram';
            } else if (iconClass.includes('phone')) {
                label = 'Call us';
            } else if (iconClass.includes('envelope')) {
                label = 'Email us';
            }
            
            if (label) {
                link.setAttribute('aria-label', label);
            }
        }
    });
    
    // Add aria-required to required form fields
    document.querySelectorAll('input[required], textarea[required]').forEach(field => {
        field.setAttribute('aria-required', 'true');
    });
    
    // Add appropriate roles to sections
    document.querySelectorAll('section:not([role])').forEach(section => {
        section.setAttribute('role', 'region');
        if (!section.hasAttribute('aria-label') && !section.hasAttribute('aria-labelledby')) {
            const heading = section.querySelector('h1, h2, h3, h4, h5, h6');
            if (heading) {
                const headingId = heading.id || `heading-${Math.random().toString(36).substring(2, 9)}`;
                heading.id = headingId;
                section.setAttribute('aria-labelledby', headingId);
            }
        }
    });
}

/**
 * Add keyboard navigation support
 */
function addKeyboardSupport() {
    // Add keyboard support for dropdown menus
    document.querySelectorAll('.has-dropdown').forEach(dropdown => {
        const link = dropdown.querySelector('.nav-link');
        const menu = dropdown.querySelector('.dropdown-menu');
        
        if (link && menu) {
            link.setAttribute('aria-expanded', 'false');
            link.setAttribute('aria-haspopup', 'true');
            
            link.addEventListener('keydown', function(e) {
                if (e.key === 'Enter' || e.key === ' ') {
                    e.preventDefault();
                    const expanded = link.getAttribute('aria-expanded') === 'true';
                    link.setAttribute('aria-expanded', !expanded);
                    menu.classList.toggle('active');
                }
            });
        }
    });
    
    // Close dropdowns when pressing Escape
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape') {
            document.querySelectorAll('.dropdown-menu.active').forEach(menu => {
                menu.classList.remove('active');
                const link = menu.parentElement.querySelector('.nav-link');
                if (link) {
                    link.setAttribute('aria-expanded', 'false');
                }
            });
        }
    });
}

/**
 * Setup skip to content functionality
 */
function setupSkipToContent() {
    const skipLink = document.querySelector('.skip-link');
    if (skipLink) {
        skipLink.addEventListener('click', function(e) {
            e.preventDefault();
            const target = document.querySelector(this.getAttribute('href'));
            if (target) {
                target.setAttribute('tabindex', '-1');
                target.focus();
            }
        });
    }
}
