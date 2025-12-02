-- Migration: Add gate pass and data entry tracking
-- Date: 2025-11-29

-- Add columns to track data entry person and manual installer/withdrawer names
ALTER TABLE device_installations 
ADD COLUMN installer_name VARCHAR(255) NULL COMMENT 'Manually entered installer name' AFTER installed_by,
ADD COLUMN installer_id VARCHAR(100) NULL COMMENT 'Manually entered installer ID' AFTER installer_name,
ADD COLUMN withdrawer_name VARCHAR(255) NULL COMMENT 'Manually entered withdrawer name' AFTER withdrawn_by,
ADD COLUMN withdrawer_id VARCHAR(100) NULL COMMENT 'Manually entered withdrawer ID' AFTER withdrawer_name,
ADD COLUMN data_entry_by INT NULL COMMENT 'User who entered/modified this record' AFTER withdrawer_id,
ADD COLUMN gate_pass_number VARCHAR(100) NULL COMMENT 'Gate pass reference number' AFTER data_entry_by,
ADD COLUMN gate_pass_date DATE NULL COMMENT 'Gate pass issue date' AFTER gate_pass_number;

-- Add foreign key for data entry user
ALTER TABLE device_installations
ADD CONSTRAINT fk_data_entry_user 
FOREIGN KEY (data_entry_by) REFERENCES users(user_id);

-- Update existing records to set data_entry_by same as installed_by
UPDATE device_installations 
SET data_entry_by = installed_by 
WHERE data_entry_by IS NULL;

-- Add index for gate pass number for quick lookup
CREATE INDEX idx_gate_pass_number ON device_installations(gate_pass_number);

-- Update the view to include new fields
DROP VIEW IF EXISTS v_device_installation_history;

CREATE VIEW v_device_installation_history AS
SELECT 
    di.installation_id,
    di.device_id,
    d.device_unique_id,
    dt.type_name,
    db.brand_name,
    d.model,
    di.room_id,
    r.room_number,
    r.room_name,
    r.building,
    r.floor,
    di.installed_date,
    di.withdrawn_date,
    di.status,
    di.installation_notes,
    di.withdrawal_notes,
    di.gate_pass_number,
    di.gate_pass_date,
    DATEDIFF(COALESCE(di.withdrawn_date, CURDATE()), di.installed_date) as days_in_room,
    -- Installer information (manual or user)
    COALESCE(di.installer_name, u1.full_name) as installed_by_name,
    di.installer_id as installed_by_id,
    -- Withdrawer information (manual or user)
    COALESCE(di.withdrawer_name, u2.full_name) as withdrawn_by_name,
    di.withdrawer_id as withdrawn_by_id,
    -- Data entry person
    u3.full_name as data_entry_by_name,
    u3.username as data_entry_username,
    di.created_at,
    di.updated_at
FROM device_installations di
INNER JOIN devices d ON di.device_id = d.device_id
INNER JOIN device_types dt ON d.type_id = dt.type_id
INNER JOIN device_brands db ON d.brand_id = db.brand_id
INNER JOIN rooms r ON di.room_id = r.room_id
LEFT JOIN users u1 ON di.installed_by = u1.user_id
LEFT JOIN users u2 ON di.withdrawn_by = u2.user_id
LEFT JOIN users u3 ON di.data_entry_by = u3.user_id
WHERE di.is_deleted = FALSE
ORDER BY di.installed_date DESC;
