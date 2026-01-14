-- Migration: Update gate pass format fields (Incoming/Outgoing + header + bearer/security/processing/authorized sections)
-- Date: 2026-01-04
-- Notes: Run once. If a column already exists, remove that line.

USE classroom_devices;

ALTER TABLE gate_passes
  ADD COLUMN pass_direction ENUM('incoming','outgoing') NOT NULL DEFAULT 'outgoing' AFTER gate_pass_date,
  ADD COLUMN gate_pass_time TIME NULL AFTER pass_direction,
  ADD COLUMN department VARCHAR(255) NULL AFTER gate_pass_time,
  ADD COLUMN gate_name VARCHAR(255) NULL AFTER department,
  ADD COLUMN vendor_destination VARCHAR(255) NULL AFTER gate_name,

  ADD COLUMN bearer_name VARCHAR(150) NULL AFTER vendor_destination,
  ADD COLUMN bearer_company VARCHAR(150) NULL AFTER bearer_name,
  ADD COLUMN bearer_contact_no VARCHAR(50) NULL AFTER bearer_company,
  ADD COLUMN bearer_signature VARCHAR(255) NULL AFTER bearer_contact_no,
  ADD COLUMN bearer_signature_date DATE NULL AFTER bearer_signature,

  ADD COLUMN security_officer_name VARCHAR(150) NULL AFTER bearer_signature_date,
  ADD COLUMN security_officer_designation VARCHAR(150) NULL AFTER security_officer_name,
  ADD COLUMN security_officer_ext VARCHAR(50) NULL AFTER security_officer_designation,
  ADD COLUMN security_officer_signature VARCHAR(255) NULL AFTER security_officer_ext,
  ADD COLUMN security_officer_signature_date DATE NULL AFTER security_officer_signature,

  ADD COLUMN processing_name VARCHAR(150) NULL AFTER security_officer_signature_date,
  ADD COLUMN processing_designation VARCHAR(150) NULL AFTER processing_name,
  ADD COLUMN processing_ext VARCHAR(50) NULL AFTER processing_designation,
  ADD COLUMN processing_signature VARCHAR(255) NULL AFTER processing_ext,
  ADD COLUMN processing_signature_date DATE NULL AFTER processing_signature,

  ADD COLUMN authorized_name VARCHAR(150) NULL AFTER processing_signature_date,
  ADD COLUMN authorized_designation VARCHAR(150) NULL AFTER authorized_name,
  ADD COLUMN authorized_ext VARCHAR(50) NULL AFTER authorized_designation,
  ADD COLUMN authorized_signature VARCHAR(255) NULL AFTER authorized_ext,
  ADD COLUMN authorized_signature_date DATE NULL AFTER authorized_signature;

SELECT 'Gate pass format migration applied' AS message;
