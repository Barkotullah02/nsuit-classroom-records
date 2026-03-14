/**
 * Invalid Installation Dates Module
 * Super Admin can view and fix invalid installation dates.
 */

let invalidInstallations = [];

document.addEventListener('DOMContentLoaded', async () => {
    if (!Utils.checkAuth()) {
        return;
    }

    if (!Utils.isSuperAdmin()) {
        window.location.href = 'dashboard.html';
        return;
    }

    initializeEventListeners();
    await loadInvalidInstallations();
});

function initializeEventListeners() {
    document.getElementById('refreshBtn').addEventListener('click', () => loadInvalidInstallations());

    document.getElementById('closeEditDatesModalBtn').addEventListener('click', closeEditDatesModal);
    document.getElementById('cancelEditDatesBtn').addEventListener('click', closeEditDatesModal);
    document.getElementById('editDatesForm').addEventListener('submit', handleUpdateDates);
}

async function loadInvalidInstallations() {
    const result = await Utils.apiRequest(CONFIG.ENDPOINTS.INVALID_INSTALLATION_DATES, {
        method: 'GET'
    });

    if (result.success) {
        invalidInstallations = result.data || [];
        renderInvalidInstallations();
    } else {
        Utils.showAlert(result.message || 'Failed to load invalid installation records');
    }
}

function formatInvalidReason(reason) {
    switch (reason) {
        case 'MISSING_OR_ZERO_INSTALLED_DATE':
            return 'Installed date missing or zero-date';
        case 'WITHDRAWN_WITHOUT_WITHDRAWN_DATE':
            return 'Withdrawn status without withdrawn date';
        case 'WITHDRAWN_BEFORE_INSTALLED':
            return 'Withdrawn date earlier than installed date';
        default:
            return reason || 'Unknown';
    }
}

function renderInvalidInstallations() {
    const tbody = document.getElementById('invalidInstallationsTableBody');

    if (!invalidInstallations.length) {
        tbody.innerHTML = '<tr><td colspan="9" class="text-center">No invalid installation dates found</td></tr>';
        return;
    }

    tbody.innerHTML = invalidInstallations.map(inst => {
        const deviceLabel = `${inst.device_unique_id} (${inst.brand_name} ${inst.model || ''})`;
        const roomLabel = `${inst.building || ''} ${inst.room_number}`.trim();

        return `
            <tr>
                <td>${inst.installation_id}</td>
                <td>${escapeHtml(deviceLabel)}</td>
                <td>${escapeHtml(roomLabel)}</td>
                <td>${inst.installed_date ? Utils.formatDate(inst.installed_date) : '<span class="text-danger">Invalid</span>'}</td>
                <td>${inst.withdrawn_date ? Utils.formatDate(inst.withdrawn_date) : '<span class="text-muted">N/A</span>'}</td>
                <td>${inst.gate_pass_date ? Utils.formatDate(inst.gate_pass_date) : '<span class="text-muted">N/A</span>'}</td>
                <td>${escapeHtml(inst.status)}</td>
                <td><span class="badge badge-danger">${escapeHtml(formatInvalidReason(inst.invalid_reason))}</span></td>
                <td>
                    <button class="btn btn-sm btn-primary" onclick="openEditDatesModal(${inst.installation_id})">
                        <i class="fas fa-edit"></i> Update Dates
                    </button>
                </td>
            </tr>
        `;
    }).join('');
}

function openEditDatesModal(installationId) {
    const record = invalidInstallations.find(item => Number(item.installation_id) === Number(installationId));
    if (!record) return;

    document.getElementById('editInstallationId').value = record.installation_id;
    document.getElementById('editInstalledDate').value = normalizeDateForInput(record.installed_date);
    document.getElementById('editWithdrawnDate').value = normalizeDateForInput(record.withdrawn_date);
    document.getElementById('editGatePassDate').value = normalizeDateForInput(record.gate_pass_date);

    document.getElementById('editDeviceInfo').innerHTML = `
        <div style="background-color: var(--bg-color); padding: 16px; border-radius: 8px;">
            <p><strong>Device:</strong> ${escapeHtml(record.device_unique_id)}</p>
            <p><strong>Room:</strong> ${escapeHtml(`${record.building || ''} ${record.room_number}`.trim())}</p>
            <p><strong>Issue:</strong> ${escapeHtml(formatInvalidReason(record.invalid_reason))}</p>
        </div>
    `;

    document.getElementById('editDatesModal').classList.add('active');
}

function closeEditDatesModal() {
    document.getElementById('editDatesModal').classList.remove('active');
}

async function handleUpdateDates(e) {
    e.preventDefault();

    const payload = {
        installation_id: Number(document.getElementById('editInstallationId').value),
        installed_date: normalizeDateForApi(document.getElementById('editInstalledDate').value),
        withdrawn_date: normalizeDateForApi(document.getElementById('editWithdrawnDate').value),
        gate_pass_date: normalizeDateForApi(document.getElementById('editGatePassDate').value)
    };

    const result = await Utils.apiRequest(CONFIG.ENDPOINTS.INVALID_INSTALLATION_DATES, {
        method: 'PUT',
        body: JSON.stringify(payload)
    });

    if (result.success) {
        closeEditDatesModal();
        await loadInvalidInstallations();
        Utils.showAlert('Installation dates updated successfully', 'success');
    } else {
        Utils.showAlert(result.message || 'Failed to update dates');
    }
}

function normalizeDateForInput(value) {
    if (!value || value === '0000-00-00') {
        return '';
    }
    return value;
}

function normalizeDateForApi(value) {
    if (!value) {
        return null;
    }
    return value;
}

function escapeHtml(text) {
    if (text === null || text === undefined) return '';
    const div = document.createElement('div');
    div.textContent = String(text);
    return div.innerHTML;
}

window.addEventListener('click', (event) => {
    const modal = document.getElementById('editDatesModal');
    if (event.target === modal) {
        closeEditDatesModal();
    }
});
