/**
 * Gate Passes Page JavaScript
 */

let gatePassesList = [];
let filteredGatePasses = [];

/**
 * Initialize page
 */
document.addEventListener('DOMContentLoaded', async () => {
    // Check authentication
    if (!Utils.isLoggedIn()) {
        window.location.href = 'login.html';
        return;
    }

    // Initialize user info in sidebar
    Utils.initUserInfo();

    // Setup event listeners
    setupEventListeners();

    // Load gate passes
    await loadGatePasses();
});

/**
 * Setup event listeners
 */
function setupEventListeners() {
    // Logout
    document.getElementById('logoutBtn').addEventListener('click', Utils.logout);

    // Filters
    document.getElementById('filterDateFrom').addEventListener('change', applyFilters);
    document.getElementById('filterDateTo').addEventListener('change', applyFilters);
    document.getElementById('filterSearch').addEventListener('input', applyFilters);
    document.getElementById('clearFiltersBtn').addEventListener('click', clearFilters);
}

/**
 * Load gate passes
 */
async function loadGatePasses() {
    const result = await Utils.apiRequest(CONFIG.ENDPOINTS.GATE_PASSES);

    if (result.success) {
        gatePassesList = result.data;
        filteredGatePasses = [...gatePassesList];
        
        updateStatistics();
        renderGatePasses();
    } else {
        Utils.showAlert('Error loading gate passes: ' + result.message, 'error');
    }
}

/**
 * Update statistics
 */
function updateStatistics() {
    const total = gatePassesList.length;
    
    // Get current date info
    const now = new Date();
    const today = now.toISOString().split('T')[0];
    const startOfWeek = new Date(now);
    startOfWeek.setDate(now.getDate() - now.getDay());
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

    // Calculate stats
    const todayCount = gatePassesList.filter(gp => 
        gp.gate_pass_date === today
    ).length;

    const weekCount = gatePassesList.filter(gp => 
        new Date(gp.gate_pass_date) >= startOfWeek
    ).length;

    const monthCount = gatePassesList.filter(gp => 
        new Date(gp.gate_pass_date) >= startOfMonth
    ).length;

    // Update display
    document.getElementById('totalGatePasses').textContent = total;
    document.getElementById('todayGatePasses').textContent = todayCount;
    document.getElementById('thisWeekGatePasses').textContent = weekCount;
    document.getElementById('thisMonthGatePasses').textContent = monthCount;
}

/**
 * Render gate passes table
 */
function renderGatePasses() {
    const tbody = document.getElementById('gatePassesTableBody');

    if (filteredGatePasses.length === 0) {
        tbody.innerHTML = '<tr><td colspan="8" class="text-center">No gate passes found</td></tr>';
        return;
    }

    let html = '';
    filteredGatePasses.forEach(gp => {
        const statusBadge = gp.status === 'active' 
            ? '<span class="badge badge-success">Active</span>' 
            : gp.status === 'completed'
            ? '<span class="badge badge-info">Completed</span>'
            : '<span class="badge badge-warning">Cancelled</span>';

        const carrierInfo = gp.carrier_name + (gp.carrier_id ? ` (${gp.carrier_id})` : '');
        const destination = gp.room_number ? `${gp.room_number} - ${gp.room_name}` : 'N/A';

        html += `
            <tr>
                <td><strong>${gp.gate_pass_number}</strong></td>
                <td>${Utils.formatDate(gp.gate_pass_date)}</td>
                <td>${gp.device_unique_id}</td>
                <td>${gp.type_name}</td>
                <td>${destination}</td>
                <td>${carrierInfo}</td>
                <td>${statusBadge}</td>
                <td>
                    <button class="btn btn-sm btn-primary" onclick="viewGatePass(${gp.gate_pass_id})" title="View Gate Pass">
                        <i class="fas fa-eye"></i> View
                    </button>
                    <button class="btn btn-sm btn-info" onclick="printGatePass(${gp.gate_pass_id})" title="Print Gate Pass">
                        <i class="fas fa-print"></i> Print
                    </button>
                    ${Utils.isAdmin() ? `
                        <button class="btn btn-sm btn-danger" onclick="deleteGatePass(${gp.gate_pass_id})" title="Delete">
                            <i class="fas fa-trash"></i>
                        </button>
                    ` : ''}
                </td>
            </tr>
        `;
    });

    tbody.innerHTML = html;
}

/**
 * Apply filters
 */
function applyFilters() {
    const dateFrom = document.getElementById('filterDateFrom').value;
    const dateTo = document.getElementById('filterDateTo').value;
    const search = document.getElementById('filterSearch').value.toLowerCase().trim();

    filteredGatePasses = gatePassesList.filter(gp => {
        // Date filter
        if (dateFrom && (gp.gate_pass_date || gp.installed_date) < dateFrom) {
            return false;
        }
        if (dateTo && (gp.gate_pass_date || gp.installed_date) > dateTo) {
            return false;
        }

        // Search filter
        if (search) {
            const searchText = `
                ${gp.gate_pass_number} 
                ${gp.device_unique_id} 
                ${gp.room_number} 
                ${gp.room_name}
                ${gp.installed_by_name || ''}
            `.toLowerCase();

            if (!searchText.includes(search)) {
                return false;
            }
        }

        return true;
    });

    renderGatePasses();
}

/**
 * Clear filters
 */
function clearFilters() {
    document.getElementById('filterDateFrom').value = '';
    document.getElementById('filterDateTo').value = '';
    document.getElementById('filterSearch').value = '';
    
    filteredGatePasses = [...gatePassesList];
    renderGatePasses();
}

/**
 * View gate pass in new window
 */
function viewGatePass(gatePassId) {
    window.open(`gate-pass-standalone.html?id=${gatePassId}`, '_blank', 'width=900,height=800');
}

/**
 * Print gate pass directly
 */
function printGatePass(gatePassId) {
    const printWindow = window.open(`gate-pass-standalone.html?id=${gatePassId}`, '_blank', 'width=900,height=800');
    
    // Auto-print when loaded
    printWindow.addEventListener('load', () => {
        setTimeout(() => {
            printWindow.print();
        }, 500);
    });
}

/**
 * Delete gate pass
 */
async function deleteGatePass(gatePassId) {
    if (!confirm('Are you sure you want to delete this gate pass?')) {
        return;
    }

    const result = await Utils.apiRequest(CONFIG.ENDPOINTS.GATE_PASSES, {
        method: 'DELETE',
        body: JSON.stringify({ gate_pass_id: gatePassId })
    });

    if (result.success) {
        Utils.showAlert('Gate pass deleted successfully!', 'success');
        await loadGatePasses();
    } else {
        Utils.showAlert('Error: ' + result.message, 'error');
    }
}
