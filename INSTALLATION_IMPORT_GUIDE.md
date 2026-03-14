# Installation History Bulk Import Guide

## Updated CSV Template Format

The installation history import template has been **updated** to match the current database structure.

### Template Columns (in order):

1. **device_unique_id** (Required) - Must match an existing device in the system
2. **room_number** (Required) - Must match an existing room in the system
3. **installed_date** (Required) - Format: YYYY-MM-DD (e.g., 2024-01-15)
4. **installer_name** (Optional) - Name of the person who installed the device
5. **installer_id** (Optional) - Employee ID of the installer
6. **team_members** (Optional) - Names of team members who helped
7. **installation_type** (Optional) - Must be one of: `NEW_INSTALLATION`, `REPAIRED`, or `OLD_REINSTALL` (default: NEW_INSTALLATION if left empty)
8. **installation_notes** (Optional) - Notes about the installation
9. **withdrawn_date** (Optional) - Format: YYYY-MM-DD (leave empty if device is still active)
10. **withdrawer_name** (Optional) - Name of the person who withdrew the device
11. **withdrawer_id** (Optional) - Employee ID of the withdrawer
12. **withdrawal_notes** (Optional) - Notes about the withdrawal
13. **issue_at_withdrawal** (Optional) - Any issues noted when device was withdrawn
14. **storage_location** (Optional) - Where the device was stored after withdrawal
15. **gate_pass_number** (Optional) - Related gate pass number
16. **gate_pass_date** (Optional) - Format: YYYY-MM-DD
17. **status** (Optional) - `active` or `withdrawn` (auto-detected from withdrawn_date)

## Example CSV:

```csv
device_unique_id,room_number,installed_date,installer_name,installer_id,team_members,installation_type,installation_notes,withdrawn_date,withdrawer_name,withdrawer_id,withdrawal_notes,issue_at_withdrawal,storage_location,gate_pass_number,gate_pass_date,status
50-ITD-00508-00542,101,2024-01-15,John Doe,EMP001,,NEW_INSTALLATION,Initial installation,,,,,,,,,active
50-ITD-00508-00543,102,2024-02-20,Jane Smith,EMP002,Tech Team A,NEW_INSTALLATION,New projector installed,2024-06-15,Mike Johnson,EMP003,Moved to room 201,,,,GP-2024-001,2024-06-15,withdrawn
50-ITD-00508-00544,201,2024-03-10,Robert Lee,EMP004,,REPAIRED,Repaired and reinstalled,,,,,,,,,active
50-ITD-00508-00545,B101,2024-04-05,Sarah Chen,EMP005,Installation Team,OLD_REINSTALL,Reinstalled old device,,,,,,,,,active
```

## How to Use:

1. **Download the Template**
   - Go to "Import Data" page
   - Click "Download Installation History Template"
   - This will download `installations_template.csv` with correct headers

2. **Fill in Your Data**
   - Open the CSV in Excel or any text editor
   - Keep the header row as is
   - Add your installation data in the rows below
   - Required fields: `device_unique_id`, `room_number`, `installed_date`
   - Make sure device_unique_id exists in your devices
   - Make sure room_number exists in your rooms

3. **Import the CSV**
   - Go to "Import Data" page
   - Select "Installation History" from dropdown
   - Choose your CSV file
   - Check "Skip duplicates" if you want to ignore errors
   - Click "Import CSV"

## Important Notes:

- **Device must exist**: The device_unique_id must match an existing device in the system
- **Room must exist**: The room_number must match an existing room in the system
- **Active installations**: A device can only have ONE active installation at a time
- **Withdrawn installations**: To import historical data, set withdrawn_date and status='withdrawn'
- **Installation types**: Use only `NEW_INSTALLATION`, `REPAIRED`, or `OLD_REINSTALL`
- **Date format**: Always use YYYY-MM-DD format for dates
- **Empty fields**: Leave fields empty (but keep the commas) if no data

## Troubleshooting:

### "Device not found" error
- Check that device_unique_id matches exactly (case-sensitive)
- Verify the device exists in your devices list

### "Room not found" error
- Check that room_number matches exactly (case-sensitive)
- Verify the room exists in your rooms list

### "Device already has an active installation" error
- This device already has an active installation
- Either import it as withdrawn (set withdrawn_date and status='withdrawn')
- Or withdraw the current installation first

### "Validation error" messages
- Check that dates are in YYYY-MM-DD format
- Check that installation_type is one of the three valid values
- Ensure required fields are not empty

## Changes from Old Template:

❌ **Removed fields:**
- `installation_time` (time component removed)
- `withdrawal_time` (time component removed)
- `data_entry_by` (automatically set to current user)

✅ **Added fields:**
- `team_members` - Track who helped with installation
- `installation_type` - Type of installation (NEW/REPAIRED/OLD)
- `issue_at_withdrawal` - Issues noted during withdrawal
- `storage_location` - Where withdrawn devices are stored
- `gate_pass_number` - Link to gate pass if applicable
- `gate_pass_date` - Date of gate pass

## Updated: January 22, 2026
