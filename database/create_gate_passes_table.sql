-- Create standalone gate_passes table
-- This table is independent of installations

CREATE TABLE IF NOT EXISTS gate_passes (
    gate_pass_id INT AUTO_INCREMENT PRIMARY KEY,
    device_id INT NOT NULL,
    gate_pass_number VARCHAR(50) NOT NULL UNIQUE,
    gate_pass_date DATE NOT NULL,
    destination_room_id INT NULL,
    carrier_name VARCHAR(100) NOT NULL,
    carrier_id VARCHAR(50) NULL,
    purpose VARCHAR(100) NOT NULL,
    remarks TEXT NULL,
    status ENUM('active', 'completed', 'cancelled') DEFAULT 'active',
    created_by INT NOT NULL,
    is_deleted BOOLEAN DEFAULT FALSE,
    deleted_at TIMESTAMP NULL,
    deleted_by INT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (device_id) REFERENCES devices(device_id),
    FOREIGN KEY (destination_room_id) REFERENCES rooms(room_id) ON DELETE SET NULL,
    FOREIGN KEY (created_by) REFERENCES users(user_id),
    FOREIGN KEY (deleted_by) REFERENCES users(user_id) ON DELETE SET NULL,
    
    INDEX idx_gate_pass_number (gate_pass_number),
    INDEX idx_device_id (device_id),
    INDEX idx_gate_pass_date (gate_pass_date),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Remove gate pass fields from device_installations table
-- (Keep them for backward compatibility but they're now optional)

SELECT 'Gate passes table created successfully' as message;
