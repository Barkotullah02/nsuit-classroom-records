/**
 * Create Gate Pass Page JavaScript
 */

let devicesList = [];
let roomsList = [];
let selectedDevices = []; // Array to store multiple selected devices

/**
 * Initialize page
 */
document.addEventListener('DOMContentLoaded', async () => {
    // Check authentication
    if (!Utils.isLoggedIn()) {
        window.location.href = 'login.html';
        return;
    }

    // Generate and display 6-digit gate pass number IMMEDIATELY
    const gatePassField = document.getElementById('gatePassNumber');
    if (gatePassField) {
        const random6Digit = Math.floor(100000 + Math.random() * 900000);
        gatePassField.value = random6Digit;
        console.log('Gate Pass Number Generated:', random6Digit);
    }

    // Initialize user info in sidebar
    Utils.initUserInfo();

    // Set default date and time to current datetime
    const dateField = document.getElementById('gatePassDate');
    if (dateField) {
        const now = new Date();
        const year = now.getFullYear();
        const month = String(now.getMonth() + 1).padStart(2, '0');
        const day = String(now.getDate()).padStart(2, '0');
        dateField.value = `${year}-${month}-${day}`;
    }

    // Setup event listeners
    setupEventListeners();

    // Check if device_id is in URL parameter
    const urlParams = new URLSearchParams(window.location.search);
    const deviceId = urlParams.get('device_id');
    
    console.log('URL params:', window.location.search);
    console.log('Device ID from URL:', deviceId);
    
    if (deviceId) {
        console.log('Loading specific device mode');
        // Load specific device
        await loadSpecificDevice(deviceId);
    } else {
        console.log('Loading all devices mode');
        // Load all devices
        await loadDevices();
    }
});

/**
 * Setup event listeners
 */
function setupEventListeners() {
    // Logout
    document.getElementById('logoutBtn').addEventListener('click', Utils.logout);

    // Form submission
    document.getElementById('gatePassForm').addEventListener('submit', handleFormSubmit);
}

/**
 * Add device to the selected devices list
 */
function addDeviceToList() {
    const deviceId = document.getElementById('deviceSelect').value;
    
    if (!deviceId) {
        Utils.showAlert('Please select a device first', 'error');
        return;
    }

    // Check if device already added
    if (selectedDevices.some(d => d.device_id == deviceId)) {
        Utils.showAlert('This device is already added to the gate pass', 'error');
        return;
    }

    const device = devicesList.find(d => d.device_id == deviceId);
    if (!device) return;

    selectedDevices.push(device);
    updateSelectedDevicesList();
    
    // Reset device select
    document.getElementById('deviceSelect').value = '';
    
    Utils.showAlert('Device added to gate pass', 'success');
}

/**
 * Remove device from selected devices list
 */
function removeDeviceFromList(deviceId) {
    selectedDevices = selectedDevices.filter(d => d.device_id != deviceId);
    updateSelectedDevicesList();
    Utils.showAlert('Device removed from gate pass', 'success');
}

/**
 * Update the selected devices list display
 */
function updateSelectedDevicesList() {
    const container = document.getElementById('devicesListContainer');
    const countEl = document.getElementById('deviceCount');
    
    countEl.textContent = selectedDevices.length;
    
    if (selectedDevices.length === 0) {
        container.innerHTML = '<p style="text-align: center; color: #666; margin: 20px 0;">No devices added yet. Select a device and click "Add This Device to Gate Pass".</p>';
        return;
    }

    let html = '<div style="display: flex; flex-direction: column; gap: 10px;">';
    
    selectedDevices.forEach((device, index) => {
        html += `
            <div style="background: white; padding: 12px; border-radius: 6px; border: 1px solid #ddd; display: flex; justify-content: space-between; align-items: center;">
                <div style="flex: 1;">
                    <strong style="color: var(--primary-color);">${index + 1}. ${device.device_unique_id}</strong> - 
                    ${device.type_name} (${device.brand_name} ${device.model || ''})
                    <br>
                    <small style="color: #666;">Serial: ${device.serial_number || 'N/A'}</small>
                </div>
                <button type="button" class="btn btn-sm" onclick="removeDeviceFromList(${device.device_id})" 
                        style="background: #dc3545; color: white; padding: 5px 10px;">
                    <i class="fas fa-trash"></i> Remove
                </button>
            </div>
        `;
    });
    
    html += '</div>';
    container.innerHTML = html;
}

/**
 * Load devices
 */
async function loadDevices() {
    const result = await Utils.apiRequest(CONFIG.ENDPOINTS.DEVICES);

    if (result.success) {
        devicesList = result.data;
        populateDeviceSelect();
    } else {
        Utils.showAlert('Error loading devices: ' + result.message, 'error');
    }
}

/**
 * Load specific device by ID
 */
async function loadSpecificDevice(deviceId) {
    console.log('Loading specific device:', deviceId);
    
    const select = document.getElementById('deviceSelect');
    select.innerHTML = '<option value="">Loading device...</option>';
    select.disabled = true;
    
    const result = await Utils.apiRequest(`${CONFIG.ENDPOINTS.DEVICES}?device_id=${deviceId}`);
    
    console.log('Device API result:', result);

    if (result.success && result.data && result.data.length > 0) {
        const device = result.data[0];
        devicesList = [device]; // Store single device in array
        
        console.log('Device loaded:', device);
        
        // Automatically add to selected devices list
        selectedDevices.push(device);
        updateSelectedDevicesList();
        
        // Clear and add the specific device as the only option
        select.innerHTML = '';
        
        const option = document.createElement('option');
        option.value = device.device_id;
        option.textContent = `${device.device_unique_id} - ${device.type_name} (${device.brand_name} ${device.model || ''})`;
        select.appendChild(option);
        
        // Auto-select
        select.value = device.device_id;
        
        // Disable dropdown since it's pre-selected
        select.disabled = true;
        
        // Update label
        const label = document.querySelector('label[for="deviceSelect"]');
        if (label) {
            label.textContent = 'Device (Pre-selected) *';
        }
        
        // Hide the add button since device is already added
        const addBtn = document.querySelector('button[onclick="addDeviceToList()"]');
        if (addBtn) {
            addBtn.style.display = 'none';
        }
        
        console.log('Device auto-selected and added to list');
    } else {
        console.error('Failed to load device:', result);
        
        // Re-enable dropdown and show error
        select.innerHTML = '<option value="">Failed to load device - Choose manually...</option>';
        select.disabled = false;
        
        Utils.showAlert('Could not load device ID ' + deviceId + '. Please select manually.', 'error');
        
        // Fall back to loading all devices
        await loadDevices();
    }
}

/**
 * Populate device dropdown
 */
function populateDeviceSelect() {
    const select = document.getElementById('deviceSelect');
    
    // Clear the default "Choose a device..." option if there are devices
    if (devicesList.length > 0) {
        select.innerHTML = '<option value="">Choose a device...</option>';
    }
    
    devicesList.forEach(device => {
        const option = document.createElement('option');
        option.value = device.device_id;
        option.textContent = `${device.device_unique_id} - ${device.type_name} (${device.brand_name} ${device.model || ''})`;
        select.appendChild(option);
    });
    
    console.log(`Populated ${devicesList.length} devices in dropdown`);
}

/**
 * Load rooms
 */
async function loadRooms() {
    const result = await Utils.apiRequest(CONFIG.ENDPOINTS.ROOMS);

    if (result.success) {
        roomsList = result.data;
        populateRoomSelect();
    }
}

/**
 * Populate room dropdown
 */
function populateRoomSelect() {
    const select = document.getElementById('destinationRoom');
    
    roomsList.forEach(room => {
        const option = document.createElement('option');
        option.value = room.room_id;
        option.textContent = `${room.room_number} - ${room.room_name}`;
        select.appendChild(option);
    });
}

/**
 * Show device preview
 */
function showDevicePreview() {
    const deviceId = document.getElementById('deviceSelect').value;
    const preview = document.getElementById('devicePreview');
    const content = document.getElementById('devicePreviewContent');

    if (!deviceId) {
        preview.style.display = 'none';
        return;
    }

    const device = devicesList.find(d => d.device_id == deviceId);
    if (!device) return;

    content.innerHTML = `
        <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px;">
            <div>
                <strong>Device ID:</strong><br>
                <span style="color: var(--primary-color);">${device.device_unique_id}</span>
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
                <strong>Status:</strong><br>
                <span class="badge ${device.status === 'available' ? 'badge-success' : device.status === 'in_use' ? 'badge-warning' : 'badge-danger'}">
                    ${device.status}
                </span>
            </div>
        </div>
    `;

    preview.style.display = 'block';
}

/**
 * Handle form submission
 */
async function handleFormSubmit(e) {
    e.preventDefault();

    // Validate at least one device is selected
    if (selectedDevices.length === 0) {
        Utils.showAlert('Please add at least one device to the gate pass', 'error');
        return;
    }

    const gatePassData = {
        devices: selectedDevices.map(d => d.device_id), // Array of device IDs
        gate_pass_number: document.getElementById('gatePassNumber').value.trim(),
        gate_pass_date: document.getElementById('gatePassDate').value,
        consignee_name: document.getElementById('consigneeName').value.trim(),
        destination: document.getElementById('destination').value.trim(),
        carrier_name: document.getElementById('carrierName').value.trim(),
        carrier_appointment: document.getElementById('carrierAppointment').value.trim(),
        carrier_department: document.getElementById('carrierDepartment').value.trim(),
        carrier_telephone: document.getElementById('carrierTelephone').value.trim(),
        security_name: document.getElementById('securityName').value.trim() || null,
        security_appointment: document.getElementById('securityAppointment').value.trim() || null,
        security_department: document.getElementById('securityDepartment').value.trim() || null,
        security_telephone: document.getElementById('securityTelephone').value.trim() || null,
        receiver_name: document.getElementById('receiverName').value.trim() || null,
        receiver_appointment: document.getElementById('receiverAppointment').value.trim() || null,
        receiver_department: document.getElementById('receiverDepartment').value.trim() || null,
        receiver_telephone: document.getElementById('receiverTelephone').value.trim() || null
    };

    // Create gate pass
    const result = await Utils.apiRequest(CONFIG.ENDPOINTS.GATE_PASSES, {
        method: 'POST',
        body: JSON.stringify(gatePassData)
    });

    if (result.success) {
        Utils.showAlert('Gate pass created successfully!', 'success');
        
        // Ask if user wants to view/print
        setTimeout(() => {
            if (confirm('Gate pass created! Do you want to view and print it now?')) {
                window.open(`gate-pass-standalone.html?id=${result.data.gate_pass_id}`, '_blank', 'width=900,height=800');
            }
            window.location.href = 'gate-passes.html';
        }, 1000);
    } else {
        Utils.showAlert('Error: ' + result.message, 'error');
    }
}
