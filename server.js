// Simple Node.js server for iBridge Website
const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 8090;

console.log(`Starting server on port ${PORT}`);
console.log(`Access the website at: http://localhost:${PORT}`);
console.log(`Access the intranet at: http://localhost:${PORT}/intranet/`);

// MIME types for different file extensions
const mimeTypes = {
    '.html': 'text/html',
    '.js': 'text/javascript',
    '.css': 'text/css',
    '.json': 'application/json',
    '.png': 'image/png',
    '.jpg': 'image/jpeg',
    '.gif': 'image/gif',
    '.svg': 'image/svg+xml',
    '.ico': 'image/x-icon',
};

// Create the server
const server = http.createServer((req, res) => {
    console.log(`Request received: ${req.url}`);
    
    // Handle root requests
    let filePath = '.' + req.url;
    if (filePath === './') {
        filePath = './index.html';
    }
    
    // Get the file extension
    const extname = path.extname(filePath);
    let contentType = mimeTypes[extname] || 'text/plain';
    
    // Read and serve the file
    fs.readFile(filePath, (err, content) => {
        if (err) {
            if (err.code === 'ENOENT') {
                // File not found
                console.log(`File not found: ${filePath}`);
                fs.readFile('./404.html', (err, content) => {
                    res.writeHead(404, { 'Content-Type': 'text/html' });
                    res.end(content, 'utf-8');
                });
            } else {
                // Server error
                console.error(`Server error: ${err.code}`);
                res.writeHead(500);
                res.end(`Server Error: ${err.code}`);
            }
        } else {
            // Success
            res.writeHead(200, { 'Content-Type': contentType });
            res.end(content, 'utf-8');
        }
    });
});

// Start listening on the specified port
server.listen(PORT, () => {
    console.log(`Server running at http://localhost:${PORT}/`);
});
