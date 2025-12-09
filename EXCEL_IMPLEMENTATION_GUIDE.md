# Excel Data Structure Implementation Guide

## Overview
This guide explains how the system has been programmed to match your Excel data structure for the "Classroom New Multimedia Install List - 2025" with withdraw tracking.

## Excel Structure Analysis

### Your Excel Sheet Structure:

**Left Section - Active Installations:**
- ID (Room Number): SAC 209, NAC 111P, etc.
- Location (Building): SAC, NAC, LIB
- Multimedia Brand: BENQ, VIEW SONIC, OPTIMA, MAXELL, HITACHI, BOXLIGHT
- Status: NEW, REPAIR, USED
- NSU ID: 50-ITD-0508-xxxxx (standardized format)
- Manufacture SL: Serial numbers
- Install Date: Installation dates
- TEAM: Technician names (can be multiple)

**Right Section - Withdraw Info:**
- Withdraw Location: @ symbol
- Status/Brand: Device brand when withdrawn
- NSU ID: Same standardized format
- Manufacture SL: Serial number
- Issue: Lamp Damage, Red Light Issue, Poor Focus, etc.
- Store: Basement, IT, WARREN Memo, etc.

## Database Schema Updates

### 1. New Fields Added to `devices` Table:
```sql
- device_status ENUM('NEW', 'REPAIR', 'USED', 'WITHDRAWN')
- current_issue VARCHAR(255) -- Current device issue
- storage_location VARCHAR(100) -- Where device is stored
```

### 2. New Fields Added to `device_installations` Table:
```sql
- team_members TEXT -- Comma-separated team member names
- issue_at_withdrawal VARCHAR(255) -- Issue found during withdrawal
- storage_location VARCHAR(100) -- Storage location after withdrawal
```

### 3. New Reference Tables Created:

**device_issues:**
- issue_id (Primary Key)
- issue_name (e.g., "Lamp Damage", "Poor Focus")
- issue_category (Hardware, Display, Power, Other)
- is_active

**storage_locations:**
- location_id (Primary Key)
- location_name (e.g., "Basement", "IT", "WARREN Memo")
- description
- is_active

### 4. New Device Brands Added:
- BENQ
- VIEW SONIC
- OPTIMA
- MAXELL
- HITACHI
- BOXLIGHT

## API Updates

### 1. **GET /api/metadata.php**
Now returns additional metadata:
```json
{
  "types": [...],
  "brands": [...],
  "issues": [
    {"issue_id": 1, "issue_name": "Lamp Damage", "issue_category": "Hardware"},
    {"issue_id": 2, "issue_name": "Poor Focus", "issue_category": "Display"}
  ],
  "storage_locations": [
    {"location_id": 1, "location_name": "Basement"},
    {"location_id": 2, "location_name": "IT"}
  ],
  "device_statuses": [
    {"value": "NEW", "label": "New"},
    {"value": "REPAIR", "label": "Repair"},
    {"value": "USED", "label": "Used"},
    {"value": "WITHDRAWN", "label": "Withdrawn"}
  ]
}
```

### 2. **GET /api/devices.php**
Now includes new fields in response:
```json
{
  "device_id": 1,
  "device_unique_id": "50-ITD-0508-00460",
  "device_status": "NEW",
  "current_issue": "Lamp Damage",
  "storage_location": "Basement",
  "brand_name": "BENQ",
  "serial_number": "VWJ2241B01148",
  "current_building": "SAC",
  "current_room_number": "SAC 209",
  ...
}
```

### 3. **POST /api/devices.php**
Accept new fields when creating devices:
```json
{
  "device_unique_id": "50-ITD-0508-00460",
  "type_id": 1,
  "brand_id": 5,
  "model": "MW536",
  "serial_number": "VWJ2241B01148",
  "device_status": "NEW",
  "current_issue": null,
  "storage_location": null,
  "purchase_date": "2025-01-14",
  "notes": ""
}
```

### 4. **GET /api/installations.php**
Enhanced to return:
```json
{
  "installation_id": 1,
  "device_unique_id": "50-ITD-0508-00460",
  "brand_name": "BENQ",
  "device_status": "NEW",
  "serial_number": "VWJ2241B01148",
  "room_number": "SAC 209",
  "building": "SAC",
  "installed_date": "2025-01-14",
  "team_members": "Arafat/Sabbir/Kayfan",
  "issue_at_withdrawal": null,
  "storage_location": null,
  ...
}
```

### 5. **POST /api/installations.php**
Accept team members:
```json
{
  "device_id": 1,
  "room_id": 5,
  "installed_date": "2025-01-14",
  "team_members": "Arafat/Sabbir/Kayfan",
  "installation_notes": "New multimedia installation"
}
```

### 6. **PUT /api/installations.php (Withdrawal)**
Accept issue and storage location:
```json
{
  "installation_id": 1,
  "withdrawn_date": "2025-12-07",
  "issue_at_withdrawal": "Lamp Damage",
  "storage_location": "Basement",
  "withdrawal_notes": "Device withdrawn due to lamp damage"
}
```

## Frontend Implementation Needed

### 1. **Update Device Form (devices.html)**
Add new fields to device creation/edit form:

```html
<!-- Device Status -->
<div class="form-group">
  <label>Device Status</label>
  <select id="deviceStatus" required>
    <option value="NEW">New</option>
    <option value="REPAIR">Repair</option>
    <option value="USED">Used</option>
    <option value="WITHDRAWN">Withdrawn</option>
  </select>
</div>

<!-- Current Issue -->
<div class="form-group">
  <label>Current Issue</label>
  <select id="currentIssue">
    <option value="">None</option>
    <!-- Populated from metadata API -->
  </select>
</div>

<!-- Storage Location -->
<div class="form-group">
  <label>Storage Location</label>
  <select id="storageLocation">
    <option value="">Not Stored</option>
    <!-- Populated from metadata API -->
  </select>
</div>
```

### 2. **Update Installation Form (installations.html)**
Add team members field:

```html
<!-- Team Members -->
<div class="form-group">
  <label>Team Members</label>
  <input type="text" id="teamMembers" 
         placeholder="e.g., Arafat/Sabbir/Kayfan">
  <small>Separate names with / (slash)</small>
</div>
```

### 3. **Update Withdrawal Form**
Add issue and storage fields:

```html
<!-- Issue at Withdrawal -->
<div class="form-group">
  <label>Issue Found</label>
  <select id="issueAtWithdrawal">
    <option value="">No Issue</option>
    <option value="Lamp Damage">Lamp Damage</option>
    <option value="Poor Focus">Poor Focus</option>
    <option value="Red Light Issue">Red Light Issue</option>
    <!-- Populated from metadata API -->
  </select>
</div>

<!-- Storage Location -->
<div class="form-group">
  <label>Storage Location</label>
  <select id="withdrawalStorage" required>
    <option value="">Select Storage</option>
    <option value="Basement">Basement</option>
    <option value="IT">IT</option>
    <option value="WARREN Memo">WARREN Memo</option>
    <!-- Populated from metadata API -->
  </select>
</div>
```

### 4. **Update Device Table Display**
Show new columns in the table:

```javascript
function displayDevices(devices) {
  const tableBody = document.querySelector('#devicesTable tbody');
  tableBody.innerHTML = devices.map(device => `
    <tr class="${device.device_status === 'REPAIR' ? 'status-repair' : ''}
              ${device.device_status === 'WITHDRAWN' ? 'status-withdrawn' : ''}">
      <td>${device.current_room_number || 'Not Installed'}</td>
      <td>${device.current_building || '-'}</td>
      <td>${device.brand_name}</td>
      <td><span class="badge badge-${device.device_status.toLowerCase()}">${device.device_status}</span></td>
      <td>${device.device_unique_id}</td>
      <td>${device.serial_number || '-'}</td>
      <td>${device.current_installation_date || '-'}</td>
      <td>${device.current_issue || '-'}</td>
      <td>${device.storage_location || '-'}</td>
      <td>
        <button onclick="editDevice(${device.device_id})">Edit</button>
        <button onclick="viewHistory(${device.device_id})">History</button>
      </td>
    </tr>
  `).join('');
}
```

### 5. **Add CSS for Status Colors**
Match Excel's color coding:

```css
.status-repair {
  background-color: #ffcccc !important;
}

.status-withdrawn {
  background-color: #ffddaa !important;
}

.badge-new {
  background-color: #4CAF50;
  color: white;
}

.badge-repair {
  background-color: #ff6b6b;
  color: white;
}

.badge-used {
  background-color: #ffd93d;
  color: black;
}

.badge-withdrawn {
  background-color: #95a5a6;
  color: white;
}
```

## Excel Import Functionality

To import your existing Excel data, create a new endpoint:

### **POST /api/import-excel.php**

This will:
1. Parse Excel file
2. Extract room information
3. Create devices if they don't exist
4. Create installations for active devices
5. Mark withdrawn devices appropriately

## Data Migration Steps

### Step 1: Run Database Migration
```bash
cd /Applications/XAMPP/xamppfiles/htdocs/nsuit-classroom-records
mysql -u root -p classroom_devices < database/migration_excel_compatibility.sql
```

### Step 2: Verify New Tables
```sql
SHOW TABLES LIKE 'device_issues';
SHOW TABLES LIKE 'storage_locations';
DESCRIBE devices; -- Should show new columns
DESCRIBE device_installations; -- Should show new columns
```

### Step 3: Test API Endpoints
```bash
# Test metadata endpoint
curl http://localhost/nsuit-classroom-records/backend/api/metadata.php \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Step 4: Update Frontend
- Modify device forms to include new fields
- Update installation forms for team tracking
- Add withdrawal issue/storage fields
- Update display tables to show new columns

## Field Mapping Reference

| Excel Column | Database Table | Database Field |
|--------------|---------------|----------------|
| ID (Room) | rooms | room_number |
| Location | rooms | building |
| Multimedia Brand | device_brands | brand_name |
| Status | devices | device_status |
| NSU ID | devices | device_unique_id |
| Manufacture SL | devices | serial_number |
| Install Date | device_installations | installed_date |
| TEAM | device_installations | team_members |
| Issue | devices / device_installations | current_issue / issue_at_withdrawal |
| Store | devices / device_installations | storage_location |

## Views for Excel-like Reports

Two SQL views have been created:

### 1. **view_excel_active_installations**
Shows active installations (left side of Excel)

### 2. **view_excel_withdrawn_devices**
Shows withdrawn devices (right side of Excel)

Use these for generating reports:
```sql
-- Get active installations report
SELECT * FROM view_excel_active_installations;

-- Get withdrawn devices report
SELECT * FROM view_excel_withdrawn_devices;
```

## Next Steps

1. ✅ Database migration completed
2. ✅ API endpoints updated
3. ✅ Metadata endpoint enhanced
4. ⏳ Update frontend forms
5. ⏳ Add Excel import functionality
6. ⏳ Create Excel export functionality
7. ⏳ Add color-coded status displays

## Testing Checklist

- [ ] Can create device with status NEW/REPAIR/USED
- [ ] Can assign issue to device
- [ ] Can set storage location
- [ ] Can create installation with team members
- [ ] Can withdraw device with issue tracking
- [ ] Metadata endpoint returns issues and storage locations
- [ ] Device list shows new columns
- [ ] Installation list shows team and issue information
- [ ] Color coding matches Excel format

---

**Created:** December 7, 2025  
**Based on:** DATA set 1 Test.xlsx  
**System:** NSU IT Classroom Records Management
