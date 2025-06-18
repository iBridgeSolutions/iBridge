# Simple HTTP server to preview website
Write-Host "Starting website preview server..." -ForegroundColor Cyan
Write-Host "Press Ctrl+C to stop the server when done" -ForegroundColor Yellow

$http = [System.Net.HttpListener]::new()
$http.Prefixes.Add("http://localhost:8000/")
$http.Start()

if ($http.IsListening) {
    Write-Host "Server is running!" -ForegroundColor Green
    Write-Host "Open your browser and navigate to: http://localhost:8000/index.html" -ForegroundColor Green
    Write-Host "You can also view other pages like:" -ForegroundColor Green
    Write-Host "  - http://localhost:8000/contact-center.html" -ForegroundColor Green
    Write-Host "  - http://localhost:8000/it-support.html" -ForegroundColor Green
    Write-Host "  - http://localhost:8000/ai-automation.html" -ForegroundColor Green
    Write-Host "  - http://localhost:8000/services.html" -ForegroundColor Green
    
    # Launch browser automatically
    Start-Process "http://localhost:8000/index.html"

    try {
        while ($http.IsListening) {
            $context = $http.GetContext()
            $request = $context.Request
            $response = $context.Response
            
            $localPath = Join-Path $PSScriptRoot $request.Url.LocalPath.TrimStart('/')
            
            if ([string]::IsNullOrEmpty($request.Url.LocalPath) -or $request.Url.LocalPath -eq "/") {
                $localPath = Join-Path $PSScriptRoot "index.html"
            }
            
            Write-Host "Request: $($request.Url.LocalPath)" -ForegroundColor Cyan
            
            if (Test-Path $localPath -PathType Leaf) {
                $content = Get-Content $localPath -Raw -Encoding Byte
                $response.ContentType = switch ([System.IO.Path]::GetExtension($localPath)) {
                    ".html" { "text/html" }
                    ".css"  { "text/css" }
                    ".js"   { "application/javascript" }
                    ".png"  { "image/png" }
                    ".jpg"  { "image/jpeg" }
                    ".jpeg" { "image/jpeg" }
                    ".gif"  { "image/gif" }
                    default { "application/octet-stream" }
                }
                
                $response.ContentLength64 = $content.Length
                $response.OutputStream.Write($content, 0, $content.Length)
            }
            else {
                $response.StatusCode = 404
                $notFoundHtml = "<html><body><h1>404 - File Not Found</h1><p>The requested file was not found: $($request.Url.LocalPath)</p></body></html>"
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($notFoundHtml)
                $response.ContentType = "text/html"
                $response.ContentLength64 = $buffer.Length
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
            }
            
            $response.Close()
        }
    }
    finally {
        $http.Stop()
    }
}
else {
    Write-Host "Failed to start server. Make sure port 8000 is available." -ForegroundColor Red
}
