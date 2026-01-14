# User Roles & Permissions Implementation

## Overview
The system now supports three distinct user roles with specific permissions:

## User Roles

### 1. **Admin** (Super User)
- **Full system access**
- Can create, edit, and delete ALL data
- Can manage users (create, edit, deactivate)
- Can view all reports and data
- Only role that can modify existing data
- Only role that can access User Management page

### 2. **Staff** (Data Entry)
- **Can ONLY ADD new data**
- Cannot edit existing data
- Cannot delete data
- Can view all reports and data
- Ideal for data entry personnel

### 3. **Viewer** (Read-Only)
- **Can ONLY VIEW data**
- Cannot add, edit, or delete anything
- Can view all reports
- Ideal for guests or auditors

## Permission Matrix

| Action | Admin | Staff | Viewer |
|--------|-------|-------|--------|
| **View Data** | ✅ | ✅ | ✅ |
| **Add New Data** | ✅ | ✅ | ❌ |
| **Edit Existing Data** | ✅ | ❌ | ❌ |
| **Delete Data** | ✅ | ❌ | ❌ |
| **Manage Users** | ✅ | ❌ | ❌ |
| **View Reports** | ✅ | ✅ | ✅ |

## API Permissions

### Devices API (`/api/devices.php`)
- **GET** (View): All authenticated users
- **POST** (Add): Admin + Staff
- **PUT** (Edit): Admin only
- **DELETE**: Admin only

### Installations API (`/api/installations.php`)
- **GET** (View): All authenticated users
- **POST** (Add): Admin + Staff
- **PUT** (Withdraw): Admin only
- **DELETE**: Admin only

### Rooms API (`/api/rooms.php`)
- **GET** (View): All authenticated users
- **POST** (Add): Admin + Staff
- **PUT** (Edit): Admin only
- **DELETE**: Admin only

### Users API (`/api/users.php`)
- **GET** (View): Admin only
- **POST** (Create): Admin only
- **PUT** (Edit): Admin only
- **DELETE**: Admin only

## Testing Results ✅

### Test 1: Admin Login
- ✅ Admin can successfully login
- ✅ Receives JWT token with admin role

### Test 2: Staff Login
- ✅ Staff can successfully login
- ✅ Receives JWT token with staff role

### Test 3: Staff Can Add Device
- ✅ Staff successfully created device (ID: 17)
- ✅ POST request accepted with staff token

### Test 4: Staff CANNOT Edit Device
- ✅ Staff attempt to edit device was **DENIED**
- ✅ Error: "Admin access required"

### Test 5: Admin CAN Edit Device
- ✅ Admin successfully updated device
- ✅ PUT request accepted with admin token

### Test 6: Viewer Login
- ✅ Viewer can successfully login
- ✅ Receives JWT token with viewer role

### Test 7: Viewer CAN Read Devices
- ✅ Viewer successfully retrieved all devices (17 total)
- ✅ GET request accepted

### Test 8: Viewer CANNOT Add Device
- ✅ Viewer attempt to add device was **DENIED**
- ✅ Error: "You do not have permission to add data. Contact administrator."

## Implementation Details

### Backend Changes

#### Auth Middleware (`/backend/includes/auth.php`)
Added new permission methods:
- `canCreate()` - Checks if user is admin or staff
- `requireCreate()` - Enforces create permission (admin/staff only)
- Updated `hasPermission()` to support 'create', 'edit', 'delete' actions

#### API Endpoints Updated
1. **devices.php**
   - POST: Uses `requireCreate()` (admin + staff)
   - PUT: Uses `requireAdmin()` (admin only)

2. **installations.php**
   - POST: Uses `requireCreate()` (admin + staff)
   - PUT: Uses `requireAdmin()` (admin only)

3. **rooms.php**
   - POST: Uses `requireCreate()` (admin + staff)
   - PUT: Uses `requireAdmin()` (admin only)

### Frontend Changes

#### User Management Page (`/frontend/users.html`)
Updated permissions display:
- Staff: "Add new data only" (removed "Edit existing data")
- Clearly shows staff cannot edit or delete

#### Navigation
- User Management menu only visible to admins
- Automatically shown via `utils.js` based on user role

## Usage

### For Administrators
1. Login with admin credentials
2. Access User Management page
3. Create new users with appropriate roles
4. Manage all data (add, edit, delete)

### For Staff
1. Login with staff credentials
2. Can add new devices, rooms, installations
3. Cannot edit or delete existing data
4. Can view all reports

### For Viewers
1. Login with viewer credentials
2. Can view all data and reports
3. Cannot make any changes

## Security Notes
- All permissions enforced at API level
- JWT tokens contain user role
- Frontend UI elements are hidden/shown based on role
- Backend validates ALL requests regardless of frontend
- Prevents privilege escalation

## Default Users
- **Admin**: username `admin`, password `admin123`
- **Viewer**: username `viewer`, password `viewer123`
- **Staff**: Created by admin as needed

## Future Enhancements
- Audit logging for all actions
- User activity tracking
- Role-based dashboard widgets
- Custom permission levels
