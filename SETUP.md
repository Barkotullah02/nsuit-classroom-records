# Quick Setup Guide

## Step-by-Step Installation

### 1️⃣ Import Database

Open phpMyAdmin (http://localhost/phpmyadmin) and:

1. Click "SQL" tab
2. Click "Import files" or paste the contents of `database/schema.sql`
3. Click "Go"

This creates the `classroom_devices` database with all tables and sample data.

### 2️⃣ Verify XAMPP is Running

Make sure both Apache and MySQL are running in XAMPP Control Panel.

### 3️⃣ Access the Application

Open your browser and go to:
```
http://localhost/nsuit-classroom-records/frontend/login.html
```

### 4️⃣ Login

**Admin User:**
- Username: `admin`
- Password: `admin123`

**Viewer User:**
- Username: `viewer`
- Password: `admin123`

## Default Data Included

### Device Types
- Multimedia Projector
- Monitor
- Speaker
- Keyboard
- Mouse

### Brands
- HP, Boxlight, A4Tech, Dell, Logitech, Sony, Epson, Samsung, LG, Microsoft

### Sample Rooms
- R101 - Computer Lab 1
- R102 - Computer Lab 2
- R201 - Conference Room
- R202 - Training Room
- R301 - Auditorium

## Testing the System

### Test 1: Add a Device (Admin Only)
1. Login as admin
2. Go to "Devices" page
3. Click "Add Device"
4. Fill in:
   - Device Unique ID: `PROJ-001`
   - Type: Multimedia Projector
   - Brand: Epson
   - Model: EB-2250U
5. Click "Save Device"

### Test 2: Install the Device
1. Go to "Installations" page
2. Click "Install Device"
3. Select the device you just created
4. Select a room (e.g., R101)
5. Set installation date to today
6. Click "Install Device"

### Test 3: View Device History
1. Go to "Devices" page
2. Find your device
3. Click "History" button
4. See the installation record

### Test 4: Withdraw Device
1. Go to "Installations" page
2. Find the active installation
3. Click "Withdraw"
4. Set withdrawal date
5. Click "Withdraw Device"

### Test 5: View as Viewer
1. Logout
2. Login as "viewer" / "admin123"
3. Notice you cannot:
   - Add/Edit/Delete devices
   - Only view and record installations

## Common Issues & Solutions

### ❌ "Connection Error"
**Solution:** Check that MySQL is running in XAMPP

### ❌ "Database not found"
**Solution:** Import the schema.sql file in phpMyAdmin

### ❌ "API Base URL" errors
**Solution:** Update the path in `frontend/js/config.js` to match your XAMPP htdocs structure

### ❌ Login page shows but login doesn't work
**Solution:** 
1. Check browser console for errors
2. Verify backend/api/auth.php is accessible
3. Check database users table has records

### ❌ Styles not loading
**Solution:** Clear browser cache and refresh

## Key Features to Explore

✅ **Automatic Lifetime Calculation** - Device lifetime is calculated from first installation date
✅ **Days in Room** - System tracks how long device stayed in each room
✅ **Soft Delete** - Deleted items can be restored (admin only)
✅ **Audit Trail** - All actions are logged in dashboard
✅ **Filtering** - Filter devices by type, brand, room, or ID
✅ **Role-Based Access** - Different permissions for viewers and admins

## Next Steps

1. **Change Default Passwords** (Important for production!)
2. **Add Your Own Rooms** - Edit in phpMyAdmin or add to schema.sql
3. **Add Device Types** - If you need additional device categories
4. **Customize Colors** - Edit CSS variables in frontend/css/style.css
5. **Add Real Data** - Start adding your actual devices

## File Structure Reference

```
nsuit-classroom-records/
├── database/
│   └── schema.sql              ← Import this first!
├── backend/
│   ├── config/
│   │   ├── database.php        ← Database connection settings
│   │   └── cors.php
│   ├── includes/
│   │   ├── auth.php
│   │   └── response.php
│   └── api/                    ← All API endpoints
│       ├── auth.php
│       ├── devices.php
│       ├── installations.php
│       ├── device-history.php
│       ├── rooms.php
│       ├── metadata.php
│       └── dashboard.php
└── frontend/
    ├── css/
    │   └── style.css           ← Customize colors here
    ├── js/
    │   ├── config.js           ← API URL configuration
    │   ├── utils.js
    │   ├── auth.js
    │   ├── dashboard.js
    │   ├── devices.js
    │   └── installations.js
    └── *.html                  ← UI pages
```

## Need Help?

Check the main README.md for:
- Complete API documentation
- Database schema details
- Advanced customization options
- Troubleshooting guide

---

**Happy Managing! 🎓📱💻**
