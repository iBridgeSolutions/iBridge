/**
 * iBridge Website - Main JavaScript
 * Vanilla JS implementation with mobile-first approach
 */

// DOM Elements
const nav = document.querySelector('.nav');
const navMenu = document.querySelector('.nav-menu');
const dropdownToggles = document.querySelectorAll('.dropdown-toggle');
const yearSpan = document.getElementById('currentYear');
const scrollTopBtn = document.querySelector('.scroll-top');

// Set current year in footer
if (yearSpan) {
    yearSpan.textContent = new Date().getFullYear();
}

// Navigation code
// No mobile menu toggle needed as it's been removed

// Dropdown Menus
dropdownToggles.forEach(toggle => {
    toggle.addEventListener('click', (e) => {
        e.preventDefault();
        const expanded = toggle.getAttribute('aria-expanded') === 'true' || false;
        toggle.setAttribute('aria-expanded', !expanded);
        
        // Find the dropdown menu
        const dropdown = toggle.nextElementSibling;
        dropdown.classList.toggle('active');
        
        // Close other open dropdowns
        dropdownToggles.forEach(otherToggle => {
            if (otherToggle !== toggle) {
                otherToggle.setAttribute('aria-expanded', 'false');
                otherToggle.nextElementSibling.classList.remove('active');
            }
        });
    });
});

// Handle click outside to close dropdown
document.addEventListener('click', (e) => {
    if (!e.target.closest('.dropdown')) {
        dropdownToggles.forEach(toggle => {
            toggle.setAttribute('aria-expanded', 'false');
            const dropdown = toggle.nextElementSibling;
            if (dropdown) dropdown.classList.remove('active');
        });
    }
});

// Header scroll effect
function handleHeaderScroll() {
    if (window.scrollY > 50) {
        nav.classList.add('scrolled');
    } else {
        nav.classList.remove('scrolled');
    }
}

// Scroll to top button
function handleScrollButton() {
    if (window.scrollY > 300) {
        scrollTopBtn?.classList.add('visible');
    } else {
        scrollTopBtn?.classList.remove('visible');
    }
}

// Scroll to top function
if (scrollTopBtn) {
    scrollTopBtn.addEventListener('click', () => {
        window.scrollTo({
            top: 0,
            behavior: 'smooth'
        });
    });
}

// Scroll event listeners
window.addEventListener('scroll', () => {
    handleHeaderScroll();
    handleScrollButton();
});

// Enhanced Animation Observer for Services Page
const observerOptions = {
    root: null,
    rootMargin: '50px',
    threshold: [0.1, 0.25, 0.5]
};

const animationObserver = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            entry.target.classList.add('fade-in', 'visible');
            entry.target.style.opacity = '1';
            entry.target.style.transform = 'translateY(0)';
            
            // Don't unobserve service elements to prevent disappearing
            const isServiceElement = entry.target.matches('.service-card, .feature-card, .benefit-card, .approach-card');
            if (!isServiceElement) {
                animationObserver.unobserve(entry.target);
            }
        }
    });
}, observerOptions);

// Enhanced animation elements selector
const animatedElements = document.querySelectorAll(
    '.animate-on-scroll, .section, .service-card, .feature-card, .team-member, .image-placeholder, .benefit-card, .approach-card'
);

// Apply animation observer to all elements
animatedElements.forEach(element => {
    animationObserver.observe(element);
});

// Animation on scroll for sections, cards, and images (Enhanced)
function animateOnScroll() {
    const animatedEls = document.querySelectorAll('.section, .service-card, .feature-card, .team-member, .image-placeholder');
    animatedEls.forEach(el => {
        const rect = el.getBoundingClientRect();
        if (rect.top < window.innerHeight - 60) {
            el.classList.add('visible');
            el.style.opacity = '1';
            el.style.transform = 'translateY(0)';
        }
    });
}

// Form validation
const contactForm = document.querySelector('.contact-form');

if (contactForm) {
    contactForm.addEventListener('submit', function(e) {
        e.preventDefault();
        
        // Simple form validation
        const name = this.querySelector('[name="name"]');
        const email = this.querySelector('[name="email"]');
        const message = this.querySelector('[name="message"]');
        let isValid = true;
        
        // Clear previous error messages
        document.querySelectorAll('.form-error-message').forEach(el => el.remove());
        
        // Validate name
        if (!name.value.trim()) {
            addErrorMessage(name, 'Please enter your name');
            isValid = false;
        }
        
        // Validate email
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!email.value.trim() || !emailRegex.test(email.value)) {
            addErrorMessage(email, 'Please enter a valid email address');
            isValid = false;
        }
        
        // Validate message
        if (!message.value.trim()) {
            addErrorMessage(message, 'Please enter your message');
            isValid = false;
        }
        
        if (isValid) {
            // Show success message
            const successMessage = document.createElement('div');
            successMessage.className = 'form-success';
            successMessage.textContent = 'Your message has been sent. We will contact you soon!';
            contactForm.prepend(successMessage);
            
            // Reset form
            contactForm.reset();
            
            // Remove success message after 5 seconds
            setTimeout(() => {
                successMessage.remove();
            }, 5000);
        }
    });
}

// Helper function to add error message
function addErrorMessage(element, message) {
    const errorMessage = document.createElement('div');
    errorMessage.className = 'form-error-message';
    errorMessage.textContent = message;
    errorMessage.style.color = 'red';
    errorMessage.style.fontSize = '0.8rem';
    errorMessage.style.marginTop = '5px';
    element.parentNode.appendChild(errorMessage);
    element.classList.add('error');
}

// Tab functionality
const tabButtons = document.querySelectorAll('[role="tab"]');
const tabPanels = document.querySelectorAll('[role="tabpanel"]');

tabButtons.forEach(button => {
    button.addEventListener('click', () => {
        // Deactivate all tabs
        tabButtons.forEach(btn => {
            btn.setAttribute('aria-selected', 'false');
            btn.classList.remove('active');
        });
        
        // Hide all tab panels
        tabPanels.forEach(panel => {
            panel.hidden = true;
        });
        
        // Activate clicked tab
        button.setAttribute('aria-selected', 'true');
        button.classList.add('active');
        
        // Show corresponding panel
        const panelId = button.getAttribute('aria-controls');
        const panel = document.getElementById(panelId);
        if (panel) panel.hidden = false;
    });
});

// Comprehensive DOMContentLoaded handler
document.addEventListener('DOMContentLoaded', () => {
    console.log('iBridge Website Loaded');
    
    // Initialize all functionality
    initScrollAnimations();
    initSmoothScrolling();
    initHeaderScrollEffect();
    initScrollToTop();
    initMobileNavigation();
    
    // Add error handling
    window.addEventListener('error', function(e) {
        console.warn('Non-critical error:', e.message);
    });
});

// Enhanced Scroll Animations with Intersection Observer
function initScrollAnimations() {
    // Create intersection observer for animations
    const observerOptions = {
        threshold: 0.1,
        rootMargin: '0px 0px -50px 0px'
    };
    
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('visible');
                // Don't unobserve to allow re-animation if needed
            }
        });
    }, observerOptions);
    
    // Observe all sections and animated elements
    const elementsToAnimate = document.querySelectorAll('.section, .animate-on-scroll, .team-member, .service-card, .feature-item');
    
    elementsToAnimate.forEach(element => {
        // Ensure elements start invisible for animation
        if (!element.classList.contains('visible')) {
            element.style.opacity = '0';
            element.style.transform = 'translateY(40px)';
            element.style.transition = 'opacity 0.7s cubic-bezier(.4,0,.2,1), transform 0.7s cubic-bezier(.4,0,.2,1)';
        }
        observer.observe(element);
    });
    
    // Fallback for elements that should always be visible
    setTimeout(() => {
        const stillHidden = document.querySelectorAll('.section:not(.visible), .animate-on-scroll:not(.visible)');
        stillHidden.forEach(element => {
            const rect = element.getBoundingClientRect();
            if (rect.top < window.innerHeight && rect.bottom > 0) {
                element.classList.add('visible');
            }
        });
    }, 1000);
}

// Smooth Scrolling for Navigation Links
function initSmoothScrolling() {
    const navLinks = document.querySelectorAll('a[href^="#"]');
    
    navLinks.forEach(link => {
        link.addEventListener('click', function(e) {
            e.preventDefault();
            
            const targetId = this.getAttribute('href');
            const targetElement = document.querySelector(targetId);
            
            if (targetElement) {
                const headerHeight = document.querySelector('.header')?.offsetHeight || 70;
                const targetPosition = targetElement.offsetTop - headerHeight;
                
                window.scrollTo({
                    top: targetPosition,
                    behavior: 'smooth'
                });
            }
        });
    });
}

// Header Scroll Effect
function initHeaderScrollEffect() {
    const header = document.querySelector('.header');
    const nav = document.querySelector('.nav');
    
    if (!header) return;
    
    let lastScrollY = window.scrollY;
    let ticking = false;
    
    function updateHeader() {
        const scrollY = window.scrollY;
        
        if (scrollY > 50) {
            header.classList.add('scrolled');
            if (nav) nav.classList.add('scrolled');
        } else {
            header.classList.remove('scrolled');
            if (nav) nav.classList.remove('scrolled');
        }
        
        lastScrollY = scrollY;
        ticking = false;
    }
    
    function requestTick() {
        if (!ticking) {
            requestAnimationFrame(updateHeader);
            ticking = true;
        }
    }
    
    window.addEventListener('scroll', requestTick, { passive: true });
}

// Scroll to Top Button
function initScrollToTop() {
    const scrollTopButton = document.querySelector('.scroll-top');
    
    if (!scrollTopButton) {
        // Create scroll to top button if it doesn't exist
        const button = document.createElement('button');
        button.className = 'scroll-top';
        button.innerHTML = '↑';
        button.setAttribute('aria-label', 'Scroll to top');
        document.body.appendChild(button);
        scrollTopButton = button;
    }
    
    let ticking = false;
    
    function updateScrollButton() {
        const scrollY = window.scrollY;
        
        if (scrollY > 300) {
            scrollTopButton.classList.add('visible');
        } else {
            scrollTopButton.classList.remove('visible');
        }
        
        ticking = false;
    }
    
    function requestTick() {
        if (!ticking) {
            requestAnimationFrame(updateScrollButton);
            ticking = true;
        }
    }
    
    window.addEventListener('scroll', requestTick, { passive: true });
    
    scrollTopButton.addEventListener('click', function() {
        window.scrollTo({
            top: 0,
            behavior: 'smooth'
        });
    });
}

// Mobile Navigation
function initMobileNavigation() {
    const mobileToggle = document.querySelector('.mobile-nav-toggle');
    const navMenu = document.querySelector('.nav-menu');
    
    if (mobileToggle && navMenu) {
        mobileToggle.addEventListener('click', function() {
            this.classList.toggle('active');
            navMenu.classList.toggle('active');
            document.body.classList.toggle('nav-open');
        });
        
        // Close mobile nav when clicking on a link
        const navLinks = navMenu.querySelectorAll('.nav-link');
        navLinks.forEach(link => {
            link.addEventListener('click', function() {
                mobileToggle.classList.remove('active');
                navMenu.classList.remove('active');
                document.body.classList.remove('nav-open');
            });
        });
        
        // Close mobile nav when clicking outside
        document.addEventListener('click', function(e) {
            if (!navMenu.contains(e.target) && !mobileToggle.contains(e.target)) {
                mobileToggle.classList.remove('active');
                navMenu.classList.remove('active');
                document.body.classList.remove('nav-open');
            }
        });
    }
}

// Form Handling (if forms exist)
function initFormHandling() {
    const forms = document.querySelectorAll('form');
    
    forms.forEach(form => {
        form.addEventListener('submit', function(e) {
            e.preventDefault();
            
            // Add your form submission logic here
            console.log('Form submitted');
            
            // Show success message
            const successMessage = document.createElement('div');
            successMessage.className = 'alert alert-success';
            successMessage.textContent = 'Thank you for your message! We will get back to you soon.';
            
            form.appendChild(successMessage);
            
            setTimeout(() => {
                successMessage.remove();
            }, 5000);
        });
    });
}

// Initialize forms if they exist
document.addEventListener('DOMContentLoaded', function() {
    setTimeout(initFormHandling, 100);
});

// Utility Functions
function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

// Performance optimization
const throttle = (func, delay) => {
    let inProgress = false;
    return (...args) => {
        if (inProgress) return;
        inProgress = true;
        setTimeout(() => {
            func(...args);
            inProgress = false;
        }, delay);
    };
};

// Error handling for missing elements
function safeQuerySelector(selector) {
    try {
        return document.querySelector(selector);
    } catch (e) {
        console.warn(`Element not found: ${selector}`);
        return null;
    }
}

function safeQuerySelectorAll(selector) {
    try {
        return document.querySelectorAll(selector);
    } catch (e) {
        console.warn(`Elements not found: ${selector}`);
        return [];
    }
}