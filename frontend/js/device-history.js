/**
 * Device History Module
 * Displays detailed history for a specific device
 */

let deviceId = null;

document.addEventListener('DOMContentLoaded', async () => {
    // Check authentication
    Utils.requireAuth();

    // Get device ID from URL
    const urlParams = new URLSearchParams(window.location.search);
    deviceId = urlParams.get('id');

    if (!deviceId) {
        Utils.showAlert('Device ID not provided', 'error');
        setTimeout(() => {
            window.location.href = 'devices.html';
        }, 2000);
        return;
    }

    await loadDeviceDetails();
    await loadDeviceHistory();
});

/**
 * Load device details
 */
async function loadDeviceDetails() {
    try {
        const result = await Utils.apiRequest(`${CONFIG.ENDPOINTS.DEVICES}?device_id=${deviceId}`, {
            method: 'GET'
        });

        if (result.success && result.data.length > 0) {
            const device = result.data[0];
            displayDeviceDetails(device);
        } else {
            document.getElementById('deviceDetails').innerHTML = '<p class="text-center">Device not found</p>';
        }
    } catch (error) {
        console.error('Error loading device details:', error);
        document.getElementById('deviceDetails').innerHTML = '<p class="text-center text-error">Failed to load device details</p>';
    }
}

/**
 * Display device details
 */
function displayDeviceDetails(device) {
    const deviceInfo = document.getElementById('deviceInfo');
    deviceInfo.textContent = `${device.device_unique_id} - ${device.type_name} (${device.brand_name})`;

    const statusBadge = device.is_active 
        ? '<span class="badge badge-success">Active</span>' 
        : '<span class="badge badge-danger">Inactive</span>';

    const currentRoom = device.current_room_number 
        ? `${device.current_room_number} - ${device.current_room_name}` 
        : '<span class="text-muted">Not currently installed</span>';

    const lifetime = device.total_lifetime_days !== null
        ? Utils.formatDays(device.total_lifetime_days)
        : 'N/A';

    const html = `
        <div class="details-grid" style="display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 20px;">
            <div>
                <strong>Device ID:</strong><br>
                <span style="font-size: 18px; color: var(--primary-color);">${device.device_unique_id}</span>
            </div>
            <div>
                <strong>Type:</strong><br>
                ${device.type_name}
            </div>
            <div>
                <strong>Brand:</strong><br>
                ${device.brand_name}
            </div>
            <div>
                <strong>Model:</strong><br>
                ${device.model || 'N/A'}
            </div>
            <div>
                <strong>Serial Number:</strong><br>
                ${device.serial_number || 'N/A'}
            </div>
            <div>
                <strong>Purchase Date:</strong><br>
                ${device.purchase_date ? Utils.formatDate(device.purchase_date) : 'N/A'}
            </div>
            <div>
                <strong>Warranty Period:</strong><br>
                ${device.warranty_period ? device.warranty_period + ' months' : 'N/A'}
            </div>
            <div>
                <strong>Status:</strong><br>
                ${statusBadge}
            </div>
            <div>
                <strong>Current Room:</strong><br>
                ${currentRoom}
            </div>
            <div>
                <strong>Total Lifetime:</strong><br>
                <span style="font-size: 18px; color: var(--success-color);">${lifetime}</span>
            </div>
            ${device.notes ? `
            <div style="grid-column: 1 / -1;">
                <strong>Notes:</strong><br>
                ${device.notes}
            </div>
            ` : ''}
        </div>
    `;

    document.getElementById('deviceDetails').innerHTML = html;
}

/**
 * Load device installation history
 */
async function loadDeviceHistory() {
    try {
        const result = await Utils.apiRequest(`${CONFIG.ENDPOINTS.DEVICE_HISTORY}?device_id=${deviceId}`, {
            method: 'GET'
        });

        if (result.success) {
            displayHistory(result.data);
            calculateStatistics(result.data);
        } else {
            console.error('Failed to load history:', result.message);
            document.getElementById('historyTableBody').innerHTML = 
                '<tr><td colspan="8" class="text-center">No history found</td></tr>';
        }
    } catch (error) {
        console.error('Error loading history:', error);
        document.getElementById('historyTableBody').innerHTML = 
            '<tr><td colspan="8" class="text-center text-error">Failed to load history</td></tr>';
    }
}

/**
 * Display installation history
 */
function displayHistory(history) {
    const tbody = document.getElementById('historyTableBody');

    if (!history || history.length === 0) {
        tbody.innerHTML = '<tr><td colspan="8" class="text-center">No installation history found</td></tr>';
        return;
    }

    let html = '';
    history.forEach(record => {
        const statusBadge = record.status === 'active' 
            ? '<span class="badge badge-success">Active</span>' 
            : '<span class="badge badge-warning">Withdrawn</span>';

        const installedBy = record.installed_by + (record.installed_by_id ? ` (${record.installed_by_id})` : '');
        const withdrawnBy = record.withdrawn_by ? record.withdrawn_by + (record.withdrawn_by_id ? ` (${record.withdrawn_by_id})` : '') : 'N/A';

        html += `
            <tr>
                <td><strong>${record.room_number} - ${record.room_name}</strong></td>
                <td>N/A</td>
                <td>${Utils.formatDate(record.installed_date)}</td>
                <td>${record.withdrawn_date ? Utils.formatDate(record.withdrawn_date) : '<span class="text-muted">Still installed</span>'}</td>
                <td><strong>${record.days_in_room} days</strong></td>
                <td>${statusBadge}</td>
                <td>${installedBy}${record.gate_pass_number ? `<br><small>GP: ${record.gate_pass_number}</small>` : ''}</td>
                <td>${withdrawnBy}${record.data_entry_by ? `<br><small>Entry: ${record.data_entry_by}</small>` : ''}</td>
            </tr>
        `;
    });

    tbody.innerHTML = html;
}

/**
 * Calculate and display statistics
 */
function calculateStatistics(history) {
    if (!history || history.length === 0) {
        return;
    }

    const totalInstallations = history.length;
    const totalDays = history.reduce((sum, record) => sum + parseInt(record.days_in_room || 0), 0);
    const uniqueRooms = new Set(history.map(record => record.room_id)).size;
    const avgDaysPerRoom = totalInstallations > 0 ? Math.round(totalDays / totalInstallations) : 0;

    document.getElementById('totalInstallations').textContent = totalInstallations;
    document.getElementById('totalDays').textContent = totalDays;
    document.getElementById('roomsUsed').textContent = uniqueRooms;
    document.getElementById('avgDaysPerRoom').textContent = avgDaysPerRoom;
}
