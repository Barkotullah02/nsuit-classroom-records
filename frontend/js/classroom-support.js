/**
 * Classroom Support Management
 * Handle support records and team members
 */

let currentUser = null;
let teamMembers = [];
let supportRecords = [];
let rooms = [];

// Initialize
document.addEventListener('DOMContentLoaded', async function() {
    // Load current user from localStorage
    currentUser = Utils.getCurrentUser();
    
    // If no user data, try to get it from the API or just continue
    // The API calls will handle authentication automatically
    if (!currentUser) {
        // Set a default to avoid errors
        currentUser = { full_name: 'User', role: 'viewer', user_id: 0 };
    }

    displayUserInfo();
    
    // Show team members section only for admins
    if (currentUser.role === 'admin') {
        const teamSection = document.getElementById('teamMembersSection');
        if (teamSection) teamSection.style.display = 'block';
    }

    await loadInitialData();
    setupEventListeners();
});

async function loadInitialData() {
    try {
        await Promise.all([
            loadTeamMembers(),
            loadRooms(),
            loadSupportRecords(),
            loadStatistics()
        ]);
    } catch (error) {
        console.error('Error loading initial data:', error);
        showError('Failed to load initial data');
    }
}

function setupEventListeners() {
    // Logout button
    const logoutBtn = document.getElementById('logoutBtn');
    if (logoutBtn) {
        logoutBtn.addEventListener('click', logout);
    }
    
    // Support record form
    document.getElementById('supportRecordForm').addEventListener('submit', handleSupportSubmit);
    
    // Team member form (admin only)
    if (currentUser.role === 'admin') {
        document.getElementById('teamMemberForm').addEventListener('submit', handleTeamMemberSubmit);
    }

    // Set default date and time
    const now = new Date();
    document.getElementById('supportDate').valueAsDate = now;
    document.getElementById('supportTime').value = now.toTimeString().slice(0, 5);
}

// Load team members
async function loadTeamMembers() {
    try {
        const data = await Utils.apiRequest(CONFIG.ENDPOINTS.SUPPORT_TEAM, {
            method: 'GET'
        });
        
        if (data.success) {
            teamMembers = data.data;
            updateTeamMemberDropdowns();
            
            if (currentUser.role === 'admin') {
                displayTeamMembersList();
            }
        }
    } catch (error) {
        console.error('Error loading team members:', error);
    }
}

function updateTeamMemberDropdowns() {
    const activeMembers = teamMembers.filter(m => m.is_active);
    
    // Support record form dropdown
    const supportMemberId = document.getElementById('supportMemberId');
    supportMemberId.innerHTML = '<option value="">Select Team Member</option>';
    activeMembers.forEach(member => {
        const option = document.createElement('option');
        option.value = member.member_id;
        option.textContent = `${member.member_name} - ${member.department || 'N/A'}`;
        supportMemberId.appendChild(option);
    });

    // Filter dropdown
    const filterMember = document.getElementById('filterMember');
    filterMember.innerHTML = '<option value="">All Members</option>';
    activeMembers.forEach(member => {
        const option = document.createElement('option');
        option.value = member.member_id;
        option.textContent = member.member_name;
        filterMember.appendChild(option);
    });
}

function displayTeamMembersList() {
    const container = document.getElementById('teamMembersList');
    
    if (teamMembers.length === 0) {
        container.innerHTML = '<p class="text-muted">No team members found. Add your first team member above.</p>';
        return;
    }

    let html = '';
    teamMembers.forEach(member => {
        const statusBadge = member.is_active 
            ? '<span class="badge badge-success">Active</span>' 
            : '<span class="badge badge-secondary">Inactive</span>';
        
        html += `
            <div class="team-member-card">
                <div class="d-flex justify-content-between align-items-start">
                    <div>
                        <h5 class="mb-1">${Utils.escapeHtml(member.member_name)} ${statusBadge}</h5>
                        <p class="mb-1"><i class="fas fa-building text-muted"></i> ${Utils.escapeHtml(member.department || 'N/A')}</p>
                        ${member.email ? `<p class="mb-1"><i class="fas fa-envelope text-muted"></i> ${Utils.escapeHtml(member.email)}</p>` : ''}
                        ${member.phone ? `<p class="mb-0"><i class="fas fa-phone text-muted"></i> ${Utils.escapeHtml(member.phone)}</p>` : ''}
                    </div>
                    <div class="action-buttons">
                        <button class="btn btn-sm btn-primary" onclick="editTeamMember(${member.member_id})">
                            <i class="fas fa-edit"></i>
                        </button>
                        <button class="btn btn-sm btn-danger" onclick="deleteTeamMember(${member.member_id}, '${Utils.escapeHtml(member.member_name)}')">
                            <i class="fas fa-trash"></i>
                        </button>
                    </div>
                </div>
            </div>
        `;
    });

    container.innerHTML = html;
}

// Load rooms
async function loadRooms() {
    try {
        const data = await Utils.apiRequest(CONFIG.ENDPOINTS.ROOMS, {
            method: 'GET'
        });
        
        if (data.success) {
            rooms = data.data;
            updateRoomDropdown();
        }
    } catch (error) {
        console.error('Error loading rooms:', error);
    }
}

function updateRoomDropdown() {
    const supportRoomId = document.getElementById('supportRoomId');
    supportRoomId.innerHTML = '<option value="">Select Room</option>';
    
    rooms.forEach(room => {
        const option = document.createElement('option');
        option.value = room.room_id;
        option.textContent = `${room.room_name} (${room.building})`;
        supportRoomId.appendChild(option);
    });
}

// Load support records
async function loadSupportRecords() {
    try {
        let endpoint = CONFIG.ENDPOINTS.CLASSROOM_SUPPORT;
        const params = new URLSearchParams();

        const memberId = document.getElementById('filterMember').value;
        const dateFrom = document.getElementById('filterDateFrom').value;
        const dateTo = document.getElementById('filterDateTo').value;
        const status = document.getElementById('filterStatus').value;
        const issueType = document.getElementById('filterIssueType').value;

        if (memberId) params.append('member_id', memberId);
        if (dateFrom) params.append('date_from', dateFrom);
        if (dateTo) params.append('date_to', dateTo);
        if (status) params.append('status', status);
        if (issueType) params.append('issue_type', issueType);

        if (params.toString()) {
            endpoint += '?' + params.toString();
        }

        const data = await Utils.apiRequest(endpoint, {
            method: 'GET'
        });
        
        if (data.success) {
            supportRecords = data.data;
            displaySupportRecords();
        }
    } catch (error) {
        console.error('Error loading support records:', error);
        showError('Failed to load support records');
    }
}

function displaySupportRecords() {
    const tbody = document.getElementById('supportRecordsTable');
    
    if (supportRecords.length === 0) {
        tbody.innerHTML = '<tr><td colspan="9" class="text-center text-muted">No support records found</td></tr>';
        return;
    }

    let html = '';
    supportRecords.forEach(record => {
        const datetime = new Date(record.support_datetime);
        const priorityClass = `priority-${record.priority.toLowerCase()}`;
        const statusBadge = getStatusBadge(record.status);
        
        html += `
            <tr>
                <td>${Utils.formatDateTime(datetime)}</td>
                <td>
                    <strong>${Utils.escapeHtml(record.member_name)}</strong><br>
                    <small class="text-muted">${Utils.escapeHtml(record.department || 'N/A')}</small>
                </td>
                <td>${Utils.escapeHtml(record.location)}</td>
                <td>${Utils.truncate(Utils.escapeHtml(record.support_description), 50)}</td>
                <td><span class="badge badge-info">${record.issue_type}</span></td>
                <td><span class="${priorityClass}">${record.priority}</span></td>
                <td>${statusBadge}</td>
                <td>${record.duration_minutes ? record.duration_minutes + ' min' : 'N/A'}</td>
                <td>
                    <div class="action-buttons">
                        <button class="btn btn-sm btn-info" onclick="viewSupport(${record.support_id})" title="View Details">
                            <i class="fas fa-eye"></i>
                        </button>
                        ${canEditSupport(record) ? `
                        <button class="btn btn-sm btn-primary" onclick="editSupport(${record.support_id})" title="Edit">
                            <i class="fas fa-edit"></i>
                        </button>
                        <button class="btn btn-sm btn-danger" onclick="deleteSupport(${record.support_id})" title="Delete">
                            <i class="fas fa-trash"></i>
                        </button>
                        ` : ''}
                    </div>
                </td>
            </tr>
        `;
    });

    tbody.innerHTML = html;
}

function getStatusBadge(status) {
    const statusMap = {
        'PENDING': { class: 'status-pending', text: 'Pending' },
        'IN_PROGRESS': { class: 'status-in-progress', text: 'In Progress' },
        'COMPLETED': { class: 'status-completed', text: 'Completed' },
        'CANCELLED': { class: 'status-cancelled', text: 'Cancelled' }
    };
    
    const s = statusMap[status] || { class: '', text: status };
    return `<span class="badge ${s.class}">${s.text}</span>`;
}

function canEditSupport(record) {
    // Admins can edit everything
    if (currentUser.role === 'admin') return true;
    
    // Users can only edit their own records
    return record.created_by === currentUser.user_id;
}

// Load statistics
async function loadStatistics() {
    try {
        const data = await Utils.apiRequest(CONFIG.ENDPOINTS.CLASSROOM_SUPPORT, {
            method: 'GET'
        });
        
        if (data.success) {
            const records = data.data;
            
            document.getElementById('totalSupports').textContent = records.length;
            document.getElementById('pendingSupports').textContent = 
                records.filter(r => r.status === 'PENDING').length;
            document.getElementById('completedSupports').textContent = 
                records.filter(r => r.status === 'COMPLETED').length;
            
            const activeCount = teamMembers.filter(m => m.is_active).length;
            document.getElementById('activeMembers').textContent = activeCount;
        }
    } catch (error) {
        console.error('Error loading statistics:', error);
    }
}

// Support record operations
function showNewSupportModal() {
    document.getElementById('supportModalTitle').innerHTML = '<i class="fas fa-plus"></i> New Support Record';
    document.getElementById('supportRecordForm').reset();
    document.getElementById('supportId').value = '';
    
    // Set defaults
    const now = new Date();
    document.getElementById('supportDate').valueAsDate = now;
    document.getElementById('supportTime').value = now.toTimeString().slice(0, 5);
    document.getElementById('supportStatus').value = 'PENDING';
    document.getElementById('supportPriority').value = 'MEDIUM';
    document.getElementById('supportIssueType').value = 'TECHNICAL';
    
    const modal = document.getElementById('supportModal');
    if (modal) modal.style.display = 'block';
}

function viewSupport(supportId) {
    const record = supportRecords.find(r => r.support_id === supportId);
    if (!record) return;

    const details = `
        <div class="row">
            <div class="col-md-6"><strong>Team Member:</strong></div>
            <div class="col-md-6">${Utils.escapeHtml(record.member_name)}</div>
        </div>
        <div class="row mt-2">
            <div class="col-md-6"><strong>Date & Time:</strong></div>
            <div class="col-md-6">${Utils.formatDateTime(new Date(record.support_datetime))}</div>
        </div>
        <div class="row mt-2">
            <div class="col-md-6"><strong>Location:</strong></div>
            <div class="col-md-6">${Utils.escapeHtml(record.location)}</div>
        </div>
        <div class="row mt-2">
            <div class="col-md-6"><strong>Description:</strong></div>
            <div class="col-md-6">${Utils.escapeHtml(record.support_description)}</div>
        </div>
        <div class="row mt-2">
            <div class="col-md-6"><strong>Issue Type:</strong></div>
            <div class="col-md-6">${record.issue_type}</div>
        </div>
        <div class="row mt-2">
            <div class="col-md-6"><strong>Priority:</strong></div>
            <div class="col-md-6">${record.priority}</div>
        </div>
        <div class="row mt-2">
            <div class="col-md-6"><strong>Status:</strong></div>
            <div class="col-md-6">${getStatusBadge(record.status)}</div>
        </div>
        ${record.duration_minutes ? `
        <div class="row mt-2">
            <div class="col-md-6"><strong>Duration:</strong></div>
            <div class="col-md-6">${record.duration_minutes} minutes</div>
        </div>` : ''}
        ${record.faculty_name ? `
        <div class="row mt-2">
            <div class="col-md-6"><strong>Faculty:</strong></div>
            <div class="col-md-6">${Utils.escapeHtml(record.faculty_name)}</div>
        </div>` : ''}
        ${record.devices_involved ? `
        <div class="row mt-2">
            <div class="col-md-6"><strong>Devices:</strong></div>
            <div class="col-md-6">${Utils.escapeHtml(record.devices_involved)}</div>
        </div>` : ''}
        ${record.notes ? `
        <div class="row mt-2">
            <div class="col-md-6"><strong>Notes:</strong></div>
            <div class="col-md-6">${Utils.escapeHtml(record.notes)}</div>
        </div>` : ''}
        <div class="row mt-2">
            <div class="col-md-6"><strong>Created By:</strong></div>
            <div class="col-md-6">${Utils.escapeHtml(record.created_by_name || 'N/A')}</div>
        </div>
    `;

    Utils.showModal('Support Record Details', details);
}

function editSupport(supportId) {
    const record = supportRecords.find(r => r.support_id === supportId);
    if (!record) return;

    document.getElementById('supportModalTitle').innerHTML = '<i class="fas fa-edit"></i> Edit Support Record';
    document.getElementById('supportId').value = record.support_id;
    document.getElementById('supportMemberId').value = record.member_id;
    document.getElementById('supportDate').value = record.support_date;
    document.getElementById('supportTime').value = record.support_time;
    document.getElementById('supportLocation').value = record.location;
    document.getElementById('supportRoomId').value = record.room_id || '';
    document.getElementById('supportDescription').value = record.support_description;
    document.getElementById('supportIssueType').value = record.issue_type;
    document.getElementById('supportPriority').value = record.priority;
    document.getElementById('supportStatus').value = record.status;
    document.getElementById('supportDuration').value = record.duration_minutes || '';
    document.getElementById('supportFacultyName').value = record.faculty_name || '';
    document.getElementById('supportDevices').value = record.devices_involved || '';
    document.getElementById('supportNotes').value = record.notes || '';

    const modal = document.getElementById('supportModal');
    if (modal) modal.style.display = 'block';
}

async function handleSupportSubmit(e) {
    e.preventDefault();

    const supportId = document.getElementById('supportId').value;
    const isEdit = !!supportId;

    const supportData = {
        member_id: document.getElementById('supportMemberId').value,
        support_date: document.getElementById('supportDate').value,
        support_time: document.getElementById('supportTime').value,
        location: document.getElementById('supportLocation').value,
        room_id: document.getElementById('supportRoomId').value || null,
        support_description: document.getElementById('supportDescription').value,
        issue_type: document.getElementById('supportIssueType').value,
        priority: document.getElementById('supportPriority').value,
        status: document.getElementById('supportStatus').value,
        duration_minutes: document.getElementById('supportDuration').value || null,
        faculty_name: document.getElementById('supportFacultyName').value || null,
        devices_involved: document.getElementById('supportDevices').value || null,
        notes: document.getElementById('supportNotes').value || null
    };

    if (isEdit) {
        supportData.support_id = supportId;
    }

    try {
        const data = await Utils.apiRequest(CONFIG.ENDPOINTS.CLASSROOM_SUPPORT, {
            method: isEdit ? 'PUT' : 'POST',
            body: JSON.stringify(supportData)
        });

        if (data.success) {
            showSuccess(isEdit ? 'Support record updated successfully' : 'Support record created successfully');
            const modal = document.getElementById('supportModal');
            if (modal) modal.style.display = 'none';
            await loadSupportRecords();
            await loadStatistics();
        } else {
            showError(data.message || 'Failed to save support record');
        }
    } catch (error) {
        console.error('Error saving support record:', error);
        showError('An error occurred while saving the support record');
    }
}

async function deleteSupport(supportId) {
    if (!confirm('Are you sure you want to delete this support record?')) {
        return;
    }

    try {
        const data = await Utils.apiRequest(`${CONFIG.ENDPOINTS.CLASSROOM_SUPPORT}?support_id=${supportId}`, {
            method: 'DELETE'
        });

        if (data.success) {
            showSuccess('Support record deleted successfully');
            await loadSupportRecords();
            await loadStatistics();
        } else {
            showError(data.message || 'Failed to delete support record');
        }
    } catch (error) {
        console.error('Error deleting support record:', error);
        showError('An error occurred while deleting the support record');
    }
}

// Team member operations (admin only)
function editTeamMember(memberId) {
    const member = teamMembers.find(m => m.member_id === memberId);
    if (!member) return;

    document.getElementById('teamMemberId').value = member.member_id;
    document.getElementById('teamMemberName').value = member.member_name;
    document.getElementById('teamMemberEmail').value = member.email || '';
    document.getElementById('teamMemberPhone').value = member.phone || '';
    document.getElementById('teamMemberDepartment').value = member.department || '';
    document.getElementById('teamMemberActive').checked = member.is_active;

    // Scroll to form
    document.getElementById('teamMemberForm').scrollIntoView({ behavior: 'smooth' });
}

async function handleTeamMemberSubmit(e) {
    e.preventDefault();

    const memberId = document.getElementById('teamMemberId').value;
    const isEdit = !!memberId;

    const memberData = {
        member_name: document.getElementById('teamMemberName').value,
        email: document.getElementById('teamMemberEmail').value || null,
        phone: document.getElementById('teamMemberPhone').value || null,
        department: document.getElementById('teamMemberDepartment').value || null,
        is_active: document.getElementById('teamMemberActive').checked
    };

    if (isEdit) {
        memberData.member_id = memberId;
    }

    try {
        const data = await Utils.apiRequest(CONFIG.ENDPOINTS.SUPPORT_TEAM, {
            method: isEdit ? 'PUT' : 'POST',
            body: JSON.stringify(memberData)
        });

        if (data.success) {
            showSuccess(isEdit ? 'Team member updated successfully' : 'Team member added successfully');
            resetTeamMemberForm();
            await loadTeamMembers();
            await loadStatistics();
        } else {
            showError(data.message || 'Failed to save team member');
        }
    } catch (error) {
        console.error('Error saving team member:', error);
        showError('An error occurred while saving the team member');
    }
}

async function deleteTeamMember(memberId, memberName) {
    if (!confirm(`Are you sure you want to delete ${memberName}?\n\nThis will fail if there are existing support records for this member.`)) {
        return;
    }

    try {
        const data = await Utils.apiRequest(`${CONFIG.ENDPOINTS.SUPPORT_TEAM}?member_id=${memberId}`, {
            method: 'DELETE'
        });

        if (data.success) {
            showSuccess('Team member deleted successfully');
            await loadTeamMembers();
            await loadStatistics();
        } else {
            showError(data.message || 'Failed to delete team member');
        }
    } catch (error) {
        console.error('Error deleting team member:', error);
        showError('An error occurred while deleting the team member');
    }
}

function resetTeamMemberForm() {
    document.getElementById('teamMemberForm').reset();
    document.getElementById('teamMemberId').value = '';
    document.getElementById('teamMemberActive').checked = true;
}

// UI helpers
function displayUserInfo() {
    const userName = document.getElementById('userName');
    const userRole = document.getElementById('userRole');
    const userAvatar = document.getElementById('userAvatar');
    
    if (userName) userName.textContent = currentUser.full_name;
    if (userRole) userRole.textContent = currentUser.role.charAt(0).toUpperCase() + currentUser.role.slice(1);
    if (userAvatar) userAvatar.textContent = currentUser.full_name.charAt(0).toUpperCase();
}

function showSuccess(message) {
    Utils.showNotification(message, 'success');
}

function showError(message) {
    Utils.showNotification(message, 'error');
}

function logout() {
    Utils.logout();
}

function closeSupportModal() {
    const modal = document.getElementById('supportModal');
    if (modal) modal.style.display = 'none';
}
