# iBridge Website

This repository contains the iBridge website codebase with enhanced features for accessibility, performance, and user experience.

## Implemented Enhancements

### Performance Improvements

- **Lazy Loading**: Images now use the `loading="lazy"` attribute for better page load performance.
- **Optimized CSS**: Styles have been consolidated and optimized.
- **Script Loading**: JavaScript files are loaded at the end of the document.

### Accessibility Enhancements

- **ARIA Attributes**: Added proper ARIA roles, labels, and states to interactive elements.
- **Keyboard Navigation**: Improved keyboard navigation throughout the site.
- **Skip to Content**: Added a skip to main content link for screen readers.
- **Form Validation**: Enhanced form validation with clear error messages and focus management.
- **Color Contrast**: Ensured text colors have sufficient contrast with backgrounds.

### User Experience Improvements

- **Consistent Navigation**: Standardized navigation across all pages.
- **White Header**: Implemented a clean white header with dark navigation links.
- **Hero Section**: Optimized hero sections with proper overlay and responsive sizing.
- **Form Feedback**: Added enhanced validation and feedback for form submissions.
- **Address Updates**: Corrected office address throughout the site (332 Kent Ave, Ferndale, Randburg, 2194).

### Design and Style

- **Logo Placement**: Standardized logo placement in header and footer.
- **Favicon**: Updated to use the iBridge logo as favicon.
- **Typography**: Improved readability with consistent font sizing and weights.
- **Visual Hierarchy**: Enhanced visual hierarchy for important elements.
- **Responsive Design**: Improved mobile and tablet experience.

## File Structure

- **HTML Files**: Main pages of the website
- **css/**: Contains all stylesheet files
  - `styles.css`: Main stylesheet
  - `style-enhancements.css`: Additional style improvements
- **js/**: JavaScript files
  - `main.js`: Main functionality
  - `accessibility.js`: Accessibility enhancements
- **images/**: All website images
- **partials/**: Reusable HTML components
  - `header.html`
  - `footer.html`

## Maintenance Guidelines

### Adding New Pages

1. Copy an existing page as a template
2. Update meta tags, title, and content
3. Ensure all scripts and stylesheets are included
4. Add the page to navigation menus

### Updating Images

1. Optimize images before uploading (compress without quality loss)
2. Use descriptive alt text for accessibility
3. Add `loading="lazy"` attribute for better performance

### CSS Modifications

1. Use `style-enhancements.css` for new styles
2. Follow existing naming conventions
3. Test changes across all screen sizes

### JavaScript Enhancements

1. Add new functionality to the appropriate JS file
2. Test thoroughly for accessibility and performance
3. Use unobtrusive JavaScript practices

## Future Enhancements

- **SEO Optimization**: Further meta tag improvements and structured data
- **Analytics Integration**: Add detailed event tracking
- **Testimonials Carousel**: Implement dynamic testimonials section
- **Newsletter Integration**: Add subscription functionality
- **Case Studies Section**: Showcase detailed client success stories
- **Blog/Resources**: Add a content marketing section
- **Live Chat**: Integrate customer support chat functionality
