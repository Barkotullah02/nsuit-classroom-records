-- Migration to add Excel compatibility fields
-- Date: 2025-12-07
-- Purpose: Add fields to match the Excel data structure

USE classroom_devices;

-- Add new brands from Excel
INSERT INTO device_brands (brand_name) VALUES
('BENQ'),
('VIEW SONIC'),
('OPTIMA'),
('MAXELL'),
('HITACHI'),
('BOXLIGHT')
ON DUPLICATE KEY UPDATE brand_name = brand_name;

-- Add device status to devices table
ALTER TABLE devices 
ADD COLUMN device_status ENUM('NEW', 'REPAIR', 'USED', 'WITHDRAWN') DEFAULT 'NEW' AFTER model,
ADD COLUMN current_issue VARCHAR(255) NULL COMMENT 'Current issue like Lamp Damage, Poor Focus, etc.' AFTER device_status,
ADD COLUMN storage_location VARCHAR(100) NULL COMMENT 'Storage location like Basement, IT, WARREN Memo' AFTER current_issue;

-- Add team/technician tracking to installations
ALTER TABLE device_installations
ADD COLUMN team_members TEXT NULL COMMENT 'Comma-separated list of team members' AFTER installed_by,
ADD COLUMN installation_type ENUM('NEW_INSTALLATION', 'REPAIRED', 'OLD_REINSTALL') DEFAULT 'NEW_INSTALLATION' COMMENT 'Type of installation: new, repaired, or old device reinstallation' AFTER team_members,
ADD COLUMN issue_at_withdrawal VARCHAR(255) NULL COMMENT 'Issue found at withdrawal' AFTER withdrawal_notes,
ADD COLUMN storage_location VARCHAR(100) NULL COMMENT 'Where device is stored after withdrawal' AFTER issue_at_withdrawal;

-- Create index for device status and storage location
CREATE INDEX idx_device_status ON devices(device_status);
CREATE INDEX idx_storage_location ON devices(storage_location);

-- Create a view that matches Excel layout
CREATE OR REPLACE VIEW view_excel_active_installations AS
SELECT 
    r.room_number as 'ID',
    r.building as 'Location',
    db.brand_name as 'Multimedia Brand',
    d.device_status as 'Status',
    d.device_unique_id as 'NSU ID',
    d.serial_number as 'Manufacture SL',
    di.installed_date as 'Install Date',
    di.installation_type as 'Installation Type',
    di.team_members as 'TEAM',
    d.current_issue as 'Current Issue',
    d.storage_location as 'Storage'
FROM device_installations di
JOIN devices d ON di.device_id = d.device_id
JOIN device_brands db ON d.brand_id = db.brand_id
JOIN rooms r ON di.room_id = r.room_id
WHERE di.status = 'active' 
AND di.is_deleted = FALSE
AND d.is_deleted = FALSE
ORDER BY r.room_number;

-- Create a view for withdrawn devices (matches right side of Excel)
CREATE OR REPLACE VIEW view_excel_withdrawn_devices AS
SELECT 
    d.device_unique_id as 'NSU ID',
    db.brand_name as 'Status/Brand',
    d.serial_number as 'Manufacture SL',
    d.current_issue as 'Issue',
    d.storage_location as 'Store',
    di.withdrawn_date as 'Withdrawn Date',
    di.issue_at_withdrawal as 'Withdrawal Issue',
    di.withdrawal_notes as 'Notes'
FROM devices d
JOIN device_brands db ON d.brand_id = db.brand_id
LEFT JOIN device_installations di ON d.device_id = di.device_id 
    AND di.status = 'withdrawn' 
    AND di.is_deleted = FALSE
WHERE (d.device_status = 'WITHDRAWN' OR di.status = 'withdrawn')
AND d.is_deleted = FALSE
ORDER BY di.withdrawn_date DESC;

-- Add sample data mapping for issue types (for dropdown consistency)
CREATE TABLE IF NOT EXISTS device_issues (
    issue_id INT AUTO_INCREMENT PRIMARY KEY,
    issue_name VARCHAR(100) UNIQUE NOT NULL,
    issue_category ENUM('Hardware', 'Display', 'Power', 'Other') DEFAULT 'Other',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Insert common issues from Excel
INSERT INTO device_issues (issue_name, issue_category) VALUES
('Lamp Damage', 'Hardware'),
('Red Light Issue', 'Power'),
('Poor Focus', 'Display'),
('Lamp Issue', 'Hardware'),
('Off Properly', 'Other'),
('LAMP Issue', 'Hardware'),
('Lamp fuse', 'Hardware'),
('No Focus', 'Display')
ON DUPLICATE KEY UPDATE issue_name = issue_name;

-- Add storage locations reference table
CREATE TABLE IF NOT EXISTS storage_locations (
    location_id INT AUTO_INCREMENT PRIMARY KEY,
    location_name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Insert storage locations from Excel
INSERT INTO storage_locations (location_name) VALUES
('Basement'),
('IT'),
('WARREN Memo'),
('IT Store'),
('IT Memo')
ON DUPLICATE KEY UPDATE location_name = location_name;

-- Update existing devices to set default status
UPDATE devices 
SET device_status = 'NEW' 
WHERE device_status IS NULL;

-- Add comment to serial_number field for clarity
ALTER TABLE devices 
MODIFY COLUMN serial_number VARCHAR(100) COMMENT 'Manufacturer Serial Number (Manufacture SL in Excel)';

