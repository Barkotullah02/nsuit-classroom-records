/**
 * Dashboard Module
 * Handles dashboard statistics and recent activities
 */

document.addEventListener('DOMContentLoaded', async () => {
    await loadDashboardData();

    // Auto-refresh every 60 seconds
    setInterval(loadDashboardData, 60000);
});

/**
 * Load dashboard statistics
 */
async function loadDashboardData() {
    try {
        const result = await Utils.apiRequest(CONFIG.ENDPOINTS.DASHBOARD, {
            method: 'GET'
        });

        if (result.success) {
            console.log('Dashboard data received:', result.data);
            console.log('available_by_type:', result.data.available_by_type);
            updateStats(result.data);
            updateDevicesByType(result.data.devices_by_type);
            updateAvailableDevicesByType(result.data.available_by_type);
            updateRecentActivities(result.data.recent_activities);
            updateLastUpdated();
        } else {
            console.error('Failed to load dashboard data:', result.message);
        }

        // Load gate passes count separately
        await loadGatePassesCount();
    } catch (error) {
        console.error('Error loading dashboard:', error);
    }
}

/**
 * Load gate passes count
 */
async function loadGatePassesCount() {
    try {
        const result = await Utils.apiRequest(CONFIG.ENDPOINTS.GATE_PASSES);
        if (result.success) {
            document.getElementById('totalGatePasses').textContent = result.data.length;
        }
    } catch (error) {
        console.error('Error loading gate passes count:', error);
        document.getElementById('totalGatePasses').textContent = '0';
    }
}

/**
 * Update statistics cards
 */
function updateStats(data) {
    document.getElementById('totalDevices').textContent = data.total_devices || 0;
    document.getElementById('activeInstallations').textContent = data.active_installations || 0;
    document.getElementById('withdrawnDevices').textContent = data.withdrawn_devices || 0;
    document.getElementById('availableDevices').textContent = data.available_devices || 0;
    document.getElementById('totalRooms').textContent = data.total_rooms || 0;
}

/**
 * Update devices by type chart
 */
function updateDevicesByType(devicesByType) {
    const container = document.getElementById('devicesByTypeContainer');
    
    if (!devicesByType || devicesByType.length === 0) {
        container.innerHTML = '<p class="text-center text-muted">No data available</p>';
        return;
    }

    // Create a simple bar chart using HTML/CSS
    let html = '<div style="padding: 20px;">';
    
    const maxCount = Math.max(...devicesByType.map(item => parseInt(item.count)));
    
    devicesByType.forEach(item => {
        const percentage = maxCount > 0 ? (item.count / maxCount) * 100 : 0;
        
        html += `
            <div style="margin-bottom: 20px;">
                <div style="display: flex; justify-content: space-between; margin-bottom: 8px;">
                    <span style="font-weight: 500;">${item.type_name}</span>
                    <span style="color: var(--text-secondary);">${item.count} devices</span>
                </div>
                <div style="background-color: var(--bg-color); height: 24px; border-radius: 8px; overflow: hidden;">
                    <div style="background: linear-gradient(90deg, var(--primary-color), var(--primary-light)); 
                               height: 100%; width: ${percentage}%; transition: width 0.3s;"></div>
                </div>
            </div>
        `;
    });
    
    html += '</div>';
    container.innerHTML = html;
}

/**
 * Update available devices by type chart
 */
function updateAvailableDevicesByType(availableByType) {
    const container = document.getElementById('availableDevicesByTypeContainer');
    
    console.log('updateAvailableDevicesByType called with:', availableByType);
    console.log('Container found:', container);
    
    if (!availableByType || availableByType.length === 0) {
        container.innerHTML = '<p class="text-center text-muted" style="padding: 20px;">No available devices</p>';
        return;
    }

    // Create a simple bar chart using HTML/CSS
    let html = '<div style="padding: 20px;">';
    
    const maxCount = Math.max(...availableByType.map(item => parseInt(item.count)));
    
    availableByType.forEach(item => {
        const percentage = maxCount > 0 ? (item.count / maxCount) * 100 : 0;
        
        html += `
            <div style="margin-bottom: 20px;">
                <div style="display: flex; justify-content: space-between; margin-bottom: 8px;">
                    <span style="font-weight: 500;">${item.type_name}</span>
                    <span style="color: var(--text-secondary);">${item.count} available</span>
                </div>
                <div style="background-color: var(--bg-color); height: 24px; border-radius: 8px; overflow: hidden;">
                    <div style="background: linear-gradient(90deg, #06b6d4, #0891b2); 
                               height: 100%; width: ${percentage}%; transition: width 0.3s;"></div>
                </div>
            </div>
        `;
    });
    
    html += '</div>';
    container.innerHTML = html;
}

/**
 * Update recent activities table
 */
function updateRecentActivities(activities) {
    const tbody = document.getElementById('recentActivitiesBody');
    
    if (!activities || activities.length === 0) {
        tbody.innerHTML = '<tr><td colspan="4" class="text-center">No recent activities</td></tr>';
        return;
    }

    let html = '';
    activities.forEach(activity => {
        const actionBadge = getActionBadge(activity.action);
        
        html += `
            <tr>
                <td>${actionBadge}</td>
                <td><code>${activity.table_name}</code></td>
                <td>${activity.user_name}</td>
                <td>${Utils.formatDateTime(activity.created_at)}</td>
            </tr>
        `;
    });

    tbody.innerHTML = html;
}

/**
 * Get badge for action type
 */
function getActionBadge(action) {
    const badges = {
        'CREATE': '<span class="badge badge-success">CREATE</span>',
        'UPDATE': '<span class="badge badge-primary">UPDATE</span>',
        'DELETE': '<span class="badge badge-danger">DELETE</span>',
        'SOFT_DELETE': '<span class="badge badge-warning">SOFT DELETE</span>',
        'RESTORE': '<span class="badge badge-success">RESTORE</span>',
        'LOGIN': '<span class="badge badge-primary">LOGIN</span>',
        'LOGOUT': '<span class="badge badge-secondary">LOGOUT</span>'
    };

    return badges[action] || `<span class="badge">${action}</span>`;
}

/**
 * Update last updated timestamp
 */
function updateLastUpdated() {
    const lastUpdatedEl = document.getElementById('lastUpdated');
    if (lastUpdatedEl) {
        const now = new Date();
        lastUpdatedEl.textContent = `Last updated: ${now.toLocaleTimeString()}`;
    }
}
