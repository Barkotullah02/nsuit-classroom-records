-- Migration: Add super_admin role
-- Date: 2026-03-03
-- Description: Introduce super_admin role for high-privilege operations

USE classroom_devices;

-- Extend role enum to include super_admin
ALTER TABLE users
MODIFY COLUMN role ENUM('super_admin', 'admin', 'staff', 'viewer') DEFAULT 'viewer'
COMMENT 'super_admin: highest access, admin: full operational access, staff: can add data only, viewer: read-only access';

-- Optional: promote existing admin account to super_admin for initial bootstrap
-- Update only if default admin exists and no super_admin exists yet
SET @super_admin_count := (
    SELECT COUNT(1)
    FROM users
    WHERE role = 'super_admin'
);

SET @promote_default_admin_sql := IF(
    @super_admin_count = 0,
    "UPDATE users SET role = 'super_admin' WHERE username = 'admin' LIMIT 1",
    'SELECT 1'
);

PREPARE stmt FROM @promote_default_admin_sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Helpful index for role filtering
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

PREPARE stmt2 FROM @idx_user_role_active_sql;
EXECUTE stmt2;
DEALLOCATE PREPARE stmt2;
