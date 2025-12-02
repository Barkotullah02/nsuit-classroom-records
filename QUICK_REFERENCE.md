# Quick Reference Guide - Manual Entry & Gate Pass Features

## 🎯 Quick Start

### Installing a Device (Manual Entry)
```
1. Login → Installations page
2. Click "Install Device"
3. Fill required fields:
   ✓ Device *
   ✓ Room *
   ✓ Installation Date *
4. Optional fields:
   ○ Installer Name (defaults to your name if blank)
   ○ Installer ID (e.g., EMP-1234)
   ○ Gate Pass Number (e.g., GP-2024-001)
   ○ Gate Pass Date
   ○ Notes
5. Submit
```

### Withdrawing a Device
```
1. Find active installation
2. Click "Withdraw"
3. Fill required:
   ✓ Withdrawal Date *
4. Optional:
   ○ Withdrawer Name (defaults to your name)
   ○ Withdrawer ID
   ○ Notes
5. Submit
```

### Viewing/Printing Gate Pass
```
1. Installations page
2. Find record with gate pass
3. Click blue "Gate Pass" button
4. New window opens with NSU gate pass
5. Click "Print Gate Pass" or Ctrl+P
```

### Printing Device History
```
1. Go to Devices page
2. Click "View History" on any device
3. Review installation history
4. Click "Print History" button
5. Print dialog opens
```

---

## 📋 Field Descriptions

### Installer Name
- **Purpose**: Name of person who physically installed device
- **Default**: Your name (logged-in user)
- **Example**: "Ahmed Khan", "Technical Team"
- **Use Case**: Admin enters data, technician installs

### Installer ID
- **Purpose**: Employee/Staff ID of installer
- **Format**: Any text (EMP-XXX, TECH-XXX, etc.)
- **Example**: "EMP-1234", "TECH-456"

### Withdrawer Name
- **Purpose**: Name of person who physically withdrew device
- **Default**: Your name (logged-in user)
- **Example**: "Fatima Rahman"

### Withdrawer ID
- **Purpose**: Employee/Staff ID of withdrawer
- **Example**: "EMP-5678"

### Gate Pass Number
- **Purpose**: Reference number for device movement authorization
- **Format**: Any text (recommended: GP-YYYY-NNN)
- **Example**: "GP-2024-001", "GATEPASS-2024-JAN-001"

### Gate Pass Date
- **Purpose**: Date gate pass was issued
- **Format**: YYYY-MM-DD
- **Default**: Can be different from installation date

---

## 🔍 Understanding the Data

### What Gets Recorded:

#### When You Install:
```
installer_name:    "Ahmed Khan" (what you entered)
installer_id:      "EMP-1234" (what you entered)
installed_by:      5 (your user ID - automatic)
data_entry_by:     5 (your user ID - automatic)
```

#### What This Means:
- **Display shows**: "Installed by Ahmed Khan (EMP-1234)"
- **Audit trail shows**: You (user ID 5) entered this record
- **Benefit**: Separates who installed from who entered data

---

## 🖨️ Print Layouts

### Gate Pass Print:
- **Format**: A4 Portrait
- **Includes**:
  - NSU Logo (top center)
  - Gate Pass Number & Date
  - Device details table
  - Installer signature area
  - Security verification area
  - Receiving authority area
- **Hidden when printing**: Buttons, navigation

### Device History Print:
- **Format**: A4 Landscape
- **Includes**:
  - Device information card
  - Complete installation history table
  - Usage statistics
- **Hidden when printing**: Sidebar, buttons

---

## 💡 Common Scenarios

### Scenario 1: Admin Enters, Technician Installs
```
Logged in as: Admin (John Smith)
Installing device in: Room 301
Actual installer: Technician (Ahmed Khan, EMP-1234)

ACTION:
- Installer Name: "Ahmed Khan"
- Installer ID: "EMP-1234"
- Gate Pass: "GP-2024-001"

RESULT:
- Display: "Installed by Ahmed Khan (EMP-1234)"
- Audit: Data entered by John Smith
- Gate Pass: Shows Ahmed Khan as installer
```

### Scenario 2: Self Installation
```
Logged in as: Technician (Sarah Lee)
Installing device yourself

ACTION:
- Leave Installer Name blank
- Leave Installer ID blank

RESULT:
- Display: "Installed by Sarah Lee"
- System uses your name automatically
```

### Scenario 3: Withdrawal by Different Person
```
Logged in as: Admin (John Smith)
Device withdrawn by: Facilities (Mike Johnson, FAC-789)

ACTION:
- Withdrawer Name: "Mike Johnson"
- Withdrawer ID: "FAC-789"

RESULT:
- Display: "Withdrawn by Mike Johnson (FAC-789)"
- Audit: Record updated by John Smith
```

---

## ⚠️ Important Notes

### Gate Pass Button:
- Only shows if gate_pass_number is entered
- Opens in new window/tab
- Requires active login (JWT token)

### Manual Entry vs Auto:
- **Leave blank**: System uses your name
- **Enter name**: System uses what you typed
- **Audit trail**: Always tracks who entered data

### Required vs Optional:
- **Required**: Device, Room, Date
- **Optional**: All installer/withdrawer/gate pass fields
- **Flexible**: Enter only what you need

### Print Tips:
- Use Chrome/Edge for best print results
- Check print preview before printing
- Gate pass: Portrait orientation
- History: Landscape orientation
- Save as PDF option available

---

## 🔧 Troubleshooting

### Gate Pass Not Loading:
```
1. Check if logged in (JWT token valid)
2. Verify installation_id in URL
3. Check browser console for errors
4. Ensure backend API accessible
```

### Print Styles Not Applied:
```
1. Clear browser cache
2. Use Ctrl+Shift+R to hard refresh
3. Check @media print support in browser
4. Try different browser
```

### Fields Not Saving:
```
1. Check required fields filled
2. Verify date format (YYYY-MM-DD)
3. Check network tab for API errors
4. Ensure backend API updated
```

### Missing Gate Pass Button:
```
1. Ensure gate_pass_number was entered
2. Reload installations page
3. Check if installation record has gate_pass_number in database
```

---

## 📊 Reports Available

### 1. Installations List
- Shows all installations
- Filter by room, status
- Gate Pass button for records with GP number

### 2. Device History
- Shows complete installation timeline
- Installer/withdrawer details with IDs
- Gate pass numbers displayed
- Data entry person shown
- Print-friendly format

### 3. Gate Pass Document
- NSU official format
- Device details table
- Signature sections
- Professional print layout

---

## 🎓 Best Practices

### Data Entry:
1. ✅ Always enter installer name if different from you
2. ✅ Use consistent gate pass number format (GP-YYYY-NNN)
3. ✅ Enter gate pass date when issued
4. ✅ Add meaningful installation notes
5. ✅ Record employee IDs for accountability

### Gate Pass Management:
1. ✅ Generate gate pass before moving device
2. ✅ Print and attach to device during transit
3. ✅ Keep gate pass number sequential
4. ✅ File printed copies for records

### Audit Trail:
1. ✅ System automatically tracks who entered data
2. ✅ Manual names show who did physical work
3. ✅ Both pieces of information preserved
4. ✅ Complete accountability maintained

---

## 📞 Need Help?

### Check These First:
1. Browser console for JavaScript errors
2. Network tab for API call failures
3. XAMPP logs for PHP errors
4. MySQL logs for database issues

### Common Solutions:
- **Clear cache**: Ctrl+Shift+Delete
- **Hard refresh**: Ctrl+Shift+R
- **Restart XAMPP**: Apache + MySQL
- **Check JWT**: localStorage.getItem('token')

---

## ✨ Feature Highlights

### What's New:
✅ Manual installer/withdrawer entry
✅ Gate pass number tracking
✅ NSU-format gate pass template
✅ Print functionality
✅ Complete audit trail
✅ Flexible workflow support
✅ Professional documentation

### Benefits:
🎯 Real-world workflow support
🎯 Separation of data entry and physical work
🎯 Complete accountability
🎯 Official documentation
🎯 Print-ready formats
🎯 Audit compliance

---

*Last Updated: Implementation Complete*
*Version: 2.0 - Manual Entry & Gate Pass*
