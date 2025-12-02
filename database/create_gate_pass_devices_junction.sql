-- Create junction table for gate passes with multiple devices

CREATE TABLE IF NOT EXISTS gate_pass_devices (
    gate_pass_device_id INT PRIMARY KEY AUTO_INCREMENT,
    gate_pass_id INT NOT NULL,
    device_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (gate_pass_id) REFERENCES gate_passes(gate_pass_id) ON DELETE CASCADE,
    FOREIGN KEY (device_id) REFERENCES devices(device_id) ON DELETE CASCADE,
    UNIQUE KEY unique_gate_pass_device (gate_pass_id, device_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Migrate existing data from gate_passes.device_id to junction table
INSERT INTO gate_pass_devices (gate_pass_id, device_id)
SELECT gate_pass_id, device_id 
FROM gate_passes 
WHERE device_id IS NOT NULL AND is_deleted = FALSE;

-- Remove device_id column from gate_passes as it's now in junction table
ALTER TABLE gate_passes DROP FOREIGN KEY gate_passes_ibfk_1;
ALTER TABLE gate_passes DROP COLUMN device_id;
