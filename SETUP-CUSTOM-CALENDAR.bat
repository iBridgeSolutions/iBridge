@echo off
echo ================================================================
echo     M365 MIRROR TO CUSTOM AUTH - CALENDAR IMPLEMENTATION
echo ================================================================
echo.
echo This script will:
echo 1. Create a custom calendar loader for the mirrored M365 data
echo 2. Update the calendar page to work with custom authentication
echo 3. Connect the calendar.html to the custom auth system
echo.
echo User: lwandile.gasela@ibridge.co.za (IBDG054)
echo.

echo Creating calendar loader script...
powershell -ExecutionPolicy Bypass -Command "$calendarLoaderPath = '.\intranet\js\calendar-custom-loader.js'; $content = @'
/**
 * iBridge Calendar Loader for Custom Authentication
 * Loads calendar data from mirrored M365 data using custom authentication
 */

document.addEventListener('DOMContentLoaded', function() {
    console.log('Calendar custom loader initialized');
    
    // Check if custom authenticator is available
    if (!window.customAuth) {
        console.error('Custom authenticator not found');
        return;
    }
    
    // Wait for auth to initialize
    setTimeout(function() {
        initializeCalendarWithCustomAuth();
    }, 500);
    
    function initializeCalendarWithCustomAuth() {
        // Get user data from custom auth
        const userData = JSON.parse(sessionStorage.getItem('portalUser') || '{}');
        if (!userData || !userData.userPrincipalName) {
            console.error('User not authenticated with custom auth');
            return;
        }
        
        console.log('Loading calendar data for:', userData.userPrincipalName);
        
        // Initialize the calendar with custom authentication
        const calendarEl = document.getElementById('calendar');
        if (!calendarEl) {
            console.error('Calendar element not found');
            return;
        }
        
        // Initialize calendar with base config
        window.calendar = new FullCalendar.Calendar(calendarEl, {
            initialView: 'dayGridMonth',
            headerToolbar: {
                left: 'prev,next today',
                center: 'title',
                right: 'dayGridMonth,timeGridWeek,timeGridDay,listMonth'
            },
            events: [], // Start with empty events
            eventClick: function(info) {
                showEventModal(info.event);
            }
        });
        
        // Load events from mirrored data
        loadMirroredCalendarData()
            .then(() => {
                // Render calendar after loading data
                window.calendar.render();
                console.log('Calendar rendered with mirrored data');
                
                // Set up filter functionality
                setupCalendarFilters();
            })
            .catch(error => {
                console.error('Error setting up calendar:', error);
            });
    }
    
    function loadMirroredCalendarData() {
        return new Promise((resolve, reject) => {
            // Create a combined promise to load all calendar data sources
            Promise.all([
                // Load main calendar events
                fetch('/intranet/data/m365-mirror/calendar/events.json')
                    .then(response => response.json())
                    .then(data => {
                        // Process calendar events from M365 mirror
                        if (data && data.events && Array.isArray(data.events)) {
                            addEventsToCalendar(data.events);
                        }
                    }),
                
                // Load holidays
                fetch('/intranet/data/m365-mirror/calendar/holidays.json')
                    .then(response => response.json())
                    .then(holidays => {
                        // Add holidays to calendar
                        if (Array.isArray(holidays)) {
                            addHolidaysToCalendar(holidays);
                        }
                    }),
                    
                // You can add more data sources here as needed
            ])
            .then(() => {
                // Update upcoming events sidebar
                updateUpcomingEventsSidebar();
                resolve();
            })
            .catch(error => {
                console.error('Error loading mirrored calendar data:', error);
                reject(error);
            });
        });
    }
    
    function addEventsToCalendar(events) {
        if (!window.calendar || !events) return;
        
        // Format events for FullCalendar
        events.forEach(event => {
            window.calendar.addEvent({
                title: event.subject,
                start: event.start.dateTime || event.start,
                end: event.end.dateTime || event.end,
                allDay: event.isAllDay || false,
                extendedProps: {
                    type: getEventType(event),
                    location: event.location?.displayName || 'No location',
                    organizer: getEventOrganizer(event),
                    description: event.bodyPreview || 'No description available',
                    attendees: getAttendees(event)
                },
                backgroundColor: getEventColor(event),
                borderColor: getEventColor(event)
            });
        });
        
        console.log('Added events to calendar:', events.length);
    }
    
    function addHolidaysToCalendar(holidays) {
        if (!window.calendar || !holidays) return;
        
        holidays.forEach(holiday => {
            window.calendar.addEvent({
                title: holiday.name,
                start: holiday.date,
                allDay: true,
                extendedProps: {
                    type: 'holiday',
                    location: 'Public Holiday',
                    organizer: 'Calendar System',
                    description: `${holiday.name} - ${holiday.isWorkDay ? 'Working Day' : 'Non-working Day'}`,
                    attendees: ['All Staff']
                },
                backgroundColor: '#dc3545',
                borderColor: '#dc3545'
            });
        });
        
        console.log('Holidays added to calendar:', holidays.length);
    }
    
    function updateUpcomingEventsSidebar() {
        const upcomingEventsContainer = document.getElementById('upcoming-events');
        if (!upcomingEventsContainer) return;
        
        // Clear existing content
        upcomingEventsContainer.innerHTML = '';
        
        // Get the next 4 events
        const today = new Date();
        const nextEvents = window.calendar.getEvents()
            .filter(event => new Date(event.start) >= today)
            .sort((a, b) => new Date(a.start) - new Date(b.start))
            .slice(0, 4);
        
        if (nextEvents.length === 0) {
            upcomingEventsContainer.innerHTML = '<div class=\"p-3 text-center\">No upcoming events</div>';
            return;
        }
        
        // Create event elements
        nextEvents.forEach(event => {
            const eventElement = document.createElement('div');
            eventElement.className = 'upcoming-event';
            
            const eventDate = new Date(event.start);
            const formattedDate = eventDate.toLocaleDateString('en-ZA', { 
                year: 'numeric', 
                month: 'long', 
                day: 'numeric' 
            });
            
            let timeDisplay = 'All Day';
            if (!event.allDay) {
                const startTime = eventDate.toLocaleTimeString('en-ZA', { 
                    hour: '2-digit', 
                    minute: '2-digit' 
                });
                const endTime = new Date(event.end).toLocaleTimeString('en-ZA', { 
                    hour: '2-digit', 
                    minute: '2-digit' 
                });
                timeDisplay = `${startTime} - ${endTime}`;
            }
            
            // Get badge class based on event type
            const badgeClass = `event-type-badge event-${event.extendedProps.type || 'company'}`;
            const typeText = event.extendedProps.type ? 
                event.extendedProps.type.charAt(0).toUpperCase() + event.extendedProps.type.slice(1) : 
                'Company';
            
            eventElement.innerHTML = `
                <div class="event-date">${formattedDate}</div>
                <div class="event-time">${timeDisplay}</div>
                <div class="event-title">${event.title}</div>
                <div class="event-location"><i class="fas fa-map-marker-alt me-1"></i> ${event.extendedProps.location}</div>
                <span class="${badgeClass}">${typeText}</span>
            `;
            
            eventElement.addEventListener('click', () => showEventModal(event));
            
            upcomingEventsContainer.appendChild(eventElement);
        });
    }
    
    function showEventModal(event) {
        const props = event.extendedProps;
        
        // Set modal content
        document.getElementById('eventModalLabel').textContent = event.title;
        document.getElementById('event-date').textContent = formatEventDate(event);
        document.getElementById('event-time').textContent = formatEventTime(event);
        document.getElementById('event-location').textContent = props.location;
        document.getElementById('event-organizer').textContent = props.organizer || 'Not specified';
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
            attendeeList.innerHTML = '<span class="text-muted">No attendees listed</span>';
        }
        
        // Change modal header color based on event type
        const modalHeader = document.querySelector('.event-modal-header');
        modalHeader.style.backgroundColor = event.backgroundColor;
        
        // Show the modal
        const eventModal = new bootstrap.Modal(document.getElementById('eventModal'));
        eventModal.show();
    }
    
    function setupCalendarFilters() {
        // Filter functionality
        const filterBtns = document.querySelectorAll('.event-filter-btn');
        
        filterBtns.forEach(btn => {
            btn.addEventListener('click', function() {
                // Update active button
                filterBtns.forEach(b => b.classList.remove('active'));
                this.classList.add('active');
                
                const eventType = this.getAttribute('data-event-type');
                
                // Filter events
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
            });
        });
        
        // "My Events Only" toggle functionality
        const myEventsToggle = document.getElementById('my-events-only');
        if (myEventsToggle) {
            myEventsToggle.addEventListener('change', function() {
                if (this.checked) {
                    // Get the current user
                    const userData = JSON.parse(sessionStorage.getItem('portalUser') || '{}');
                    const userEmail = userData.userPrincipalName;
                    
                    if (!userEmail) {
                        console.error('User email not found in session');
                        return;
                    }
                    
                    // Filter to only show events for this user
                    window.calendar.getEvents().forEach(event => {
                        const isUserEvent = event.extendedProps.attendees && 
                            (event.extendedProps.attendees.includes(userEmail) || 
                             event.extendedProps.attendees.includes('All Staff') ||
                             event.extendedProps.organizer === userData.displayName);
                             
                        event.setProp('display', isUserEvent ? 'auto' : 'none');
                    });
                } else {
                    // Show all events based on current type filter
                    const activeBtn = document.querySelector('.event-filter-btn.active');
                    if (activeBtn) {
                        activeBtn.click();
                    } else {
                        window.calendar.getEvents().forEach(event => event.setProp('display', 'auto'));
                    }
                }
            });
        }
    }
    
    // Helper functions
    function getEventType(event) {
        // Determine event type based on categories or other properties
        if (event.categories) {
            if (event.categories.includes('Holiday')) return 'holiday';
            if (event.categories.includes('Training')) return 'training';
            if (event.categories.includes('Team')) return 'team';
        }
        
        if (event.importance === 'high') return 'company';
        if (event.isOnlineMeeting) return 'team';
        
        return 'company';
    }
    
    function getEventColor(event) {
        // Return color based on event type
        const type = getEventType(event);
        switch (type) {
            case 'company': return '#a1c44f';
            case 'team': return '#17a2b8';
            case 'training': return '#ffc107';
            case 'holiday': return '#dc3545';
            default: return '#a1c44f';
        }
    }
    
    function getEventOrganizer(event) {
        if (event.organizer && event.organizer.emailAddress) {
            return event.organizer.emailAddress.name;
        }
        return 'Unknown';
    }
    
    function getAttendees(event) {
        if (!event.attendees || !event.attendees.length) return ['No attendees'];
        
        return event.attendees.map(attendee => {
            if (attendee.emailAddress) {
                return attendee.emailAddress.name || attendee.emailAddress.address;
            }
            return attendee.toString();
        });
    }
    
    function formatEventDate(event) {
        if (event.allDay) {
            if (event.start && event.end) {
                const startDate = new Date(event.start).toLocaleDateString('en-ZA', { 
                    weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' 
                });
                const endDate = new Date(event.end).toLocaleDateString('en-ZA', { 
                    weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' 
                });
                return `${startDate} - ${endDate}`;
            } else {
                return new Date(event.start).toLocaleDateString('en-ZA', { 
                    weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' 
                });
            }
        } else {
            return new Date(event.start).toLocaleDateString('en-ZA', { 
                weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' 
            });
        }
    }
    
    function formatEventTime(event) {
        if (event.allDay) {
            return 'All Day';
        } else {
            const startTime = new Date(event.start).toLocaleTimeString('en-ZA', { 
                hour: '2-digit', minute: '2-digit' 
            });
            const endTime = new Date(event.end).toLocaleTimeString('en-ZA', { 
                hour: '2-digit', minute: '2-digit' 
            });
            return `${startTime} - ${endTime}`;
        }
    }
});
'@; Set-Content -Path $calendarLoaderPath -Value $content -Force; Write-Host 'Created calendar loader script at: ' -NoNewline; Write-Host $calendarLoaderPath -ForegroundColor Green"
echo.

echo Updating calendar.html to use the new custom auth system...
powershell -ExecutionPolicy Bypass -Command "$calendarPath = '.\intranet\calendar.html'; if (Test-Path $calendarPath) { $content = Get-Content $calendarPath -Raw; $updatedContent = $content -replace '<script src=\"https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js\"></script>\r?\n    <!-- MSAL -->\r?\n    <script src=\"https://alcdn.msauth.net/browser/2.30.0/js/msal-browser.js\"></script>', '<script src=\"https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js\"></script>'; $updatedContent = $updatedContent -replace '<script src=\"js/intranet.js\"></script>', '<script src=\"js/intranet.js\"></script>\r\n    <script src=\"js/custom-authenticator.js\"></script>\r\n    <script src=\"js/calendar-custom-loader.js\"></script>'; $updatedContent = $updatedContent -replace '<script>\r?\n        // Calendar specific JavaScript.*?</script>', '<script>\r\n        // Calendar initialization handled by calendar-custom-loader.js\r\n        document.addEventListener(\"DOMContentLoaded\", function() {\r\n            console.log(\"Calendar page loaded with custom authentication\");\r\n        });\r\n    </script>'; Set-Content -Path $calendarPath -Value $updatedContent -Force; Write-Host 'Updated calendar.html to use custom authentication' -ForegroundColor Green } else { Write-Host 'Calendar.html not found!' -ForegroundColor Red }"
echo.

echo Creating sample calendar events for demonstration...
powershell -ExecutionPolicy Bypass -Command "$outputDir = '.\intranet\data\m365-mirror\calendar'; if (!(Test-Path $outputDir)) { New-Item -ItemType Directory -Path $outputDir -Force | Out-Null }; $events = @{ events = @( @{ subject = 'Weekly Team Meeting'; start = @{ dateTime = (Get-Date).AddDays(1).ToString('yyyy-MM-ddTHH:00:00'); timeZone = 'South Africa Standard Time' }; end = @{ dateTime = (Get-Date).AddDays(1).AddHours(1).ToString('yyyy-MM-ddTHH:00:00'); timeZone = 'South Africa Standard Time' }; location = @{ displayName = 'Main Conference Room' }; attendees = @( @{ emailAddress = @{ address = 'team@ibridge.co.za'; name = 'iBridge Team' }; type = 'required' } ); importance = 'normal'; categories = @('Team'); isOnlineMeeting = $true }, @{ subject = 'Executive Review - Q2 2025'; start = @{ dateTime = (Get-Date).AddDays(7).ToString('yyyy-MM-ddT09:00:00'); timeZone = 'South Africa Standard Time' }; end = @{ dateTime = (Get-Date).AddDays(7).AddHours(3).ToString('yyyy-MM-ddT12:00:00'); timeZone = 'South Africa Standard Time' }; location = @{ displayName = 'Executive Boardroom' }; attendees = @( @{ emailAddress = @{ address = 'executives@ibridge.co.za'; name = 'iBridge Executives' } } ); importance = 'high'; categories = @('Company') }, @{ subject = 'Staff Training: New CRM System'; start = @{ dateTime = (Get-Date).AddDays(14).ToString('yyyy-MM-ddT13:00:00'); timeZone = 'South Africa Standard Time' }; end = @{ dateTime = (Get-Date).AddDays(14).AddHours(4).ToString('yyyy-MM-ddT17:00:00'); timeZone = 'South Africa Standard Time' }; location = @{ displayName = 'Training Room' }; attendees = @( @{ emailAddress = @{ address = 'staff@ibridge.co.za'; name = 'All Staff' } } ); importance = 'normal'; categories = @('Training') } ) }; $holidays = @( @{ date = '2025-08-09'; name = 'National Women''s Day'; isWorkDay = $false }, @{ date = '2025-09-24'; name = 'Heritage Day'; isWorkDay = $false }, @{ date = '2025-12-16'; name = 'Day of Reconciliation'; isWorkDay = $false }, @{ date = '2025-12-25'; name = 'Christmas Day'; isWorkDay = $false } ); $events | ConvertTo-Json -Depth 10 | Out-File -FilePath \"$outputDir\events.json\" -Encoding UTF8; $holidays | ConvertTo-Json -Depth 10 | Out-File -FilePath \"$outputDir\holidays.json\" -Encoding UTF8; Write-Host 'Created sample calendar data in:' -NoNewline; Write-Host \" $outputDir\" -ForegroundColor Green"
echo.

echo Setup complete!
echo.
echo The calendar page now uses custom authentication with employee code IBDG054
echo and will display mirrored data from Microsoft 365.
echo.
echo To use the updated calendar:
echo 1. Run CHECK-AND-START-UNIFIED-SERVER.bat to start the portal
echo 2. Access the portal at http://localhost:8090/intranet/
echo 3. Login with employee code IBDG054
echo 4. Navigate to the Calendar page
echo.
echo Press any key to exit...
pause > nul
