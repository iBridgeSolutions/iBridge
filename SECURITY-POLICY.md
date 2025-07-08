# iBridge Intranet Security Policy

## Overview

This document outlines the security measures implemented in the iBridge Intranet Portal. These measures are designed to protect user data, prevent unauthorized access, and ensure the integrity and reliability of the system.

## Authentication Security

### 1. Password Security

- **Password Hashing**: All passwords are stored using secure SHA-256 hashing with unique salts
- **Strength Requirements**: Passwords must include a combination of uppercase, lowercase, numbers, and special characters
- **Password Strength Meter**: Visual feedback helps users create strong passwords
- **Secure Storage**: Passwords are never stored in plaintext

### 2. Account Protection

- **Failed Attempt Limiting**: Accounts are temporarily locked after 5 failed login attempts
- **Rate Limiting**: Login attempts are rate-limited to prevent brute force attacks
- **Session Management**: Sessions expire after 8 hours of inactivity
- **CSRF Protection**: All forms and API requests are protected against Cross-Site Request Forgery

### 3. Two-Factor Authentication (2FA)

- **Email Verification**: Optional 2FA requiring email verification codes
- **Time-Limited Codes**: Verification codes expire after 10 minutes
- **Single-Use Codes**: Each code can only be used once
- **Account Recovery**: Secure process for recovering access if 2FA is unavailable

## Data Security

### 1. Data Storage

- **Local Storage**: All data is stored locally, removing Microsoft 365 dependencies
- **JSON Structured Storage**: Data is organized in structured JSON files
- **Regular Backups**: Data is backed up before any modifications
- **Access Control**: Data access is restricted based on user permissions

### 2. Transport Security

- **HTTPS Only**: All communications should be over HTTPS
- **Secure Cookies**: Cookies use SameSite=Strict and secure attributes
- **Content Security Policy**: Restricts resource loading to trusted sources
- **Anti-Forgery Tokens**: Prevents cross-site request forgery attacks

## Application Security

### 1. Input Validation

- **Client-Side Validation**: Immediate feedback on invalid inputs
- **Server-Side Validation**: All inputs are validated server-side
- **Output Encoding**: Data is properly encoded when displayed
- **Content-Type Headers**: Proper content types prevent injection attacks

### 2. Error Handling

- **Secure Error Messages**: Error messages don't reveal sensitive information
- **Logging**: Security events are logged for auditing
- **Graceful Degradation**: System remains functional during partial failures

## Implementation Guidelines

### 1. Security Features Integration

- **Password Hashing**: Use `password-utils.js` for all password operations
- **CSRF Protection**: Include `anti-forgery.js` on all pages with forms
- **Rate Limiting**: Use `rate-limiter.js` for APIs and login operations
- **Two-Factor Auth**: Integrate `two-factor-auth.js` for sensitive operations

### 2. Administrative Tools

- **Password Migration**: Use `MIGRATE-PASSWORDS.bat` to convert plaintext passwords to hashed
- **2FA Setup**: Use `SETUP-TWO-FACTOR-AUTH.bat` to enable/disable 2FA for users
- **Access Control**: Manage user permissions via `access-control.json`

## Security Maintenance

### 1. Regular Updates

- **Security Audit**: Monthly review of security measures
- **Dependency Updates**: Keep all libraries and frameworks updated
- **Vulnerability Scanning**: Regular scanning for security issues
- **Penetration Testing**: Annual security testing

### 2. Incident Response

- **Detection**: Monitoring for unusual activity
- **Containment**: Procedures to contain security breaches
- **Eradication**: Remove security threats
- **Recovery**: Restore systems to normal operation
- **Documentation**: Document incidents and responses

## Contact

For security concerns or questions, contact the IT Security team.

---

Document Version: 1.0
Last Updated: July 2025
