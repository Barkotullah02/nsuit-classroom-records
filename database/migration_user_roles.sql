-- Migration: Update User Roles System
-- Date: 2026-01-14
-- Description: Add 'staff' role and ensure proper role management

USE classroom_devices;

-- Update users table role enum to include staff
ALTER TABLE users 
MODIFY COLUMN role ENUM('admin', 'staff', 'viewer') DEFAULT 'viewer' 
COMMENT 'admin: full access, staff: can add/edit data, viewer: read-only access';

-- Ensure existing admin users remain admins
UPDATE users SET role = 'admin' WHERE role = 'admin';

-- Add comment to table
ALTER TABLE users COMMENT = 'User accounts with role-based access control';

-- Create index for better performance on role queries
CREATE INDEX IF NOT EXISTS idx_user_role_active ON users(role, is_active);

-- Show updated structure
DESCRIBE users;

-- Show current users
SELECT user_id, username, full_name, role, is_active FROM users;
