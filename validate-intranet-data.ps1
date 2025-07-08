# Validate Intranet Data Files
# This script checks all data files to ensure they have consistent properties and structure

# Import required modules
using namespace System.Collections.Generic

# Set the working directory to the script location
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

Write-Host "Starting data validation for iBridge Intranet..." -ForegroundColor Cyan

# Define data file paths
$employeesFile = ".\intranet\data\employees.json"
$departmentsFile = ".\intranet\data\departments.json"
$organizationFile = ".\intranet\data\organization.json"
$settingsFile = ".\intranet\data\settings.json"

# Check if files exist
$files = @(
    $employeesFile,
    $departmentsFile,
    $organizationFile,
    $settingsFile
)

$allFilesExist = $true
foreach ($file in $files) {
    if (-not (Test-Path $file)) {
        Write-Host "Missing file: $file" -ForegroundColor Red
        $allFilesExist = $false
    }
}

if (-not $allFilesExist) {
    Write-Host "One or more required data files are missing. Please fix before continuing." -ForegroundColor Red
    Exit 1
}

# Load and validate employees.json
Write-Host "`nValidating employees.json..." -ForegroundColor Yellow
try {
    $employees = Get-Content $employeesFile -Raw | ConvertFrom-Json
    Write-Host "- Found $($employees.Count) employee records" -ForegroundColor Green
    
    # Check for required properties in each employee
    $requiredEmployeeProps = @("id", "displayName", "email", "department")
    $employeeIssues = [List[string]]::new()
    
    foreach ($emp in $employees) {
        foreach ($prop in $requiredEmployeeProps) {
            if (-not $emp.PSObject.Properties.Name.Contains($prop)) {
                $employeeIssues.Add("Employee with ID $($emp.id) is missing required property: $prop")
            }
        }
    }
    
    if ($employeeIssues.Count -gt 0) {
        Write-Host "- Found $($employeeIssues.Count) issues in employee records:" -ForegroundColor Yellow
        foreach ($issue in $employeeIssues) {
            Write-Host "  - $issue" -ForegroundColor Yellow
        }
    } else {
        Write-Host "- All employee records have the required properties" -ForegroundColor Green
    }
    
    # Check for consistent properties
    $employeeProps = $employees[0].PSObject.Properties.Name
    $inconsistentEmployees = [List[string]]::new()
    
    foreach ($emp in $employees) {
        $currentProps = $emp.PSObject.Properties.Name
        $missingProps = $employeeProps | Where-Object { $currentProps -notcontains $_ }
        if ($missingProps.Count -gt 0) {
            $inconsistentEmployees.Add("Employee $($emp.displayName) (ID: $($emp.id)) is missing properties: $($missingProps -join ', ')")
        }
    }
    
    if ($inconsistentEmployees.Count -gt 0) {
        Write-Host "- Found inconsistent property structure in employee records:" -ForegroundColor Yellow
        foreach ($issue in $inconsistentEmployees) {
            Write-Host "  - $issue" -ForegroundColor Yellow
        }
    } else {
        Write-Host "- All employee records have a consistent property structure" -ForegroundColor Green
    }
} catch {
    Write-Host "Error processing employees.json: $_" -ForegroundColor Red
}

# Load and validate departments.json
Write-Host "`nValidating departments.json..." -ForegroundColor Yellow
try {
    $departments = Get-Content $departmentsFile -Raw | ConvertFrom-Json
    Write-Host "- Found $($departments.Count) department records" -ForegroundColor Green
    
    # Check for required properties in each department
    $requiredDeptProps = @("id", "name", "count", "members", "description", "headOfDepartment")
    $deptIssues = [List[string]]::new()
    
    foreach ($dept in $departments) {
        foreach ($prop in $requiredDeptProps) {
            if (-not $dept.PSObject.Properties.Name.Contains($prop)) {
                $deptIssues.Add("Department $($dept.name) (ID: $($dept.id)) is missing required property: $prop")
            }
        }
    }
    
    if ($deptIssues.Count -gt 0) {
        Write-Host "- Found $($deptIssues.Count) issues in department records:" -ForegroundColor Yellow
        foreach ($issue in $deptIssues) {
            Write-Host "  - $issue" -ForegroundColor Yellow
        }
    } else {
        Write-Host "- All department records have the required properties" -ForegroundColor Green
    }
    
    # Check for consistent properties
    $deptProps = $departments[0].PSObject.Properties.Name
    $inconsistentDepts = [List[string]]::new()
    
    foreach ($dept in $departments) {
        $currentProps = $dept.PSObject.Properties.Name
        $missingProps = $deptProps | Where-Object { $currentProps -notcontains $_ }
        if ($missingProps.Count -gt 0) {
            $inconsistentDepts.Add("Department $($dept.name) (ID: $($dept.id)) is missing properties: $($missingProps -join ', ')")
        }
    }
    
    if ($inconsistentDepts.Count -gt 0) {
        Write-Host "- Found inconsistent property structure in department records:" -ForegroundColor Yellow
        foreach ($issue in $inconsistentDepts) {
            Write-Host "  - $issue" -ForegroundColor Yellow
        }
    } else {
        Write-Host "- All department records have a consistent property structure" -ForegroundColor Green
    }
} catch {
    Write-Host "Error processing departments.json: $_" -ForegroundColor Red
}

# Load and validate organization.json
Write-Host "`nValidating organization.json..." -ForegroundColor Yellow
try {
    $organization = Get-Content $organizationFile -Raw | ConvertFrom-Json
    
    # Check for required properties
    $requiredOrgProps = @("displayName", "city", "country", "phoneNumber", "verifiedDomains")
    $orgIssues = [List[string]]::new()
    
    foreach ($prop in $requiredOrgProps) {
        if (-not $organization.PSObject.Properties.Name.Contains($prop)) {
            $orgIssues.Add("Organization data is missing required property: $prop")
        }
    }
    
    if ($orgIssues.Count -gt 0) {
        Write-Host "- Found $($orgIssues.Count) issues in organization data:" -ForegroundColor Yellow
        foreach ($issue in $orgIssues) {
            Write-Host "  - $issue" -ForegroundColor Yellow
        }
    } else {
        Write-Host "- Organization data has all required properties" -ForegroundColor Green
    }
} catch {
    Write-Host "Error processing organization.json: $_" -ForegroundColor Red
}

# Load and validate settings.json
Write-Host "`nValidating settings.json..." -ForegroundColor Yellow
try {
    $settings = Get-Content $settingsFile -Raw | ConvertFrom-Json
    
    # Check for required properties
    $requiredSettingsProps = @("companyName", "adminUsers", "devMode", "useM365Data", "microsoftConfig")
    $settingsIssues = [List[string]]::new()
    
    foreach ($prop in $requiredSettingsProps) {
        if (-not $settings.PSObject.Properties.Name.Contains($prop)) {
            $settingsIssues.Add("Settings data is missing required property: $prop")
        }
    }
    
    if ($settingsIssues.Count -gt 0) {
        Write-Host "- Found $($settingsIssues.Count) issues in settings data:" -ForegroundColor Yellow
        foreach ($issue in $settingsIssues) {
            Write-Host "  - $issue" -ForegroundColor Yellow
        }
    } else {
        Write-Host "- Settings data has all required properties" -ForegroundColor Green
    }
    
    # Check M365 integration settings
    if ($settings.useM365Data -eq $true) {
        if ($settings.devMode -eq $true) {
            Write-Host "- Dev mode is active with M365 integration enabled (using simulated data)" -ForegroundColor Green
        } else {
            # Check microsoft config
            $msConfig = $settings.microsoftConfig
            if (-not ($msConfig.clientId -and $msConfig.tenantId -and $msConfig.redirectUri)) {
                Write-Host "- Microsoft 365 integration is enabled but configuration is incomplete" -ForegroundColor Yellow
            } else {
                Write-Host "- Microsoft 365 integration is properly configured" -ForegroundColor Green
            }
        }
    } else {
        Write-Host "- Microsoft 365 integration is disabled in settings" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Error processing settings.json: $_" -ForegroundColor Red
}

# Cross-reference check between employees and departments
Write-Host "`nPerforming cross-reference checks..." -ForegroundColor Yellow
try {
    $employeeDepts = $employees | ForEach-Object { $_.department } | Sort-Object -Unique
    $deptNames = $departments | ForEach-Object { $_.name } | Sort-Object -Unique
    
    $missingDepts = $employeeDepts | Where-Object { $deptNames -notcontains $_ }
    if ($missingDepts.Count -gt 0) {
        Write-Host "- Found $($missingDepts.Count) departments in employee records that don't exist in department data:" -ForegroundColor Yellow
        foreach ($dept in $missingDepts) {
            Write-Host "  - $dept" -ForegroundColor Yellow
        }
    } else {
        Write-Host "- All employee departments exist in the department data" -ForegroundColor Green
    }
    
    # Check if member count matches actual members in departments
    foreach ($dept in $departments) {
        $actualCount = $dept.members.Count
        if ($dept.count -ne $actualCount) {
            Write-Host "- Department $($dept.name) has a count of $($dept.count) but actually has $actualCount members" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "Error performing cross-reference checks: $_" -ForegroundColor Red
}

Write-Host "`nData validation complete." -ForegroundColor Cyan
Write-Host "If any issues were found, please update the corresponding data files to ensure consistency." -ForegroundColor Cyan
