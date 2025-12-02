/**
 * Devices Module
 * Handles device management functionality
 */

let metadata = { types: [], brands: [] };
let rooms = [];
let devices = [];

document.addEventListener('DOMContentLoaded', async () => {
    await loadMetadata();
    await loadRooms();
    await loadDevices();

    initializeEventListeners();
});

/**
 * Initialize event listeners
 */
function initializeEventListeners() {
    // Add device button
    const addDeviceBtn = document.getElementById('addDeviceBtn');
    if (addDeviceBtn && Utils.isAdmin()) {
        addDeviceBtn.addEventListener('click', () => openDeviceModal());
    } else if (addDeviceBtn) {
        addDeviceBtn.style.display = 'none';
    }

    // Modal close buttons
    document.getElementById('closeModalBtn').addEventListener('click', closeDeviceModal);
    document.getElementById('cancelBtn').addEventListener('click', closeDeviceModal);
    document.getElementById('closeHistoryModalBtn').addEventListener('click', closeHistoryModal);
    document.getElementById('closeAddBrandModalBtn').addEventListener('click', closeAddBrandModal);
    document.getElementById('cancelAddBrandBtn').addEventListener('click', closeAddBrandModal);
    document.getElementById('closeAddDeviceTypeModalBtn').addEventListener('click', closeAddDeviceTypeModal);
    document.getElementById('cancelAddDeviceTypeBtn').addEventListener('click', closeAddDeviceTypeModal);

    // Device form submit
    document.getElementById('deviceForm').addEventListener('submit', handleDeviceSubmit);
    document.getElementById('addBrandForm').addEventListener('submit', handleAddBrandSubmit);
    document.getElementById('addDeviceTypeForm').addEventListener('submit', handleAddDeviceTypeSubmit);

    // Add brand/type buttons (admin only)
    if (Utils.isAdmin()) {
        document.getElementById('addBrandBtn').style.display = 'block';
        document.getElementById('addTypeBtn').style.display = 'block';
        document.getElementById('addBrandBtn').addEventListener('click', () => openAddBrandModal());
        document.getElementById('addTypeBtn').addEventListener('click', () => openAddDeviceTypeModal());
    }

    // Filter listeners
    document.getElementById('filterDeviceId').addEventListener('input', 
        Utils.debounce(() => loadDevices(), 500));
    document.getElementById('filterType').addEventListener('change', () => loadDevices());
    document.getElementById('filterBrand').addEventListener('change', () => loadDevices());
    document.getElementById('filterRoom').addEventListener('change', () => loadDevices());
    
    document.getElementById('clearFiltersBtn').addEventListener('click', clearFilters);
}

/**
 * Load metadata (types and brands)
 */
async function loadMetadata() {
    const result = await Utils.apiRequest(CONFIG.ENDPOINTS.METADATA, {
        method: 'GET'
    });

    if (result.success) {
        metadata = result.data;
        populateFilterDropdowns();
        populateFormDropdowns();
    }
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
        populateRoomFilter();
    }
}

/**
 * Load devices
 */
async function loadDevices() {
    const params = new URLSearchParams();
    
    const deviceId = document.getElementById('filterDeviceId').value.trim();
    const typeId = document.getElementById('filterType').value;
    const brandId = document.getElementById('filterBrand').value;
    const roomId = document.getElementById('filterRoom').value;

    if (deviceId) params.append('device_unique_id', deviceId);
    if (typeId) params.append('type_id', typeId);
    if (brandId) params.append('brand_id', brandId);
    if (roomId) params.append('room_id', roomId);

    const queryString = params.toString();
    const url = CONFIG.ENDPOINTS.DEVICES + (queryString ? '?' + queryString : '');

    const result = await Utils.apiRequest(url, {
        method: 'GET'
    });

    if (result.success) {
        devices = result.data;
        displayDevices(devices);
    } else {
        console.error('Failed to load devices:', result.message);
    }
}

/**
 * Display devices in table
 */
function displayDevices(devicesList) {
    const tbody = document.getElementById('devicesTableBody');
    
    if (!devicesList || devicesList.length === 0) {
        tbody.innerHTML = '<tr><td colspan="8" class="text-center">No devices found</td></tr>';
        return;
    }

    let html = '';
    devicesList.forEach(device => {
        const statusBadge = device.is_active 
            ? '<span class="badge badge-success">Active</span>' 
            : '<span class="badge badge-danger">Inactive</span>';

        const currentRoom = device.current_room_number 
            ? `${device.current_room_number} - ${device.current_room_name}` 
            : '<span class="text-muted">Not installed</span>';

        const lifetime = device.total_lifetime_days !== null
            ? Utils.formatDays(device.total_lifetime_days)
            : '<span class="text-muted">N/A</span>';

        html += `
            <tr>
                <td><strong>${device.device_unique_id}</strong></td>
                <td>${device.type_name}</td>
                <td>${device.brand_name}</td>
                <td>${device.model || 'N/A'}</td>
                <td>${currentRoom}</td>
                <td>${lifetime}</td>
                <td>${statusBadge}</td>
                <td>
                    <button class="btn btn-sm btn-info" onclick="createGatePassForDevice(${device.device_id}, '${device.device_unique_id}')" title="Create Gate Pass">
                        <i class="fas fa-file-alt"></i> Gate Pass
                    </button>
                    <button class="btn btn-sm btn-primary" onclick="window.location.href='device-history.html?id=${device.device_id}'">
                        <i class="fas fa-history"></i> History
                    </button>
                    ${Utils.isAdmin() ? `
                        <button class="btn btn-sm btn-secondary" onclick="editDevice(${device.device_id})">
                            <i class="fas fa-edit"></i> Edit
                        </button>
                        <button class="btn btn-sm btn-danger" onclick="deleteDevice(${device.device_id}, '${device.device_unique_id}')">
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
 * Populate filter dropdowns
 */
function populateFilterDropdowns() {
    const typeSelect = document.getElementById('filterType');
    const brandSelect = document.getElementById('filterBrand');

    metadata.types.forEach(type => {
        typeSelect.innerHTML += `<option value="${type.type_id}">${type.type_name}</option>`;
    });

    metadata.brands.forEach(brand => {
        brandSelect.innerHTML += `<option value="${brand.brand_id}">${brand.brand_name}</option>`;
    });
}

/**
 * Populate room filter
 */
function populateRoomFilter() {
    const roomSelect = document.getElementById('filterRoom');
    
    rooms.forEach(room => {
        roomSelect.innerHTML += `<option value="${room.room_id}">${room.room_number} - ${room.room_name}</option>`;
    });
}

/**
 * Populate form dropdowns
 */
function populateFormDropdowns() {
    const typeSelect = document.getElementById('typeId');
    const brandSelect = document.getElementById('brandId');

    metadata.types.forEach(type => {
        typeSelect.innerHTML += `<option value="${type.type_id}">${type.type_name}</option>`;
    });

    metadata.brands.forEach(brand => {
        brandSelect.innerHTML += `<option value="${brand.brand_id}">${brand.brand_name}</option>`;
    });
}

/**
 * Clear filters
 */
function clearFilters() {
    document.getElementById('filterDeviceId').value = '';
    document.getElementById('filterType').value = '';
    document.getElementById('filterBrand').value = '';
    document.getElementById('filterRoom').value = '';
    loadDevices();
}

/**
 * Open device modal
 */
function openDeviceModal(device = null) {
    const modal = document.getElementById('deviceModal');
    const form = document.getElementById('deviceForm');
    const title = document.getElementById('modalTitle');
    const isActiveGroup = document.getElementById('isActiveGroup');

    form.reset();

    if (device) {
        title.textContent = 'Edit Device';
        document.getElementById('deviceId').value = device.device_id;
        document.getElementById('deviceUniqueId').value = device.device_unique_id;
        document.getElementById('typeId').value = device.type_id;
        document.getElementById('brandId').value = device.brand_id;
        document.getElementById('model').value = device.model || '';
        document.getElementById('serialNumber').value = device.serial_number || '';
        document.getElementById('purchaseDate').value = device.purchase_date || '';
        document.getElementById('warrantyPeriod').value = device.warranty_period || '';
        document.getElementById('notes').value = device.notes || '';
        document.getElementById('isActive').checked = device.is_active;
        isActiveGroup.style.display = 'block';
    } else {
        title.textContent = 'Add Device';
        isActiveGroup.style.display = 'none';
    }

    modal.classList.add('active');
}

/**
 * Close device modal
 */
function closeDeviceModal() {
    document.getElementById('deviceModal').classList.remove('active');
}

/**
 * Handle device form submit
 */
async function handleDeviceSubmit(e) {
    e.preventDefault();

    const deviceId = document.getElementById('deviceId').value;
    const isEdit = deviceId !== '';

    const deviceData = {
        device_unique_id: document.getElementById('deviceUniqueId').value.trim(),
        type_id: document.getElementById('typeId').value,
        brand_id: document.getElementById('brandId').value,
        model: document.getElementById('model').value.trim(),
        serial_number: document.getElementById('serialNumber').value.trim(),
        purchase_date: document.getElementById('purchaseDate').value || null,
        warranty_period: document.getElementById('warrantyPeriod').value || null,
        notes: document.getElementById('notes').value.trim()
    };

    if (isEdit) {
        deviceData.device_id = deviceId;
        deviceData.is_active = document.getElementById('isActive').checked;
    }

    const result = await Utils.apiRequest(CONFIG.ENDPOINTS.DEVICES, {
        method: isEdit ? 'PUT' : 'POST',
        body: JSON.stringify(deviceData)
    });

    if (result.success) {
        closeDeviceModal();
        await loadDevices();
        Utils.showAlert(isEdit ? 'Device updated successfully!' : 'Device created successfully!', 'success');
    } else {
        Utils.showAlert('Error: ' + result.message, 'error');
    }
}

/**
 * Edit device
 */
async function editDevice(deviceId) {
    const device = devices.find(d => d.device_id === deviceId);
    if (device) {
        openDeviceModal(device);
    }
}

/**
 * Delete device
 */
async function deleteDevice(deviceId, deviceUniqueId) {
    if (!confirm(`Are you sure you want to delete device "${deviceUniqueId}"?\n\nThis will soft-delete the device and it can be restored later from the Deleted Items page.`)) {
        return;
    }

    const result = await Utils.apiRequest(CONFIG.ENDPOINTS.DEVICES, {
        method: 'DELETE',
        body: JSON.stringify({ device_id: deviceId })
    });

    if (result.success) {
        await loadDevices();
        Utils.showNotification('Device deleted successfully! You can restore it from Deleted Items.', 'success');
    } else {
        Utils.showNotification('Error: ' + result.message, 'error');
    }
}

/**
 * Create gate pass for device
 */
function createGatePassForDevice(deviceId, deviceUniqueId) {
    // Redirect to create gate pass page with device pre-selected
    window.location.href = `create-gate-pass.html?device_id=${deviceId}`;
}

/**
 * View device history
 */
async function viewHistory(deviceId) {
    const modal = document.getElementById('historyModal');
    const content = document.getElementById('historyContent');

    modal.classList.add('active');
    content.innerHTML = '<div class="spinner"></div>';

    const result = await Utils.apiRequest(`${CONFIG.ENDPOINTS.DEVICE_HISTORY}?device_id=${deviceId}`, {
        method: 'GET'
    });

    if (result.success && result.data.length > 0) {
        let html = '<div class="table-container"><table><thead><tr>';
        html += '<th>Room</th><th>Installed</th><th>Withdrawn</th><th>Days</th><th>Status</th><th>Installed By</th>';
        html += '</tr></thead><tbody>';

        result.data.forEach(record => {
            const statusBadge = record.status === 'active' 
                ? '<span class="badge badge-success">Active</span>' 
                : '<span class="badge badge-warning">Withdrawn</span>';

            html += `
                <tr>
                    <td>${record.room_number} - ${record.room_name}</td>
                    <td>${Utils.formatDate(record.installed_date)}</td>
                    <td>${record.withdrawn_date ? Utils.formatDate(record.withdrawn_date) : 'N/A'}</td>
                    <td>${record.days_in_room} days</td>
                    <td>${statusBadge}</td>
                    <td>${record.installed_by}</td>
                </tr>
            `;
        });

        html += '</tbody></table></div>';
        content.innerHTML = html;
    } else {
        content.innerHTML = '<p class="text-center">No installation history found</p>';
    }
}

/**
 * Add new brand
 */
function openAddBrandModal() {
    const modal = document.getElementById('addBrandModal');
    document.getElementById('addBrandForm').reset();
    modal.classList.add('active');
}

function closeAddBrandModal() {
    document.getElementById('addBrandModal').classList.remove('active');
}

async function handleAddBrandSubmit(e) {
    e.preventDefault();

    const brandName = document.getElementById('newBrandName').value.trim();

    const result = await Utils.apiRequest(CONFIG.ENDPOINTS.METADATA, {
        method: 'POST',
        body: JSON.stringify({
            type: 'brand',
            brand_name: brandName
        })
    });

    if (result.success) {
        Utils.showAlert('Brand added successfully!', 'success');
        closeAddBrandModal();
        await loadMetadata();
        // Select the newly created brand
        document.getElementById('brandId').value = result.data.brand_id;
    } else {
        Utils.showAlert('Failed to add brand: ' + result.message);
    }
}

/**
 * Add new device type
 */
function openAddDeviceTypeModal() {
    const modal = document.getElementById('addDeviceTypeModal');
    document.getElementById('addDeviceTypeForm').reset();
    modal.classList.add('active');
}

function closeAddDeviceTypeModal() {
    document.getElementById('addDeviceTypeModal').classList.remove('active');
}

async function handleAddDeviceTypeSubmit(e) {
    e.preventDefault();

    const typeName = document.getElementById('newTypeName').value.trim();
    const description = document.getElementById('newTypeDescription').value.trim();

    const result = await Utils.apiRequest(CONFIG.ENDPOINTS.METADATA, {
        method: 'POST',
        body: JSON.stringify({
            type: 'device_type',
            type_name: typeName,
            description: description
        })
    });

    if (result.success) {
        Utils.showAlert('Device type added successfully!', 'success');
        closeAddDeviceTypeModal();
        await loadMetadata();
        // Select the newly created type
        document.getElementById('typeId').value = result.data.type_id;
    } else {
        Utils.showAlert('Failed to add device type: ' + result.message);
    }
}

/**
 * Close history modal
 */
function closeHistoryModal() {
    document.getElementById('historyModal').classList.remove('active');
}
