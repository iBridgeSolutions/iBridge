/**
 * Password Migration Utility
 * This script converts plaintext passwords to secure hashed versions
 * Run this in the browser console while logged in as admin to update employee codes
 */

class PasswordMigration {
    constructor() {
        this.employeeCodesPath = '/intranet/data/employee-codes.json';
        this.employeeCodes = null;
    }
    
    /**
     * Start the migration process
     */
    async start() {
        try {
            console.log('Starting password migration...');
            await this.loadEmployeeCodes();
            await this.migratePasswords();
            console.log('Password migration completed. Please save the updated employee codes.');
            return this.employeeCodes;
        } catch (error) {
            console.error('Error during migration:', error);
            return null;
        }
    }
    
    /**
     * Load employee codes from the JSON file
     */
    async loadEmployeeCodes() {
        try {
            const response = await fetch(this.employeeCodesPath);
            if (!response.ok) throw new Error('Failed to load employee codes');
            
            this.employeeCodes = await response.json();
            console.log(`Loaded ${this.employeeCodes.employees.length} employee records`);
        } catch (error) {
            console.error('Error loading employee codes:', error);
            throw error;
        }
    }
    
    /**
     * Migrate passwords from plaintext to hashed format
     */
    async migratePasswords() {
        if (!this.employeeCodes || !this.employeeCodes.employees) {
            throw new Error('No employee data loaded');
        }
        
        const employees = this.employeeCodes.employees;
        console.log(`Migrating ${employees.length} passwords...`);
        
        for (const employee of employees) {
            
            // Skip if already migrated
            if (employee.passwordHash && employee.salt) {
                console.log(`Employee ${employee.code} already has hashed password, skipping`);
                continue;
            }
            
            // Skip if no password
            if (!employee.password) {
                console.warn(`Employee ${employee.code} has no password, skipping`);
                continue;
            }
            
            try {
                // Generate hash and salt
                const hashResult = await window.PasswordUtils.hashPassword(employee.password);
                
                // Update employee record
                employee.passwordHash = hashResult.hash;
                employee.salt = hashResult.salt;
                
                // Keep original password for now (can be removed later)
                // employee.password = '[MIGRATED]'; // Uncomment to remove plaintext passwords
                
                console.log(`Migrated password for employee ${employee.code}`);
            } catch (error) {
                console.error(`Error migrating password for employee ${employee.code}:`, error);
            }
        }
        
        console.log('All passwords migrated');
    }
    
    /**
     * Save the updated employee codes
     * This function just returns the JSON to be saved manually by an admin
     */
    getUpdatedData() {
        return JSON.stringify(this.employeeCodes, null, 2);
    }
}

/**
 * Run the migration when the script is loaded
 */
async function runMigration() {
    // Check if we have the required utilities
    if (!window.PasswordUtils) {
        console.error('PasswordUtils not found! Make sure password-utils.js is loaded first.');
        return;
    }
    
    const migration = new PasswordMigration();
    const result = await migration.start();
    
    if (result) {
        console.log('Migration successful. Here is the updated JSON:');
        console.log(migration.getUpdatedData());
        console.log('Copy this JSON and save it to your employee-codes.json file.');
    }
}

// Don't run automatically, wait for manual execution
console.log('Password migration utility loaded. Type "runMigration()" to start the migration process.');
