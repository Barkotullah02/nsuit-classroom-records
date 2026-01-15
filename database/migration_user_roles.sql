-- Migration: Update User Roles System
-- Date: 2026-01-14
-- Description: Add 'staff' role and ensure proper role management

USE classroom_devices;

-- Update users table role enum to include staff
ALTER TABLE users 
MODIFY COLUMN role ENUM('admin', 'staff', 'viewer') DEFAULT 'viewer' 
COMMENT 'admin: full access, staff: can add data only, viewer: read-only access';

-- Ensure existing admin users remain admins
UPDATE users SET role = 'admin' WHERE role = 'admin';

-- Add comment to table
ALTER TABLE users COMMENT = 'User accounts with role-based access control';

-- Create index for better performance on role queries
SET @idx_user_role_active_exists := (
	SELECT COUNT(1)
	FROM information_schema.statistics
	WHERE table_schema = 'classroom_devices'
	  AND table_name = 'users'
	  AND index_name = 'idx_user_role_active'
);

SET @idx_user_role_active_sql := IF(
	@idx_user_role_active_exists = 0,
	'CREATE INDEX idx_user_role_active ON users(role, is_active)',
	'SELECT 1'
);

PREPARE stmt FROM @idx_user_role_active_sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Show updated structure
DESCRIBE users;

-- Show current users
SELECT user_id, username, full_name, role, is_active FROM users;
