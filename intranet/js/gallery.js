/**
 * Staff Gallery Module
 * Displays internal staff photos in various sections of the intranet
 */

class StaffGallery {
    constructor() {
        this.galleryData = [];
        this.initialized = false;
    }
    
    /**
     * Initialize the gallery
     */
    async initialize() {
        if (this.initialized) return;
        
        try {
            // Fetch gallery data
            const response = await fetch('data/staff-gallery.json');
            if (!response.ok) {
                throw new Error('Failed to load gallery data');
            }
            
            this.galleryData = await response.json();
            console.log(`Loaded ${this.galleryData.length} gallery items`);
            
            this.initialized = true;
            return true;
        } catch (error) {
            console.error('Error initializing gallery:', error);
            return false;
        }
    }
    
    /**
     * Load gallery carousel on the page
     * @param {string} containerId - ID of the container element
     * @param {number} count - Number of images to show (default: 5)
     */
    async loadCarousel(containerId = 'staffGalleryCarousel', count = 5) {
        if (!this.initialized) await this.initialize();
        
        const container = document.getElementById(containerId);
        if (!container) return;
        
        // Get most recent gallery items
        const recentItems = this.galleryData
            .sort((a, b) => new Date(b.date) - new Date(a.date))
            .slice(0, count);
            
        if (recentItems.length === 0) {
            container.innerHTML = '<p class="text-center text-muted">No gallery images available</p>';
            return;
        }
        
        // Create carousel indicators
        const indicators = document.createElement('div');
        indicators.className = 'carousel-indicators';
        
        // Create carousel items
        const inner = document.createElement('div');
        inner.className = 'carousel-inner rounded';
        
        recentItems.forEach((item, index) => {
            // Create indicator button
            const indicator = document.createElement('button');
            indicator.type = 'button';
            indicator.dataset.bsTarget = `#${containerId}`;
            indicator.dataset.bsSlideTo = index;
            if (index === 0) {
                indicator.className = 'active';
                indicator.setAttribute('aria-current', 'true');
            }
            indicator.setAttribute('aria-label', `Slide ${index + 1}`);
            indicators.appendChild(indicator);
            
            // Create carousel item
            const itemDiv = document.createElement('div');
            itemDiv.className = `carousel-item${index === 0 ? ' active' : ''}`;
            
            // Use thumbnail or placeholder if image doesn't exist
            const imgSrc = item.thumbnail || item.url || 'images/gallery/placeholder.jpg';
            
            itemDiv.innerHTML = `
                <img src="${imgSrc}" class="d-block w-100" alt="${item.title}">
                <div class="carousel-caption d-none d-md-block">
                    <h5>${item.title}</h5>
                    <p>${item.description}</p>
                </div>
            `;
            
            inner.appendChild(itemDiv);
        });
        
        // Create carousel controls
        const prevButton = `
            <button class="carousel-control-prev" type="button" data-bs-target="#${containerId}" data-bs-slide="prev">
                <span class="carousel-control-prev-icon" aria-hidden="true"></span>
                <span class="visually-hidden">Previous</span>
            </button>
        `;
        
        const nextButton = `
            <button class="carousel-control-next" type="button" data-bs-target="#${containerId}" data-bs-slide="next">
                <span class="carousel-control-next-icon" aria-hidden="true"></span>
                <span class="visually-hidden">Next</span>
            </button>
        `;
        
        // Update container
        container.innerHTML = '';
        container.appendChild(indicators);
        container.appendChild(inner);
        container.insertAdjacentHTML('beforeend', prevButton);
        container.insertAdjacentHTML('beforeend', nextButton);
        
        // Initialize Bootstrap carousel
        new bootstrap.Carousel(container, {
            interval: 5000,
            wrap: true
        });
    }
    
    /**
     * Load gallery grid on the page
     * @param {string} containerId - ID of the container element
     * @param {Object} options - Options for the grid display
     */
    async loadGrid(containerId, options = {}) {
        if (!this.initialized) await this.initialize();
        
        const container = document.getElementById(containerId);
        if (!container) return;
        
        const defaultOptions = {
            limit: 12,
            columns: 3,
            showDate: true,
            showUploader: true,
            filterable: true
        };
        
        const settings = { ...defaultOptions, ...options };
        
        // Filter and sort gallery items
        let filteredItems = [...this.galleryData];
        
        if (settings.tag) {
            filteredItems = filteredItems.filter(item => 
                item.tags && item.tags.includes(settings.tag)
            );
        }
        
        // Sort by date (newest first)
        filteredItems.sort((a, b) => new Date(b.date) - new Date(a.date));
        
        // Apply limit
        const limitedItems = filteredItems.slice(0, settings.limit);
        
        if (limitedItems.length === 0) {
            container.innerHTML = '<p class="text-center text-muted py-5">No gallery images available</p>';
            return;
        }
        
        // Create filter UI if enabled
        if (settings.filterable && this.getTags().length > 0) {
            const filterContainer = document.createElement('div');
            filterContainer.className = 'gallery-filters mb-4';
            
            const tags = this.getTags();
            let filtersHTML = `
                <div class="d-flex flex-wrap align-items-center">
                    <span class="me-2 fw-bold">Filter:</span>
                    <button class="btn btn-sm btn-outline-secondary me-2 mb-2 active" data-filter="all">All</button>
            `;
            
            tags.forEach(tag => {
                filtersHTML += `<button class="btn btn-sm btn-outline-secondary me-2 mb-2" data-filter="${tag}">${this.formatTag(tag)}</button>`;
            });
            
            filtersHTML += '</div>';
            filterContainer.innerHTML = filtersHTML;
            container.appendChild(filterContainer);
            
            // Add event listeners to filter buttons
            filterContainer.querySelectorAll('button[data-filter]').forEach(btn => {
                btn.addEventListener('click', () => {
                    // Update active button
                    filterContainer.querySelectorAll('button').forEach(b => b.classList.remove('active'));
                    btn.classList.add('active');
                    
                    // Filter gallery
                    const filter = btn.getAttribute('data-filter');
                    this.filterGallery(container, filter);
                });
            });
        }
        
        // Create gallery grid
        const gridContainer = document.createElement('div');
        gridContainer.className = 'row gallery-grid';
        
        limitedItems.forEach(item => {
            const colClass = `col-md-${12 / settings.columns}`;
            const itemDiv = document.createElement('div');
            itemDiv.className = `${colClass} mb-4 gallery-item`;
            if (item.tags) {
                itemDiv.dataset.tags = item.tags.join(' ');
            }
            
            // Format date
            const itemDate = new Date(item.date);
            const formattedDate = itemDate.toLocaleDateString('en-ZA', { 
                year: 'numeric',
                month: 'long', 
                day: 'numeric' 
            });
            
            itemDiv.innerHTML = `
                <div class="card h-100">
                    <img src="${item.url || 'images/gallery/placeholder.jpg'}" class="card-img-top" alt="${item.title}">
                    <div class="card-body">
                        <h5 class="card-title">${item.title}</h5>
                        <p class="card-text">${item.description}</p>
                        ${settings.showDate ? `<p class="card-text"><small class="text-muted"><i class="far fa-calendar-alt me-1"></i> ${formattedDate}</small></p>` : ''}
                        ${settings.showUploader && item.uploadedBy ? `<p class="card-text"><small class="text-muted"><i class="fas fa-user me-1"></i> ${item.uploadedBy}</small></p>` : ''}
                    </div>
                </div>
            `;
            
            gridContainer.appendChild(itemDiv);
        });
        
        container.appendChild(gridContainer);
    }
    
    /**
     * Filter gallery items by tag
     */
    filterGallery(container, tag) {
        const items = container.querySelectorAll('.gallery-item');
        
        items.forEach(item => {
            if (tag === 'all' || !tag) {
                item.style.display = 'block';
            } else {
                const itemTags = item.dataset.tags || '';
                if (itemTags.includes(tag)) {
                    item.style.display = 'block';
                } else {
                    item.style.display = 'none';
                }
            }
        });
    }
    
    /**
     * Get all unique tags from gallery items
     */
    getTags() {
        const tags = new Set();
        
        this.galleryData.forEach(item => {
            if (item.tags && Array.isArray(item.tags)) {
                item.tags.forEach(tag => tags.add(tag));
            }
        });
        
        return Array.from(tags);
    }
    
    /**
     * Format tag for display
     */
    formatTag(tag) {
        return tag
            .split('-')
            .map(word => word.charAt(0).toUpperCase() + word.slice(1))
            .join(' ');
    }
}

// Create global instance
const staffGallery = new StaffGallery();

// Initialize gallery on DOM content loaded
document.addEventListener('DOMContentLoaded', function() {
    const galleryCarousel = document.getElementById('staffGalleryCarousel');
    if (galleryCarousel) {
        staffGallery.loadCarousel('staffGalleryCarousel', 3);
    }
    
    const galleryGrid = document.getElementById('galleryGrid');
    if (galleryGrid) {
        staffGallery.loadGrid('galleryGrid', {
            columns: 4,
            limit: 12,
            filterable: true
        });
    }
});
