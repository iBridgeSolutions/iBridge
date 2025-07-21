/**
 * Calendar Custom Loader
 * Loads calendar data from local mirrored sources instead of Microsoft 365 API
 */

// Function to load calendar events from local JSON data
async function loadCalendarEvents() {
    try {
        // Show loading indicator in the calendar container
        const calendarEl = document.getElementById('calendar');
        if (calendarEl && !calendarEl.querySelector('.loading-indicator')) {
            calendarEl.innerHTML = '<div class="loading-indicator d-flex justify-content-center p-5"><div class="spinner-border text-primary" role="status"><span class="visually-hidden">Loading calendar data...</span></div></div>';
        }

        // Fetch the mirrored calendar data
        const mirroredDataResponse = await fetch('data/mirrored/calendar-events.json');
        if (!mirroredDataResponse.ok) {
            throw new Error('Failed to load mirrored calendar data');
        }
        
        const calendarData = await mirroredDataResponse.json();
        console.log(`Loaded ${calendarData.length} events from mirrored data`);
        
        // Check if there are any locally saved events in localStorage
        const localEvents = [];
        const storedEvents = localStorage.getItem('calendar_events');
        if (storedEvents) {
            try {
                const parsedEvents = JSON.parse(storedEvents);
                localEvents.push(...parsedEvents);
                console.log(`Loaded ${parsedEvents.length} events from localStorage`);
            } catch (e) {
                console.error('Error parsing local events from localStorage:', e);
            }
        }
        
        // Try to fetch server-saved events
        const serverEvents = [];
        try {
            // Try PHP API endpoint first
            const serverDataResponse = await fetch('api/get-events.php');
            if (serverDataResponse.ok) {
                const serverData = await serverDataResponse.json();
                if (Array.isArray(serverData)) {
                    serverEvents.push(...serverData);
                    console.log(`Loaded ${serverData.length} events from server API`);
                }
            } else {
                // Fall back to PowerShell script via fetch with no-cache
                console.log('API endpoint not available, trying PowerShell script...');
                const psScriptResponse = await fetch('../get-calendar-events.ps1', { 
                    cache: 'no-store',
                    headers: { 'Cache-Control': 'no-cache' }
                });

                if (psScriptResponse.ok) {
                    const psData = await psScriptResponse.json();
                    if (Array.isArray(psData)) {
                        serverEvents.push(...psData);
                        console.log(`Loaded ${psData.length} events from PowerShell script`);
                    }
                } else {
                    console.log('PowerShell script not accessible');
                    
                    // Try to load from user-events.json directly as a last resort
                    const userEventsResponse = await fetch('data/user-events.json');
                    if (userEventsResponse.ok) {
                        const userData = await userEventsResponse.json();
                        if (Array.isArray(userData)) {
                            serverEvents.push(...userData);
                            console.log(`Loaded ${userData.length} events from user-events.json`);
                        }
                    }
                }
            }
        } catch (err) {
            console.warn('Could not load server events:', err);
            
            // Try to load from user-events.json directly as a last resort
            try {
                const userEventsResponse = await fetch('data/user-events.json');
                if (userEventsResponse.ok) {
                    const userData = await userEventsResponse.json();
                    if (Array.isArray(userData)) {
                        serverEvents.push(...userData);
                        console.log(`Loaded ${userData.length} events from user-events.json`);
                    }
                }
            } catch (e) {
                console.warn('Could not load user events JSON:', e);
            }
        }
        
        // Combine all events - prioritize server events over localStorage
        const allEvents = [...calendarData, ...serverEvents, ...localEvents];
        
        // Format the events for FullCalendar
        const formattedEvents = allEvents.map(event => {
            // Map event types to colors
            const colorMap = {
                'company': '#a1c44f',
                'team': '#17a2b8',
                'training': '#ffc107',
                'holiday': '#dc3545',
                'personal': '#6f42c1',
                'meeting': '#007bff',
                'deadline': '#fd7e14',
                'other': '#20c997'
            };
            
            // Default to 'other' type if not specified
            const eventType = event.type || 'other';
            const backgroundColor = colorMap[eventType] || colorMap.other;
            
            return {
                title: event.title,
                start: event.startDateTime,
                end: event.endDateTime,
                allDay: event.isAllDay,
                extendedProps: {
                    type: eventType,
                    location: event.location || 'No location specified',
                    organizer: event.organizer || 'iBridge System',
                    description: event.description || 'No description available',
                    attendees: event.attendees || []
                },
                backgroundColor: backgroundColor,
                borderColor: backgroundColor
            };
        });
        
        return formattedEvents;
    } catch (error) {
        console.error('Error loading calendar data:', error);
        // Return sample events if data couldn't be loaded
        return getSampleEvents();
    }
}

// Fallback function to provide sample events if mirrored data isn't available yet
function getSampleEvents() {
    // Get current date info
    const currentDate = new Date();
    const currentYear = currentDate.getFullYear();
    const currentMonth = currentDate.getMonth(); // 0-based
    
    // Create dates relative to current date for sample events
    const today = new Date(currentYear, currentMonth, currentDate.getDate());
    const tomorrow = new Date(currentYear, currentMonth, currentDate.getDate() + 1);
    const nextWeek = new Date(currentYear, currentMonth, currentDate.getDate() + 7);
    const twoWeeksFromNow = new Date(currentYear, currentMonth, currentDate.getDate() + 14);
    const nextMonth = new Date(currentYear, currentMonth + 1, 15);
    
    // Format dates for events
    const formatEventDate = (date, time) => {
        const year = date.getFullYear();
        const month = (date.getMonth() + 1).toString().padStart(2, '0');
        const day = date.getDate().toString().padStart(2, '0');
        return time ? `${year}-${month}-${day}T${time}` : `${year}-${month}-${day}`;
    };
    
    return [
        {
            title: 'All Staff Meeting',
            start: formatEventDate(today, '09:00:00'),
            end: formatEventDate(today, '10:30:00'),
            extendedProps: {
                type: 'company',
                location: 'Main Conference Room',
                organizer: 'John Smith, CEO',
                description: 'Quarterly company update meeting for all staff members. Updates on company performance, new initiatives, and Q&A session.',
                attendees: ['All Staff']
            },
            backgroundColor: '#a1c44f',
            borderColor: '#a1c44f'
        },
        {
            title: 'Sales Team Review',
            start: formatEventDate(tomorrow, '14:00:00'),
            end: formatEventDate(tomorrow, '15:30:00'),
            extendedProps: {
                type: 'team',
                location: 'Meeting Room 2',
                organizer: 'Lisa van Wyk, Sales Manager',
                description: 'Monthly sales team performance review and goal setting for the next month.',
                attendees: ['Sales Team']
            },
            backgroundColor: '#17a2b8',
            borderColor: '#17a2b8'
        },
        {
            title: 'Customer Experience Workshop',
            start: formatEventDate(nextWeek, '09:00:00'),
            end: formatEventDate(nextWeek, '17:00:00'),
            extendedProps: {
                type: 'training',
                location: 'Training Center',
                organizer: 'Thandi Mkhize, HR Manager',
                description: 'Full-day workshop focused on improving customer experience strategies and implementing best practices.',
                attendees: ['Contact Center Team', 'Sales Team', 'Operations Team']
            },
            backgroundColor: '#ffc107',
            borderColor: '#ffc107'
        },
        {
            title: 'Company Retreat Planning',
            start: formatEventDate(twoWeeksFromNow),
            allDay: true,
            extendedProps: {
                type: 'company',
                location: 'Offsite Planning Center',
                organizer: 'HR Department',
                description: 'Planning day for the upcoming company retreat. Team building activities and strategy sessions will be organized.',
                attendees: ['Management Team', 'HR Team']
            },
            backgroundColor: '#a1c44f',
            borderColor: '#a1c44f'
        },
        {
            title: 'Quarterly Review',
            start: formatEventDate(nextMonth, '10:00:00'),
            end: formatEventDate(nextMonth, '16:00:00'),
            extendedProps: {
                type: 'company',
                location: 'Main Conference Room',
                organizer: 'Executive Team',
                description: 'Quarterly business review and planning session for the next quarter.',
                attendees: ['All Staff']
            },
            backgroundColor: '#a1c44f',
            borderColor: '#a1c44f'
        }
    ];
}

// Function to initialize the calendar with local data
async function initializeCalendarWithLocalData() {
    console.log("Initializing calendar with local data...");
    try {
        // Show loading indicator
        const calendarEl = document.getElementById('calendar');
        if (!calendarEl) {
            console.error('Calendar element not found');
            return;
        }
        
        calendarEl.innerHTML = '<div class="d-flex justify-content-center p-5"><div class="spinner-border text-primary" role="status"><span class="visually-hidden">Loading...</span></div></div>';
        
        // Load calendar events from local JSON data
        console.log("Loading calendar events...");
        const events = await loadCalendarEvents();
        console.log(`Loaded ${events.length} calendar events`);
        
        const calendar = new FullCalendar.Calendar(calendarEl, {
            initialView: 'dayGridMonth',
            headerToolbar: {
                left: 'prev,next today',
                center: 'title',
                right: 'dayGridMonth,timeGridWeek,timeGridDay'
            },
            events: events,
            editable: false, // Not editable by drag-drop
            selectable: true, // Allow date selection
            nowIndicator: true, // Show "now" indicator line in time views
            businessHours: { // Define business hours
                daysOfWeek: [1, 2, 3, 4, 5], // Monday - Friday
                startTime: '08:00',
                endTime: '17:00',
            },
            selectMirror: true,
            navLinks: true, // Allow clicking on day/week names to navigate views
            dayMaxEvents: true, // Allow "more" link when too many events
            eventColor: '#a1c44f', // Default color (overridden by individual events)
            eventTimeFormat: { // Format time display
                hour: '2-digit',
                minute: '2-digit',
                hour12: true
            },
            // Handle date click (for adding new events)
            dateClick: function(info) {
                // Only allow admins to create events via date click
                if (isUserAdmin()) {
                    openAddEventModal(info.date);
                }
            },
            // Handle event click (show event details)
            eventClick: function(info) {
                const event = info.event;
                const props = event.extendedProps;
                
                // Set modal content
                document.getElementById('eventModalLabel').textContent = event.title;
                document.getElementById('event-date').textContent = formatEventDate(event);
                document.getElementById('event-time').textContent = formatEventTime(event);
                document.getElementById('event-location').textContent = props.location || 'No location specified';
                document.getElementById('event-organizer').textContent = props.organizer || 'System';
                document.getElementById('event-description').textContent = props.description || 'No description available';
                
                // Set attendees
                const attendeeList = document.getElementById('attendee-list');
                attendeeList.innerHTML = '';
                if (props.attendees && props.attendees.length) {
                    props.attendees.forEach(attendee => {
                        const badge = document.createElement('span');
                        badge.className = 'badge bg-light text-dark me-2 mb-2';
                        badge.textContent = attendee;
                        attendeeList.appendChild(badge);
                    });
                } else {
                    const badge = document.createElement('span');
                    badge.className = 'badge bg-light text-dark me-2 mb-2';
                    badge.textContent = 'No attendees specified';
                    attendeeList.appendChild(badge);
                }
                
                // Show reminder if available
                const eventReminder = document.getElementById('event-reminder');
                if (eventReminder) {
                    if (props.reminderMinutes) {
                        const reminderText = document.getElementById('event-reminder-text');
                        if (reminderText) {
                            let reminderMsg = '';
                            
                            if (props.reminderMinutes < 60) {
                                reminderMsg = `${props.reminderMinutes} minutes before`;
                            } else if (props.reminderMinutes === 60) {
                                reminderMsg = '1 hour before';
                            } else if (props.reminderMinutes === 1440) {
                                reminderMsg = '1 day before';
                            } else {
                                reminderMsg = `${props.reminderMinutes} minutes before`;
                            }
                            
                            reminderText.textContent = reminderMsg;
                            eventReminder.classList.remove('d-none');
                        }
                    } else {
                        eventReminder.classList.add('d-none');
                    }
                }
                
                // Change modal header color based on event type
                const modalHeader = document.querySelector('.event-modal-header');
                if (modalHeader) {
                    modalHeader.style.backgroundColor = event.backgroundColor || '#a1c44f';
                }
                
                // Show the modal
                const eventModal = new bootstrap.Modal(document.getElementById('eventModal'));
                eventModal.show();
            }
        });
        
        // Make calendar globally accessible
        window.calendar = calendar;
        
        // Render the calendar
        calendar.render();
        
        // Update the upcoming events sidebar
        updateUpcomingEventsSidebar(events);
        
        // Add event listeners
        initializeEventListeners();
        
        console.log("Calendar initialized successfully");
    } catch (error) {
        console.error("Error initializing calendar:", error);
        const calendarEl = document.getElementById('calendar');
        if (calendarEl) {
            calendarEl.innerHTML = `
                <div class="alert alert-danger">
                    <i class="fas fa-exclamation-triangle me-2"></i>
                    Failed to initialize calendar. Please try refreshing the page.
                    <div class="small mt-2">Error details: ${error.message}</div>
                </div>
            `;
        }
    }
});

// Function to check if current user is admin
function isUserAdmin() {
    // Check if user has admin role
    const userInfo = getUserInfo();
    
    if (!userInfo) return false;
    
    const userRole = userInfo.role ? userInfo.role.toLowerCase() : '';
    return userRole.includes('admin') || userRole.includes('manager') || userRole === 'executive';
}

// Function to get user info
function getUserInfo() {
    // Get user info from localStorage (set by custom-authenticator.js)
    const userInfoStr = localStorage.getItem('user_info');
    if (!userInfoStr) return null;
    
    try {
        return JSON.parse(userInfoStr);
    } catch (e) {
        console.error('Error parsing user info:', e);
        return null;
    }
}

// Function to initialize event listeners
function initializeEventListeners() {
    // Add event button functionality
    const addEventBtn = document.querySelector('.btn-add-event');
    if (addEventBtn) {
        addEventBtn.addEventListener('click', function() {
            openAddEventModal();
        });
    }
    
    // Create event button click handler
    const createEventBtn = document.getElementById('create-event-btn');
    if (createEventBtn) {
        createEventBtn.addEventListener('click', createNewEvent);
    }
    
    // Filter functionality
    const filterBtns = document.querySelectorAll('.event-filter-btn');
    
    filterBtns.forEach(btn => {
        btn.addEventListener('click', function() {
            // Update active button
            filterBtns.forEach(b => b.classList.remove('active'));
            this.classList.add('active');
            
            const eventType = this.getAttribute('data-event-type');
            
            // Filter events
            if (window.calendar) {
                if (eventType === 'all') {
                    window.calendar.getEvents().forEach(event => event.setProp('display', 'auto'));
                } else {
                    window.calendar.getEvents().forEach(event => {
                        if (event.extendedProps.type === eventType) {
                            event.setProp('display', 'auto');
                        } else {
                            event.setProp('display', 'none');
                        }
                    });
                }
            }
        });
    });
    
    // "My Events Only" toggle functionality
    const myEventsToggle = document.getElementById('my-events-only');
    if (myEventsToggle) {
        myEventsToggle.addEventListener('change', function() {
            if (!window.calendar) return;
            
            if (this.checked) {
                // Get user info
                const userInfo = getUserInfo();
                
                if (!userInfo) {
                    showToast('User information not available. Please log in again.', 'error');
                    this.checked = false;
                    return;
                }
                
                // Filter events to only show those for the current user's team/department
                window.calendar.getEvents().forEach(event => {
                    const attendees = event.extendedProps.attendees || [];
                    let shouldDisplay = false;
                    
                    // Check if any attendee matches user's team/department
                    for (const attendee of attendees) {
                        if (isUserInTeam(attendee, userInfo)) {
                            shouldDisplay = true;
                            break;
                        }
                    }
                    
                    // Set display property
                    event.setProp('display', shouldDisplay ? 'auto' : 'none');
                });
            } else {
                // Reset filter to current type filter
                const activeType = document.querySelector('.event-filter-btn.active').getAttribute('data-event-type');
                document.querySelector(`.event-filter-btn[data-event-type="${activeType}"]`).click();
            }
        });
    }
    
    // Sync button
    const syncBtn = document.getElementById('sync-calendar-btn');
    if (syncBtn) {
        syncBtn.addEventListener('click', synchronizeCalendar);
    }
    
    // Reminder badge selection in add event modal
    const reminderBadges = document.querySelectorAll('.reminder-badge');
    if (reminderBadges.length > 0) {
        reminderBadges.forEach(badge => {
            badge.addEventListener('click', function() {
                // Remove active class from all badges
                reminderBadges.forEach(b => b.classList.remove('active'));
                // Add active class to clicked badge
                this.classList.add('active');
                // Set the hidden input value
                document.getElementById('reminder-time').value = this.getAttribute('data-value');
            });
        });
    }
    
    // Reminder checkbox toggle
    const reminderCheck = document.getElementById('set-reminder');
    const reminderOptions = document.getElementById('reminder-options');
    if (reminderCheck && reminderOptions) {
        reminderCheck.addEventListener('change', function() {
            if (this.checked) {
                reminderOptions.classList.remove('d-none');
            } else {
                reminderOptions.classList.add('d-none');
                document.getElementById('reminder-time').value = '';
                reminderBadges.forEach(b => b.classList.remove('active'));
            }
        });
    }
    
    // All day event checkbox
    const allDayCheck = document.getElementById('event-all-day');
    const startTimeInput = document.getElementById('event-start-time');
    const endTimeInput = document.getElementById('event-end-time');
    if (allDayCheck && startTimeInput && endTimeInput) {
        allDayCheck.addEventListener('change', function() {
            if (this.checked) {
                startTimeInput.disabled = true;
                endTimeInput.disabled = true;
            } else {
                startTimeInput.disabled = false;
                endTimeInput.disabled = false;
            }
        });
    }
}

// Function to synchronize calendar events from all sources
async function synchronizeCalendar() {
    try {
        // Show synchronizing indicator
        const syncButton = document.getElementById('sync-calendar-btn');
        if (syncButton) {
            const originalText = syncButton.innerHTML;
            syncButton.innerHTML = '<i class="fas fa-sync-alt fa-spin"></i> Syncing...';
            syncButton.disabled = true;
            
            // Reload calendar events
            const events = await loadCalendarEvents();
            
            // Re-render the calendar with the updated events
            if (window.calendar) {
                window.calendar.removeAllEvents();
                window.calendar.addEventSource(events);
                
                // Update "Upcoming Events" sidebar
                updateUpcomingEventsSidebar(events);
                
                // Show success message
                showToast('Calendar synchronized successfully!', 'success');
                
                // Reset button
                setTimeout(() => {
                    syncButton.innerHTML = originalText;
                    syncButton.disabled = false;
                }, 500);
                
                return true;
            }
        }
        return false;
    } catch (error) {
        console.error('Error synchronizing calendar:', error);
        
        // Show error message
        showToast('Failed to synchronize calendar: ' + error.message, 'error');
        
        // Reset sync button
        const syncButton = document.getElementById('sync-calendar-btn');
        if (syncButton) {
            syncButton.innerHTML = '<i class="fas fa-sync-alt"></i> Sync';
            syncButton.disabled = false;
        }
        
        return false;
    }
}

// Function to display toast notifications
function showToast(message, type = 'info') {
    // Create toast container if it doesn't exist
    let toastContainer = document.querySelector('.calendar-toast');
    if (!toastContainer) {
        toastContainer = document.createElement('div');
        toastContainer.className = 'calendar-toast';
        document.body.appendChild(toastContainer);
    }
    
    // Create the toast element
    const toast = document.createElement('div');
    toast.className = `toast show align-items-center text-white bg-${type === 'error' ? 'danger' : type === 'success' ? 'success' : 'primary'}`;
    toast.setAttribute('role', 'alert');
    toast.setAttribute('aria-live', 'assertive');
    toast.setAttribute('aria-atomic', 'true');
    
    // Create toast content
    toast.innerHTML = `
        <div class="d-flex">
            <div class="toast-body">
                ${message}
            </div>
            <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast" aria-label="Close"></button>
        </div>
    `;
    
    // Add to container
    toastContainer.appendChild(toast);
    
    // Auto-remove after 5 seconds
    setTimeout(() => {
        toast.classList.remove('show');
        setTimeout(() => {
            toastContainer.removeChild(toast);
        }, 300);
    }, 5000);
}

// Helper function to check if user is part of a team/department
function isUserInTeam(team, userInfo) {
    if (!userInfo) return false;
    if (!team || team === 'all') return true;
    
    // Check if user is in the specified team
    const userTeam = userInfo.team ? userInfo.team.toLowerCase() : '';
    const userDepartment = userInfo.department ? userInfo.department.toLowerCase() : '';
    const userRole = userInfo.role ? userInfo.role.toLowerCase() : '';
    
    // Try to match by team, department, or role
    return team.toLowerCase() === userTeam || 
           team.toLowerCase() === userDepartment ||
           team.toLowerCase() === userRole ||
           team.toLowerCase().includes(userTeam) ||
           userTeam.includes(team.toLowerCase());
}

// Function to synchronize calendar events
async function synchronizeCalendarEvents() {
    try {
        // Show sync indicator
        showNotification('Synchronizing', 'Fetching the latest calendar events...', 'info');
        
        // Fetch latest events from all sources
        const mirroredResponse = await fetch('data/mirrored/calendar-events.json?' + new Date().getTime());
        if (!mirroredResponse.ok) {
            throw new Error('Failed to fetch mirrored events');
        }
        
        const mirroredEvents = await mirroredResponse.json();
        console.log(`Synced ${mirroredEvents.length} mirrored events`);
        
        // Try to fetch server events
        let serverEvents = [];
        try {
            // Try the PHP endpoint
            const serverResponse = await fetch('api/get-events.php?' + new Date().getTime());
            if (serverResponse.ok) {
                serverEvents = await serverResponse.json();
                console.log(`Synced ${serverEvents.length} server events`);
            }
        } catch (err) {
            console.warn('Could not sync server events:', err);
        }
        
        // Get current events from localStorage
        let localEvents = [];
        const storedEvents = localStorage.getItem('calendar_events');
        if (storedEvents) {
            try {
                localEvents = JSON.parse(storedEvents);
                console.log(`Found ${localEvents.length} local events`);
            } catch (e) {
                console.error('Error parsing local events:', e);
            }
        }
        
        // Format all events for the calendar
        const formattedEvents = [...mirroredEvents, ...serverEvents, ...localEvents].map(event => {
            // Map event types to colors
            const colorMap = {
                'company': '#a1c44f',
                'team': '#17a2b8',
                'training': '#ffc107',
                'holiday': '#dc3545',
                'personal': '#6f42c1',
                'meeting': '#007bff',
                'deadline': '#fd7e14',
                'other': '#20c997'
            };
            
            // Default to 'other' type if not specified
            const eventType = event.type || 'other';
            const backgroundColor = colorMap[eventType] || colorMap.other;
            
            return {
                title: event.title,
                start: event.startDateTime,
                end: event.endDateTime,
                allDay: event.isAllDay,
                extendedProps: {
                    type: eventType,
                    location: event.location || 'No location specified',
                    organizer: event.organizer || 'iBridge System',
                    description: event.description || 'No description available',
                    attendees: event.attendees || [],
                    source: event.source || 'unknown',
                    id: event.id || null
                },
                backgroundColor: backgroundColor,
                borderColor: backgroundColor
            };
        });
        
        // Update the calendar with new events
        const calendar = document.querySelector('.fc').fullCalendar;
        if (calendar) {
            // Remove existing events
            calendar.removeAllEvents();
            
            // Add new events
            calendar.addEventSource(formattedEvents);
            
            // Refresh the calendar view
            calendar.refetchEvents();
        }
        
        // Also update the upcoming events sidebar
        loadUpcomingEvents(formattedEvents);
        
        showNotification('Sync Complete', 'Calendar events have been updated.', 'success');
        return formattedEvents;
    } catch (error) {
        console.error('Error synchronizing events:', error);
        showNotification('Sync Failed', `Could not synchronize events: ${error.message}`, 'danger');
        return null;
    }
}

// Add a sync button to the calendar UI
function addSyncButton(calendar) {
    // Create the sync button in the header toolbar
    const headerToolbar = document.querySelector('.fc-header-toolbar .fc-right');
    if (headerToolbar) {
        const syncButton = document.createElement('button');
        syncButton.className = 'fc-button fc-button-primary fc-sync-button ms-2';
        syncButton.innerHTML = '<i class="fas fa-sync-alt"></i>';
        syncButton.title = 'Synchronize calendar events';
        headerToolbar.appendChild(syncButton);
        
        // Add click event
        syncButton.addEventListener('click', async function() {
            this.disabled = true;
            this.innerHTML = '<i class="fas fa-sync-alt fa-spin"></i>';
            
            await synchronizeCalendarEvents();
            
            setTimeout(() => {
                this.disabled = false;
                this.innerHTML = '<i class="fas fa-sync-alt"></i>';
            }, 1000);
        });
    }
}

// Initialize when the DOM is fully loaded
document.addEventListener('DOMContentLoaded', async function() {
    try {
        console.log("Initializing calendar with enhanced features...");
        
        // Load calendar events
        const events = await loadCalendarEvents();
        
        // Get calendar element
        const calendarEl = document.getElementById('calendar');
        
        // Exit if calendar element doesn't exist
        if (!calendarEl) {
            console.error("Calendar element not found");
            return;
        }
        
        // Clear any loading indicators
        calendarEl.innerHTML = '';
        
        // Initialize FullCalendar
        const calendar = new FullCalendar.Calendar(calendarEl, {
            initialView: 'dayGridMonth',
            headerToolbar: {
                left: 'prev,next today',
                center: 'title',
                right: 'dayGridMonth,timeGridWeek,timeGridDay'
            },
            events: events,
            editable: false, // Not editable by drag-drop
            selectable: true, // Allow date selection
            nowIndicator: true, // Show "now" indicator line in time views
            businessHours: { // Define business hours
                daysOfWeek: [1, 2, 3, 4, 5], // Monday - Friday
                startTime: '08:00',
                endTime: '17:00',
            },
            selectMirror: true,
            navLinks: true, // Allow clicking on day/week names to navigate views
            dayMaxEvents: true, // Allow "more" link when too many events
            eventColor: '#a1c44f', // Default color (overridden by individual events)
            eventTimeFormat: { // Format time display
                hour: '2-digit',
                minute: '2-digit',
                hour12: true
            },
            // Handle date click (for adding new events)
            dateClick: function(info) {
                // Only allow admins to create events via date click
                if (isUserAdmin()) {
                    openAddEventModal(info.date);
                }
            },
            // Handle event click (show event details)
            eventClick: function(info) {
                const event = info.event;
                const props = event.extendedProps;
                
                // Set modal content
                document.getElementById('eventModalLabel').textContent = event.title;
                document.getElementById('event-date').textContent = formatEventDate(event);
                document.getElementById('event-time').textContent = formatEventTime(event);
                document.getElementById('event-location').textContent = props.location || 'No location specified';
                document.getElementById('event-organizer').textContent = props.organizer || 'System';
                document.getElementById('event-description').textContent = props.description || 'No description available';
                
                // Set attendees
                const attendeeList = document.getElementById('attendee-list');
                attendeeList.innerHTML = '';
                if (props.attendees && props.attendees.length) {
                    props.attendees.forEach(attendee => {
                        const badge = document.createElement('span');
                        badge.className = 'badge bg-light text-dark me-2 mb-2';
                        badge.textContent = attendee;
                        attendeeList.appendChild(badge);
                    });
                } else {
                    const badge = document.createElement('span');
                    badge.className = 'badge bg-light text-dark me-2 mb-2';
                    badge.textContent = 'No attendees specified';
                    attendeeList.appendChild(badge);
                }
                
                // Show reminder if available
                const eventReminder = document.getElementById('event-reminder');
                if (eventReminder) {
                    if (props.reminderMinutes) {
                        const reminderText = document.getElementById('event-reminder-text');
                        if (reminderText) {
                            let reminderMsg = '';
                            
                            if (props.reminderMinutes < 60) {
                                reminderMsg = `${props.reminderMinutes} minutes before`;
                            } else if (props.reminderMinutes === 60) {
                                reminderMsg = '1 hour before';
                            } else if (props.reminderMinutes === 1440) {
                                reminderMsg = '1 day before';
                            } else {
                                reminderMsg = `${props.reminderMinutes} minutes before`;
                            }
                            
                            reminderText.textContent = reminderMsg;
                            eventReminder.classList.remove('d-none');
                        }
                    } else {
                        eventReminder.classList.add('d-none');
                    }
                }
                
                // Change modal header color based on event type
                const modalHeader = document.querySelector('.event-modal-header');
                if (modalHeader) {
                    modalHeader.style.backgroundColor = event.backgroundColor || '#a1c44f';
                }
                
                // Show the modal
                const eventModal = new bootstrap.Modal(document.getElementById('eventModal'));
                eventModal.show();
            }
        });
        
        // Make calendar globally accessible
        window.calendar = calendar;
        
        // Render the calendar
        calendar.render();
        
        // Update the upcoming events sidebar
        updateUpcomingEventsSidebar(events);
        
        // Add event listeners
        initializeEventListeners();
        
        console.log("Calendar initialized successfully");
    } catch (error) {
        console.error("Error initializing calendar:", error);
        const calendarEl = document.getElementById('calendar');
        if (calendarEl) {
            calendarEl.innerHTML = `
                <div class="alert alert-danger">
                    <i class="fas fa-exclamation-triangle me-2"></i>
                    Failed to initialize calendar. Please try refreshing the page.
                    <div class="small mt-2">Error details: ${error.message}</div>
                </div>
            `;
        }
    }
});

// Function to check if current user is admin
function isUserAdmin() {
    // Check if user has admin role
    const userInfo = getUserInfo();
    
    if (!userInfo) return false;
    
    const userRole = userInfo.role ? userInfo.role.toLowerCase() : '';
    return userRole.includes('admin') || userRole.includes('manager') || userRole === 'executive';
}

// Function to get user info
function getUserInfo() {
    // Get user info from localStorage (set by custom-authenticator.js)
    const userInfoStr = localStorage.getItem('user_info');
    if (!userInfoStr) return null;
    
    try {
        return JSON.parse(userInfoStr);
    } catch (e) {
        console.error('Error parsing user info:', e);
        return null;
    }
}

// Function to initialize event listeners
function initializeEventListeners() {
    // Add event button functionality
    const addEventBtn = document.querySelector('.btn-add-event');
    if (addEventBtn) {
        addEventBtn.addEventListener('click', function() {
            openAddEventModal();
        });
    }
    
    // Create event button click handler
    const createEventBtn = document.getElementById('create-event-btn');
    if (createEventBtn) {
        createEventBtn.addEventListener('click', createNewEvent);
    }
    
    // Filter functionality
    const filterBtns = document.querySelectorAll('.event-filter-btn');
    
    filterBtns.forEach(btn => {
        btn.addEventListener('click', function() {
            // Update active button
            filterBtns.forEach(b => b.classList.remove('active'));
            this.classList.add('active');
            
            const eventType = this.getAttribute('data-event-type');
            
            // Filter events
            if (window.calendar) {
                if (eventType === 'all') {
                    window.calendar.getEvents().forEach(event => event.setProp('display', 'auto'));
                } else {
                    window.calendar.getEvents().forEach(event => {
                        if (event.extendedProps.type === eventType) {
                            event.setProp('display', 'auto');
                        } else {
                            event.setProp('display', 'none');
                        }
                    });
                }
            }
        });
    });
    
    // "My Events Only" toggle functionality
    const myEventsToggle = document.getElementById('my-events-only');
    if (myEventsToggle) {
        myEventsToggle.addEventListener('change', function() {
            if (!window.calendar) return;
            
            if (this.checked) {
                // Get user info
                const userInfo = getUserInfo();
                
                if (!userInfo) {
                    showToast('User information not available. Please log in again.', 'error');
                    this.checked = false;
                    return;
                }
                
                // Filter events to only show those for the current user's team/department
                window.calendar.getEvents().forEach(event => {
                    const attendees = event.extendedProps.attendees || [];
                    let shouldDisplay = false;
                    
                    // Check if any attendee matches user's team/department
                    for (const attendee of attendees) {
                        if (isUserInTeam(attendee, userInfo)) {
                            shouldDisplay = true;
                            break;
                        }
                    }
                    
                    // Set display property
                    event.setProp('display', shouldDisplay ? 'auto' : 'none');
                });
            } else {
                // Reset filter to current type filter
                const activeType = document.querySelector('.event-filter-btn.active').getAttribute('data-event-type');
                document.querySelector(`.event-filter-btn[data-event-type="${activeType}"]`).click();
            }
        });
    }
    
    // Sync button
    const syncBtn = document.getElementById('sync-calendar-btn');
    if (syncBtn) {
        syncBtn.addEventListener('click', synchronizeCalendar);
    }
    
    // Reminder badge selection in add event modal
    const reminderBadges = document.querySelectorAll('.reminder-badge');
    if (reminderBadges.length > 0) {
        reminderBadges.forEach(badge => {
            badge.addEventListener('click', function() {
                // Remove active class from all badges
                reminderBadges.forEach(b => b.classList.remove('active'));
                // Add active class to clicked badge
                this.classList.add('active');
                // Set the hidden input value
                document.getElementById('reminder-time').value = this.getAttribute('data-value');
            });
        });
    }
    
    // Reminder checkbox toggle
    const reminderCheck = document.getElementById('set-reminder');
    const reminderOptions = document.getElementById('reminder-options');
    if (reminderCheck && reminderOptions) {
        reminderCheck.addEventListener('change', function() {
            if (this.checked) {
                reminderOptions.classList.remove('d-none');
            } else {
                reminderOptions.classList.add('d-none');
                document.getElementById('reminder-time').value = '';
                reminderBadges.forEach(b => b.classList.remove('active'));
            }
        });
    }
    
    // All day event checkbox
    const allDayCheck = document.getElementById('event-all-day');
    const startTimeInput = document.getElementById('event-start-time');
    const endTimeInput = document.getElementById('event-end-time');
    if (allDayCheck && startTimeInput && endTimeInput) {
        allDayCheck.addEventListener('change', function() {
            if (this.checked) {
                startTimeInput.disabled = true;
                endTimeInput.disabled = true;
            } else {
                startTimeInput.disabled = false;
                endTimeInput.disabled = false;
            }
        });
    }
}

// Function to format event date
function formatEventDate(event) {
    if (event.allDay) {
        if (event.start && event.end) {
            const startDate = event.start.toLocaleDateString('en-ZA', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' });
            const endDate = event.end.toLocaleDateString('en-ZA', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' });
            return `${startDate} - ${endDate}`;
        } else {
            return event.start.toLocaleDateString('en-ZA', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' });
        }
    } else {
        return event.start.toLocaleDateString('en-ZA', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' });
    }
}

// Function to format event time
function formatEventTime(event) {
    if (event.allDay) {
        return 'All Day';
    } else {
        const startTime = event.start.toLocaleTimeString('en-ZA', { hour: '2-digit', minute: '2-digit' });
        const endTime = event.end ? event.end.toLocaleTimeString('en-ZA', { hour: '2-digit', minute: '2-digit' }) : '';
        return endTime ? `${startTime} - ${endTime}` : startTime;
    }
}

// Function to open the Add Event modal with optional prefilled date
function openAddEventModal(date) {
    // Set default dates if provided
    if (date) {
        const startDateInput = document.getElementById('event-start-date');
        const endDateInput = document.getElementById('event-end-date');
        
        if (startDateInput && endDateInput) {
            const formattedDate = date.toISOString().substring(0, 10); // YYYY-MM-DD
            startDateInput.value = formattedDate;
            endDateInput.value = formattedDate;
        }
    }
    
    // Show the modal
    const addEventModal = new bootstrap.Modal(document.getElementById('addEventModal'));
    addEventModal.show();
}

// Function to create a new event
async function createNewEvent() {
    try {
        // Get form inputs
        const titleInput = document.getElementById('event-title');
        const startDateInput = document.getElementById('event-start-date');
        const endDateInput = document.getElementById('event-end-date');
        const startTimeInput = document.getElementById('event-start-time');
        const endTimeInput = document.getElementById('event-end-time');
        const allDayCheck = document.getElementById('event-all-day');
        const locationInput = document.getElementById('event-location-input');
        const typeSelect = document.getElementById('event-type');
        const descriptionInput = document.getElementById('event-description-input');
        const attendeesSelect = document.getElementById('event-attendees-select');
        const reminderTimeInput = document.getElementById('reminder-time');
        
        // Validate required fields
        if (!titleInput.value.trim()) {
            showToast('Please enter an event title', 'error');
            titleInput.focus();
            return;
        }
        
        if (!startDateInput.value) {
            showToast('Please select a start date', 'error');
            startDateInput.focus();
            return;
        }
        
        if (!endDateInput.value) {
            showToast('Please select an end date', 'error');
            endDateInput.focus();
            return;
        }
        
        // Check if end date is not before start date
        if (new Date(endDateInput.value) < new Date(startDateInput.value)) {
            showToast('End date cannot be before start date', 'error');
            endDateInput.focus();
            return;
        }
        
        // Create start and end datetime strings
        let startDateTime, endDateTime;
        const isAllDay = allDayCheck && allDayCheck.checked;
        
        if (isAllDay) {
            // For all-day events, we don't need time
            startDateTime = startDateInput.value;
            endDateTime = endDateInput.value;
        } else {
            // Combine date and time
            const startTime = startTimeInput.value || '00:00';
            const endTime = endTimeInput.value || '23:59';
            
            startDateTime = `${startDateInput.value}T${startTime}:00`;
            endDateTime = `${endDateInput.value}T${endTime}:00`;
        }
        
        // Get selected attendees
        const selectedAttendees = Array.from(attendeesSelect.selectedOptions).map(option => option.value);
        
        // Get user info
        const userInfo = getUserInfo();
        const organizer = userInfo ? `${userInfo.name || 'User'} (${userInfo.role || 'Staff'})` : 'System User';
        
        // Create event object
        const eventData = {
            title: titleInput.value.trim(),
            startDateTime: startDateTime,
            endDateTime: endDateTime,
            isAllDay: isAllDay,
            location: locationInput.value.trim() || 'No location specified',
            type: typeSelect.value,
            description: descriptionInput.value.trim(),
            attendees: selectedAttendees.length > 0 ? selectedAttendees : ['all'],
            organizer: organizer,
            createdBy: userInfo ? userInfo.username || userInfo.email : 'anonymous'
        };
        
        // Add reminder if specified
        if (reminderTimeInput && reminderTimeInput.value) {
            eventData.reminderMinutes = parseInt(reminderTimeInput.value, 10);
        }
        
        // Show saving indicator
        const createBtn = document.getElementById('create-event-btn');
        const originalBtnText = createBtn.innerHTML;
        createBtn.innerHTML = '<i class="fas fa-spinner fa-spin me-1"></i> Saving...';
        createBtn.disabled = true;
        
        // Save the event
        const saveResult = await saveCalendarEvent(eventData);
        
        if (saveResult.success) {
            // Show success message
            showToast('Event created successfully!', 'success');
            
            // Close the modal
            const addEventModal = bootstrap.Modal.getInstance(document.getElementById('addEventModal'));
            addEventModal.hide();
            
            // Reset the form
            document.getElementById('add-event-form').reset();
            
            // Update the calendar
            await synchronizeCalendar();
        } else {
            // Show error message
            showToast('Failed to create event: ' + (saveResult.error || 'Unknown error'), 'error');
            
            // Reset button
            createBtn.innerHTML = originalBtnText;
            createBtn.disabled = false;
        }
    } catch (error) {
        console.error('Error creating event:', error);
        showToast('An error occurred while creating the event', 'error');
        
        // Reset button
        const createBtn = document.getElementById('create-event-btn');
        if (createBtn) {
            createBtn.innerHTML = '<i class="fas fa-plus-circle me-1"></i> Create Event';
            createBtn.disabled = false;
        }
    }
}

// Function to update the upcoming events sidebar
function updateUpcomingEventsSidebar(events) {
    const upcomingEventsContainer = document.getElementById('upcoming-events');
    if (!upcomingEventsContainer) return;
    
    // Clear existing content
    upcomingEventsContainer.innerHTML = '';
    
    // Filter events to only show future events
    const now = new Date();
    const futureEvents = events.filter(event => {
        const eventStart = new Date(event.start);
        return eventStart >= now;
    });
    
    // Sort by date (ascending)
    futureEvents.sort((a, b) => {
        return new Date(a.start) - new Date(b.start);
    });
    
    // Get the first 4 events
    const upcomingEvents = futureEvents.slice(0, 4);
    
    if (upcomingEvents.length === 0) {
        upcomingEventsContainer.innerHTML = '<div class="text-center p-3 text-muted">No upcoming events</div>';
        return;
    }
    
    // Add each event to the sidebar
    upcomingEvents.forEach(event => {
        const eventDate = new Date(event.start);
        const formattedDate = eventDate.toLocaleDateString('en-ZA', { year: 'numeric', month: 'long', day: 'numeric' });
        
        // Format time
        let formattedTime;
        if (event.allDay) {
            formattedTime = 'All Day';
        } else {
            const startTime = eventDate.toLocaleTimeString('en-ZA', { hour: '2-digit', minute: '2-digit' });
            const endTime = event.end ? new Date(event.end).toLocaleTimeString('en-ZA', { hour: '2-digit', minute: '2-digit' }) : '';
            formattedTime = endTime ? `${startTime} - ${endTime}` : startTime;
        }
        
        // Create event element
        const eventElement = document.createElement('div');
        eventElement.className = 'upcoming-event';
        eventElement.innerHTML = `
            <div class="event-date">${formattedDate}</div>
            <div class="event-time">${formattedTime}</div>
            <div class="event-title">${event.title}</div>
            <div class="event-location"><i class="fas fa-map-marker-alt me-1"></i> ${event.extendedProps.location}</div>
            <span class="event-type-badge event-${event.extendedProps.type}">${capitalizeFirstLetter(event.extendedProps.type)}</span>
        `;
        
        // Add click event to show event details
        eventElement.style.cursor = 'pointer';
        eventElement.addEventListener('click', function() {
            if (window.calendar) {
                // Find the event in the calendar
                const calendarEvent = window.calendar.getEvents().find(e => 
                    e.title === event.title && 
                    e.start.getTime() === new Date(event.start).getTime()
                );
                
                if (calendarEvent) {
                    // Simulate click on the event
                    calendarEvent.publicClick();
                }
            }
        });
        
        upcomingEventsContainer.appendChild(eventElement);
    });
}

// Helper function to capitalize first letter
function capitalizeFirstLetter(string) {
    return string.charAt(0).toUpperCase() + string.slice(1);
}
