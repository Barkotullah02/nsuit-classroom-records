-- Update gate_passes table to add new fields matching the NSU gate pass format

ALTER TABLE gate_passes 
ADD COLUMN consignee_name TEXT AFTER gate_pass_date,
ADD COLUMN destination VARCHAR(255) AFTER consignee_name,
ADD COLUMN carrier_appointment VARCHAR(100) AFTER carrier_name,
ADD COLUMN carrier_department VARCHAR(100) AFTER carrier_appointment,
ADD COLUMN carrier_telephone VARCHAR(50) AFTER carrier_department,
ADD COLUMN security_name VARCHAR(100) AFTER carrier_telephone,
ADD COLUMN security_appointment VARCHAR(100) AFTER security_name,
ADD COLUMN security_department VARCHAR(100) AFTER security_appointment,
ADD COLUMN security_telephone VARCHAR(50) AFTER security_department,
ADD COLUMN receiver_name VARCHAR(100) AFTER security_telephone,
ADD COLUMN receiver_appointment VARCHAR(100) AFTER receiver_name,
ADD COLUMN receiver_department VARCHAR(100) AFTER receiver_appointment,
ADD COLUMN receiver_telephone VARCHAR(50) AFTER receiver_department;

-- Remove carrier_id column as it's replaced by carrier_telephone
ALTER TABLE gate_passes 
DROP COLUMN carrier_id;
