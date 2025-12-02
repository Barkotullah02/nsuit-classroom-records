/**
 * Deleted Items Management
 */

let deletedItems = { devices: [], rooms: [] };
let currentRestoreItem = null;
let currentDeleteItem = null;

/**
 * Initialize page
 */
document.addEventListener('DOMContentLoaded', function() {
    // Check if user is authenticated
    const user = Utils.getCurrentUser();
    console.log('Current user:', user);
    
    if (!user) {
        console.log('No user found, redirecting to login');
        window.location.href = 'login.html';
        return;
    }
    
    console.log('User role:', user.role);
    
    // Check if user is admin
    if (user.role !== 'admin') {
        console.log('User is not admin, redirecting to dashboard');
        alert('Access denied. Admin privileges required.');
        window.location.href = 'dashboard.html';
        return;
    }
    
    console.log('User is admin, loading deleted items');
    loadUserInfo();
    loadDeletedItems();
});

/**
 * Load user information
 */
function loadUserInfo() {
    const user = Utils.getCurrentUser();
    if (user) {
        document.getElementById('userName').textContent = user.full_name;
        document.getElementById('userRole').textContent = user.role.charAt(0).toUpperCase() + user.role.slice(1);
    }
}

/**
 * Load deleted items from API
 */
async function loadDeletedItems() {
    try {
        console.log('CONFIG:', CONFIG);
        console.log('CONFIG.ENDPOINTS:', CONFIG.ENDPOINTS);
        console.log('CONFIG.ENDPOINTS.DELETED_ITEMS:', CONFIG.ENDPOINTS.DELETED_ITEMS);
        
        const result = await Utils.apiRequest(CONFIG.ENDPOINTS.DELETED_ITEMS, {
            method: 'GET'
        });

        if (result.success) {
            deletedItems = result.data;
            displayDeletedDevices();
            displayDeletedRooms();
        } else {
            throw new Error(result.message);
        }
    } catch (error) {
        console.error('Error loading deleted items:', error);
        showNotification('Failed to load deleted items: ' + error.message, 'error');
    }
}

/**
 * Display deleted devices
 */
function displayDeletedDevices() {
    const tbody = document.getElementById('deletedDevicesTableBody');
    
    if (!deletedItems.devices || deletedItems.devices.length === 0) {
        tbody.innerHTML = '<tr><td colspan="8" class="text-center text-muted">No deleted devices</td></tr>';
        return;
    }

    tbody.innerHTML = deletedItems.devices.map(device => `
        <tr>
            <td><span class="badge badge-secondary">${escapeHtml(device.device_unique_id)}</span></td>
            <td>${escapeHtml(device.type_name || 'N/A')}</td>
            <td>${escapeHtml(device.brand_name || 'N/A')}</td>
            <td>${escapeHtml(device.model || 'N/A')}</td>
            <td>${escapeHtml(device.serial_number || 'N/A')}</td>
            <td>${escapeHtml(device.deleted_by_name || 'Unknown')}</td>
            <td>${formatDateTime(device.deleted_at)}</td>
            <td>
                <button class="btn btn-sm btn-success" onclick="showRestoreModal('device', ${device.device_id}, '${escapeHtml(device.device_unique_id)}')">
                    <i class="fas fa-trash-restore"></i> Restore
                </button>
                <button class="btn btn-sm btn-danger" onclick="showPermanentDeleteModal('device', ${device.device_id}, '${escapeHtml(device.device_unique_id)}')">
                    <i class="fas fa-trash"></i> Delete
                </button>
            </td>
        </tr>
    `).join('');
}

/**
 * Display deleted rooms
 */
function displayDeletedRooms() {
    const tbody = document.getElementById('deletedRoomsTableBody');
    
    if (!deletedItems.rooms || deletedItems.rooms.length === 0) {
        tbody.innerHTML = '<tr><td colspan="7" class="text-center text-muted">No deleted rooms</td></tr>';
        return;
    }

    tbody.innerHTML = deletedItems.rooms.map(room => `
        <tr>
            <td><span class="badge badge-primary">${escapeHtml(room.room_number)}</span></td>
            <td>${escapeHtml(room.room_name)}</td>
            <td>${escapeHtml(room.building || 'N/A')}</td>
            <td>${escapeHtml(room.floor || 'N/A')}</td>
            <td>${room.capacity || 'N/A'}</td>
            <td>${formatDateTime(room.deleted_at)}</td>
            <td>
                <button class="btn btn-sm btn-success" onclick="showRestoreModal('room', ${room.room_id}, '${escapeHtml(room.room_number)} - ${escapeHtml(room.room_name)}')">
                    <i class="fas fa-trash-restore"></i> Restore
                </button>
                <button class="btn btn-sm btn-danger" onclick="showPermanentDeleteModal('room', ${room.room_id}, '${escapeHtml(room.room_number)} - ${escapeHtml(room.room_name)}')">
                    <i class="fas fa-trash"></i> Delete
                </button>
            </td>
        </tr>
    `).join('');
}

/**
 * Switch tabs
 */
function switchTab(event, tab) {
    // Update tab buttons
    document.querySelectorAll('.tab-btn').forEach(btn => btn.classList.remove('active'));
    event.target.classList.add('active');
    
    // Update tab content
    document.querySelectorAll('.tab-content').forEach(content => content.classList.remove('active'));
    document.getElementById(tab + 'Tab').classList.add('active');
}

/**
 * Show restore modal
 */
function showRestoreModal(type, id, name) {
    currentRestoreItem = { type, id, name };
    document.getElementById('restoreType').textContent = type;
    document.getElementById('restoreItemName').textContent = name;
    document.getElementById('restoreModal').classList.add('active');
}

/**
 * Close restore modal
 */
function closeRestoreModal() {
    document.getElementById('restoreModal').classList.remove('active');
    currentRestoreItem = null;
}

/**
 * Confirm restore
 */
async function confirmRestore() {
    if (!currentRestoreItem) return;

    try {
        const result = await Utils.apiRequest(CONFIG.ENDPOINTS.DELETED_ITEMS, {
            method: 'POST',
            body: JSON.stringify({
                type: currentRestoreItem.type,
                id: currentRestoreItem.id
            })
        });

        if (result.success) {
            showNotification(`${currentRestoreItem.type.charAt(0).toUpperCase() + currentRestoreItem.type.slice(1)} restored successfully`, 'success');
            closeRestoreModal();
            loadDeletedItems(); // Reload the list
        } else {
            throw new Error(result.message);
        }
    } catch (error) {
        console.error('Error restoring item:', error);
        showNotification('Failed to restore item: ' + error.message, 'error');
    }
}

/**
 * Show permanent delete modal
 */
function showPermanentDeleteModal(type, id, name) {
    currentDeleteItem = { type, id, name };
    document.getElementById('deleteType').textContent = type;
    document.getElementById('deleteItemName').textContent = name;
    document.getElementById('permanentDeleteModal').classList.add('active');
}

/**
 * Close permanent delete modal
 */
function closePermanentDeleteModal() {
    document.getElementById('permanentDeleteModal').classList.remove('active');
    currentDeleteItem = null;
}

/**
 * Confirm permanent delete
 */
async function confirmPermanentDelete() {
    if (!currentDeleteItem) return;

    try {
        const result = await Utils.apiRequest(CONFIG.ENDPOINTS.DELETED_ITEMS, {
            method: 'DELETE',
            body: JSON.stringify({
                type: currentDeleteItem.type,
                id: currentDeleteItem.id
            })
        });

        if (result.success) {
            showNotification(`${currentDeleteItem.type.charAt(0).toUpperCase() + currentDeleteItem.type.slice(1)} permanently deleted`, 'success');
            closePermanentDeleteModal();
            loadDeletedItems(); // Reload the list
        } else {
            throw new Error(result.message);
        }
    } catch (error) {
        console.error('Error deleting item:', error);
        showNotification('Failed to delete item: ' + error.message, 'error');
    }
}

/**
 * Format datetime
 */
function formatDateTime(dateString) {
    if (!dateString) return 'N/A';
    const date = new Date(dateString);
    return date.toLocaleString('en-US', {
        year: 'numeric',
        month: 'short',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    });
}

/**
 * Show notification
 */
function showNotification(message, type = 'info') {
    const notification = document.createElement('div');
    notification.className = `notification notification-${type}`;
    notification.innerHTML = `
        <i class="fas fa-${type === 'success' ? 'check-circle' : type === 'error' ? 'exclamation-circle' : 'info-circle'}"></i>
        <span>${message}</span>
    `;
    
    notification.style.cssText = `
        position: fixed;
        top: 20px;
        right: 20px;
        background: ${type === 'success' ? '#4caf50' : type === 'error' ? '#f44336' : '#2196f3'};
        color: white;
        padding: 15px 20px;
        border-radius: 5px;
        box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        z-index: 10000;
        display: flex;
        align-items: center;
        gap: 10px;
        animation: slideIn 0.3s ease-out;
    `;
    
    document.body.appendChild(notification);
    
    setTimeout(() => {
        notification.style.animation = 'slideOut 0.3s ease-in';
        setTimeout(() => notification.remove(), 300);
    }, 5000);
}

/**
 * Escape HTML to prevent XSS
 */
function escapeHtml(text) {
    if (!text) return '';
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

// Close modals when clicking outside
window.addEventListener('click', function(event) {
    if (event.target.id === 'restoreModal') {
        closeRestoreModal();
    }
    if (event.target.id === 'permanentDeleteModal') {
        closePermanentDeleteModal();
    }
});
