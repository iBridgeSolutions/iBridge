# Website Preview and Launch Script

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "   WEBSITE PREVIEW AND LAUNCH UTILITY" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host

function Start-WebsitePreview {
    Write-Host "Starting local web server for website preview..." -ForegroundColor Yellow
    
    $job = Start-Job -ScriptBlock {
        param($workingDir)
        
        Set-Location $workingDir
        
        try {
            $listener = New-Object System.Net.HttpListener
            $listener.Prefixes.Add("http://localhost:8000/")
            $listener.Start()
            
            Write-Output "Server started successfully"
            
            while ($listener.IsListening) {
                $context = $listener.GetContext()
                $request = $context.Request
                $response = $context.Response
                
                $localPath = Join-Path $workingDir $request.Url.LocalPath.TrimStart('/')
                
                if ([string]::IsNullOrEmpty($request.Url.LocalPath) -or $request.Url.LocalPath -eq "/") {
                    $localPath = Join-Path $workingDir "index.html"
                }
                
                Write-Output "Request: $($request.Url.LocalPath)"
                
                if (Test-Path $localPath -PathType Leaf) {
                    $content = [System.IO.File]::ReadAllBytes($localPath)
                    
                    $response.ContentType = switch ([System.IO.Path]::GetExtension($localPath).ToLower()) {
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
        catch {
            Write-Output "Server error: $_"
        }
        finally {
            if ($listener -ne $null) {
                $listener.Stop()
            }
        }
    } -ArgumentList (Get-Location)

    # Wait for server to start
    Start-Sleep -Seconds 2
    
    $status = Receive-Job -Job $job -Keep
    if ($status -contains "Server started successfully") {
        Write-Host "Server is running!" -ForegroundColor Green
        Write-Host "`nPreview your website at:" -ForegroundColor Cyan
        Write-Host "  Main pages:" -ForegroundColor White
        Write-Host "  - http://localhost:8000/index.html (Home)" -ForegroundColor Yellow
        Write-Host "  - http://localhost:8000/about.html (About Us)" -ForegroundColor Yellow
        Write-Host "  - http://localhost:8000/services.html (Services)" -ForegroundColor Yellow
        Write-Host "  - http://localhost:8000/contact.html (Contact)" -ForegroundColor Yellow
        Write-Host "`n  Service pages:" -ForegroundColor White
        Write-Host "  - http://localhost:8000/contact-center.html (Contact Center Solutions)" -ForegroundColor Yellow
        Write-Host "  - http://localhost:8000/it-support.html (IT Support)" -ForegroundColor Yellow
        Write-Host "  - http://localhost:8000/ai-automation.html (AI & Automation)" -ForegroundColor Yellow
        
        # Launch browser automatically
        Start-Process "http://localhost:8000/index.html"
        Start-Sleep -Seconds 2
        Start-Process "http://localhost:8000/contact-center.html"
        
        Write-Host "`nPress Ctrl+C to stop the server when done" -ForegroundColor Magenta
        
        try {
            while ($true) {
                Start-Sleep -Seconds 1
                $status = Receive-Job -Job $job -Keep
                if ($status -contains "Server error") {
                    Write-Host "Server encountered an error. Stopping preview." -ForegroundColor Red
                    break
                }
            }
        }
        finally {
            Stop-Job -Job $job
            Remove-Job -Job $job
        }
    }
    else {
        Write-Host "Failed to start server. Make sure port 8000 is available." -ForegroundColor Red
        Stop-Job -Job $job
        Remove-Job -Job $job
    }
}

# Execute the function
Start-WebsitePreview
