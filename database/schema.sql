-- Database Schema for Classroom Device Management System
-- Created: November 28, 2025

DROP DATABASE IF EXISTS classroom_devices;
CREATE DATABASE classroom_devices CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE classroom_devices;

-- Users Table
CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    role ENUM('viewer', 'admin') DEFAULT 'viewer',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_username (username),
    INDEX idx_role (role)
) ENGINE=InnoDB;

-- Rooms Table
CREATE TABLE rooms (
    room_id INT AUTO_INCREMENT PRIMARY KEY,
    room_number VARCHAR(50) UNIQUE NOT NULL,
    room_name VARCHAR(100),
    building VARCHAR(100),
    floor INT,
    capacity INT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_room_number (room_number)
) ENGINE=InnoDB;

-- Device Types Table
CREATE TABLE device_types (
    type_id INT AUTO_INCREMENT PRIMARY KEY,
    type_name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Device Brands Table
CREATE TABLE device_brands (
    brand_id INT AUTO_INCREMENT PRIMARY KEY,
    brand_name VARCHAR(50) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Devices Table
CREATE TABLE devices (
    device_id INT AUTO_INCREMENT PRIMARY KEY,
    device_unique_id VARCHAR(100) UNIQUE NOT NULL,
    type_id INT NOT NULL,
    brand_id INT NOT NULL,
    model VARCHAR(100),
    serial_number VARCHAR(100),
    purchase_date DATE,
    warranty_period INT COMMENT 'Warranty period in months',
    notes TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    is_deleted BOOLEAN DEFAULT FALSE,
    deleted_at TIMESTAMP NULL,
    deleted_by INT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (type_id) REFERENCES device_types(type_id),
    FOREIGN KEY (brand_id) REFERENCES device_brands(brand_id),
    FOREIGN KEY (deleted_by) REFERENCES users(user_id),
    INDEX idx_device_unique_id (device_unique_id),
    INDEX idx_type_id (type_id),
    INDEX idx_brand_id (brand_id),
    INDEX idx_is_deleted (is_deleted)
) ENGINE=InnoDB;

-- Device Installations Table (Tracks movement history)
CREATE TABLE device_installations (
    installation_id INT AUTO_INCREMENT PRIMARY KEY,
    device_id INT NOT NULL,
    room_id INT NOT NULL,
    installed_date DATE NOT NULL,
    withdrawn_date DATE NULL,
    installed_by INT NOT NULL,
    withdrawn_by INT NULL,
    installation_notes TEXT,
    withdrawal_notes TEXT,
    status ENUM('active', 'withdrawn') DEFAULT 'active',
    is_deleted BOOLEAN DEFAULT FALSE,
    deleted_at TIMESTAMP NULL,
    deleted_by INT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (device_id) REFERENCES devices(device_id),
    FOREIGN KEY (room_id) REFERENCES rooms(room_id),
    FOREIGN KEY (installed_by) REFERENCES users(user_id),
    FOREIGN KEY (withdrawn_by) REFERENCES users(user_id),
    FOREIGN KEY (deleted_by) REFERENCES users(user_id),
    INDEX idx_device_id (device_id),
    INDEX idx_room_id (room_id),
    INDEX idx_status (status),
    INDEX idx_installed_date (installed_date),
    INDEX idx_is_deleted (is_deleted)
) ENGINE=InnoDB;

-- Audit Log Table (Track all changes)
CREATE TABLE audit_log (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    action VARCHAR(50) NOT NULL COMMENT 'CREATE, UPDATE, DELETE, RESTORE, LOGIN, LOGOUT',
    table_name VARCHAR(50) NOT NULL,
    record_id INT NOT NULL,
    old_values JSON,
    new_values JSON,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    INDEX idx_user_id (user_id),
    INDEX idx_action (action),
    INDEX idx_table_name (table_name),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB;

-- Sessions Table (For managing user sessions)
CREATE TABLE sessions (
    session_id VARCHAR(128) PRIMARY KEY,
    user_id INT NOT NULL,
    ip_address VARCHAR(45),
    user_agent TEXT,
    last_activity TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_last_activity (last_activity)
) ENGINE=InnoDB;

-- Insert default device types
INSERT INTO device_types (type_name, description) VALUES
('Multimedia Projector', 'Digital multimedia projectors'),
('Monitor', 'Computer monitors and displays'),
('Speaker', 'Audio speakers and sound systems'),
('Keyboard', 'Computer keyboards'),
('Mouse', 'Computer mice and pointing devices');

-- Insert default brands
INSERT INTO device_brands (brand_name) VALUES
('HP'),
('Boxlight'),
('A4Tech'),
('Dell'),
('Logitech'),
('Sony'),
('Epson'),
('Samsung'),
('LG'),
('Microsoft');

-- Insert default admin user (password: admin123 - CHANGE IN PRODUCTION!)
-- Password hash for 'admin123'
INSERT INTO users (username, password_hash, full_name, email, role) VALUES
('admin', '$2y$10$5IGymiE.6LhqQzJkfqXZ5eKn8X0F0HqQX5GjZPEKU6xDJPJKVHvKa', 'System Administrator', 'admin@classroom.local', 'admin'),
('viewer', '$2y$10$5IGymiE.6LhqQzJkfqXZ5eKn8X0F0HqQX5GjZPEKU6xDJPJKVHvKa', 'Guest Viewer', 'viewer@classroom.local', 'viewer');

-- Insert sample rooms
INSERT INTO rooms (room_number, room_name, building, floor, capacity) VALUES
('R101', 'Computer Lab 1', 'Main Building', 1, 40),
('R102', 'Computer Lab 2', 'Main Building', 1, 40),
('R201', 'Conference Room', 'Main Building', 2, 20),
('R202', 'Training Room', 'Main Building', 2, 30),
('R301', 'Auditorium', 'Main Building', 3, 100);

-- Create Views for easier querying

-- View: Current Device Locations
CREATE VIEW view_current_device_locations AS
SELECT 
    d.device_id,
    d.device_unique_id,
    dt.type_name,
    db.brand_name,
    d.model,
    r.room_number,
    r.room_name,
    di.installed_date,
    DATEDIFF(CURDATE(), di.installed_date) as days_in_current_room,
    u.full_name as installed_by_name
FROM devices d
LEFT JOIN device_types dt ON d.type_id = dt.type_id
LEFT JOIN device_brands db ON d.brand_id = db.brand_id
LEFT JOIN device_installations di ON d.device_id = di.device_id AND di.status = 'active' AND di.is_deleted = FALSE
LEFT JOIN rooms r ON di.room_id = r.room_id
LEFT JOIN users u ON di.installed_by = u.user_id
WHERE d.is_deleted = FALSE;

-- View: Device Lifetime Statistics
CREATE VIEW view_device_lifetime_stats AS
SELECT 
    d.device_id,
    d.device_unique_id,
    dt.type_name,
    db.brand_name,
    d.model,
    MIN(di.installed_date) as first_installation_date,
    DATEDIFF(CURDATE(), MIN(di.installed_date)) as total_lifetime_days,
    COUNT(DISTINCT di.installation_id) as total_installations,
    COUNT(DISTINCT di.room_id) as total_rooms_used
FROM devices d
LEFT JOIN device_types dt ON d.type_id = dt.type_id
LEFT JOIN device_brands db ON d.brand_id = db.brand_id
LEFT JOIN device_installations di ON d.device_id = di.device_id AND di.is_deleted = FALSE
WHERE d.is_deleted = FALSE
GROUP BY d.device_id, d.device_unique_id, dt.type_name, db.brand_name, d.model;

-- Stored Procedures

-- Procedure: Get Device History
DELIMITER //
CREATE PROCEDURE sp_get_device_history(IN p_device_id INT)
BEGIN
    SELECT 
        di.installation_id,
        r.room_number,
        r.room_name,
        di.installed_date,
        di.withdrawn_date,
        DATEDIFF(IFNULL(di.withdrawn_date, CURDATE()), di.installed_date) as days_in_room,
        di.status,
        u_installed.full_name as installed_by,
        u_withdrawn.full_name as withdrawn_by,
        di.installation_notes,
        di.withdrawal_notes
    FROM device_installations di
    JOIN rooms r ON di.room_id = r.room_id
    JOIN users u_installed ON di.installed_by = u_installed.user_id
    LEFT JOIN users u_withdrawn ON di.withdrawn_by = u_withdrawn.user_id
    WHERE di.device_id = p_device_id
        AND di.is_deleted = FALSE
    ORDER BY di.installed_date DESC;
END //

-- Procedure: Soft Delete Device
CREATE PROCEDURE sp_soft_delete_device(
    IN p_device_id INT,
    IN p_deleted_by INT
)
BEGIN
    UPDATE devices 
    SET is_deleted = TRUE,
        deleted_at = CURRENT_TIMESTAMP,
        deleted_by = p_deleted_by
    WHERE device_id = p_device_id;
    
    -- Log the action
    INSERT INTO audit_log (user_id, action, table_name, record_id, ip_address)
    VALUES (p_deleted_by, 'SOFT_DELETE', 'devices', p_device_id, 'SYSTEM');
END //

-- Procedure: Restore Deleted Device
CREATE PROCEDURE sp_restore_device(
    IN p_device_id INT,
    IN p_restored_by INT
)
BEGIN
    UPDATE devices 
    SET is_deleted = FALSE,
        deleted_at = NULL,
        deleted_by = NULL
    WHERE device_id = p_device_id;
    
    -- Log the action
    INSERT INTO audit_log (user_id, action, table_name, record_id, ip_address)
    VALUES (p_restored_by, 'RESTORE', 'devices', p_device_id, 'SYSTEM');
END //

DELIMITER ;

-- Create indexes for better performance
CREATE INDEX idx_devices_active ON devices(is_active, is_deleted);
CREATE INDEX idx_installations_active ON device_installations(status, is_deleted);
