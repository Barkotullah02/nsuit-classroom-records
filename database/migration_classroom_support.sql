-- Migration for Classroom Support Feature
-- Date: 2025-12-09
-- Purpose: Add classroom support tracking system

USE classroom_devices;

-- Create support team members table
CREATE TABLE IF NOT EXISTS support_team_members (
    member_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NULL COMMENT 'Link to users table if member has login',
    member_name VARCHAR(100) NOT NULL,
    member_email VARCHAR(100),
    member_phone VARCHAR(20),
    department VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by INT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL,
    FOREIGN KEY (created_by) REFERENCES users(user_id) ON DELETE SET NULL,
    INDEX idx_member_name (member_name),
    INDEX idx_is_active (is_active)
) ENGINE=InnoDB COMMENT='Support team members who provide classroom assistance';

-- Create classroom support records table
CREATE TABLE IF NOT EXISTS classroom_support_records (
    support_id INT AUTO_INCREMENT PRIMARY KEY,
    member_id INT NOT NULL COMMENT 'Support team member who provided support',
    support_date DATE NOT NULL,
    support_time TIME NOT NULL,
    location VARCHAR(100) NOT NULL COMMENT 'Classroom number/location',
    room_id INT NULL COMMENT 'Optional link to rooms table',
    support_description TEXT NOT NULL,
    issue_type ENUM('TECHNICAL', 'SETUP', 'TRAINING', 'MAINTENANCE', 'OTHER') DEFAULT 'TECHNICAL',
    priority ENUM('LOW', 'MEDIUM', 'HIGH') DEFAULT 'MEDIUM',
    status ENUM('PENDING', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED') DEFAULT 'PENDING',
    devices_involved TEXT NULL COMMENT 'Comma-separated device IDs if applicable',
    duration_minutes INT NULL COMMENT 'Duration of support in minutes',
    faculty_name VARCHAR(100) NULL COMMENT 'Faculty/staff who requested support',
    notes TEXT NULL,
    created_by INT NOT NULL COMMENT 'User who created this record',
    is_deleted BOOLEAN DEFAULT FALSE,
    deleted_at TIMESTAMP NULL,
    deleted_by INT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (member_id) REFERENCES support_team_members(member_id),
    FOREIGN KEY (room_id) REFERENCES rooms(room_id) ON DELETE SET NULL,
    FOREIGN KEY (created_by) REFERENCES users(user_id),
    FOREIGN KEY (deleted_by) REFERENCES users(user_id) ON DELETE SET NULL,
    INDEX idx_member_id (member_id),
    INDEX idx_support_date (support_date),
    INDEX idx_location (location),
    INDEX idx_status (status),
    INDEX idx_is_deleted (is_deleted),
    INDEX idx_created_by (created_by)
) ENGINE=InnoDB COMMENT='Records of classroom support activities';

-- Create support statistics view
DROP VIEW IF EXISTS view_support_statistics;
CREATE VIEW view_support_statistics AS
SELECT 
    stm.member_id,
    stm.member_name,
    stm.department,
    COUNT(csr.support_id) as total_supports,
    COUNT(CASE WHEN csr.support_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY) THEN 1 END) as supports_last_30_days,
    COUNT(CASE WHEN csr.support_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY) THEN 1 END) as supports_last_7_days,
    SUM(CASE WHEN csr.duration_minutes IS NOT NULL THEN csr.duration_minutes ELSE 0 END) as total_minutes,
    AVG(CASE WHEN csr.duration_minutes IS NOT NULL THEN csr.duration_minutes ELSE NULL END) as avg_duration_minutes,
    MAX(csr.support_date) as last_support_date
FROM support_team_members stm
LEFT JOIN classroom_support_records csr ON stm.member_id = csr.member_id 
    AND csr.is_deleted = FALSE
WHERE stm.is_active = TRUE
GROUP BY stm.member_id, stm.member_name, stm.department;

-- Create daily support summary view
DROP VIEW IF EXISTS view_daily_support_summary;
CREATE VIEW view_daily_support_summary AS
SELECT 
    csr.support_date,
    COUNT(csr.support_id) as total_supports,
    COUNT(DISTINCT csr.member_id) as team_members_active,
    COUNT(DISTINCT csr.location) as locations_served,
    SUM(CASE WHEN csr.duration_minutes IS NOT NULL THEN csr.duration_minutes ELSE 0 END) as total_minutes,
    COUNT(CASE WHEN csr.issue_type = 'TECHNICAL' THEN 1 END) as technical_issues,
    COUNT(CASE WHEN csr.issue_type = 'SETUP' THEN 1 END) as setup_issues,
    COUNT(CASE WHEN csr.issue_type = 'TRAINING' THEN 1 END) as training_issues,
    COUNT(CASE WHEN csr.issue_type = 'MAINTENANCE' THEN 1 END) as maintenance_issues,
    COUNT(CASE WHEN csr.priority = 'HIGH' THEN 1 END) as `high_priority`,
    COUNT(CASE WHEN csr.priority = 'MEDIUM' THEN 1 END) as medium_priority
FROM classroom_support_records csr
WHERE csr.is_deleted = FALSE
GROUP BY csr.support_date
ORDER BY csr.support_date DESC;

-- Insert sample support team members (optional - for testing)
INSERT INTO support_team_members (member_name, member_email, department, is_active) VALUES
('John Doe', 'john.doe@nsu.edu', 'IT Support', TRUE),
('Jane Smith', 'jane.smith@nsu.edu', 'Technical Services', TRUE),
('Mike Johnson', 'mike.johnson@nsu.edu', 'IT Support', TRUE)
ON DUPLICATE KEY UPDATE member_name = member_name;

-- Add audit logging for support records
DELIMITER //

CREATE TRIGGER IF NOT EXISTS trg_support_audit_insert
AFTER INSERT ON classroom_support_records
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (user_id, action, table_name, record_id, new_values)
    VALUES (
        NEW.created_by,
        'CREATE',
        'classroom_support_records',
        NEW.support_id,
        JSON_OBJECT(
            'member_id', NEW.member_id,
            'support_date', NEW.support_date,
            'location', NEW.location,
            'support_description', NEW.support_description
        )
    );
END//

CREATE TRIGGER IF NOT EXISTS trg_support_audit_update
AFTER UPDATE ON classroom_support_records
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (user_id, action, table_name, record_id, old_values, new_values)
    VALUES (
        NEW.created_by,
        'UPDATE',
        'classroom_support_records',
        NEW.support_id,
        JSON_OBJECT(
            'member_id', OLD.member_id,
            'support_date', OLD.support_date,
            'location', OLD.location,
            'support_description', OLD.support_description
        ),
        JSON_OBJECT(
            'member_id', NEW.member_id,
            'support_date', NEW.support_date,
            'location', NEW.location,
            'support_description', NEW.support_description
        )
    );
END//

DELIMITER ;

