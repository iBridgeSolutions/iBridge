# Unified Server Configuration for iBridge Website & Intranet

This document explains how the unified server approach works to serve both the main iBridge website and the intranet portal from a single server port.

## Benefits of the Unified Server Approach

1. **Simplified Configuration**: Only one server instance needed
2. **Consistent Navigation**: Easy navigation between main site and intranet
3. **Shared Resources**: CSS and other assets can be shared between sites
4. **Single Port**: No need to remember multiple port numbers
5. **Consistent URLs**: Predictable URL structure for both sites

## How It Works

The unified server serves files from the root directory of the project:

- Main website files are served from `/` (e.g., `http://localhost:8090/`)
- Intranet files are served from `/intranet/` (e.g., `http://localhost:8090/intranet/`)

This allows both sites to coexist on the same server instance while maintaining their separate content.

## Navigation Between Sites

For seamless navigation between the main website and intranet:

1. **From Main Website to Intranet**: Click the "Staff Portal" link in the navigation bar
2. **From Intranet to Main Website**: Click the "Main Site" link in the intranet navigation

## Starting the Unified Server

### Option 1: Using the Batch File (Recommended)

Double-click on `CHECK-AND-START-UNIFIED-SERVER.bat` to:
- Verify your configuration
- Check navigation links
- Start the unified server

### Option 2: Using PowerShell

Run the PowerShell script directly:

```powershell
./start-unified-server.ps1
```

## Troubleshooting

If you encounter issues with the unified server:

1. **Check port availability**: Make sure no other service is using port 8090
2. **Verify file paths**: Ensure all files are in their correct locations
3. **Check navigation links**: Make sure all navigation links use the correct paths
4. **Run the verification script**: Use `./verify-intranet-files.ps1` to check your setup

## For Developers

When adding new pages or features:

1. **Main website pages**: Add them to the root directory
2. **Intranet pages**: Add them to the `/intranet/` directory
3. **Shared resources**: Consider placing shared resources in a common location

Remember to test navigation between the main website and intranet to ensure a seamless user experience.
