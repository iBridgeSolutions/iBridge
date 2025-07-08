# Generate Employee Codes with IBD[Last Name Initials][Unique ID] Format
# This script creates employee codes and updates the employee-codes.json file

# Configuration
$outputFile = ".\intranet\data\employee-codes.json"
$defaultPassword = "iBridge2025" # This would be hashed in a real system

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "    EMPLOYEE CODE GENERATOR (IBD[Last Name Initials][Unique ID])" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host ""

# Function to generate employee code
function Generate-EmployeeCode {
    param (
        [string]$firstName,
        [string]$lastName,
        [array]$existingCodes
    )
    
    # Get last name initials (up to 3 characters)
    $lastNameInitials = $lastName.Substring(0, [Math]::Min($lastName.Length, 3)).ToUpper()
    
    # Find highest existing ID with same initials
    $highestId = 0
    $codePrefix = "IBD$lastNameInitials"
    
    foreach ($mapping in $existingCodes) {
        if ($mapping.employeeCode -match "$codePrefix(\d+)") {
            $idPart = $Matches[1]
            $idNumber = [int]$idPart
            if ($idNumber -gt $highestId) {
                $highestId = $idNumber
            }
        }
    }
    
    # Generate new ID (increment highest existing ID)
    $newId = $highestId + 1
    
    # Format with leading zeros based on number of digits
    $idPart = $newId.ToString()
    if ($newId -lt 10) {
        $idPart = "0$newId"
    }
    
    return "$codePrefix$idPart"
}

# Load existing employee codes
try {
    if (Test-Path $outputFile) {
        $employeeCodes = Get-Content -Path $outputFile -Raw | ConvertFrom-Json
        $existingMappings = $employeeCodes.mappings
    } else {
        $existingMappings = @()
        $employeeCodes = @{
            mappings = $existingMappings
            format = "IBD[Last Name Initials][Unique ID]"
            lastUpdated = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        }
    }
} catch {
    Write-Host "Error loading existing employee codes: $_" -ForegroundColor Red
    $existingMappings = @()
    $employeeCodes = @{
        mappings = $existingMappings
        format = "IBD[Last Name Initials][Unique ID]"
        lastUpdated = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    }
}

# Function to add a new employee
function Add-NewEmployee {
    # Get user input
    Write-Host "`nEnter employee details:" -ForegroundColor Yellow
    $firstName = Read-Host "First Name"
    $lastName = Read-Host "Last Name"
    $email = Read-Host "Email Address"
    $department = Read-Host "Department"
    $position = Read-Host "Position"
    $isAdmin = (Read-Host "Is Admin? (y/n)").ToLower() -eq "y"
    $isEditor = (Read-Host "Is Editor? (y/n)").ToLower() -eq "y"
    
    # Generate employee code
    $employeeCode = Generate-EmployeeCode -firstName $firstName -lastName $lastName -existingCodes $existingMappings
    
    # Create new employee object
    $newEmployee = @{
        userPrincipalName = $email
        employeeCode = $employeeCode
        firstName = $firstName
        lastName = $lastName
        department = $department
        position = $position
        permissions = @{
            isAdmin = $isAdmin
            isEditor = $isEditor
            canViewAdminPanel = $isAdmin
            canManageUsers = $isAdmin
        }
    }
    
    # Add to mappings
    $existingMappings += $newEmployee
    
    # Update lastUpdated timestamp
    $employeeCodes.lastUpdated = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    
    # Save to file
    $employeeCodes.mappings = $existingMappings
    $employeeCodes | ConvertTo-Json -Depth 4 | Out-File -FilePath $outputFile -Encoding UTF8
    
    Write-Host "`nEmployee added successfully:" -ForegroundColor Green
    Write-Host "  Name: $firstName $lastName" -ForegroundColor White
    Write-Host "  Email: $email" -ForegroundColor White
    Write-Host "  Employee Code: $employeeCode" -ForegroundColor White
    Write-Host "  Role: $(if ($isAdmin) { 'Administrator' } else { if ($isEditor) { 'Editor' } else { 'Standard User' } })" -ForegroundColor White
}

# Function to display all employees
function Show-AllEmployees {
    Write-Host "`nCurrent Employee Codes:" -ForegroundColor Yellow
    
    if ($existingMappings.Count -eq 0) {
        Write-Host "  No employees found." -ForegroundColor Red
        return
    }
    
    Write-Host "  ----------------------------------------------------------------------"
    Write-Host "  | Employee Code | Name                 | Email                       |"
    Write-Host "  ----------------------------------------------------------------------"
    
    foreach ($employee in $existingMappings) {
        $name = "$($employee.firstName) $($employee.lastName)"
        $padding1 = " " * (12 - $employee.employeeCode.Length)
        $padding2 = " " * (20 - $name.Length)
        $email = $employee.userPrincipalName
        
        Write-Host "  | $($employee.employeeCode)$padding1 | $name$padding2 | $email |"
    }
    
    Write-Host "  ----------------------------------------------------------------------"
    Write-Host "  Total: $($existingMappings.Count) employees" -ForegroundColor Green
}

# Function to update an employee
function Update-Employee {
    Show-AllEmployees
    
    Write-Host "`nEnter the employee code to update:" -ForegroundColor Yellow
    $codeToUpdate = Read-Host "Employee Code"
    
    $employeeToUpdate = $existingMappings | Where-Object { $_.employeeCode -eq $codeToUpdate }
    
    if ($null -eq $employeeToUpdate) {
        Write-Host "Employee code not found." -ForegroundColor Red
        return
    }
    
    Write-Host "`nUpdating employee: $($employeeToUpdate.firstName) $($employeeToUpdate.lastName)" -ForegroundColor Yellow
    Write-Host "Leave fields blank to keep current values." -ForegroundColor Gray
    
    $firstName = Read-Host "First Name [$($employeeToUpdate.firstName)]"
    if ([string]::IsNullOrEmpty($firstName)) {
        $firstName = $employeeToUpdate.firstName
    }
    
    $lastName = Read-Host "Last Name [$($employeeToUpdate.lastName)]"
    if ([string]::IsNullOrEmpty($lastName)) {
        $lastName = $employeeToUpdate.lastName
    }
    
    $email = Read-Host "Email [$($employeeToUpdate.userPrincipalName)]"
    if ([string]::IsNullOrEmpty($email)) {
        $email = $employeeToUpdate.userPrincipalName
    }
    
    $department = Read-Host "Department [$($employeeToUpdate.department)]"
    if ([string]::IsNullOrEmpty($department)) {
        $department = $employeeToUpdate.department
    }
    
    $position = Read-Host "Position [$($employeeToUpdate.position)]"
    if ([string]::IsNullOrEmpty($position)) {
        $position = $employeeToUpdate.position
    }
    
    $currentIsAdmin = $employeeToUpdate.permissions.isAdmin
    $adminPrompt = "Is Admin? (y/n) [$(if ($currentIsAdmin) { "y" } else { "n" })]"
    $adminResponse = Read-Host $adminPrompt
    
    if ([string]::IsNullOrEmpty($adminResponse)) {
        $isAdmin = $currentIsAdmin
    } else {
        $isAdmin = $adminResponse.ToLower() -eq "y"
    }
    
    $currentIsEditor = $employeeToUpdate.permissions.isEditor
    $editorPrompt = "Is Editor? (y/n) [$(if ($currentIsEditor) { "y" } else { "n" })]"
    $editorResponse = Read-Host $editorPrompt
    
    if ([string]::IsNullOrEmpty($editorResponse)) {
        $isEditor = $currentIsEditor
    } else {
        $isEditor = $editorResponse.ToLower() -eq "y"
    }
    
    # Update employee
    $employeeToUpdate.firstName = $firstName
    $employeeToUpdate.lastName = $lastName
    $employeeToUpdate.userPrincipalName = $email
    $employeeToUpdate.department = $department
    $employeeToUpdate.position = $position
    $employeeToUpdate.permissions.isAdmin = $isAdmin
    $employeeToUpdate.permissions.isEditor = $isEditor
    $employeeToUpdate.permissions.canViewAdminPanel = $isAdmin
    $employeeToUpdate.permissions.canManageUsers = $isAdmin
    
    # Update lastUpdated timestamp
    $employeeCodes.lastUpdated = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    
    # Save to file
    $employeeCodes | ConvertTo-Json -Depth 4 | Out-File -FilePath $outputFile -Encoding UTF8
    
    Write-Host "`nEmployee updated successfully!" -ForegroundColor Green
}

# Function to delete an employee
function Remove-Employee {
    Show-AllEmployees
    
    Write-Host "`nEnter the employee code to delete:" -ForegroundColor Yellow
    $codeToDelete = Read-Host "Employee Code"
    
    $employeeToDelete = $existingMappings | Where-Object { $_.employeeCode -eq $codeToDelete }
    
    if ($null -eq $employeeToDelete) {
        Write-Host "Employee code not found." -ForegroundColor Red
        return
    }
    
    Write-Host "`nYou are about to delete the following employee:" -ForegroundColor Yellow
    Write-Host "  Name: $($employeeToDelete.firstName) $($employeeToDelete.lastName)" -ForegroundColor White
    Write-Host "  Email: $($employeeToDelete.userPrincipalName)" -ForegroundColor White
    Write-Host "  Employee Code: $($employeeToDelete.employeeCode)" -ForegroundColor White
    
    $confirmation = Read-Host "Are you sure? (y/n)"
    
    if ($confirmation.ToLower() -ne "y") {
        Write-Host "Deletion cancelled." -ForegroundColor Yellow
        return
    }
    
    # Remove employee
    $updatedMappings = $existingMappings | Where-Object { $_.employeeCode -ne $codeToDelete }
    
    # Update lastUpdated timestamp
    $employeeCodes.lastUpdated = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    
    # Save to file
    $employeeCodes.mappings = $updatedMappings
    $employeeCodes | ConvertTo-Json -Depth 4 | Out-File -FilePath $outputFile -Encoding UTF8
    
    Write-Host "`nEmployee deleted successfully!" -ForegroundColor Green
}

# Function to update access control
function Update-AccessControl {
    $accessControlFile = ".\intranet\data\access-control.json"
    
    try {
        $accessControl = Get-Content -Path $accessControlFile -Raw | ConvertFrom-Json
    } catch {
        Write-Host "Error loading access control file: $_" -ForegroundColor Red
        $accessControl = @{
            restrictedAccess = $true
            accessPolicy = "exclusive"
            lastUpdated = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            allowedUsers = @()
            allowedEmployeeCodes = @()
        }
    }
    
    Write-Host "`nCurrent Access Control Settings:" -ForegroundColor Yellow
    Write-Host "  Restricted Access: $($accessControl.restrictedAccess)" -ForegroundColor White
    Write-Host "  Access Policy: $($accessControl.accessPolicy)" -ForegroundColor White
    Write-Host "  Allowed Users: $($accessControl.allowedUsers -join ', ')" -ForegroundColor White
    Write-Host "  Allowed Employee Codes: $($accessControl.allowedEmployeeCodes -join ', ')" -ForegroundColor White
    
    Write-Host "`nUpdate Access Control:" -ForegroundColor Yellow
    $restrictResponse = Read-Host "Restricted Access? (y/n) [$(if ($accessControl.restrictedAccess) { 'y' } else { 'n' })]"
    if (![string]::IsNullOrEmpty($restrictResponse)) {
        $accessControl.restrictedAccess = $restrictResponse.ToLower() -eq "y"
    }
    
    if ($accessControl.restrictedAccess) {
        Write-Host "`nManage Allowed Users:" -ForegroundColor Yellow
        Write-Host "  1. Add a user to allowed list" -ForegroundColor White
        Write-Host "  2. Remove a user from allowed list" -ForegroundColor White
        Write-Host "  3. Skip this section" -ForegroundColor White
        $userOption = Read-Host "Select an option"
        
        if ($userOption -eq "1") {
            Show-AllEmployees
            $userToAdd = Read-Host "`nEnter email address to add to allowed list"
            if (![string]::IsNullOrEmpty($userToAdd) -and !$accessControl.allowedUsers.Contains($userToAdd)) {
                $accessControl.allowedUsers += $userToAdd
            }
        } elseif ($userOption -eq "2") {
            Write-Host "`nCurrent allowed users:" -ForegroundColor Yellow
            for ($i = 0; $i -lt $accessControl.allowedUsers.Count; $i++) {
                Write-Host "  $($i+1). $($accessControl.allowedUsers[$i])" -ForegroundColor White
            }
            $indexToRemove = [int](Read-Host "`nEnter number of user to remove") - 1
            if ($indexToRemove -ge 0 -and $indexToRemove -lt $accessControl.allowedUsers.Count) {
                $accessControl.allowedUsers = $accessControl.allowedUsers | Where-Object { $_ -ne $accessControl.allowedUsers[$indexToRemove] }
            }
        }
        
        Write-Host "`nManage Allowed Employee Codes:" -ForegroundColor Yellow
        Write-Host "  1. Add an employee code to allowed list" -ForegroundColor White
        Write-Host "  2. Remove an employee code from allowed list" -ForegroundColor White
        Write-Host "  3. Skip this section" -ForegroundColor White
        $codeOption = Read-Host "Select an option"
        
        if ($codeOption -eq "1") {
            Show-AllEmployees
            $codeToAdd = Read-Host "`nEnter employee code to add to allowed list"
            if (![string]::IsNullOrEmpty($codeToAdd) -and !$accessControl.allowedEmployeeCodes.Contains($codeToAdd)) {
                $accessControl.allowedEmployeeCodes += $codeToAdd
            }
        } elseif ($codeOption -eq "2") {
            Write-Host "`nCurrent allowed employee codes:" -ForegroundColor Yellow
            for ($i = 0; $i -lt $accessControl.allowedEmployeeCodes.Count; $i++) {
                Write-Host "  $($i+1). $($accessControl.allowedEmployeeCodes[$i])" -ForegroundColor White
            }
            $indexToRemove = [int](Read-Host "`nEnter number of employee code to remove") - 1
            if ($indexToRemove -ge 0 -and $indexToRemove -lt $accessControl.allowedEmployeeCodes.Count) {
                $accessControl.allowedEmployeeCodes = $accessControl.allowedEmployeeCodes | Where-Object { $_ -ne $accessControl.allowedEmployeeCodes[$indexToRemove] }
            }
        }
    }
    
    # Update lastUpdated timestamp
    $accessControl.lastUpdated = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    
    # Save to file
    $accessControl | ConvertTo-Json -Depth 4 | Out-File -FilePath $accessControlFile -Encoding UTF8
    
    Write-Host "`nAccess control updated successfully!" -ForegroundColor Green
}

# Main menu
function Show-Menu {
    Write-Host "`n========= EMPLOYEE CODE MANAGEMENT =========" -ForegroundColor Cyan
    Write-Host "1. Add New Employee" -ForegroundColor White
    Write-Host "2. Show All Employees" -ForegroundColor White
    Write-Host "3. Update Employee" -ForegroundColor White
    Write-Host "4. Delete Employee" -ForegroundColor White
    Write-Host "5. Update Access Control" -ForegroundColor White
    Write-Host "6. Exit" -ForegroundColor White
    Write-Host "===========================================" -ForegroundColor Cyan
    
    $option = Read-Host "Select an option"
    return $option
}

# Main program loop
$exit = $false
while (-not $exit) {
    $option = Show-Menu
    
    switch ($option) {
        "1" { Add-NewEmployee }
        "2" { Show-AllEmployees }
        "3" { Update-Employee }
        "4" { Remove-Employee }
        "5" { Update-AccessControl }
        "6" { $exit = $true }
        default { Write-Host "`nInvalid option. Please try again." -ForegroundColor Red }
    }
    
    if (-not $exit) {
        Write-Host "`nPress Enter to continue..."
        Read-Host | Out-Null
    }
}

Write-Host "`nEmployee code management completed." -ForegroundColor Green
