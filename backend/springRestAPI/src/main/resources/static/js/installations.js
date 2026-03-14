/**
 * Installations Module
 * Handles device installation and withdrawal
 */

let rooms = [];
let devices = [];
let installations = [];
let metadata = { issues: [], storage_locations: [] };

document.addEventListener('DOMContentLoaded', async () => {
    await loadMetadata();
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

    // Update dates modal
    document.getElementById('closeUpdateDatesModalBtn').addEventListener('click', closeUpdateDatesModal);
    document.getElementById('cancelUpdateDatesBtn').addEventListener('click', closeUpdateDatesModal);
    document.getElementById('updateDatesForm').addEventListener('submit', handleUpdateDatesSubmit);

    // Filter listeners
    document.getElementById('filterRoom').addEventListener('change', () => loadInstallations());
    document.getElementById('filterStatus').addEventListener('change', () => loadInstallations());
    document.getElementById('filterInstallationType').addEventListener('change', () => loadInstallations());
    document.getElementById('clearFiltersBtn').addEventListener('click', clearFilters);

    // Set default date to today
    const today = new Date().toISOString().split('T')[0];
    document.getElementById('installedDate').value = today;
    document.getElementById('withdrawnDate').value = today;
}

/**
 * Load metadata (issues and storage locations)
 */
async function loadMetadata() {
    const result = await Utils.apiRequest(CONFIG.ENDPOINTS.METADATA, {
        method: 'GET'
    });

    if (result.success) {
        metadata = result.data;
        populateIssueAndStorageDropdowns();
    }
}

/**
 * Populate issue and storage dropdowns
 */
function populateIssueAndStorageDropdowns() {
    const issueSelect = document.getElementById('issueAtWithdrawal');
    const storageSelect = document.getElementById('withdrawalStorage');

    // Populate issues
    if (metadata.issues) {
        metadata.issues.forEach(issue => {
            issueSelect.innerHTML += `<option value="${issue.issue_name}">${issue.issue_name}</option>`;
        });
    }

    // Populate storage locations
    if (metadata.storage_locations) {
        metadata.storage_locations.forEach(location => {
            storageSelect.innerHTML += `<option value="${location.location_name}">${location.location_name}</option>`;
        });
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
        console.log('Available devices for installation:', devices.length);
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
    const installationType = document.getElementById('filterInstallationType')?.value;

    if (roomId) params.append('room_id', roomId);
    if (status) params.append('status', status);
    if (installationType) params.append('installation_type', installationType);

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
        tbody.innerHTML = '<tr><td colspan="11" class="text-center">No installation records found</td></tr>';
        return;
    }

    let html = '';
    installationsList.forEach(inst => {
        const statusBadge = inst.status === 'active' 
            ? '<span class="badge badge-success">Active</span>' 
            : '<span class="badge badge-warning">Withdrawn</span>';

        const team = inst.team_members || '<span class="text-muted">-</span>';
        const issue = inst.issue_at_withdrawal || (inst.status === 'withdrawn' ? '<span class="text-muted">No issue</span>' : '<span class="text-muted">-</span>');
        
        // Installation type badge
        let installTypeBadge = '';
        switch(inst.installation_type) {
            case 'NEW_INSTALLATION':
                installTypeBadge = '<span class="badge badge-success">New</span>';
                break;
            case 'REPAIRED':
                installTypeBadge = '<span class="badge badge-info">Repaired</span>';
                break;
            case 'OLD_REINSTALL':
                installTypeBadge = '<span class="badge badge-secondary">Old Reinstall</span>';
                break;
            default:
                installTypeBadge = '<span class="badge badge-primary">N/A</span>';
        }

        html += `
            <tr>
                <td><strong>${inst.device_unique_id}</strong></td>
                <td>${inst.type_name}</td>
                <td>${inst.brand_name} ${inst.model || ''}</td>
                <td>${inst.building || ''} ${inst.room_number}</td>
                <td>${Utils.formatDate(inst.installed_date)}</td>
                <td>${installTypeBadge}</td>
                <td>${team}</td>
                <td>${inst.days_in_room} days</td>
                <td>${statusBadge}</td>
                <td>${issue}</td>
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
                    ${Utils.isAdmin() ? `
                        <button class="btn btn-sm btn-warning" onclick="openUpdateDatesModal(${inst.installation_id}, '${inst.device_unique_id}', '${inst.installed_date || ''}', '${inst.withdrawn_date || ''}', '${inst.gate_pass_date || ''}')" title="Update installation dates">
                            <i class="fas fa-calendar-alt"></i> Dates
                        </button>
                    ` : ''}
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
 * Open update dates modal
 */
function openUpdateDatesModal(installationId, deviceId, installedDate, withdrawnDate, gatePassDate) {
    document.getElementById('updateDatesInstallationId').value = installationId;
    document.getElementById('updateInstalledDate').value = (installedDate && installedDate !== '0000-00-00') ? installedDate : '';
    document.getElementById('updateWithdrawnDate').value = withdrawnDate || '';
    document.getElementById('updateGatePassDate').value = gatePassDate || '';

    document.getElementById('updateDatesDeviceInfo').innerHTML = `
        <div style="background-color: var(--bg-color); padding: 12px; border-radius: 8px; margin-bottom: 8px;">
            <p><strong>Device:</strong> ${deviceId}</p>
            <p><strong>Installation ID:</strong> #${installationId}</p>
        </div>
    `;

    document.getElementById('updateDatesModal').classList.add('active');
}

/**
 * Close update dates modal
 */
function closeUpdateDatesModal() {
    document.getElementById('updateDatesModal').classList.remove('active');
}

/**
 * Handle update dates form submit
 */
async function handleUpdateDatesSubmit(e) {
    e.preventDefault();

    const installationId = parseInt(document.getElementById('updateDatesInstallationId').value);
    const installedDate  = document.getElementById('updateInstalledDate').value  || null;
    const withdrawnDate  = document.getElementById('updateWithdrawnDate').value  || null;
    const gatePassDate   = document.getElementById('updateGatePassDate').value   || null;

    const result = await Utils.apiRequest(CONFIG.ENDPOINTS.INVALID_INSTALLATION_DATES, {
        method: 'PUT',
        body: JSON.stringify({
            installation_id: installationId,
            installed_date:  installedDate,
            withdrawn_date:  withdrawnDate,
            gate_pass_date:  gatePassDate
        })
    });

    if (result.success) {
        closeUpdateDatesModal();
        await loadInstallations();
        Utils.showAlert('Dates updated successfully!', 'success');
    } else {
        const errors = result.errors ? Object.values(result.errors).join(', ') : result.message;
        Utils.showAlert('Error: ' + errors, 'error');
    }
}

/**
 * View gate pass
 */
function viewGatePass(installationId) {
    window.open(`/gate-pass?id=${installationId}`, '_blank', 'width=900,height=800');
}

/**
 * Populate room dropdowns
 */
function populateRoomDropdowns() {
    const filterRoom = document.getElementById('filterRoom');
    const roomSelect = document.getElementById('roomSelect');

    rooms.forEach(room => {
        const option = `<option  style="color: black;" value="${room.room_id}">${room.room_number} - ${room.room_name}</option>`;
        filterRoom.innerHTML += option;
        roomSelect.innerHTML += option;
    });
}

/**
 * Initialize device autocomplete
 */
function populateDeviceDropdown() {
    const searchInput = document.getElementById('deviceSearch');
    
    if (!searchInput) {
        console.error('Device search input not found');
        return;
    }

    // Remove any existing event listeners by cloning
    const newSearchInput = searchInput.cloneNode(true);
    searchInput.parentNode.replaceChild(newSearchInput, searchInput);

    // Get fresh references after cloning
    const deviceSearchInput = document.getElementById('deviceSearch');
    const deviceDropdown = document.getElementById('deviceDropdown');
    const hiddenInput = document.getElementById('deviceSelect');

    console.log('Initializing autocomplete with', devices.length, 'devices');

    // Handle input for searching
    deviceSearchInput.addEventListener('input', function() {
        const searchTerm = this.value.toLowerCase().trim();
        hiddenInput.value = ''; // Clear selection when typing

        if (searchTerm.length < 1) {
            deviceDropdown.innerHTML = '';
            deviceDropdown.style.display = 'none';
            return;
        }

        // Filter devices based on search term
        const filteredDevices = devices.filter(device => {
            const deviceText = `${device.device_unique_id} ${device.type_name} ${device.brand_name} ${device.model || ''}`.toLowerCase();
            return deviceText.includes(searchTerm);
        });

        console.log('Found', filteredDevices.length, 'devices matching:', searchTerm);

        // Display results
        if (filteredDevices.length > 0) {
            const resultsHtml = filteredDevices.slice(0, 50).map(device => `
                <div class="autocomplete-item" data-device-id="${device.device_id}">
                    <strong>${device.device_unique_id}</strong> - ${device.type_name} (${device.brand_name}${device.model ? ' ' + device.model : ''})
                </div>
            `).join('');
            
            deviceDropdown.innerHTML = resultsHtml;
            deviceDropdown.style.display = 'block';

            // Add click handlers to results
            deviceDropdown.querySelectorAll('.autocomplete-item').forEach(item => {
                item.addEventListener('click', function() {
                    const deviceId = this.getAttribute('data-device-id');
                    const device = devices.find(d => d.device_id == deviceId);
                    
                    if (device) {
                        const hiddenInputRef = document.getElementById('deviceSelect');
                        const searchInputRef = document.getElementById('deviceSearch');
                        const dropdownRef = document.getElementById('deviceDropdown');
                        
                        searchInputRef.value = `${device.device_unique_id} - ${device.type_name} (${device.brand_name})`;
                        hiddenInputRef.value = device.device_id;
                        dropdownRef.innerHTML = '';
                        dropdownRef.style.display = 'none';
                    }
                });
            });
        } else {
            deviceDropdown.innerHTML = '<div class="autocomplete-item no-results">No available devices found matching "' + searchTerm + '"</div>';
            deviceDropdown.style.display = 'block';
        }
    });

    // Close dropdown when clicking outside
    document.addEventListener('click', function(e) {
        const searchRef = document.getElementById('deviceSearch');
        const dropdownRef = document.getElementById('deviceDropdown');
        if (searchRef && dropdownRef && !searchRef.contains(e.target) && !dropdownRef.contains(e.target)) {
            dropdownRef.style.display = 'none';
        }
    });

    // Handle focus - show recent/all options if empty
    deviceSearchInput.addEventListener('focus', function() {
        const dropdownRef = document.getElementById('deviceDropdown');
        
        if (this.value.length === 0) {
            if (devices.length > 0) {
                const recentDevices = devices.slice(0, 20);
                const resultsHtml = recentDevices.map(device => `
                    <div class="autocomplete-item" data-device-id="${device.device_id}">
                        <strong>${device.device_unique_id}</strong> - ${device.type_name} (${device.brand_name}${device.model ? ' ' + device.model : ''})
                    </div>
                `).join('');
                
                dropdownRef.innerHTML = '<div class="autocomplete-header">Available devices (${devices.length} total - type to search)</div>' + resultsHtml;
                dropdownRef.style.display = 'block';

                // Add click handlers
                dropdownRef.querySelectorAll('.autocomplete-item').forEach(item => {
                    item.addEventListener('click', function() {
                        const deviceId = this.getAttribute('data-device-id');
                        const device = devices.find(d => d.device_id == deviceId);
                        
                        if (device) {
                            const hiddenInputRef = document.getElementById('deviceSelect');
                            const searchInputRef = document.getElementById('deviceSearch');
                            const dropdownRef2 = document.getElementById('deviceDropdown');
                            
                            searchInputRef.value = `${device.device_unique_id} - ${device.type_name} (${device.brand_name})`;
                            hiddenInputRef.value = device.device_id;
                            dropdownRef2.innerHTML = '';
                            dropdownRef2.style.display = 'none';
                        }
                    });
                });
            } else {
                dropdownRef.innerHTML = '<div class="autocomplete-item no-results">No devices available for installation. All devices may be currently installed.</div>';
                dropdownRef.style.display = 'block';
            }
        }
    });
}

/**
 * Clear filters
 */
function clearFilters() {
    document.getElementById('filterRoom').value = '';
    document.getElementById('filterStatus').value = '';
    document.getElementById('filterInstallationType').value = '';
    loadInstallations();
}

/**
 * Open install modal
 */
function openInstallModal() {
    const modal = document.getElementById('installModal');
    document.getElementById('installForm').reset();
    
    // Clear autocomplete fields
    document.getElementById('deviceSearch').value = '';
    document.getElementById('deviceSelect').value = '';
    document.getElementById('deviceDropdown').innerHTML = '';
    document.getElementById('deviceDropdown').style.display = 'none';
    
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
        installation_type: document.getElementById('installationType').value,
        installation_notes: document.getElementById('installationNotes').value.trim(),
        installer_name: document.getElementById('installerName').value.trim() || null,
        installer_id: document.getElementById('installerId').value.trim() || null,
        team_members: document.getElementById('teamMembers').value.trim() || null,
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
        withdrawer_id: document.getElementById('withdrawerId').value.trim() || null,
        issue_at_withdrawal: document.getElementById('issueAtWithdrawal').value || null,
        storage_location: document.getElementById('withdrawalStorage').value || null
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
