        let currentRoomId = null;
        let currentDeleteRoomId = null;
        let allRooms = []; // Store all rooms for filtering

        document.addEventListener('DOMContentLoaded', async () => {
            await loadRooms();
        });

        async function loadRooms() {
            const result = await Utils.apiRequest(CONFIG.ENDPOINTS.ROOMS, {
                method: 'GET'
            });

            if (result.success) {
                allRooms = result.data; // Store all rooms
                displayRooms(allRooms);
            }
        }

        function extractBuildingFromRoomName(roomNumber) {
            // Extract building prefix (NAC, SAC, NTR, LIB, LAB, etc.) from room_number
            const match = roomNumber.match(/^([A-Z]+)/);
            return match ? match[1] : '';
        }

        function extractFloorFromRoomName(roomNumber) {
            // Extract first digit from 3-digit room number (e.g., "SAC 201" -> "2", "NAC 304" -> "3")
            const match = roomNumber.match(/\s+(\d)(\d{2})/);
            return match ? match[1] : '';
        }

        function applyFilters() {
            const buildingFilter = document.getElementById('buildingFilter').value.toUpperCase();
            const floorFilter = document.getElementById('floorFilter').value;
            const searchFilter = document.getElementById('searchFilter').value.toLowerCase();

            const filteredRooms = allRooms.filter(room => {
                // Extract building and floor from room_number (use DB fields only if not empty)
                const roomBuilding = (room.building && room.building.trim() !== '') 
                    ? room.building 
                    : extractBuildingFromRoomName(room.room_number);
                const roomFloor = (room.floor && room.floor.trim() !== '') 
                    ? room.floor 
                    : extractFloorFromRoomName(room.room_number);
                
                // Building filter
                if (buildingFilter && roomBuilding.toUpperCase() !== buildingFilter) {
                    return false;
                }

                // Floor filter
                if (floorFilter && roomFloor !== floorFilter) {
                    return false;
                }

                // Search filter
                if (searchFilter) {
                    const searchText = `${room.room_number} ${room.room_name}`.toLowerCase();
                    if (!searchText.includes(searchFilter)) {
                        return false;
                    }
                }

                return true;
            });

            displayRooms(filteredRooms);
        }

        function clearFilters() {
            document.getElementById('buildingFilter').value = '';
            document.getElementById('floorFilter').value = '';
            document.getElementById('searchFilter').value = '';
            displayRooms(allRooms);
        }

        function displayRooms(rooms) {
            const grid = document.getElementById('roomsGrid');
            
            if (!rooms || rooms.length === 0) {
                grid.innerHTML = '<p class="text-center" style="grid-column: 1/-1;">No rooms found</p>';
                return;
            }

            let html = '';
            rooms.forEach(room => {
                // Extract building and floor from room_number (use DB fields only if not empty)
                const building = (room.building && room.building.trim() !== '') 
                    ? room.building 
                    : extractBuildingFromRoomName(room.room_number);
                const floor = (room.floor && room.floor.trim() !== '') 
                    ? room.floor 
                    : extractFloorFromRoomName(room.room_number);
                
                html += `
                    <div class="card">
                        <div style="display: flex; justify-content: space-between; align-items: start; margin-bottom: 16px;">
                            <div>
                                <h3 style="font-size: 24px; font-weight: 700; margin-bottom: 4px;">
                                    ${room.room_number}
                                </h3>
                                <p style="color: var(--text-secondary);">${room.room_name}</p>
                            </div>
                            <div class="stat-icon primary">
                                <i class="fas fa-door-open"></i>
                            </div>
                        </div>
                        <div style="border-top: 1px solid var(--border-color); padding-top: 16px; margin-bottom: 16px;">
                            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 12px; font-size: 14px;">
                                <div>
                                    <span style="color: var(--text-secondary);">Building:</span>
                                    <strong>${building || 'N/A'}</strong>
                                </div>
                                <div>
                                    <span style="color: var(--text-secondary);">Floor:</span>
                                    <strong>${floor ? (floor === '0' ? 'Ground' : floor) : 'N/A'}</strong>
                                </div>
                                <div>
                                    <span style="color: var(--text-secondary);">Capacity:</span>
                                    <strong>${room.capacity || 'N/A'}</strong>
                                </div>
                                <div>
                                    <span style="color: var(--text-secondary);">Devices:</span>
                                    <strong>${room.device_count || 0}</strong>
                                </div>
                            </div>
                        </div>
                        <div class="room-actions">
                            <button class="btn btn-sm btn-info" onclick="window.location.href='/room-history?room_id=${room.room_id}'">
                            History
                            </button>
                            <button class="btn btn-sm btn-success" onclick="viewRoomDevices(${room.room_id}, '${escapeHtml(room.room_number)} - ${escapeHtml(room.room_name)}')">
                            Devices
                            </button>
                            <button class="btn btn-sm btn-primary" onclick="showEditRoomModal(${room.room_id}, '${escapeHtml(room.room_number)}', '${escapeHtml(room.room_name)}', '${escapeHtml(room.building || '')}', '${escapeHtml(room.floor || '')}', ${room.capacity || 'null'})">
                            Edit
                            </button>
                            <button class="btn btn-sm btn-danger" onclick="showDeleteModal(${room.room_id}, '${escapeHtml(room.room_number)} - ${escapeHtml(room.room_name)}')">
                            Delete
                            </button>
                        </div>
                    </div>
                `;
            });

            grid.innerHTML = html;
        }

        function showAddRoomModal() {
            currentRoomId = null;
            document.getElementById('roomModalTitle').innerHTML = '<i class="fas fa-door-open"></i> Add Room';
            document.getElementById('roomForm').reset();
            document.getElementById('roomId').value = '';
            document.getElementById('roomModal').classList.add('active');
        }

        function showEditRoomModal(id, number, name, building, floor, capacity) {
            currentRoomId = id;
            document.getElementById('roomModalTitle').innerHTML = '<i class="fas fa-edit"></i> Edit Room';
            document.getElementById('roomId').value = id;
            document.getElementById('roomNumber').value = number;
            document.getElementById('roomName').value = name;
            document.getElementById('building').value = building;
            document.getElementById('floor').value = floor;
            document.getElementById('capacity').value = capacity || '';
            document.getElementById('roomModal').classList.add('active');
        }

        function closeRoomModal() {
            document.getElementById('roomModal').classList.remove('active');
            currentRoomId = null;
        }

        async function saveRoom() {
            const roomData = {
                room_number: document.getElementById('roomNumber').value,
                room_name: document.getElementById('roomName').value,
                building: document.getElementById('building').value || null,
                floor: document.getElementById('floor').value || null,
                capacity: document.getElementById('capacity').value || null
            };

            if (currentRoomId) {
                roomData.room_id = currentRoomId;
            }

            const method = currentRoomId ? 'PUT' : 'POST';
            const result = await Utils.apiRequest(CONFIG.ENDPOINTS.ROOMS, {
                method: method,
                body: JSON.stringify(roomData)
            });

            if (result.success) {
                Utils.showNotification(currentRoomId ? 'Room updated successfully' : 'Room created successfully', 'success');
                closeRoomModal();
                await loadRooms();
            } else {
                Utils.showNotification(result.message || 'Failed to save room', 'error');
            }
        }

        function showDeleteModal(id, name) {
            currentDeleteRoomId = id;
            document.getElementById('deleteRoomName').textContent = name;
            document.getElementById('deleteModal').classList.add('active');
        }

        function closeDeleteModal() {
            document.getElementById('deleteModal').classList.remove('active');
            currentDeleteRoomId = null;
        }

        async function confirmDelete() {
            if (!currentDeleteRoomId) {
                console.error('No room ID selected for deletion');
                showNotification('No room selected', 'error');
                return;
            }

            console.log('Deleting room with ID:', currentDeleteRoomId);

            try {
                const result = await Utils.apiRequest(CONFIG.ENDPOINTS.ROOMS, {
                    method: 'DELETE',
                    body: JSON.stringify({ room_id: currentDeleteRoomId })
                });

                console.log('Delete result:', result);

                if (result.success) {
                    showNotification('Room deleted successfully', 'success');
                    closeDeleteModal();
                    await loadRooms();
                } else {
                    showNotification(result.message || 'Failed to delete room', 'error');
                }
            } catch (error) {
                console.error('Error deleting room:', error);
                showNotification('Error deleting room: ' + error.message, 'error');
            }
        }

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

        function escapeHtml(text) {
            if (!text) return '';
            const div = document.createElement('div');
            div.textContent = text;
            return div.innerHTML;
        }

        async function viewRoomDevices(roomId, roomName) {
            document.getElementById('devicesRoomName').textContent = roomName;
            document.getElementById('devicesModal').classList.add('active');
            document.getElementById('devicesListContainer').innerHTML = '<div class="spinner"></div>';

            try {
                const result = await Utils.apiRequest(CONFIG.ENDPOINTS.ROOMS + '?room_id=' + roomId, {
                    method: 'GET'
                });

                if (result.success && result.data) {
                    displayRoomDevices(result.data);
                } else {
                    document.getElementById('devicesListContainer').innerHTML = '<p class="text-center">No devices found</p>';
                }
            } catch (error) {
                console.error('Error loading room details:', error);
                document.getElementById('devicesListContainer').innerHTML = '<p class="text-center text-danger">Error loading devices</p>';
            }
        }

        function displayRoomDevices(roomData) {
            const container = document.getElementById('devicesListContainer');
            
            let html = '';
            
            // Active Devices Section
            html += '<h4 style="margin-bottom: 16px;"><i class="fas fa-check-circle" style="color: var(--success-color);"></i> Active Devices</h4>';
            
            if (!roomData.active_devices || roomData.active_devices.length === 0) {
                html += '<p class="text-center" style="color: var(--text-secondary); margin-bottom: 30px;">No active devices</p>';
            } else {
                html += '<div class="table-container" style="margin-bottom: 30px;"><table class="data-table"><thead><tr>';
                html += '<th>Device ID</th>';
                html += '<th>Type</th>';
                html += '<th>Brand</th>';
                html += '<th>Model</th>';
                html += '<th>Installed By</th>';
                html += '<th>Installation Date</th>';
                html += '<th>Actions</th>';
                html += '</tr></thead><tbody>';

                roomData.active_devices.forEach(device => {
                    html += '<tr>';
                    html += `<td><code>${escapeHtml(device.device_unique_id)}</code></td>`;
                    html += `<td>${escapeHtml(device.type_name || 'N/A')}</td>`;
                    html += `<td>${escapeHtml(device.brand_name || 'N/A')}</td>`;
                    html += `<td>${escapeHtml(device.model || 'N/A')}</td>`;
                    html += `<td>${escapeHtml(device.installed_by_name || 'N/A')}</td>`;
                    html += `<td>${device.installed_date ? new Date(device.installed_date).toLocaleDateString() : 'N/A'}</td>`;
                    html += `<td><button class="btn btn-sm btn-info" onclick="showDeviceHistory(${device.device_id}, '${escapeHtml(device.device_unique_id)}')"><i class="fas fa-history"></i> History</button></td>`;
                    html += '</tr>';
                });

                html += '</tbody></table></div>';
            }
            
            // Withdrawn Devices Section
            html += '<h4 style="margin-bottom: 16px;"><i class="fas fa-arrow-down" style="color: var(--danger-color);"></i> Recently Withdrawn Devices</h4>';
            
            if (!roomData.withdrawn_devices || roomData.withdrawn_devices.length === 0) {
                html += '<p class="text-center" style="color: var(--text-secondary);">No withdrawn devices</p>';
            } else {
                html += '<div class="table-container"><table class="data-table"><thead><tr>';
                html += '<th>Device ID</th>';
                html += '<th>Type</th>';
                html += '<th>Brand</th>';
                html += '<th>Model</th>';
                html += '<th>Withdrawn By</th>';
                html += '<th>Withdrawal Date</th>';
                html += '<th>Reason</th>';
                html += '<th>Actions</th>';
                html += '</tr></thead><tbody>';

                roomData.withdrawn_devices.forEach(device => {
                    html += '<tr>';
                    html += `<td><code>${escapeHtml(device.device_unique_id)}</code></td>`;
                    html += `<td>${escapeHtml(device.type_name || 'N/A')}</td>`;
                    html += `<td>${escapeHtml(device.brand_name || 'N/A')}</td>`;
                    html += `<td>${escapeHtml(device.model || 'N/A')}</td>`;
                    html += `<td>${escapeHtml(device.withdrawn_by_name || 'N/A')}</td>`;
                    html += `<td>${device.withdrawn_date ? new Date(device.withdrawn_date).toLocaleDateString() : 'N/A'}</td>`;
                    html += `<td><span style="font-size: 12px;">${escapeHtml(device.withdrawal_notes || 'N/A')}</span></td>`;
                    html += `<td><button class="btn btn-sm btn-info" onclick="showDeviceHistory(${device.device_id}, '${escapeHtml(device.device_unique_id)}')"><i class="fas fa-history"></i> History</button></td>`;
                    html += '</tr>';
                });

                html += '</tbody></table></div>';
            }

            container.innerHTML = html;
        }

        async function showDeviceHistory(deviceId, deviceUniqueId) {
            document.getElementById('historyDeviceId').textContent = deviceUniqueId;
            document.getElementById('deviceHistoryModal').classList.add('active');
            document.getElementById('deviceHistoryContainer').innerHTML = '<div class="spinner"></div>';

            try {
                const result = await Utils.apiRequest(CONFIG.ENDPOINTS.DEVICE_HISTORY + '?device_id=' + deviceId, {
                    method: 'GET'
                });

                if (result.success && result.data) {
                    displayDeviceHistory(result.data);
                } else {
                    document.getElementById('deviceHistoryContainer').innerHTML = '<p class="text-center">No history found</p>';
                }
            } catch (error) {
                console.error('Error loading device history:', error);
                document.getElementById('deviceHistoryContainer').innerHTML = '<p class="text-center text-danger">Error loading history</p>';
            }
        }

        function displayDeviceHistory(history) {
            const container = document.getElementById('deviceHistoryContainer');
            
            if (!history || history.length === 0) {
                container.innerHTML = '<p class="text-center">No history records found</p>';
                return;
            }

            let html = '<div class="table-container"><table class="data-table"><thead><tr>';
            html += '<th>Room</th>';
            html += '<th>Installation Date</th>';
            html += '<th>Installed By</th>';
            html += '<th>Status</th>';
            html += '<th>Withdrawal Date</th>';
            html += '<th>Withdrawn By</th>';
            html += '<th>Reason</th>';
            html += '</tr></thead><tbody>';

            history.forEach(record => {
                const statusClass = record.status === 'active' ? 'success' : record.status === 'withdrawn' ? 'danger' : 'warning';
                
                html += '<tr>';
                html += `<td><strong>${escapeHtml(record.room_number || 'N/A')}</strong> - ${escapeHtml(record.room_name || 'N/A')}</td>`;
                html += `<td>${record.installation_date ? new Date(record.installation_date).toLocaleDateString() : 'N/A'}</td>`;
                html += `<td>${escapeHtml(record.installed_by_name || record.installer_name || 'N/A')}</td>`;
                html += `<td><span class="badge badge-${statusClass}">${escapeHtml(record.status || 'N/A')}</span></td>`;
                html += `<td>${record.withdrawal_date ? new Date(record.withdrawal_date).toLocaleDateString() : '-'}</td>`;
                html += `<td>${escapeHtml(record.withdrawn_by_name || '-')}</td>`;
                html += `<td><span style="font-size: 12px;">${escapeHtml(record.withdrawal_reason || '-')}</span></td>`;
                html += '</tr>';
            });

            html += '</tbody></table></div>';
            container.innerHTML = html;
        }

        function closeDevicesModal() {
            document.getElementById('devicesModal').classList.remove('active');
        }

        function closeDeviceHistoryModal() {
            document.getElementById('deviceHistoryModal').classList.remove('active');
        }

        // Close modals when clicking outside
        window.addEventListener('click', function(event) {
            if (event.target.id === 'roomModal') {
                closeRoomModal();
            }
            if (event.target.id === 'deleteModal') {
                closeDeleteModal();
            }
            if (event.target.id === 'devicesModal') {
                closeDevicesModal();
            }
            if (event.target.id === 'deviceHistoryModal') {
                closeDeviceHistoryModal();
            }
        });
