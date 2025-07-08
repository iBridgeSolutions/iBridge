# Enrich Employee Data for iBridge Intranet
# This script adds missing properties to employee records for consistency

# Set the working directory to the script location
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

Write-Host "Starting employee data enrichment for iBridge Intranet..." -ForegroundColor Cyan

# Define data file paths
$employeesFile = ".\intranet\data\employees.json"
$departmentsFile = ".\intranet\data\departments.json"

# Check if files exist
if (-not (Test-Path $employeesFile)) {
    Write-Host "Employees file not found: $employeesFile" -ForegroundColor Red
    Exit 1
}

if (-not (Test-Path $departmentsFile)) {
    Write-Host "Departments file not found: $departmentsFile" -ForegroundColor Red
    Exit 1
}

# Load employee and department data
try {
    $employees = Get-Content $employeesFile -Raw | ConvertFrom-Json
    $departments = Get-Content $departmentsFile -Raw | ConvertFrom-Json
    
    Write-Host "- Loaded $($employees.Count) employee records" -ForegroundColor Green
    Write-Host "- Loaded $($departments.Count) department records" -ForegroundColor Green
} catch {
    Write-Host "Error loading data: $_" -ForegroundColor Red
    Exit 1
}

# Create a backup of employees.json
$backupFile = ".\intranet\data\employees_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
try {
    Copy-Item -Path $employeesFile -Destination $backupFile -Force
    Write-Host "- Created backup at $backupFile" -ForegroundColor Green
} catch {
    Write-Host "Error creating backup: $_" -ForegroundColor Red
    Exit 1
}

# Get the reference employee (Lwandile) with all properties
$referenceEmployee = $employees | Where-Object { $_.id -eq "1" }
if (-not $referenceEmployee) {
    Write-Host "Reference employee (ID: 1) not found" -ForegroundColor Red
    Exit 1
}

# Get all property names from the reference employee
$allProperties = $referenceEmployee.PSObject.Properties.Name

# Initialize counter for enriched employees
$enrichedCount = 0

# Enrich employee records
foreach ($employee in $employees) {
    # Skip the reference employee
    if ($employee.id -eq "1") {
        continue
    }
    
    $needsEnrichment = $false
    
    # Check for missing properties
    foreach ($prop in $allProperties) {
        if (-not $employee.PSObject.Properties.Name.Contains($prop)) {
            $needsEnrichment = $true
            
            # Add the missing property with appropriate default value
            switch ($prop) {
                "roles" { 
                    $employee | Add-Member -MemberType NoteProperty -Name $prop -Value @("user") 
                }
                "socialMedia" { 
                    $employee | Add-Member -MemberType NoteProperty -Name $prop -Value @{
                        linkedin = ""
                        github = ""
                    }
                }
                "manager" {
                    # Try to find the manager based on department
                    $deptInfo = $departments | Where-Object { $_.name -eq $employee.department }
                    if ($deptInfo -and $deptInfo.headOfDepartment -and ($deptInfo.headOfDepartment.id -ne $employee.id)) {
                        $managerId = $deptInfo.headOfDepartment.id
                        $managerName = $deptInfo.headOfDepartment.displayName
                        $managerEmail = $deptInfo.headOfDepartment.email
                        
                        $employee | Add-Member -MemberType NoteProperty -Name $prop -Value @{
                            id = $managerId
                            displayName = $managerName
                            email = $managerEmail
                        }
                    } else {
                        # Default to Michael Thompson as manager if no department head is found
                        $employee | Add-Member -MemberType NoteProperty -Name $prop -Value @{
                            id = "4"
                            displayName = "Michael Thompson"
                            email = "michael.thompson@ibridge.co.za"
                        }
                    }
                }
                "bio" {
                    $employee | Add-Member -MemberType NoteProperty -Name $prop -Value "$($employee.displayName) works in the $($employee.department) department as a $($employee.jobTitle)."
                }
                "profilePhoto" { 
                    $employee | Add-Member -MemberType NoteProperty -Name $prop -Value $employee.photoUrl 
                }
                "hireDate" { 
                    # Generate a random hire date between 2018-2024
                    $year = Get-Random -Minimum 2018 -Maximum 2025
                    $month = Get-Random -Minimum 1 -Maximum 13
                    $day = Get-Random -Minimum 1 -Maximum 29
                    $hireDate = "$year-$('{0:D2}' -f $month)-$('{0:D2}' -f $day)"
                    $employee | Add-Member -MemberType NoteProperty -Name $prop -Value $hireDate
                }
                "skills" { 
                    # Generate skills based on job title
                    $jobSpecificSkills = @()
                    switch -Wildcard ($employee.jobTitle) {
                        "*Manager*" { $jobSpecificSkills = @("Leadership", "Project Management", "Communication", "Strategy") }
                        "*Developer*" { $jobSpecificSkills = @("Programming", "Problem Solving", "API Design", "Software Development") }
                        "*Support*" { $jobSpecificSkills = @("Customer Service", "Technical Support", "Troubleshooting", "Documentation") }
                        "*Analyst*" { $jobSpecificSkills = @("Data Analysis", "Research", "Reporting", "Business Intelligence") }
                        "*Marketing*" { $jobSpecificSkills = @("Digital Marketing", "Content Creation", "Social Media", "Brand Management") }
                        "*HR*" { $jobSpecificSkills = @("Recruitment", "Employee Relations", "Training", "Compliance") }
                        "*Sales*" { $jobSpecificSkills = @("Negotiation", "Client Relations", "Lead Generation", "Sales Strategy") }
                        "*Call Center*" { $jobSpecificSkills = @("Customer Service", "Call Handling", "Problem Resolution", "Communication") }
                        default { $jobSpecificSkills = @("Communication", "Time Management", "Problem Solving", "Teamwork") }
                    }
                    $employee | Add-Member -MemberType NoteProperty -Name $prop -Value $jobSpecificSkills
                }
                "languages" { 
                    # Randomly assign languages
                    $langOptions = @("English", "Afrikaans", "Zulu", "Xhosa", "Sotho", "Tswana")
                    $langCount = Get-Random -Minimum 1 -Maximum 3
                    $langs = @("English")
                    
                    if ($langCount -gt 1) {
                        $otherLangs = $langOptions | Where-Object { $_ -ne "English" } | Get-Random -Count ($langCount - 1)
                        $langs += $otherLangs
                    }
                    
                    $employee | Add-Member -MemberType NoteProperty -Name $prop -Value $langs
                }
                default { 
                    # For any other properties, just copy the value from the reference employee
                    if ($prop -notin @("id", "displayName", "firstName", "lastName", "email", "jobTitle", "department")) {
                        $employee | Add-Member -MemberType NoteProperty -Name $prop -Value $referenceEmployee.$prop
                    }
                }
            }
        }
    }
    
    # Update the lastUpdated field to today
    $employee.lastUpdated = (Get-Date -Format "yyyy-MM-dd")
    
    if ($needsEnrichment) {
        $enrichedCount++
    }
}

# Save the updated employees data
try {
    $employees | ConvertTo-Json -Depth 10 | Out-File -FilePath $employeesFile -Encoding utf8
    Write-Host "- Enriched $enrichedCount employee records" -ForegroundColor Green
    Write-Host "- Updated employee data saved to $employeesFile" -ForegroundColor Green
} catch {
    Write-Host "Error saving updated employee data: $_" -ForegroundColor Red
    Write-Host "The original file is backed up at $backupFile" -ForegroundColor Yellow
    Exit 1
}

Write-Host "`nEmployee data enrichment complete!" -ForegroundColor Cyan
Write-Host "All employee records now have a consistent property structure." -ForegroundColor Cyan
