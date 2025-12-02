/**
 * Installations Module
 * Handles device installation and withdrawal
 */

let rooms = [];
let devices = [];
let installations = [];

document.addEventListener('DOMContentLoaded', async () => {
    await loadRooms();
    await loadDevices();
    await loadInstallations();

    initializeEventListeners();
});

/**
 * Initialize event listeners
 */
function initializeEventListeners() {
    // Add installation button
    document.getElementById('addInstallationBtn').addEventListener('click', () => openInstallModal());

    // Modal close buttons
    document.getElementById('closeInstallModalBtn').addEventListener('click', closeInstallModal);
    document.getElementById('cancelInstallBtn').addEventListener('click', closeInstallModal);
    document.getElementById('closeWithdrawModalBtn').addEventListener('click', closeWithdrawModal);
    document.getElementById('cancelWithdrawBtn').addEventListener('click', closeWithdrawModal);
    document.getElementById('closeAddRoomModalBtn').addEventListener('click', closeAddRoomModal);
    document.getElementById('cancelAddRoomBtn').addEventListener('click', closeAddRoomModal);

    // Form submits
    document.getElementById('installForm').addEventListener('submit', handleInstallSubmit);
    document.getElementById('withdrawForm').addEventListener('submit', handleWithdrawSubmit);
    document.getElementById('addRoomForm').addEventListener('submit', handleAddRoomSubmit);

    // Add room button (admin only)
    if (Utils.isAdmin()) {
        document.getElementById('addRoomBtn').style.display = 'block';
        document.getElementById('addRoomBtn').addEventListener('click', () => openAddRoomModal());
    }

    // Filter listeners
    document.getElementById('filterRoom').addEventListener('change', () => loadInstallations());
    document.getElementById('filterStatus').addEventListener('change', () => loadInstallations());
    document.getElementById('clearFiltersBtn').addEventListener('click', clearFilters);

    // Set default date to today
    const today = new Date().toISOString().split('T')[0];
    document.getElementById('installedDate').value = today;
    document.getElementById('withdrawnDate').value = today;
}

/**
 * Load rooms
 */
async function loadRooms() {
    const result = await Utils.apiRequest(CONFIG.ENDPOINTS.ROOMS, {
        method: 'GET'
    });

    if (result.success) {
        rooms = result.data;
        populateRoomDropdowns();
    }
}

/**
 * Load devices (only those not currently installed)
 */
async function loadDevices() {
    const result = await Utils.apiRequest(CONFIG.ENDPOINTS.DEVICES, {
        method: 'GET'
    });

    if (result.success) {
        // Filter to only show devices without active installations
        devices = result.data.filter(device => !device.current_room_id);
        populateDeviceDropdown();
    }
}

/**
 * Load installations
 */
async function loadInstallations() {
    const params = new URLSearchParams();
    
    const roomId = document.getElementById('filterRoom').value;
    const status = document.getElementById('filterStatus').value;

    if (roomId) params.append('room_id', roomId);
    if (status) params.append('status', status);

    const queryString = params.toString();
    const url = CONFIG.ENDPOINTS.INSTALLATIONS + (queryString ? '?' + queryString : '');

    const result = await Utils.apiRequest(url, {
        method: 'GET'
    });

    if (result.success) {
        installations = result.data;
        displayInstallations(installations);
    } else {
        console.error('Failed to load installations:', result.message);
    }
}

/**
 * Display installations in table
 */
function displayInstallations(installationsList) {
    const tbody = document.getElementById('installationsTableBody');
    
    if (!installationsList || installationsList.length === 0) {
        tbody.innerHTML = '<tr><td colspan="8" class="text-center">No installation records found</td></tr>';
        return;
    }

    let html = '';
    installationsList.forEach(inst => {
        const statusBadge = inst.status === 'active' 
            ? '<span class="badge badge-success">Active</span>' 
            : '<span class="badge badge-warning">Withdrawn</span>';

        html += `
            <tr>
                <td><strong>${inst.device_unique_id}</strong></td>
                <td>${inst.type_name}</td>
                <td>${inst.brand_name} ${inst.model || ''}</td>
                <td>${inst.room_number} - ${inst.room_name}</td>
                <td>${Utils.formatDate(inst.installed_date)}</td>
                <td>${inst.days_in_room} days</td>
                <td>${statusBadge}</td>
                <td>
                    ${inst.gate_pass_number ? `
                        <button class="btn btn-sm btn-info" onclick="viewGatePass(${inst.installation_id})" title="View Gate Pass">
                            <i class="fas fa-file-alt"></i> Gate Pass
                        </button>
                    ` : ''}
                    ${inst.status === 'active' ? `
                        <button class="btn btn-sm btn-danger" onclick="openWithdrawModal(${inst.installation_id}, '${inst.device_unique_id}', '${inst.room_number}')">
                            <i class="fas fa-sign-out-alt"></i> Withdraw
                        </button>
                    ` : `
                        <span class="text-muted">Withdrawn on ${Utils.formatDate(inst.withdrawn_date)}</span>
                    `}
                    ${Utils.isAdmin() && inst.status === 'withdrawn' ? `
                        <button class="btn btn-sm btn-danger" onclick="deleteInstallation(${inst.installation_id})">
                            <i class="fas fa-trash"></i> Delete
                        </button>
                    ` : ''}
                </td>
            </tr>
        `;
    });

    tbody.innerHTML = html;
}

/**
 * View gate pass
 */
function viewGatePass(installationId) {
    window.open(`gate-pass.html?id=${installationId}`, '_blank', 'width=900,height=800');
}

/**
 * Populate room dropdowns
 */
function populateRoomDropdowns() {
    const filterRoom = document.getElementById('filterRoom');
    const roomSelect = document.getElementById('roomSelect');

    rooms.forEach(room => {
        const option = `<option value="${room.room_id}">${room.room_number} - ${room.room_name}</option>`;
        filterRoom.innerHTML += option;
        roomSelect.innerHTML += option;
    });
}

/**
 * Populate device dropdown
 */
function populateDeviceDropdown() {
    const deviceSelect = document.getElementById('deviceSelect');
    deviceSelect.innerHTML = '<option value="">Choose a device...</option>';

    devices.forEach(device => {
        deviceSelect.innerHTML += `
            <option value="${device.device_id}">
                ${device.device_unique_id} - ${device.type_name} (${device.brand_name})
            </option>
        `;
    });
}

/**
 * Clear filters
 */
function clearFilters() {
    document.getElementById('filterRoom').value = '';
    document.getElementById('filterStatus').value = '';
    loadInstallations();
}

/**
 * Open install modal
 */
function openInstallModal() {
    const modal = document.getElementById('installModal');
    document.getElementById('installForm').reset();
    
    const today = new Date().toISOString().split('T')[0];
    document.getElementById('installedDate').value = today;
    
    modal.classList.add('active');
}

/**
 * Close install modal
 */
function closeInstallModal() {
    document.getElementById('installModal').classList.remove('active');
}

/**
 * Handle install form submit
 */
async function handleInstallSubmit(e) {
    e.preventDefault();

    const installData = {
        device_id: document.getElementById('deviceSelect').value,
        room_id: document.getElementById('roomSelect').value,
        installed_date: document.getElementById('installedDate').value,
        installation_notes: document.getElementById('installationNotes').value.trim(),
        installer_name: document.getElementById('installerName').value.trim() || null,
        installer_id: document.getElementById('installerId').value.trim() || null,
        gate_pass_number: document.getElementById('gatePassNumber').value.trim() || null,
        gate_pass_date: document.getElementById('gatePassDate').value || null
    };

    const result = await Utils.apiRequest(CONFIG.ENDPOINTS.INSTALLATIONS, {
        method: 'POST',
        body: JSON.stringify(installData)
    });

    if (result.success) {
        closeInstallModal();
        await loadDevices(); // Reload to update available devices
        await loadInstallations();
        Utils.showAlert('Device installed successfully!', 'success');
    } else {
        Utils.showAlert('Error: ' + result.message, 'error');
    }
}

/**
 * Open withdraw modal
 */
function openWithdrawModal(installationId, deviceId, roomNumber) {
    const modal = document.getElementById('withdrawModal');
    const form = document.getElementById('withdrawForm');
    const info = document.getElementById('withdrawDeviceInfo');

    form.reset();
    document.getElementById('withdrawInstallationId').value = installationId;
    
    const today = new Date().toISOString().split('T')[0];
    document.getElementById('withdrawnDate').value = today;

    info.innerHTML = `
        <div style="background-color: var(--bg-color); padding: 16px; border-radius: 8px;">
            <p><strong>Device:</strong> ${deviceId}</p>
            <p><strong>Current Room:</strong> ${roomNumber}</p>
        </div>
    `;

    modal.classList.add('active');
}

/**
 * Close withdraw modal
 */
function closeWithdrawModal() {
    document.getElementById('withdrawModal').classList.remove('active');
}

/**
 * Handle withdraw form submit
 */
async function handleWithdrawSubmit(e) {
    e.preventDefault();

    const withdrawData = {
        installation_id: document.getElementById('withdrawInstallationId').value,
        withdrawn_date: document.getElementById('withdrawnDate').value,
        withdrawal_notes: document.getElementById('withdrawalNotes').value.trim(),
        withdrawer_name: document.getElementById('withdrawerName').value.trim() || null,
        withdrawer_id: document.getElementById('withdrawerId').value.trim() || null
    };

    const result = await Utils.apiRequest(CONFIG.ENDPOINTS.INSTALLATIONS, {
        method: 'PUT',
        body: JSON.stringify(withdrawData)
    });

    if (result.success) {
        closeWithdrawModal();
        await loadDevices(); // Reload to update available devices
        await loadInstallations();
        Utils.showAlert('Device withdrawn successfully!', 'success');
    } else {
        Utils.showAlert('Error: ' + result.message, 'error');
    }
}

/**
 * Delete installation record (admin only)
 */
async function deleteInstallation(installationId) {
    if (!confirm('Are you sure you want to delete this installation record? This will soft-delete the record.')) {
        return;
    }

    const result = await Utils.apiRequest(`${CONFIG.ENDPOINTS.INSTALLATIONS}?installation_id=${installationId}`, {
        method: 'DELETE'
    });

    if (result.success) {
        await loadInstallations();
        Utils.showAlert('Installation record deleted successfully!', 'success');
    } else {
        Utils.showAlert('Error: ' + result.message, 'error');
    }
}

/**
 * Open add room modal
 */
function openAddRoomModal() {
    const modal = document.getElementById('addRoomModal');
    document.getElementById('addRoomForm').reset();
    modal.classList.add('active');
}

/**
 * Close add room modal
 */
function closeAddRoomModal() {
    document.getElementById('addRoomModal').classList.remove('active');
}

/**
 * Handle add room form submit
 */
async function handleAddRoomSubmit(e) {
    e.preventDefault();

    const roomData = {
        room_number: document.getElementById('newRoomNumber').value.trim(),
        room_name: document.getElementById('newRoomName').value,
        building: null,
        floor: null,
        capacity: null
    };

    const result = await Utils.apiRequest(CONFIG.ENDPOINTS.ROOMS, {
        method: 'POST',
        body: JSON.stringify(roomData)
    });

    if (result.success) {
        Utils.showAlert('Room added successfully!', 'success');
        closeAddRoomModal();
        await loadRooms();
        // Select the newly created room
        document.getElementById('roomSelect').value = result.data.room_id;
    } else {
        Utils.showAlert('Failed to add room: ' + result.message);
    }
}
