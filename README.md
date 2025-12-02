# Classroom Device Management System

A comprehensive web-based system for managing classroom equipment with detailed tracking of device installations, movements, and history.

## Features

### Core Functionality
- ✅ **Device Management**: Track multimedia projectors, monitors, speakers, keyboards, and mice
- ✅ **Installation Tracking**: Record when devices are installed or withdrawn from rooms
- ✅ **Lifetime Calculation**: Automatic calculation of device lifetime from first installation
- ✅ **Room History**: View complete history of where each device has been installed
- ✅ **User Roles**: Two user types (Viewer and Admin) with different permissions
- ✅ **Soft Delete**: Records are never permanently deleted, allowing recovery
- ✅ **Audit Trail**: Complete logging of all user actions

### User Permissions

**Viewer Role:**
- View all devices and their information
- View installation history
- Record new installations and withdrawals
- Filter and search devices

**Admin Role:**
- All viewer permissions
- Add, edit, and delete devices
- Soft delete records
- Restore deleted records
- Full access to audit logs

### Key Features
- **Automatic Lifetime Tracking**: System automatically calculates total lifetime from first installation date
- **Room Duration Tracking**: Tracks how many days each device stayed in each room
- **Unique Device IDs**: Each device has a unique identifier for easy tracking
- **Advanced Filtering**: Filter by room number, device type, and brand
- **Beautiful UI**: Modern, responsive interface with intuitive navigation
- **Separate Frontend/Backend**: Clean architecture with REST API backend

## Technology Stack

### Backend
- **PHP 7.4+**: Server-side logic
- **MySQL 5.7+**: Database
- **PDO**: Database abstraction layer
- **RESTful API**: Clean API architecture

### Frontend
- **HTML5**: Structure
- **CSS3**: Modern styling with CSS variables
- **JavaScript (ES6+)**: Client-side functionality
- **Font Awesome 6**: Icons

## Project Structure

```
nsuit-classroom-records/
├── database/
│   └── schema.sql                  # Database schema with tables, views, and procedures
├── backend/
│   ├── config/
│   │   ├── database.php           # Database connection configuration
│   │   └── cors.php               # CORS headers configuration
│   ├── includes/
│   │   ├── auth.php               # Authentication & session management
│   │   └── response.php           # Standardized API responses
│   └── api/
│       ├── auth.php               # Login/logout endpoints
│       ├── devices.php            # Device CRUD operations
│       ├── installations.php      # Installation/withdrawal operations
│       ├── device-history.php     # Device history endpoint
│       ├── rooms.php              # Room listing
│       ├── metadata.php           # Device types and brands
│       └── dashboard.php          # Dashboard statistics
└── frontend/
    ├── css/
    │   └── style.css              # Main stylesheet
    ├── js/
    │   ├── config.js              # API configuration
    │   ├── utils.js               # Utility functions
    │   ├── auth.js                # Login functionality
    │   ├── dashboard.js           # Dashboard page
    │   ├── devices.js             # Devices page
    │   └── installations.js       # Installations page
    ├── login.html                 # Login page
    ├── dashboard.html             # Dashboard
    ├── devices.html               # Device management
    └── installations.html         # Installation management
```

## Database Schema

### Main Tables

1. **users**: System users with role-based access
2. **rooms**: Classroom/room information
3. **device_types**: Categories of devices (projector, monitor, etc.)
4. **device_brands**: Device manufacturers
5. **devices**: Device inventory with unique IDs
6. **device_installations**: Installation and withdrawal records
7. **audit_log**: Complete audit trail of all actions
8. **sessions**: User session management

### Views

- **view_current_device_locations**: Current location of all devices
- **view_device_lifetime_stats**: Lifetime statistics for each device

### Stored Procedures

- **sp_get_device_history**: Get complete installation history for a device
- **sp_soft_delete_device**: Soft delete a device
- **sp_restore_device**: Restore a soft-deleted device

## Installation Instructions

### Prerequisites

- XAMPP (or similar) with:
  - Apache 2.4+
  - PHP 7.4+
  - MySQL 5.7+
- Modern web browser

### Step 1: Setup Database

1. Open phpMyAdmin or MySQL command line
2. Import the database schema:
   ```sql
   source /Applications/XAMPP/xamppfiles/htdocs/nsuit-classroom-records/database/schema.sql
   ```

The schema will create:
- Database: `classroom_devices`
- All necessary tables
- Sample data (rooms, device types, brands)
- Default users:
  - **Admin**: username: `admin`, password: `admin123`
  - **Viewer**: username: `viewer`, password: `admin123`

### Step 2: Configure Backend

1. Open `backend/config/database.php`
2. Update database credentials if needed:
   ```php
   private $host = "localhost";
   private $db_name = "classroom_devices";
   private $username = "root";
   private $password = "";
   ```

### Step 3: Configure Frontend

1. Open `frontend/js/config.js`
2. Update API base URL if needed:
   ```javascript
   API_BASE_URL: 'http://localhost/nsuit-classroom-records/backend/api'
   ```

### Step 4: Start Application

1. Start Apache and MySQL in XAMPP
2. Open browser and navigate to:
   ```
   http://localhost/nsuit-classroom-records/frontend/login.html
   ```

### Step 5: Login

Use one of the default accounts:

**Admin Account:**
- Username: `admin`
- Password: `admin123`

**Viewer Account:**
- Username: `viewer`
- Password: `admin123`

⚠️ **IMPORTANT**: Change these default passwords in production!

## Usage Guide

### Adding a Device

1. Login as Admin
2. Navigate to "Devices" page
3. Click "Add Device" button
4. Fill in device details:
   - Device Unique ID (required)
   - Device Type (required)
   - Brand (required)
   - Model, Serial Number (optional)
   - Purchase Date, Warranty Period (optional)
   - Notes (optional)
5. Click "Save Device"

### Installing a Device

1. Navigate to "Installations" page
2. Click "Install Device" button
3. Select device from dropdown (only uninstalled devices shown)
4. Select target room
5. Set installation date
6. Add optional notes
7. Click "Install Device"

### Withdrawing a Device

1. Navigate to "Installations" page
2. Find the active installation
3. Click "Withdraw" button
4. Set withdrawal date
5. Add optional notes
6. Click "Withdraw Device"

### Viewing Device History

1. Navigate to "Devices" page
2. Find the device in the table
3. Click "History" button
4. View complete installation history with:
   - Rooms where device was installed
   - Installation and withdrawal dates
   - Days spent in each room
   - Who installed/withdrew the device

### Filtering Devices

Use the filter panel to search by:
- Device ID (text search)
- Device Type (dropdown)
- Brand (dropdown)
- Current Room (dropdown)

### Dashboard

The dashboard shows:
- Total number of devices
- Active installations count
- Total rooms
- Devices by type (visual chart)
- Recent user activities

## API Documentation

### Authentication

**Login**
```
POST /api/auth.php
Body: { "username": "admin", "password": "admin123" }
Response: { "success": true, "data": { user object } }
```

**Logout**
```
DELETE /api/auth.php
Response: { "success": true, "message": "Logged out successfully" }
```

**Get Current User**
```
GET /api/auth.php
Response: { "success": true, "data": { user object } }
```

### Devices

**Get All Devices**
```
GET /api/devices.php
Query Params: ?type_id=1&brand_id=2&room_id=3&device_unique_id=ABC123
Response: { "success": true, "data": [ device objects ] }
```

**Create Device**
```
POST /api/devices.php
Body: { device object }
Response: { "success": true, "data": { "device_id": 123 } }
```

**Update Device**
```
PUT /api/devices.php
Body: { device object with device_id }
Response: { "success": true }
```

**Delete Device (Soft)**
```
DELETE /api/devices.php?device_id=123
Response: { "success": true }
```

### Installations

**Get Installations**
```
GET /api/installations.php
Query Params: ?room_id=1&device_id=2&status=active
Response: { "success": true, "data": [ installation objects ] }
```

**Install Device**
```
POST /api/installations.php
Body: { "device_id": 1, "room_id": 2, "installed_date": "2025-11-28", "installation_notes": "..." }
Response: { "success": true, "data": { "installation_id": 123 } }
```

**Withdraw Device**
```
PUT /api/installations.php
Body: { "installation_id": 123, "withdrawn_date": "2025-11-28", "withdrawal_notes": "..." }
Response: { "success": true }
```

### Other Endpoints

**Get Rooms**: `GET /api/rooms.php`
**Get Metadata**: `GET /api/metadata.php`
**Get Device History**: `GET /api/device-history.php?device_id=123`
**Get Dashboard Stats**: `GET /api/dashboard.php`

## Security Features

1. **Password Hashing**: All passwords stored using PHP's `password_hash()`
2. **Session Management**: Secure session handling with database storage
3. **Role-Based Access**: Admin and Viewer roles with different permissions
4. **SQL Injection Protection**: PDO prepared statements
5. **Audit Trail**: All actions logged with user, IP, and timestamp
6. **Soft Delete**: Prevents accidental data loss

## Customization

### Adding New Device Types

1. Go to phpMyAdmin
2. Navigate to `device_types` table
3. Insert new row with type name and description

### Adding New Brands

1. Go to phpMyAdmin
2. Navigate to `device_brands` table
3. Insert new row with brand name

### Adding New Rooms

1. Go to phpMyAdmin
2. Navigate to `rooms` table
3. Insert new row with room details

### Changing Colors

Edit `frontend/css/style.css` and modify CSS variables:
```css
:root {
    --primary-color: #4F46E5;
    --secondary-color: #10B981;
    --danger-color: #EF4444;
    /* ... more colors */
}
```

## Troubleshooting

### Database Connection Error
- Check MySQL is running in XAMPP
- Verify database credentials in `backend/config/database.php`
- Ensure `classroom_devices` database exists

### Login Not Working
- Check browser console for errors
- Verify API URL in `frontend/js/config.js`
- Check Apache is running
- Verify CORS headers are set correctly

### Devices Not Loading
- Check browser console for API errors
- Verify you're logged in
- Check database has data
- Verify API endpoints are accessible

### Style Issues
- Clear browser cache
- Check CSS file path is correct
- Verify Font Awesome CDN is accessible

## Future Enhancements

- [ ] Export data to Excel/PDF
- [ ] Advanced reporting and analytics
- [ ] Email notifications for warranty expiration
- [ ] Mobile app
- [ ] Barcode/QR code scanning
- [ ] Multi-language support
- [ ] Dark mode theme
- [ ] Batch device operations

## Support

For issues or questions, please refer to the code comments or contact the development team.

## License

This project is for educational/internal use. Modify as needed for your organization.

---

**Version**: 1.0.0  
**Last Updated**: November 28, 2025  
**Developer**: Custom Development Team
