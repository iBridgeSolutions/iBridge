/**
 * Files Custom Loader
 * Loads files data from local mirrored sources instead of Microsoft 365 API
 */

document.addEventListener('DOMContentLoaded', async function() {
    // Initialize file explorer
    initializeFileExplorer();
});

/**
 * Initialize the file explorer with local data
 */
async function initializeFileExplorer() {
    try {
        // Fetch the file metadata
        const metadata = await loadFileMetadata();
        
        if (!metadata || !metadata.files || !Array.isArray(metadata.files)) {
            showError('No file data available');
            return;
        }
        
        // Initialize UI elements
        setupFileExplorerUI(metadata);
        
        // Display files (initially show all)
        displayFiles(metadata.files);
        
        // Setup search and filters
        setupSearch(metadata.files);
        setupFilters(metadata.files);
        
        // Update stats
        updateFileStats(metadata);
        
        console.log('File explorer initialized with', metadata.files.length, 'files');
    } catch (error) {
        console.error('Error initializing file explorer:', error);
        showError('Failed to load file data. Please try again later.');
    }
}

/**
 * Load file metadata from JSON
 * @returns {Promise<Object>} File metadata object
 */
async function loadFileMetadata() {
    try {
        const response = await fetch('/intranet/data/mirrored/files/file-metadata.json');
        if (!response.ok) {
            throw new Error('Failed to load file metadata');
        }
        
        return await response.json();
    } catch (error) {
        console.error('Error loading file metadata:', error);
        return null;
    }
}

/**
 * Setup the file explorer UI
 * @param {Object} metadata - File metadata
 */
function setupFileExplorerUI(metadata) {
    // Setup breadcrumb navigation
    const breadcrumb = document.getElementById('file-breadcrumb');
    if (breadcrumb) {
        breadcrumb.innerHTML = `
            <li class="breadcrumb-item active">Home</li>
        `;
    }
    
    // Setup view toggle
    const viewToggle = document.getElementById('view-toggle');
    if (viewToggle) {
        viewToggle.addEventListener('click', function() {
            const fileContainer = document.getElementById('file-container');
            fileContainer.classList.toggle('grid-view');
            fileContainer.classList.toggle('list-view');
            
            // Update button icon
            const icon = this.querySelector('i');
            if (icon.classList.contains('fa-th')) {
                icon.classList.replace('fa-th', 'fa-list');
                this.setAttribute('title', 'Switch to list view');
            } else {
                icon.classList.replace('fa-list', 'fa-th');
                this.setAttribute('title', 'Switch to grid view');
            }
        });
    }
}

/**
 * Display files in the file explorer
 * @param {Array} files - Array of file objects
 */
function displayFiles(files) {
    const fileContainer = document.getElementById('file-container');
    if (!fileContainer) return;
    
    // Clear existing files
    fileContainer.innerHTML = '';
    
    if (files.length === 0) {
        fileContainer.innerHTML = '<div class="no-files">No files found</div>';
        return;
    }
    
    // Sort files: folders first, then by name
    const sortedFiles = [...files].sort((a, b) => {
        if (a.folder === b.folder) {
            return a.name.localeCompare(b.name);
        }
        return a.folder.localeCompare(b.folder);
    });
    
    // Create file items
    sortedFiles.forEach(file => {
        const fileItem = createFileItem(file);
        fileContainer.appendChild(fileItem);
    });
}

/**
 * Create a file item element
 * @param {Object} file - File object
 * @returns {HTMLElement} File item element
 */
function createFileItem(file) {
    const item = document.createElement('div');
    item.className = 'file-item';
    item.dataset.type = file.type;
    item.dataset.name = file.name;
    item.dataset.folder = file.folder;
    
    // Determine icon based on file type
    let icon = 'fa-file';
    let colorClass = '';
    
    switch (file.type) {
        case 'document':
            icon = 'fa-file-word';
            colorClass = 'text-primary';
            break;
        case 'spreadsheet':
            icon = 'fa-file-excel';
            colorClass = 'text-success';
            break;
        case 'presentation':
            icon = 'fa-file-powerpoint';
            colorClass = 'text-warning';
            break;
        case 'pdf':
            icon = 'fa-file-pdf';
            colorClass = 'text-danger';
            break;
        case 'image':
            icon = 'fa-file-image';
            colorClass = 'text-info';
            break;
        case 'folder':
            icon = 'fa-folder';
            colorClass = 'text-warning';
            break;
    }
    
    // Format date
    const modifiedDate = new Date(file.modified);
    const formattedDate = modifiedDate.toLocaleDateString('en-ZA', {
        year: 'numeric',
        month: 'short',
        day: 'numeric'
    });
    
    // Format size
    const formattedSize = formatFileSize(file.size);
    
    // Create file item HTML
    item.innerHTML = `
        <div class="file-icon">
            <i class="fas ${icon} ${colorClass}"></i>
        </div>
        <div class="file-details">
            <div class="file-name">${file.name}</div>
            <div class="file-meta">
                <span class="file-modified">Modified: ${formattedDate}</span>
                <span class="file-size">${formattedSize}</span>
                <span class="file-type">${file.type}</span>
            </div>
        </div>
        <div class="file-actions">
            <button class="btn btn-sm btn-outline-secondary file-preview" title="Preview">
                <i class="fas fa-eye"></i>
            </button>
            <button class="btn btn-sm btn-outline-primary file-download" title="Download">
                <i class="fas fa-download"></i>
            </button>
            <button class="btn btn-sm btn-outline-secondary file-info" title="Details">
                <i class="fas fa-info-circle"></i>
            </button>
        </div>
    `;
    
    // Add event listeners
    const previewButton = item.querySelector('.file-preview');
    previewButton.addEventListener('click', function(e) {
        e.stopPropagation();
        showFilePreview(file);
    });
    
    const downloadButton = item.querySelector('.file-download');
    downloadButton.addEventListener('click', function(e) {
        e.stopPropagation();
        downloadFile(file);
    });
    
    const infoButton = item.querySelector('.file-info');
    infoButton.addEventListener('click', function(e) {
        e.stopPropagation();
        showFileDetails(file);
    });
    
    // File item click
    item.addEventListener('click', function() {
        if (file.type === 'folder') {
            // Navigate into folder
            navigateToFolder(file.path);
        } else {
            // Show preview for files
            showFilePreview(file);
        }
    });
    
    return item;
}

/**
 * Format file size to human-readable format
 * @param {number} bytes - File size in bytes
 * @returns {string} Formatted file size
 */
function formatFileSize(bytes) {
    if (bytes === 0) return '0 Bytes';
    
    const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
    const i = Math.floor(Math.log(bytes) / Math.log(1024));
    return parseFloat((bytes / Math.pow(1024, i)).toFixed(2)) + ' ' + sizes[i];
}

/**
 * Show file preview modal
 * @param {Object} file - File object
 */
function showFilePreview(file) {
    // Get modal elements
    const modal = document.getElementById('file-preview-modal');
    const modalTitle = modal.querySelector('.modal-title');
    const modalBody = modal.querySelector('.modal-body');
    const modalFooter = modal.querySelector('.modal-footer');
    
    // Set modal title
    modalTitle.textContent = file.name;
    
    // Set preview content based on file type
    let previewContent = '';
    
    switch (file.type) {
        case 'document':
            previewContent = `
                <div class="document-preview">
                    <div class="preview-header">
                        <i class="fas fa-file-word text-primary"></i> Microsoft Word Document
                    </div>
                    <div class="preview-content">
                        <p>This is a preview of document content. In a real implementation, 
                        this would show the actual document content.</p>
                        <p>Created by: ${file.createdBy}</p>
                        <p>Modified by: ${file.modifiedBy}</p>
                        <p>Tags: ${file.tags.join(', ')}</p>
                    </div>
                </div>
            `;
            break;
        case 'spreadsheet':
            previewContent = `
                <div class="spreadsheet-preview">
                    <div class="preview-header">
                        <i class="fas fa-file-excel text-success"></i> Microsoft Excel Spreadsheet
                    </div>
                    <div class="preview-content">
                        <p>This is a preview of spreadsheet content. In a real implementation, 
                        this would show the actual spreadsheet content.</p>
                        <p>Created by: ${file.createdBy}</p>
                        <p>Modified by: ${file.modifiedBy}</p>
                        <p>Tags: ${file.tags.join(', ')}</p>
                    </div>
                </div>
            `;
            break;
        case 'presentation':
            previewContent = `
                <div class="presentation-preview">
                    <div class="preview-header">
                        <i class="fas fa-file-powerpoint text-warning"></i> Microsoft PowerPoint Presentation
                    </div>
                    <div class="preview-content">
                        <p>This is a preview of presentation content. In a real implementation, 
                        this would show the actual presentation content.</p>
                        <p>Created by: ${file.createdBy}</p>
                        <p>Modified by: ${file.modifiedBy}</p>
                        <p>Tags: ${file.tags.join(', ')}</p>
                    </div>
                </div>
            `;
            break;
        case 'image':
            previewContent = `
                <div class="image-preview">
                    <div class="preview-header">
                        <i class="fas fa-file-image text-info"></i> Image
                    </div>
                    <div class="preview-content text-center">
                        <p>This is a placeholder for the image preview.</p>
                        <div class="image-placeholder">
                            <i class="fas fa-image fa-5x text-muted"></i>
                        </div>
                        <p>Created by: ${file.createdBy}</p>
                        <p>Tags: ${file.tags.join(', ')}</p>
                    </div>
                </div>
            `;
            break;
        case 'pdf':
            previewContent = `
                <div class="pdf-preview">
                    <div class="preview-header">
                        <i class="fas fa-file-pdf text-danger"></i> PDF Document
                    </div>
                    <div class="preview-content">
                        <p>This is a preview of PDF content. In a real implementation, 
                        this would show the actual PDF content.</p>
                        <p>Created by: ${file.createdBy}</p>
                        <p>Modified by: ${file.modifiedBy}</p>
                        <p>Tags: ${file.tags.join(', ')}</p>
                    </div>
                </div>
            `;
            break;
        default:
            previewContent = `
                <div class="generic-preview">
                    <div class="preview-header">
                        <i class="fas fa-file text-secondary"></i> File
                    </div>
                    <div class="preview-content">
                        <p>Preview not available for this file type.</p>
                        <p>Created by: ${file.createdBy}</p>
                        <p>Modified by: ${file.modifiedBy}</p>
                        <p>Tags: ${file.tags.join(', ')}</p>
                    </div>
                </div>
            `;
    }
    
    // Set modal body content
    modalBody.innerHTML = previewContent;
    
    // Update download button
    const downloadButton = modalFooter.querySelector('.download-file');
    if (downloadButton) {
        downloadButton.onclick = function() {
            downloadFile(file);
        };
    }
    
    // Show modal
    const bootstrapModal = new bootstrap.Modal(modal);
    bootstrapModal.show();
}

/**
 * Show file details sidebar
 * @param {Object} file - File object
 */
function showFileDetails(file) {
    const detailsSidebar = document.getElementById('file-details-sidebar');
    if (!detailsSidebar) return;
    
    // Format dates
    const createdDate = new Date(file.created);
    const modifiedDate = new Date(file.modified);
    
    const formattedCreatedDate = createdDate.toLocaleDateString('en-ZA', {
        year: 'numeric',
        month: 'long',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    });
    
    const formattedModifiedDate = modifiedDate.toLocaleDateString('en-ZA', {
        year: 'numeric',
        month: 'long',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    });
    
    // Set content
    detailsSidebar.innerHTML = `
        <div class="sidebar-header">
            <h5>File Details</h5>
            <button type="button" class="btn-close" aria-label="Close"></button>
        </div>
        <div class="sidebar-body">
            <div class="file-detail-icon text-center mb-3">
                <i class="fas fa-file-${getFileIconClass(file.type)} fa-4x ${getFileColorClass(file.type)}"></i>
            </div>
            
            <h4 class="file-detail-name">${file.name}</h4>
            
            <div class="file-detail-item">
                <div class="detail-label">Type</div>
                <div class="detail-value">${file.type}</div>
            </div>
            
            <div class="file-detail-item">
                <div class="detail-label">Size</div>
                <div class="detail-value">${formatFileSize(file.size)}</div>
            </div>
            
            <div class="file-detail-item">
                <div class="detail-label">Created</div>
                <div class="detail-value">${formattedCreatedDate}</div>
            </div>
            
            <div class="file-detail-item">
                <div class="detail-label">Created By</div>
                <div class="detail-value">${file.createdBy}</div>
            </div>
            
            <div class="file-detail-item">
                <div class="detail-label">Modified</div>
                <div class="detail-value">${formattedModifiedDate}</div>
            </div>
            
            <div class="file-detail-item">
                <div class="detail-label">Modified By</div>
                <div class="detail-value">${file.modifiedBy}</div>
            </div>
            
            <div class="file-detail-item">
                <div class="detail-label">Location</div>
                <div class="detail-value">/${file.folder}</div>
            </div>
            
            <div class="file-detail-item">
                <div class="detail-label">Tags</div>
                <div class="detail-value tags">
                    ${file.tags.map(tag => `<span class="badge bg-secondary">${tag}</span>`).join(' ')}
                </div>
            </div>
        </div>
        <div class="sidebar-footer">
            <button class="btn btn-primary w-100 download-file">
                <i class="fas fa-download me-2"></i> Download
            </button>
        </div>
    `;
    
    // Add event listeners
    const closeButton = detailsSidebar.querySelector('.btn-close');
    closeButton.addEventListener('click', function() {
        detailsSidebar.classList.remove('active');
    });
    
    const downloadButton = detailsSidebar.querySelector('.download-file');
    downloadButton.addEventListener('click', function() {
        downloadFile(file);
    });
    
    // Show sidebar
    detailsSidebar.classList.add('active');
}

/**
 * Download a file
 * @param {Object} file - File object
 */
function downloadFile(file) {
    // In a real implementation, this would download the actual file
    alert(`Downloading ${file.name}...\n\nIn a production environment, this would download the actual file.`);
}

/**
 * Navigate to a folder
 * @param {string} folderPath - Folder path
 */
function navigateToFolder(folderPath) {
    // In a real implementation, this would update the file list to show files in the folder
    alert(`Navigating to folder: ${folderPath}\n\nIn a production environment, this would show the files in this folder.`);
}

/**
 * Setup search functionality
 * @param {Array} files - Array of file objects
 */
function setupSearch(files) {
    const searchInput = document.getElementById('file-search');
    if (!searchInput) return;
    
    searchInput.addEventListener('input', function() {
        const searchTerm = this.value.toLowerCase().trim();
        
        if (!searchTerm) {
            // If search is empty, show all files
            displayFiles(files);
            return;
        }
        
        // Filter files based on search term
        const filteredFiles = files.filter(file => {
            return file.name.toLowerCase().includes(searchTerm) ||
                   file.type.toLowerCase().includes(searchTerm) ||
                   file.tags.some(tag => tag.toLowerCase().includes(searchTerm)) ||
                   file.createdBy.toLowerCase().includes(searchTerm) ||
                   file.modifiedBy.toLowerCase().includes(searchTerm);
        });
        
        displayFiles(filteredFiles);
    });
}

/**
 * Setup file type filters
 * @param {Array} files - Array of file objects
 */
function setupFilters(files) {
    const filterButtons = document.querySelectorAll('.file-filter');
    if (!filterButtons.length) return;
    
    filterButtons.forEach(button => {
        button.addEventListener('click', function() {
            // Update active state
            filterButtons.forEach(btn => btn.classList.remove('active'));
            this.classList.add('active');
            
            const filterType = this.getAttribute('data-filter');
            
            if (filterType === 'all') {
                displayFiles(files);
            } else {
                const filteredFiles = files.filter(file => file.type === filterType);
                displayFiles(filteredFiles);
            }
        });
    });
}

/**
 * Update file statistics display
 * @param {Object} metadata - File metadata
 */
function updateFileStats(metadata) {
    const totalFilesElement = document.getElementById('total-files');
    const totalSizeElement = document.getElementById('total-size');
    const lastUpdatedElement = document.getElementById('last-updated');
    
    if (totalFilesElement) {
        totalFilesElement.textContent = metadata.totalCount;
    }
    
    if (totalSizeElement) {
        totalSizeElement.textContent = formatFileSize(metadata.totalSize);
    }
    
    if (lastUpdatedElement && metadata.lastUpdated) {
        const lastUpdated = new Date(metadata.lastUpdated);
        lastUpdatedElement.textContent = lastUpdated.toLocaleDateString('en-ZA', {
            year: 'numeric',
            month: 'long',
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        });
    }
}

/**
 * Show error message
 * @param {string} message - Error message
 */
function showError(message) {
    const fileContainer = document.getElementById('file-container');
    if (!fileContainer) return;
    
    fileContainer.innerHTML = `
        <div class="error-message">
            <i class="fas fa-exclamation-triangle text-warning"></i>
            <p>${message}</p>
        </div>
    `;
}

/**
 * Get file icon class based on file type
 * @param {string} type - File type
 * @returns {string} Icon class name
 */
function getFileIconClass(type) {
    switch (type) {
        case 'document': return 'word';
        case 'spreadsheet': return 'excel';
        case 'presentation': return 'powerpoint';
        case 'pdf': return 'pdf';
        case 'image': return 'image';
        case 'folder': return 'folder';
        default: return 'alt';
    }
}

/**
 * Get file color class based on file type
 * @param {string} type - File type
 * @returns {string} Color class name
 */
function getFileColorClass(type) {
    switch (type) {
        case 'document': return 'text-primary';
        case 'spreadsheet': return 'text-success';
        case 'presentation': return 'text-warning';
        case 'pdf': return 'text-danger';
        case 'image': return 'text-info';
        case 'folder': return 'text-warning';
        default: return 'text-secondary';
    }
}
