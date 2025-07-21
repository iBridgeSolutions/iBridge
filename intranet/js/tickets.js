/**
 * IT Support Ticketing System
 */

class TicketManager {
    constructor() {
        this.tickets = [];
        this.categories = [];
        this.statuses = [];
        this.priorities = [];
        this.initialized = false;
    }

    async initialize() {
        try {
            // Load ticket data
            const response = await fetch('data/tickets.json');
            const data = await response.json();
            
            this.categories = data.categories;
            this.statuses = data.statuses;
            this.priorities = data.priorities;
            this.tickets = data.tickets;
            
            this.initialized = true;
            
            // Initialize UI
            this.initializeUI();
            
            return true;
        } catch (error) {
            console.error('Failed to initialize ticket manager:', error);
            return false;
        }
    }

    initializeUI() {
        // Initialize filter dropdowns
        this.initializeFilters();
        
        // Initialize new ticket form
        this.initializeNewTicketForm();
        
        // Load and display tickets
        this.loadTickets();
        
        // Initialize search
        this.initializeSearch();
        
        // Update statistics
        this.updateStatistics();
    }

    initializeFilters() {
        // Status filter
        const statusFilter = document.getElementById('statusFilter');
        this.statuses.forEach(status => {
            const option = document.createElement('option');
            option.value = status.id;
            option.textContent = status.name;
            statusFilter.appendChild(option);
        });
        statusFilter.addEventListener('change', () => this.applyFilters());

        // Category filter
        const categoryFilter = document.getElementById('categoryFilter');
        this.categories.forEach(category => {
            const option = document.createElement('option');
            option.value = category.id;
            option.textContent = category.name;
            categoryFilter.appendChild(option);
        });
        categoryFilter.addEventListener('change', () => this.applyFilters());

        // Priority filter
        const priorityFilter = document.getElementById('priorityFilter');
        this.priorities.forEach(priority => {
            const option = document.createElement('option');
            option.value = priority.id;
            option.textContent = priority.name;
            priorityFilter.appendChild(option);
        });
        priorityFilter.addEventListener('change', () => this.applyFilters());
    }

    initializeNewTicketForm() {
        // Add categories to new ticket form
        const ticketCategory = document.getElementById('ticketCategory');
        this.categories.forEach(category => {
            const option = document.createElement('option');
            option.value = category.id;
            option.textContent = category.name;
            ticketCategory.appendChild(option);
        });

        // Add priorities to new ticket form
        const ticketPriority = document.getElementById('ticketPriority');
        this.priorities.forEach(priority => {
            const option = document.createElement('option');
            option.value = priority.id;
            option.textContent = priority.name;
            ticketPriority.appendChild(option);
        });

        // Handle new ticket button
        const newTicketBtn = document.getElementById('newTicketBtn');
        newTicketBtn.addEventListener('click', () => this.showNewTicketModal());

        // Handle form submission
        const submitTicket = document.getElementById('submitTicket');
        submitTicket.addEventListener('click', () => this.submitNewTicket());
    }

    initializeSearch() {
        const searchInput = document.getElementById('ticketSearch');
        searchInput.addEventListener('input', debounce(() => this.applyFilters(), 300));
    }

    async loadTickets() {
        const ticketsList = document.getElementById('ticketsList');
        ticketsList.innerHTML = '';

        const filteredTickets = await this.getFilteredTickets();

        if (filteredTickets.length === 0) {
            ticketsList.innerHTML = `
                <div class="no-tickets">
                    <p>No tickets found</p>
                </div>
            `;
            return;
        }

        filteredTickets.forEach(ticket => {
            const ticketElement = this.createTicketElement(ticket);
            ticketsList.appendChild(ticketElement);
        });
    }

    createTicketElement(ticket) {
        const div = document.createElement('div');
        div.className = 'ticket-item';
        div.setAttribute('data-ticket-id', ticket.id);

        const status = this.statuses.find(s => s.id === ticket.status);
        const priority = this.priorities.find(p => p.id === ticket.priority);
        
        div.innerHTML = `
            <span class="ticket-status status-${ticket.status}">${status.name}</span>
            <div class="ticket-info">
                <div class="ticket-title">${ticket.title}</div>
                <div class="ticket-meta">
                    #${ticket.id} opened ${this.formatDate(ticket.createdAt)} by ${ticket.createdBy}
                </div>
            </div>
            <span class="ticket-priority priority-${ticket.priority}">${priority.name}</span>
            <span class="ticket-time">${this.getTimeAgo(ticket.createdAt)}</span>
        `;

        div.addEventListener('click', () => this.showTicketDetails(ticket.id));

        return div;
    }

    async getFilteredTickets() {
        const statusFilter = document.getElementById('statusFilter').value;
        const categoryFilter = document.getElementById('categoryFilter').value;
        const priorityFilter = document.getElementById('priorityFilter').value;
        const searchQuery = document.getElementById('ticketSearch').value.toLowerCase();

        return this.tickets.filter(ticket => {
            if (statusFilter !== 'all' && ticket.status !== statusFilter) return false;
            if (categoryFilter !== 'all' && ticket.category !== categoryFilter) return false;
            if (priorityFilter !== 'all' && ticket.priority !== priorityFilter) return false;
            if (searchQuery && !this.ticketMatchesSearch(ticket, searchQuery)) return false;
            return true;
        });
    }

    ticketMatchesSearch(ticket, query) {
        return ticket.title.toLowerCase().includes(query) ||
               ticket.description.toLowerCase().includes(query) ||
               ticket.id.toString().includes(query) ||
               ticket.createdBy.toLowerCase().includes(query);
    }

    async showTicketDetails(ticketId) {
        const ticket = this.tickets.find(t => t.id === ticketId);
        if (!ticket) return;

        const modal = document.getElementById('ticketDetailsModal');
        const detailsDiv = modal.querySelector('.ticket-details');
        const status = this.statuses.find(s => s.id === ticket.status);
        const priority = this.priorities.find(p => p.id === ticket.priority);
        const category = this.categories.find(c => c.id === ticket.category);

        detailsDiv.innerHTML = `
            <dl>
                <dt>Ticket ID</dt>
                <dd>#${ticket.id}</dd>
                
                <dt>Status</dt>
                <dd><span class="ticket-status status-${ticket.status}">${status.name}</span></dd>
                
                <dt>Priority</dt>
                <dd><span class="ticket-priority priority-${ticket.priority}">${priority.name}</span></dd>
                
                <dt>Category</dt>
                <dd>${category.name}</dd>
                
                <dt>Created By</dt>
                <dd>${ticket.createdBy}</dd>
                
                <dt>Created At</dt>
                <dd>${this.formatDate(ticket.createdAt)}</dd>
                
                <dt>Description</dt>
                <dd>${ticket.description}</dd>
            </dl>
        `;

        // Load updates
        const updatesList = modal.querySelector('.updates-list');
        updatesList.innerHTML = '';
        ticket.updates?.forEach(update => {
            updatesList.appendChild(this.createUpdateElement(update));
        });

        // Show modal
        const modalInstance = new bootstrap.Modal(modal);
        modalInstance.show();
    }

    createUpdateElement(update) {
        const div = document.createElement('div');
        div.className = 'update-item';
        div.innerHTML = `
            <div class="update-header">
                <span class="update-author">${update.author}</span>
                <span class="update-time">${this.getTimeAgo(update.timestamp)}</span>
            </div>
            <div class="update-message">${update.message}</div>
        `;
        return div;
    }

    async submitNewTicket() {
        const form = document.getElementById('newTicketForm');
        const title = document.getElementById('ticketTitle').value;
        const category = document.getElementById('ticketCategory').value;
        const priority = document.getElementById('ticketPriority').value;
        const description = document.getElementById('ticketDescription').value;
        
        if (!title || !category || !priority || !description) {
            alert('Please fill in all required fields');
            return;
        }

        const userData = JSON.parse(sessionStorage.getItem('secureSession')).user;

        const newTicket = {
            id: this.generateTicketId(),
            title,
            category,
            priority,
            description,
            status: 'new',
            createdBy: userData.displayName,
            createdAt: new Date().toISOString(),
            updates: [],
            attachments: []
        };

        // Handle file attachments
        const attachmentInput = document.getElementById('ticketAttachment');
        const files = attachmentInput.files;
        if (files.length > 0) {
            for (let file of files) {
                if (file.size > 5 * 1024 * 1024) {
                    alert('File size must not exceed 5MB');
                    return;
                }
                // In a real implementation, files would be uploaded to a server
                newTicket.attachments.push({
                    name: file.name,
                    size: file.size,
                    type: file.type
                });
            }
        }

        // Add ticket to list
        this.tickets.unshift(newTicket);
        
        // Save tickets (in a real implementation, this would be an API call)
        await this.saveTickets();

        // Reset form and close modal
        form.reset();
        const modal = bootstrap.Modal.getInstance(document.getElementById('newTicketModal'));
        modal.hide();

        // Refresh ticket list
        this.loadTickets();
        
        // Update statistics
        this.updateStatistics();

        // Show success message
        showNotification('Ticket created successfully!', 'success');
    }

    async saveTickets() {
        // In a real implementation, this would be an API call
        // For now, we'll just log to console
        console.log('Saving tickets:', this.tickets);
    }

    generateTicketId() {
        return 'T' + Date.now().toString().slice(-6);
    }

    updateStatistics() {
        const openTickets = this.tickets.filter(t => t.status !== 'closed' && t.status !== 'resolved').length;
        document.getElementById('openTicketsCount').textContent = openTickets;

        const resolvedToday = this.tickets.filter(t => {
            if (t.status !== 'resolved') return false;
            const resolvedDate = new Date(t.resolvedAt);
            const today = new Date();
            return resolvedDate.toDateString() === today.toDateString();
        }).length;
        document.getElementById('resolvedToday').textContent = resolvedToday;

        // Calculate average response time
        const responseTimeSum = this.tickets.reduce((sum, ticket) => {
            if (!ticket.firstResponseAt) return sum;
            const created = new Date(ticket.createdAt);
            const response = new Date(ticket.firstResponseAt);
            return sum + (response - created);
        }, 0);
        const avgResponse = this.tickets.length ? Math.round(responseTimeSum / this.tickets.length / 3600000) : 0;
        document.getElementById('avgResponse').textContent = avgResponse + 'h';
    }

    formatDate(date) {
        return new Date(date).toLocaleString();
    }

    getTimeAgo(date) {
        const seconds = Math.floor((new Date() - new Date(date)) / 1000);
        
        let interval = Math.floor(seconds / 31536000);
        if (interval > 1) return interval + ' years ago';
        if (interval === 1) return 'a year ago';
        
        interval = Math.floor(seconds / 2592000);
        if (interval > 1) return interval + ' months ago';
        if (interval === 1) return 'a month ago';
        
        interval = Math.floor(seconds / 86400);
        if (interval > 1) return interval + ' days ago';
        if (interval === 1) return 'yesterday';
        
        interval = Math.floor(seconds / 3600);
        if (interval > 1) return interval + ' hours ago';
        if (interval === 1) return 'an hour ago';
        
        interval = Math.floor(seconds / 60);
        if (interval > 1) return interval + ' minutes ago';
        if (interval === 1) return 'a minute ago';
        
        return 'just now';
    }
}

// Initialize ticket manager
document.addEventListener('DOMContentLoaded', async () => {
    const ticketManager = new TicketManager();
    await ticketManager.initialize();
});
