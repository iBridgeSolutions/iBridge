<?php
/**
 * Event Retrieval Handler
 * Gets all calendar events from the user-events.json file
 * 
 * This file handles GET requests to retrieve saved calendar events
 */

header('Content-Type: application/json');

// Set proper headers to prevent caching
header("Cache-Control: no-store, no-cache, must-revalidate, max-age=0");
header("Cache-Control: post-check=0, pre-check=0", false);
header("Pragma: no-cache");

// Only allow GET requests for retrieving
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405); // Method Not Allowed
    echo json_encode(['status' => 'error', 'message' => 'Only GET requests are allowed']);
    exit;
}

try {
    // Path to the events JSON file
    $eventsFile = '../data/user-events.json';
    
    // Read events from the file
    if (file_exists($eventsFile)) {
        $fileContent = file_get_contents($eventsFile);
        if (!empty($fileContent)) {
            $events = json_decode($fileContent, true);
            
            // If the file is not valid JSON, return an empty array
            if ($events === null) {
                echo json_encode([]);
            } else {
                echo json_encode($events);
            }
        } else {
            echo json_encode([]);
        }
    } else {
        echo json_encode([]);
    }
} catch (Exception $e) {
    http_response_code(500); // Internal Server Error
    echo json_encode(['status' => 'error', 'message' => 'Server error: ' . $e->getMessage()]);
}
