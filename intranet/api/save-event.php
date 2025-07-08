<?php
/**
 * Event Storage Handler
 * Saves calendar events to a JSON file for persistence across browsers
 * 
 * This file handles POST requests to save new calendar events
 */

header('Content-Type: application/json');

// Set proper headers to prevent caching
header("Cache-Control: no-store, no-cache, must-revalidate, max-age=0");
header("Cache-Control: post-check=0, pre-check=0", false);
header("Pragma: no-cache");

// Only allow POST requests for saving
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405); // Method Not Allowed
    echo json_encode(['status' => 'error', 'message' => 'Only POST requests are allowed']);
    exit;
}

try {
    // Get the event data from the request body
    $requestBody = file_get_contents('php://input');
    $eventData = json_decode($requestBody, true);
    
    // Validate the event data
    if (!isset($eventData['title']) || !isset($eventData['startDateTime']) || !isset($eventData['endDateTime'])) {
        http_response_code(400); // Bad Request
        echo json_encode(['status' => 'error', 'message' => 'Invalid event data - missing required fields']);
        exit;
    }
    
    // Path to the events JSON file
    $eventsFile = '../data/user-events.json';
    
    // Read existing events
    $existingEvents = [];
    if (file_exists($eventsFile)) {
        $fileContent = file_get_contents($eventsFile);
        if (!empty($fileContent)) {
            $existingEvents = json_decode($fileContent, true);
        }
        
        // If the file is not valid JSON, initialize as empty array
        if ($existingEvents === null) {
            $existingEvents = [];
        }
    }
    
    // Generate a unique ID for the event
    $eventData['id'] = uniqid('evt_');
    $eventData['createdBy'] = isset($_POST['user']) ? $_POST['user'] : 'unknown';
    $eventData['createdAt'] = date('Y-m-d\TH:i:s');
    
    // Add the new event to the array
    $existingEvents[] = $eventData;
    
    // Save the updated events back to the file
    if (file_put_contents($eventsFile, json_encode($existingEvents, JSON_PRETTY_PRINT))) {
        // Return success response with the new event
        echo json_encode(['status' => 'success', 'message' => 'Event saved successfully', 'event' => $eventData]);
    } else {
        // Return error if saving failed
        http_response_code(500); // Internal Server Error
        echo json_encode(['status' => 'error', 'message' => 'Failed to save event to file']);
    }
} catch (Exception $e) {
    http_response_code(500); // Internal Server Error
    echo json_encode(['status' => 'error', 'message' => 'Server error: ' . $e->getMessage()]);
}
