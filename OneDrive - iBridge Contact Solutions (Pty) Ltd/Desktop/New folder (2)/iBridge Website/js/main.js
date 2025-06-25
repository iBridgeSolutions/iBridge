// iBridge Website JavaScript
(function() {
    'use strict';

    // DOM Content Loaded
    document.addEventListener('DOMContentLoaded', function() {
        initializeNavigation();
        initializeCurrentYear();
        initializeScrollEffects();
        initializeFormHandling();
        initializeAnimations();
        initializeTestimonials();
        initializeContact();
        initializePerformance();
        initializeAccessibility();
        initializeMobileNavigation();
        initializeSmoothScrolling();
        initializeBackToTopButton();
        createScrollToTop();
        enhanceFormHandling();
        initPerformanceMonitoring();
        enhanceAccessibility();
        enhanceSEO();
        initializeDarkModeToggle();
        
        // Fallback: Make all animated elements visible immediately
        document.querySelectorAll('.animated, .staggered-item').forEach(function(el) {
            el.classList.add('in-view');
        });
    });

    // Navigation functionality
    function initializeNavigation() {
        const navToggle = document.querySelector('.nav-toggle');
        const navMenu = document.querySelector('.nav-menu');
        const navLinks = document.querySelectorAll('.nav-link');

        // Mobile menu toggle
        if (navToggle && navMenu) {
            navToggle.addEventListener('click', function() {
                const isExpanded = navToggle.getAttribute('aria-expanded') === 'true';
                navToggle.setAttribute('aria-expanded', !isExpanded);
                navMenu.classList.toggle('active');
            });
        }

        // Close mobile menu when clicking nav links
        navLinks.forEach(function(link) {
            link.addEventListener('click', function() {
                if (navMenu?.classList.contains('active')) {
                    navMenu.classList.remove('active');
                    navToggle?.setAttribute('aria-expanded', 'false');
                }
            });
        });

        // Close mobile menu when clicking outside
        document.addEventListener('click', function(e) {
            if (navMenu?.classList.contains('active')) {
                if (!navMenu.contains(e.target) && !navToggle.contains(e.target)) {
                    navMenu.classList.remove('active');
                    navToggle?.setAttribute('aria-expanded', 'false');
                }
            }
        });

        // Handle dropdown menus with keyboard navigation
        const dropdowns = document.querySelectorAll('.dropdown');
        dropdowns.forEach(function(dropdown) {
            const toggle = dropdown.querySelector('.dropdown-toggle');
            const menu = dropdown.querySelector('.dropdown-menu');

            if (toggle && menu) {
                toggle.addEventListener('keydown', function(e) {
                    if (e.key === 'Enter' || e.key === ' ') {
                        e.preventDefault();
                        const isExpanded = toggle.getAttribute('aria-expanded') === 'true';
                        toggle.setAttribute('aria-expanded', !isExpanded);
                        menu.style.display = isExpanded ? 'none' : 'block';
                    }
                });
            }
        });

        // Keyboard navigation for custom elements
        const focusableElements = document.querySelectorAll('button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])');
        focusableElements.forEach(function(element) {
            element.addEventListener('keydown', function(e) {
                if (e.key === 'Enter' && element.tagName === 'BUTTON') {
                    element.click();
                }
            });
        });
    }

    // Update current year in footer
    function initializeCurrentYear() {
        const currentYearElement = document.getElementById('currentYear');
        if (currentYearElement) {
            currentYearElement.textContent = new Date().getFullYear();
        }
    }

    // Scroll effects
    function initializeScrollEffects() {
        // Smooth scrolling for anchor links
        const anchorLinks = document.querySelectorAll('a[href^="#"]');
        anchorLinks.forEach(function(link) {
            link.addEventListener('click', function(e) {
                const href = this.getAttribute('href');
                if (href === '#') return;

                const target = document.querySelector(href);
                if (target) {
                    e.preventDefault();
                    const headerHeight = document.querySelector('.header').offsetHeight;
                    const targetPosition = target.offsetTop - headerHeight - 20;
                    
                    window.scrollTo({
                        top: targetPosition,
                        behavior: 'smooth'
                    });
                }
            });
        });

        // Header scroll effect
        const header = document.querySelector('.header');
        window.addEventListener('scroll', function() {
            const scrollTop = window.pageYOffset || document.documentElement.scrollTop;

            // Add/remove scrolled class for styling
            if (scrollTop > 100) {
                header?.classList.add('scrolled');
            } else {
                header?.classList.remove('scrolled');
            }
        });

        // Intersection Observer for animations
        if ('IntersectionObserver' in window) {
            const observerOptions = {
                threshold: 0.1,
                rootMargin: '0px 0px -50px 0px'
            };

            const observer = new IntersectionObserver(function(entries) {
                entries.forEach(function(entry) {
                    if (entry.isIntersecting) {
                        entry.target.classList.add('animate-in');
                    }
                });
            }, observerOptions);

            // Observe elements for animation
            const animateElements = document.querySelectorAll('.service-card, .feature-card, .testimonial-card, .contact-item');
            animateElements.forEach(function(el) {
                observer.observe(el);
            });
        }
    }

    // Form handling
    function initializeFormHandling() {
        const forms = document.querySelectorAll('form');

        // Move callback functions outside to avoid deep nesting
        function requiredFieldCallbackFactory(isValidRef) {
            return function(field, valid) {
                if (!valid) isValidRef.value = false;
            };
        }

        function emailFieldCallbackFactory(isValidRef) {
            return function(field, valid) {
                if (!valid) {
                    isValidRef.value = false;
                    // Optionally, add a custom property or log for email-specific validation
                    field.dataset.emailError = "true";
                } else {
                    delete field.dataset.emailError;
                }
            };
        }

        forms.forEach(function(form) {
            form.addEventListener('submit', function(e) {
                e.preventDefault();

                // Basic form validation
                const requiredFields = form.querySelectorAll('[required]');
                let isValid = { value: true };

                validateRequiredFields(requiredFields, requiredFieldCallbackFactory(isValid));

                // Email validation
                const emailFields = form.querySelectorAll('input[type="email"]');

                validateEmailFields(emailFields, emailFieldCallbackFactory(isValid));

                if (isValid.value) {
                    // Show success message
                    showMessage('Thank you for your message! We will get back to you soon.', 'success');
                    form.reset();
                } else {
                    showMessage('Please correct the errors below.', 'error');
                }
            });
        });
    }

    // Helper for required fields validation
    function validateRequiredFields(fields, callback) {
        fields.forEach(function(field) {
            if (!field.value.trim()) {
                field.classList.add('error');
                showFieldError(field, 'This field is required');
                callback(field, false);
            } else {
                field.classList.remove('error');
                hideFieldError(field);
                callback(field, true);
            }
        });
    }

    // Helper for email fields validation
    function validateEmailFields(fields, callback) {
        fields.forEach(function(field) {
            if (field.value && !isValidEmail(field.value)) {
                field.classList.add('error');
                showFieldError(field, 'Please enter a valid email address');
                callback(field, false);
            } else {
                callback(field, true);
            }
        });
    }

    // Utility functions
    function isValidEmail(email) {
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        return emailRegex.test(email);
    }

    function showFieldError(field, message) {
        hideFieldError(field);
        const errorElement = document.createElement('div');
        errorElement.className = 'field-error';
        errorElement.textContent = message;
        field.parentNode.appendChild(errorElement);
    }

    function hideFieldError(field) {
        const existingError = field.parentNode.querySelector('.field-error');
        if (existingError) {
            existingError.remove();
        }
    }

    function showMessage(message, type) {
        // Remove existing messages
        const existingMessages = document.querySelectorAll('.message');
        existingMessages.forEach(function(msg) {
            msg.remove();
        });

        // Create new message
        const messageElement = document.createElement('div');
        messageElement.className = `message message-${type}`;
        messageElement.textContent = message;
        
        // Insert at top of page
        document.body.insertBefore(messageElement, document.body.firstChild);
        
        // Auto-remove after 5 seconds
        setTimeout(function() {
            messageElement.remove();
        }, 5000);
    }

    // Initialize animations
    function initializeAnimations() {
        // Ensure body is visible immediately
        document.body.style.opacity = '1';
        document.body.style.transform = 'none';
        
        // Services page specific fixes - ensure all service content is visible
        const serviceElements = document.querySelectorAll('.service-card, .feature-card, .benefit-card, .approach-card');
        serviceElements.forEach(function(element) {
            element.style.opacity = '1';
            element.style.transform = 'translateY(0)';
            element.classList.add('visible');
        });
        
        // Add fade-in animation for other elements
        const fadeElements = document.querySelectorAll('.fade-in');
        
        // Use Intersection Observer for fade-in animations
        if ('IntersectionObserver' in window) {
            const observerOptions = {
                threshold: 0.1,
                rootMargin: '0px 0px -20px 0px'
            };

            const fadeObserver = new IntersectionObserver(function(entries) {
                entries.forEach(function(entry) {
                    if (entry.isIntersecting) {
                        entry.target.classList.add('visible');
                        // Don't unobserve service elements to prevent content disappearing
                        if (!entry.target.classList.contains('service-card') && 
                            !entry.target.classList.contains('feature-card') &&
                            !entry.target.classList.contains('benefit-card') &&
                            !entry.target.classList.contains('approach-card')) {
                            fadeObserver.unobserve(entry.target);
                        }
                    }
                });
            }, observerOptions);

            // Observe fade-in elements
            fadeElements.forEach(function(element) {
                fadeObserver.observe(element);
            });
        } else {
            // Fallback - make all elements visible
            fadeElements.forEach(function(element) {
                element.classList.add('visible');
            });
        }
        
        // Hero content immediate visibility
        const heroContent = document.querySelector('.hero-content');
        if (heroContent) {
            heroContent.classList.add('visible');
            heroContent.style.opacity = '1';
        }
    }

    // Testimonials slider functionality
    function initializeTestimonials() {
        const testimonials = document.querySelectorAll('.testimonial-card');
        let currentTestimonial = 0;

        if (testimonials.length > 1) {
            // Auto-rotate testimonials every 5 seconds
            setInterval(function() {
                testimonials[currentTestimonial].classList.remove('active');
                currentTestimonial = (currentTestimonial + 1) % testimonials.length;
                testimonials[currentTestimonial].classList.add('active');
            }, 5000);

            // Initialize first testimonial as active
            if (testimonials[0]) {
                testimonials[0].classList.add('active');
            }
        }
    }

    // Testimonials Carousel
    document.addEventListener('DOMContentLoaded', function() {
        const testimonialSlides = document.querySelectorAll('.testimonial-card');
        const prevButton = document.querySelector('.testimonial-prev');
        const nextButton = document.querySelector('.testimonial-next');
        const indicators = document.querySelectorAll('.testimonial-indicator');
        
        if (!testimonialSlides.length) return;
        
        let currentSlide = 0;
        
        // Initialize the carousel
        function initCarousel() {
            testimonialSlides[currentSlide].classList.add('active');
            if (indicators.length) indicators[currentSlide].classList.add('active');
        }
        
        // Go to specific slide
        function goToSlide(index) {
            // Remove active class from all slides and indicators
            testimonialSlides.forEach(slide => slide.classList.remove('active'));
            if (indicators.length) indicators.forEach(dot => dot.classList.remove('active'));
            
            // Add active class to current slide and indicator
            testimonialSlides[index].classList.add('active');
            if (indicators.length) indicators[index].classList.add('active');
            
            currentSlide = index;
        }
        
        // Next slide function
        function nextSlide() {
            let nextIndex = currentSlide + 1;
            if (nextIndex >= testimonialSlides.length) nextIndex = 0;
            goToSlide(nextIndex);
        }
        
        // Previous slide function
        function prevSlide() {
            let prevIndex = currentSlide - 1;
            if (prevIndex < 0) prevIndex = testimonialSlides.length - 1;
            goToSlide(prevIndex);
        }
        
        // Event listeners
        if (prevButton && nextButton) {
            prevButton.addEventListener('click', prevSlide);
            nextButton.addEventListener('click', nextSlide);
        }
        
        // Indicator clicks
        if (indicators.length) {
            indicators.forEach((indicator, index) => {
                indicator.addEventListener('click', () => goToSlide(index));
            });
        }
        
        // Initialize the carousel
        initCarousel();
        
        // Auto-play (optional)
        const interval = setInterval(nextSlide, 6000);
        
        // Stop auto-play when user interacts with carousel
        const carousel = document.querySelector('.testimonials-carousel');
        if (carousel) {
            carousel.addEventListener('mouseenter', () => clearInterval(interval));
        }
    });

    // Enhance testimonial carousel accessibility and keyboard navigation
    (function enhanceTestimonialCarouselAccessibility() {
        const prevBtn = document.querySelector('.testimonial-prev');
        const nextBtn = document.querySelector('.testimonial-next');
        const indicators = document.querySelectorAll('.indicator');
        const slides = document.querySelectorAll('.testimonial-slide');
        let current = 0;

        function goToSlide(idx) {
            slides.forEach((slide, i) => {
                slide.classList.toggle('active', i === idx);
            });
            indicators.forEach((ind, i) => {
                ind.classList.toggle('active', i === idx);
                ind.setAttribute('aria-selected', i === idx ? 'true' : 'false');
                ind.setAttribute('tabindex', i === idx ? '0' : '-1');
            });
            current = idx;
        }

        if (prevBtn && nextBtn && indicators.length) {
            prevBtn.addEventListener('click', () => goToSlide((current - 1 + slides.length) % slides.length));
            nextBtn.addEventListener('click', () => goToSlide((current + 1) % slides.length));
            indicators.forEach((ind, idx) => {
                ind.addEventListener('click', () => goToSlide(idx));
                ind.addEventListener('keydown', e => {
                    if (e.key === 'Enter' || e.key === ' ') {
                        e.preventDefault();
                        goToSlide(idx);
                    }
                    if (e.key === 'ArrowLeft') {
                        e.preventDefault();
                        goToSlide((current - 1 + slides.length) % slides.length);
                    }
                    if (e.key === 'ArrowRight') {
                        e.preventDefault();
                        goToSlide((current + 1) % slides.length);
                    }
                });
            });
            // Set initial ARIA state
            goToSlide(0);
        }
    })();

    // Contact functionality
    function initializeContact() {
        // WhatsApp integration
        const whatsappButton = document.querySelector('.whatsapp-float');
        if (whatsappButton) {
            whatsappButton.addEventListener('click', function(e) {
                e.preventDefault();
                const message = 'Hello! I would like to know more about iBridge services.';
                const whatsappUrl = `https://wa.me/27111234567?text=${encodeURIComponent(message)}`;
                window.open(whatsappUrl, '_blank');
            });
        }

        // Phone number formatting
        const phoneLinks = document.querySelectorAll('a[href^="tel:"]');
        phoneLinks.forEach(function(link) {
            link.addEventListener('click', function() {
                // Track phone call analytics if needed
                if (typeof gtag !== 'undefined') {
                    gtag('event', 'phone_call', {
                        'event_category': 'Contact',
                        'event_label': 'Header Phone'
                    });
                }
            });
        });
    }

    // Performance optimization
    function initializePerformance() {
        // Lazy loading for images
        if ('IntersectionObserver' in window) {
            const imageObserver = new IntersectionObserver(function(entries) {
                entries.forEach(function(entry) {
                    if (entry.isIntersecting) {
                        const img = entry.target;
                        img.src = img.dataset.src;
                        img.classList.remove('lazy');
                        imageObserver.unobserve(img);
                    }
                });
            });

            const lazyImages = document.querySelectorAll('img[data-src]');
            lazyImages.forEach(function(img) {
                imageObserver.observe(img);
            });
        }
    }

    // Accessibility enhancements
    function initializeAccessibility() {
        // Skip link functionality
        const skipLink = document.querySelector('.skip-link');
        if (skipLink) {
            skipLink.addEventListener('click', function(e) {
                e.preventDefault();
                const target = document.querySelector('#main-content');
                if (target) {
                    target.focus();
                    target.scrollIntoView();
                }
            });
        }

        // Focus management for modals and dropdowns
        document.addEventListener('keydown', function(e) {
            if (e.key === 'Escape') {
                // Close mobile menu
                const navMenu = document.querySelector('.nav-menu');
                const navToggle = document.querySelector('.nav-toggle');
                if (navMenu?.classList.contains('active')) {
                    navMenu.classList.remove('active');
                    if (navToggle) {
                        navToggle.setAttribute('aria-expanded', 'false');
                        navToggle.focus();
                    }
                }
            }
        });
    }

    // Mobile navigation enhancements
    function initializeMobileNavigation() {
        const mobileMenuButton = document.querySelector('.mobile-menu-toggle');
        const mobileMenu = document.querySelector('.mobile-menu');
        
        if (mobileMenuButton && mobileMenu) {
            mobileMenuButton.addEventListener('click', function() {
                const isOpen = mobileMenu.classList.contains('open');
                mobileMenu.classList.toggle('open');
                mobileMenuButton.setAttribute('aria-expanded', !isOpen);
                
                // Prevent body scroll when menu is open
                document.body.style.overflow = isOpen ? '' : 'hidden';
            });
        }

        // Close mobile menu on window resize
        window.addEventListener('resize', function() {
            if (window.innerWidth > 768 && mobileMenu) {
                mobileMenu.classList.remove('open');
                document.body.style.overflow = '';
                if (mobileMenuButton) {
                    mobileMenuButton.setAttribute('aria-expanded', 'false');
                }
            }
        });
    }

    // Smooth scrolling enhancements
    function initializeSmoothScrolling() {
        // Polyfill for browsers that don't support smooth scrolling
        if (!('scrollBehavior' in document.documentElement.style)) {
            const script = document.createElement('script');
            script.src = 'https://cdn.jsdelivr.net/gh/iamdustan/smoothscroll@master/src/smoothscroll.js';
            document.head.appendChild(script);
        }
    }

    // Back to top button
    function initializeBackToTopButton() {
        const btn = document.querySelector('.back-to-top');
        if (!btn) return;
        window.addEventListener('scroll', function() {
            if (window.scrollY > 300) {
                btn.classList.add('visible');
            } else {
                btn.classList.remove('visible');
            }
        });
        btn.addEventListener('click', function() {
            window.scrollTo({ top: 0, behavior: 'smooth' });
        });
        btn.addEventListener('keydown', function(e) {
            if (e.key === 'Enter' || e.key === ' ') {
                e.preventDefault();
                btn.click();
            }
        });
    }

    // Service page functionality
    function initializeServicePages() {
        // Service cards hover effects
        const serviceCards = document.querySelectorAll('.service-card');
        serviceCards.forEach(function(card) {
            card.addEventListener('mouseenter', function() {
                this.style.transform = 'translateY(-5px)';
            });
            
            card.addEventListener('mouseleave', function() {
                this.style.transform = 'translateY(0)';
            });
        });
    }

    // Counter animation for statistics
    function initializeCounters() {
        const counters = document.querySelectorAll('.counter');
        
        // Helper function moved outside to reduce nesting
        function updateCounter(counter, target, increment, current, observer) {
            if (current < target) {
                current += increment;
                counter.textContent = Math.ceil(current);
                setTimeout(() => updateCounter(counter, target, increment, current, observer), 10);
            } else {
                counter.textContent = target;
            }
        }

        if ('IntersectionObserver' in window) {
            const counterObserver = new IntersectionObserver(function(entries) {
                entries.forEach(function(entry) {
                    if (entry.isIntersecting) {
                        const counter = entry.target;
                        const target = parseInt(counter.getAttribute('data-target'));
                        const increment = target / 200;
                        let current = 0;
                        
                        updateCounter(counter, target, increment, current, counterObserver);
                        counterObserver.unobserve(counter);
                    }
                });
            });

            counters.forEach(function(counter) {
                counterObserver.observe(counter);
            });
        }
    }

    // Helper function to close all FAQ items except the current one
    function closeOtherFAQItems(faqItems, currentItem) {
        faqItems.forEach(function(otherItem) {
            if (otherItem !== currentItem) {
                otherItem.classList.remove('open');
            }
        });
    }

    // FAQ accordion functionality
    function initializeFAQ() {
        const faqItems = document.querySelectorAll('.faq-item');
        
        faqItems.forEach(function(item) {
            const question = item.querySelector('.faq-question');
            const answer = item.querySelector('.faq-answer');
            
            if (question && answer) {
                question.addEventListener('click', function() {
                    const isOpen = item.classList.contains('open');
                    
                    // Close all other FAQ items using helper
                    closeOtherFAQItems(faqItems, item);
                    
                    // Toggle current item
                    item.classList.toggle('open');
                    question.setAttribute('aria-expanded', !isOpen);
                });
            }
        });
    }

    // Scroll to Top Button
    function createScrollToTop() {
        const scrollBtn = document.createElement('button');
        scrollBtn.className = 'scroll-top';
        scrollBtn.innerHTML = '↑';
        scrollBtn.setAttribute('aria-label', 'Scroll to top');
        scrollBtn.setAttribute('title', 'Scroll to top');
        document.body.appendChild(scrollBtn);

        // Show/hide button based on scroll position
        window.addEventListener('scroll', () => {
            if (window.pageYOffset > 300) {
                scrollBtn.classList.add('visible');
            } else {
                scrollBtn.classList.remove('visible');
            }
        });

        // Smooth scroll to top
        scrollBtn.addEventListener('click', () => {
            window.scrollTo({
                top: 0,
                behavior: 'smooth'
            });
        });
    }

    // Notification System
    function showNotification(message, type = 'info', duration = 3000) {
        const notification = document.createElement('div');
        notification.className = `notification ${type}`;
        notification.textContent = message;
        notification.setAttribute('role', 'alert');
        document.body.appendChild(notification);

        // Show notification
        setTimeout(() => notification.classList.add('show'), 100);

        // Hide and remove notification
        setTimeout(() => {
            notification.classList.remove('show');
            setTimeout(() => notification.remove(), 300);
        }, duration);
    }

    // Enhanced Form Handling with Loading States
    function enhanceFormHandling() {
        const forms = document.querySelectorAll('form');
        
        forms.forEach(form => {
            form.addEventListener('submit', handleFormSubmit);
        });
    }

    // Extracted async handler to reduce nesting
    async function handleFormSubmit(e) {
        e.preventDefault();
        const form = e.currentTarget;
        const submitBtn = form.querySelector('button[type="submit"]');
        const originalText = submitBtn.textContent;

        // Add loading state
        submitBtn.classList.add('loading');
        submitBtn.textContent = 'Sending...';
        submitBtn.disabled = true;

        try {
            // Simulate form submission (replace with actual API call)
            await new Promise(resolve => setTimeout(resolve, 2000));

            showNotification('Message sent successfully!', 'success');
            form.reset();
        } catch (error) {
            console.error('Form submission error:', error);
            showNotification('Failed to send message. Please try again.', 'error');
        } finally {
            // Remove loading state
            submitBtn.classList.remove('loading');
            submitBtn.textContent = originalText;
            submitBtn.disabled = false;
        }
    }

    // Performance Monitoring
    function initPerformanceMonitoring() {
        // Log page load time
        window.addEventListener('load', () => {
            const loadTime = Math.round(performance.now());
            console.log(`Page loaded in ${loadTime}ms`);
            
            // Track Core Web Vitals
            if ('web-vital' in window) {
                // This would integrate with actual web vitals library
                console.log('Web Vitals tracking initialized');
            }
        });
    }

    // Accessibility Enhancements
    function enhanceAccessibility() {
        // Add keyboard navigation for custom elements
        const interactiveElements = document.querySelectorAll('.service-card, .feature-card');
        
        interactiveElements.forEach(element => {
            element.setAttribute('tabindex', '0');
            
            element.addEventListener('keydown', (e) => {
                if (e.key === 'Enter' || e.key === ' ') {
                    e.preventDefault();
                    element.click();
                }
            });
        });
        
        // Enhanced focus management
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Tab') {
                document.body.classList.add('keyboard-navigation');
            }
        });
        
        document.addEventListener('mousedown', () => {
            document.body.classList.remove('keyboard-navigation');
        });
    }

    // SEO and Meta Tags Enhancement
    function enhanceSEO() {
        // Add structured data for organization
        const structuredData = {
            "@context": "https://schema.org",
            "@type": "Organization",
            "name": "iBridge Contact Solutions",
            "description": "Professional BPO and BPaaS services provider",
            "url": window.location.origin,
            "logo": `${window.location.origin}/images/logo.png`,
            "contactPoint": {
                "@type": "ContactPoint",
                "telephone": "+27-xxx-xxx-xxxx",
                "contactType": "customer service"
            },
            "address": {
                "@type": "PostalAddress",
                "addressCountry": "ZA"
            }
        };
        
        const script = document.createElement('script');
        script.type = 'application/ld+json';
        script.textContent = JSON.stringify(structuredData);
        document.head.appendChild(script);
    }

    // Dark mode toggle
    function initializeDarkModeToggle() {
        const toggle = document.querySelector('.dark-mode-toggle');
        if (!toggle) return;
        const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
        const saved = localStorage.getItem('darkMode');
        let dark = saved === 'true' || (saved === null && prefersDark);
        setDarkMode(dark);
        toggle.setAttribute('aria-pressed', dark);
        toggle.addEventListener('click', function() {
            dark = !dark;
            setDarkMode(dark);
            localStorage.setItem('darkMode', dark);
            toggle.setAttribute('aria-pressed', dark);
        });
    }
    function setDarkMode(enabled) {
        document.body.classList.toggle('dark-mode', enabled);
    }

    // Initialize all functionality when DOM is loaded
    document.addEventListener('DOMContentLoaded', function() {
        initializeNavigation();
        initializeCurrentYear();
        initializeScrollEffects();
        initializeFormHandling();
        initializeAnimations();
        initializeTestimonials();
        initializeContact();
        initializePerformance();
        initializeAccessibility();
        initializeMobileNavigation();
        initializeSmoothScrolling();
        initializeBackToTopButton();
        initializeServicePages();
        initializeCounters();
        initializeFAQ();
        createScrollToTop();
        enhanceFormHandling();
        initPerformanceMonitoring();
        enhanceAccessibility();
        enhanceSEO();
        initializeDarkModeToggle();
        initTimelineAnimation();
        
        // Ensure services page content is visible after all initialization
        setTimeout(function() {
            const allServiceContent = document.querySelectorAll('.service-card, .feature-card, .benefit-card, .approach-card');
            allServiceContent.forEach(function(element) {
                element.style.opacity = '1';
                element.style.transform = 'translateY(0)';
                element.classList.add('visible');
            });
        }, 100);
    });

    // Error handling
    window.addEventListener('error', function(e) {
        console.error('JavaScript error:', e.error);
        // Could send error to analytics or logging service
    });

    // Performance monitoring
    if ('performance' in window) {
        window.addEventListener('load', function() {
            setTimeout(function() {
                const perfData = performance.getEntriesByType('navigation')[0];
                console.log('Page load time:', perfData.loadEventEnd - perfData.loadEventStart);
            }, 0);
        });
    }

    // Service Worker Registration (for future PWA capabilities)
    if ('serviceWorker' in navigator) {
        window.addEventListener('load', () => {
            // This would register a service worker when implemented
            console.log('Service Worker support detected');
        });
    }

    // Timeline animation
    function initTimelineAnimation() {
        const timelineItems = document.querySelectorAll('.timeline-item');
        
        if (timelineItems.length > 0) {
            // Create IntersectionObserver to detect when timeline items enter the viewport
            const observer = new IntersectionObserver((entries) => {
                entries.forEach(entry => {
                    if (entry.isIntersecting) {
                        entry.target.classList.add('animate-in');
                        // Unobserve after animation to improve performance
                        observer.unobserve(entry.target);
                    }
                });
            }, {
                threshold: 0.2, // Trigger when 20% of item is visible
                rootMargin: '0px 0px -100px 0px' // Adjust when animation triggers
            });
            
            // Observe each timeline item
            timelineItems.forEach(item => {
                observer.observe(item);
            });
        }
    }

    // Helper functions for testimonial filtering
    function resetFilterButtons(filterBtns) {
        filterBtns.forEach(function(btn) {
            btn.classList.remove('active');
            btn.setAttribute('aria-pressed', 'false');
        });
    }

    function filterTestimonialSlides(testimonialSlides, filter, featuredName) {
        testimonialSlides.forEach(function(slide) {
            const name = slide.querySelector('.client-name')?.textContent?.trim();
            if (name === featuredName) {
                slide.style.display = 'none';
                return;
            }
            if (filter === 'all' || slide.getAttribute('data-industry') === filter) {
                slide.style.display = '';
            } else {
                slide.style.display = 'none';
            }
        });
    }

    function hideFeaturedTestimonials(testimonialSlides, featuredName) {
        testimonialSlides.forEach(function(slide) {
            const name = slide.querySelector('.client-name')?.textContent?.trim();
            if (name === featuredName) {
                slide.style.display = 'none';
            }
        });
    }

    // Testimonial Filter System and Accessibility Enhancements
    (function() {
        const filterBtns = document.querySelectorAll('.filter-btn');
        const testimonialSlides = document.querySelectorAll('.testimonial-slide');
        const featuredName = 'Sarah Johnson';
        
        filterBtns.forEach(function(btn) {
            btn.addEventListener('click', function() {
                resetFilterButtons(filterBtns);
                btn.classList.add('active');
                btn.setAttribute('aria-pressed', 'true');
                const filter = btn.getAttribute('data-filter');
                filterTestimonialSlides(testimonialSlides, filter, featuredName);
            });
            
            btn.addEventListener('keydown', function(e) {
                if (e.key === 'Enter' || e.key === ' ') {
                    e.preventDefault();
                    btn.click();
                }
            });
        });
        
        // Hide featured testimonial from carousel if duplicated
        hideFeaturedTestimonials(testimonialSlides, featuredName);
    })();

    // --- Testimonial Carousel (index.html) ---
    document.addEventListener('DOMContentLoaded', function() {
      const slides = document.querySelectorAll('.testimonial-slide');
      const prevBtn = document.querySelector('.testimonial-prev');
      const nextBtn = document.querySelector('.testimonial-next');
      const indicators = document.querySelectorAll('.testimonial-indicators .indicator');
      if (!slides.length) return;
      let current = 0;
      let autoPlayInterval;

      function showSlide(idx) {
        slides.forEach((slide, i) => {
          slide.classList.toggle('active', i === idx);
          slide.setAttribute('aria-hidden', i !== idx);
          slide.style.display = i === idx ? '' : 'none';
        });
        indicators.forEach((dot, i) => {
          dot.classList.toggle('active', i === idx);
          dot.setAttribute('aria-selected', i === idx ? 'true' : 'false');
          dot.setAttribute('tabindex', i === idx ? '0' : '-1');
        });
        current = idx;
      }
      function nextSlide() {
        showSlide((current + 1) % slides.length);
      }
      function prevSlide() {
        showSlide((current - 1 + slides.length) % slides.length);
      }
      function startAutoPlay() {
        autoPlayInterval = setInterval(nextSlide, 6000);
      }
      function stopAutoPlay() {
        clearInterval(autoPlayInterval);
      }
      if (prevBtn && nextBtn) {
        prevBtn.addEventListener('click', () => { prevSlide(); stopAutoPlay(); startAutoPlay(); });
        nextBtn.addEventListener('click', () => { nextSlide(); stopAutoPlay(); startAutoPlay(); });
      }
      indicators.forEach((dot, idx) => {
        dot.addEventListener('click', () => { showSlide(idx); stopAutoPlay(); startAutoPlay(); });
        dot.addEventListener('keydown', e => {
          if (e.key === 'Enter' || e.key === ' ') {
            e.preventDefault();
            showSlide(idx);
            stopAutoPlay();
            startAutoPlay();
          }
          if (e.key === 'ArrowLeft') {
            e.preventDefault();
            prevSlide();
            stopAutoPlay();
            startAutoPlay();
          }
          if (e.key === 'ArrowRight') {
            e.preventDefault();
            nextSlide();
            stopAutoPlay();
            startAutoPlay();
          }
        });
      });
      // Arrow key navigation for carousel
      document.addEventListener('keydown', function(e) {
        if (document.activeElement && document.activeElement.closest('.testimonials-carousel')) {
          if (e.key === 'ArrowLeft') {
            prevSlide();
            stopAutoPlay();
            startAutoPlay();
          }
          if (e.key === 'ArrowRight') {
            nextSlide();
            stopAutoPlay();
            startAutoPlay();
          }
        }
      });
      // Pause on hover/focus for accessibility
      const carousel = document.querySelector('.testimonials-carousel');
      if (carousel) {
        carousel.addEventListener('mouseenter', stopAutoPlay);
        carousel.addEventListener('mouseleave', startAutoPlay);
        carousel.addEventListener('focusin', stopAutoPlay);
        carousel.addEventListener('focusout', startAutoPlay);
      }
      showSlide(0);
      startAutoPlay();
    });

    // Partners logo scroller (looping)
    document.addEventListener('DOMContentLoaded', function() {
      const logoContainer = document.querySelector('.partners-carousel');
      if (!logoContainer) return;
      const logos = logoContainer.querySelectorAll('.partner-logo');
      if (logos.length <= 1) return;
      let currentLogo = 0;
      // Create nav buttons
      let prev = document.createElement('button');
      prev.className = 'partner-prev';
      prev.setAttribute('aria-label', 'Previous partner logo');
      prev.innerHTML = '<i class="fas fa-chevron-left"></i>';
      let next = document.createElement('button');
      next.className = 'partner-next';
      next.setAttribute('aria-label', 'Next partner logo');
      next.innerHTML = '<i class="fas fa-chevron-right"></i>';
      logoContainer.parentNode.insertBefore(prev, logoContainer);
      logoContainer.parentNode.appendChild(next);
      function showLogo(idx) {
        logos.forEach((logo, i) => {
          logo.style.display = i === idx ? 'block' : 'none';
        });
        currentLogo = idx;
      }
      function nextLogo() {
        showLogo((currentLogo + 1) % logos.length);
      }
      function prevLogo() {
        showLogo((currentLogo - 1 + logos.length) % logos.length);
      }
      prev.addEventListener('click', prevLogo);
      next.addEventListener('click', nextLogo);
      showLogo(0);
    });
})();