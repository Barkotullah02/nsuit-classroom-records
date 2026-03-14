        let roomId = null;
        let roomData = null;
        let allHistory = [];

        // Initialize
        document.addEventListener('DOMContentLoaded', function() {
            Utils.checkAuth();

            const logoutBtn = document.getElementById('logoutBtn');
            if (logoutBtn) {
                logoutBtn.addEventListener('click', () => Utils.logout());
            }
            
            // Get room ID from URL
            const urlParams = new URLSearchParams(window.location.search);
            roomId = urlParams.get('room_id');
            
            if (!roomId) {
                showError('No room ID provided');
                setTimeout(() => window.location.href = '/rooms', 2000);
                return;
            }
            
            loadRoomHistory();
        });

        async function loadRoomHistory() {
            try {
                // Build API URL — append date_from / date_to only when set
                const dateFrom = document.getElementById('dateFrom')?.value || '';
                const dateTo   = document.getElementById('dateTo')?.value   || '';
                let apiUrl = `${CONFIG.ENDPOINTS.ROOM_HISTORY}?room_id=${roomId}`;
                if (dateFrom) apiUrl += `&date_from=${encodeURIComponent(dateFrom)}`;
                if (dateTo)   apiUrl += `&date_to=${encodeURIComponent(dateTo)}`;

                const result = await Utils.apiRequest(apiUrl, {
                    method: 'GET'
                });
                
                if (result.success) {
                    roomData = {
                        ...result.data.room,
                        active_devices: result.data.active_devices,
                        withdrawn_devices: result.data.withdrawn_devices,
                        active_device_count: result.data.statistics.active_count,
                        withdrawn_device_count: result.data.statistics.withdrawn_count
                    };
                    allHistory = result.data.complete_history;
                    
                    displayRoomHeader();
                    displayActiveDevices();
                    displayWithdrawnDevices();
                    displayHistoryTable(allHistory);
                } else {
                    showError(result.message || 'Failed to load room data');
                }
            } catch (error) {
                console.error('Error loading room history:', error);
                showError('Failed to load room history');
            }
        }

        function displayRoomHeader() {
            const header = document.getElementById('roomHeader');
            if (!header) {
                console.warn('roomHeader not found in DOM');
                return;
            }

            header.innerHTML = `
                <h1><i class="fas fa-door-open"></i> ${roomData.room_name}</h1>
                <div class="room-info">
                    <div class="room-info-item">
                        <label>Room Number</label>
                        <strong>${roomData.room_number}</strong>
                    </div>
                    <div class="room-info-item">
                        <label>Building</label>
                        <strong>${roomData.building || 'N/A'}</strong>
                    </div>
                    <div class="room-info-item">
                        <label>Floor</label>
                        <strong>${roomData.floor || 'N/A'}</strong>
                    </div>
                    <div class="room-info-item">
                        <label>Capacity</label>
                        <strong>${roomData.capacity || 'N/A'}</strong>
                    </div>
                    <div class="room-info-item">
                        <label>Active Devices</label>
                        <strong>${roomData.active_device_count}</strong>
                    </div>
                    <div class="room-info-item">
                        <label>Total History Records</label>
                        <strong>${roomData.active_device_count + roomData.withdrawn_device_count}</strong>
                    </div>
                </div>
            `;
        }

        function displayActiveDevices() {
            const grid = document.getElementById('activeDevicesGrid');
            const countEl = document.getElementById('activeDeviceCount');

            if (!grid) {
                console.warn('activeDevicesGrid not found in DOM');
                return;
            }

            if (!countEl) {
                console.warn('activeDeviceCount not found in DOM');
                return;
            }
            
            countEl.textContent = roomData.active_device_count;
            
            if (roomData.active_devices.length === 0) {
                grid.innerHTML = `
                    <div class="no-data" style="grid-column: 1/-1;">
                        <i class="fas fa-inbox"></i>
                        <p>No devices currently installed in this room</p>
                    </div>
                `;
                return;
            }
            
            grid.innerHTML = roomData.active_devices.map(device => `
                <div class="device-card active">
                    <div class="device-header">
                        <div class="device-title">
                            <h3>${device.type_name || 'Unknown Type'}</h3>
                            <div class="device-id">${device.device_unique_id}</div>
                        </div>
                        <span class="status-badge active">Active</span>
                    </div>
                    
                    <div class="device-info">
                        <div class="device-info-row">
                            <label>Brand:</label>
                            <span>${device.brand_name || 'N/A'}</span>
                        </div>
                        <div class="device-info-row">
                            <label>Model:</label>
                            <span>${device.model || 'N/A'}</span>
                        </div>
                        <div class="device-info-row">
                            <label>Serial Number:</label>
                            <span>${device.serial_number || 'N/A'}</span>
                        </div>
                        <div class="device-info-row">
                            <label>Installed Date:</label>
                            <span>${formatDate(device.installed_date)}</span>
                        </div>
                        <div class="device-info-row">
                            <label>Installed By:</label>
                            <span>${device.installed_by_name || 'N/A'}</span>
                        </div>
                    </div>
                    
                    ${device.installation_notes ? `
                        <div class="device-notes">
                            <strong>Installation Notes:</strong>
                            ${device.installation_notes}
                        </div>
                    ` : ''}
                </div>
            `).join('');
        }

        function displayWithdrawnDevices() {
            const grid = document.getElementById('pastDevicesGrid');
            const countEl = document.getElementById('pastDeviceCount');

            if (!grid) {
                console.warn('pastDevicesGrid not found in DOM');
                return;
            }

            if (!countEl) {
                console.warn('pastDeviceCount not found in DOM');
                return;
            }
            
            countEl.textContent = roomData.withdrawn_device_count;
            
            if (roomData.withdrawn_devices.length === 0) {
                grid.innerHTML = `
                    <div class="no-data" style="grid-column: 1/-1;">
                        <i class="fas fa-inbox"></i>
                        <p>No withdrawn devices found</p>
                    </div>
                `;
                return;
            }
            
            grid.innerHTML = roomData.withdrawn_devices.map(device => `
                <div class="device-card withdrawn">
                    <div class="device-header">
                        <div class="device-title">
                            <h3>${device.type_name || 'Unknown Type'}</h3>
                            <div class="device-id">${device.device_unique_id}</div>
                        </div>
                        <span class="status-badge withdrawn">Withdrawn</span>
                    </div>
                    
                    <div class="device-info">
                        <div class="device-info-row">
                            <label>Brand:</label>
                            <span>${device.brand_name || 'N/A'}</span>
                        </div>
                        <div class="device-info-row">
                            <label>Model:</label>
                            <span>${device.model || 'N/A'}</span>
                        </div>
                        <div class="device-info-row">
                            <label>Serial Number:</label>
                            <span>${device.serial_number || 'N/A'}</span>
                        </div>
                        <div class="device-info-row">
                            <label>Withdrawn Date:</label>
                            <span>${formatDate(device.withdrawn_date)}</span>
                        </div>
                        <div class="device-info-row">
                            <label>Withdrawn By:</label>
                            <span>${device.withdrawn_by_name || 'N/A'}</span>
                        </div>
                    </div>
                    
                    ${device.withdrawal_notes ? `
                        <div class="device-notes">
                            <strong>Withdrawal Notes:</strong>
                            ${device.withdrawal_notes}
                        </div>
                    ` : ''}
                    
                    ${device.current_location ? `
                        <div class="current-location">
                            <strong><i class="fas fa-map-marker-alt"></i> Currently Installed At:</strong>
                            <span>${device.current_location.room_number} - ${device.current_location.room_name}</span>
                            <br><small>Since ${formatDate(device.current_location.installed_date)}</small>
                        </div>
                    ` : ''}
                </div>
            `).join('');
        }

        function displayHistoryTable(history) {
            const container = document.getElementById('historyTableContainer');

            if (!container) {
                console.warn('historyTableContainer not found in DOM');
                return;
            }
            
            if (history.length === 0) {
                container.innerHTML = `
                    <div class="no-data">
                        <i class="fas fa-inbox"></i>
                        <p>No history records found</p>
                    </div>
                `;
                return;
            }
            
            // Sort by date (most recent first)
            history.sort((a, b) => new Date(b.installed_date) - new Date(a.installed_date));
            
            container.innerHTML = `
                <div class="table-container">
                <table>
                    <thead>
                        <tr style="color: black !important;">
                            <th style="color: black !important;">Device ID</th>
                            <th style="color: black !important;">Type</th>
                            <th style="color: black !important;">Brand</th>
                            <th style="color: black !important;">Installed Date</th>
                            <th style="color: black !important;">Withdrawn Date</th>
                            <th style="color: black !important;">Days in Room</th>
                            <th style="color: black !important;">Status</th>
                            <th style="color: black !important;">Installed By</th>
                            <th style="color: black !important;">Withdrawn By</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${history.map(record => `
                            <tr>
                                <td style="color: black !important;"><strong>${record.device_unique_id}</strong></td>
                                <td style="color: black !important;">${record.type_name || 'N/A'}</td>
                                <td style="color: black !important;">${record.brand_name || 'N/A'}</td>
                                <td style="color: black !important;">${formatDate(record.installed_date)}</td>
                                <td style="color: black !important;">${record.withdrawn_date ? formatDate(record.withdrawn_date) : '<span style="color: #4CAF50;">Active</span>'}</td>
                                <td style="color: black !important;">${record.days_in_room} days</td>
                                <td>
                                    <span class="status-badge ${record.status}">
                                        ${record.status}
                                    </span>
                                </td>
                                <td style="color: black !important;">${record.installed_by || 'N/A'}</td>
                                <td style="color: black !important;">${record.withdrawn_by || '-'}</td>
                            </tr>
                        `).join('')}
                    </tbody>
                </table>
                </div>
            `;
        }

        function applyDateFilter() {
            const dateFrom = document.getElementById('dateFrom').value;
            const dateTo   = document.getElementById('dateTo').value;
            const clearBtn     = document.getElementById('clearFilterBtn');
            const filterInfo   = document.getElementById('filterInfo');
            const printDateNote = document.getElementById('printDateNote');
            const today = new Date().toISOString().split('T')[0];

            const hasFilter = dateFrom || dateTo;

            if (hasFilter) {
                clearBtn.style.display = 'inline-flex';

                let infoText  = '';
                let noteText  = '';

                if (dateFrom && dateTo) {
                    infoText = `Showing history from ${formatDate(dateFrom)} to ${formatDate(dateTo)}`;
                    noteText = `History filtered: ${formatDate(dateFrom)} → ${formatDate(dateTo)}`;
                } else if (dateFrom) {
                    infoText = `Showing history from ${formatDate(dateFrom)} to today`;
                    noteText = `History filtered: ${formatDate(dateFrom)} → ${formatDate(today)}`;
                } else {
                    infoText = `Showing history up to ${formatDate(dateTo)}`;
                    noteText = `History filtered: Beginning → ${formatDate(dateTo)}`;
                }

                filterInfo.textContent   = infoText;
                printDateNote.textContent = noteText;
            } else {
                clearBtn.style.display    = 'none';
                filterInfo.textContent    = '';
                printDateNote.textContent = '';
            }

            loadRoomHistory();
        }

        function clearDateFilter() {
            document.getElementById('dateFrom').value = '';
            document.getElementById('dateTo').value   = '';
            document.getElementById('clearFilterBtn').style.display = 'none';
            document.getElementById('filterInfo').textContent       = '';
            document.getElementById('printDateNote').textContent    = '';
            loadRoomHistory();
        }

        function formatDate(dateString) {
            if (!dateString) return 'N/A';
            const date = new Date(dateString);
            return date.toLocaleDateString('en-US', { 
                year: 'numeric', 
                month: 'short', 
                day: 'numeric' 
            });
        }

        function showError(message) {
            const roomHeader = document.getElementById('roomHeader');
            if (!roomHeader) {
                console.warn('roomHeader not found in DOM while showing error:', message);
                return;
            }

            roomHeader.innerHTML = `
                <div class="error-message">
                    <i class="fas fa-exclamation-triangle"></i>
                    ${message}
                </div>
            `;
        }
