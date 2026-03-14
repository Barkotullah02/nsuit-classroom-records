        let currentUserId = null;
        let deleteUserId = null;

        // Initialize
        document.addEventListener('DOMContentLoaded', function() {
            Utils.checkAuth();
            
            // Check if user is admin
            const user = Utils.getCurrentUser();
            if (user && (user.role === CONFIG.ROLES.SUPER_ADMIN || user.role === CONFIG.ROLES.ADMIN)) {
                document.getElementById('userManagementNav').style.display = 'block';
                loadUsers();
            } else {
                window.location.href = '/dashboard';
            }
        });

        async function loadUsers() {
            try {
                const result = await Utils.apiRequest(CONFIG.ENDPOINTS.USERS, {
                    method: 'GET'
                });

                if (result.success) {
                    displayUsers(result.data);
                } else {
                    Utils.showAlert(result.message || 'Failed to load users', 'error');
                }
            } catch (error) {
                console.error('Error loading users:', error);
                Utils.showAlert('Failed to load users', 'error');
            }
        }

        function displayUsers(users) {
            const container = document.getElementById('usersContainer');
            
            if (!users || users.length === 0) {
                container.innerHTML = '<p class="text-center">No users found</p>';
                return;
            }

            let html = '';
            users.forEach(user => {
                const isActive = user.is_active == 1;
                const roleClass = user.role;
                const createdDate = new Date(user.created_at).toLocaleDateString();

                html += `
                    <div class="user-card ${!isActive ? 'inactive' : ''}">
                        <div class="user-header">
                            <div class="user-info">
                                <h3>
                                    <i class="fas fa-user-circle"></i> ${Utils.escapeHtml(user.full_name)}
                                    ${!isActive ? '<span style="color: #f44336;">(Inactive)</span>' : ''}
                                </h3>
                                <div class="user-meta">
                                    <strong>@${Utils.escapeHtml(user.username)}</strong> | 
                                    ${Utils.escapeHtml(user.email)} | 
                                    <span class="role-badge ${roleClass}">${user.role}</span>
                                </div>
                                <div class="user-meta" style="margin-top: 0.5rem;">
                                    <i class="fas fa-calendar"></i> Created: ${createdDate}
                                </div>
                            </div>
                            <div class="user-actions">
                                <button class="btn btn-sm btn-primary" onclick="showEditUserModal(${user.user_id}, '${Utils.escapeHtml(user.username)}', '${Utils.escapeHtml(user.full_name)}', '${Utils.escapeHtml(user.email)}', '${user.role}', ${user.is_active})">
                                    <i class="fas fa-edit"></i> Edit
                                </button>
                                <button class="btn btn-sm btn-danger" onclick="showDeleteModal(${user.user_id}, '${Utils.escapeHtml(user.full_name)}')" ${!isActive ? 'disabled' : ''}>
                                    <i class="fas fa-user-slash"></i> Deactivate
                                </button>
                            </div>
                        </div>
                    </div>
                `;
            });

            container.innerHTML = html;
        }

        function showAddUserModal() {
            currentUserId = null;
            document.getElementById('userModalTitle').innerHTML = '<i class="fas fa-user-plus"></i> Add User';
            document.getElementById('userForm').reset();
            document.getElementById('userId').value = '';
            document.getElementById('isActive').checked = true;
            document.getElementById('passwordGroup').style.display = 'block';
            document.getElementById('confirmPasswordGroup').style.display = 'block';
            document.getElementById('password').required = true;
            document.getElementById('confirmPassword').required = true;
            document.getElementById('userModal').classList.add('active');
        }

        function showEditUserModal(id, username, fullName, email, role, isActive) {
            currentUserId = id;
            document.getElementById('userModalTitle').innerHTML = '<i class="fas fa-edit"></i> Edit User';
            document.getElementById('userId').value = id;
            document.getElementById('username').value = username;
            document.getElementById('fullName').value = fullName;
            document.getElementById('email').value = email;
            document.getElementById('role').value = role;
            document.getElementById('isActive').checked = isActive == 1;
            
            // Make password optional for editing
            document.getElementById('passwordGroup').style.display = 'block';
            document.getElementById('confirmPasswordGroup').style.display = 'block';
            document.getElementById('password').required = false;
            document.getElementById('confirmPassword').required = false;
            document.getElementById('password').value = '';
            document.getElementById('confirmPassword').value = '';
            
            const passwordLabel = document.querySelector('label[for="password"]');
            passwordLabel.textContent = 'New Password (leave blank to keep current)';
            
            document.getElementById('userModal').classList.add('active');
        }

        function closeUserModal() {
            document.getElementById('userModal').classList.remove('active');
            currentUserId = null;
        }

        async function saveUser() {
            const userData = {
                username: document.getElementById('username').value.trim(),
                full_name: document.getElementById('fullName').value.trim(),
                email: document.getElementById('email').value.trim(),
                role: document.getElementById('role').value,
                is_active: document.getElementById('isActive').checked
            };

            const password = document.getElementById('password').value;
            const confirmPassword = document.getElementById('confirmPassword').value;

            // Validate
            if (!userData.username || !userData.full_name || !userData.email || !userData.role) {
                Utils.showAlert('Please fill all required fields', 'error');
                return;
            }

            // Password validation
            if (currentUserId) {
                // Editing - password is optional
                if (password || confirmPassword) {
                    if (password !== confirmPassword) {
                        Utils.showAlert('Passwords do not match', 'error');
                        return;
                    }
                    if (password.length < 6) {
                        Utils.showAlert('Password must be at least 6 characters', 'error');
                        return;
                    }
                    userData.password = password;
                }
                userData.user_id = currentUserId;
            } else {
                // Adding - password is required
                if (!password || !confirmPassword) {
                    Utils.showAlert('Password is required', 'error');
                    return;
                }
                if (password !== confirmPassword) {
                    Utils.showAlert('Passwords do not match', 'error');
                    return;
                }
                if (password.length < 6) {
                    Utils.showAlert('Password must be at least 6 characters', 'error');
                    return;
                }
                userData.password = password;
            }

            try {
                const method = currentUserId ? 'PUT' : 'POST';
                const result = await Utils.apiRequest(CONFIG.ENDPOINTS.USERS, {
                    method: method,
                    body: JSON.stringify(userData)
                });

                if (result.success) {
                    Utils.showAlert(result.message, 'success');
                    closeUserModal();
                    loadUsers();
                } else {
                    Utils.showAlert(result.message || 'Failed to save user', 'error');
                }
            } catch (error) {
                console.error('Error saving user:', error);
                Utils.showAlert('Failed to save user', 'error');
            }
        }

        function showDeleteModal(userId, userName) {
            deleteUserId = userId;
            document.getElementById('deleteUserName').textContent = userName;
            document.getElementById('deleteModal').classList.add('active');
        }

        function closeDeleteModal() {
            document.getElementById('deleteModal').classList.remove('active');
            deleteUserId = null;
        }

        async function confirmDelete() {
            if (!deleteUserId) return;

            try {
                const result = await Utils.apiRequest(CONFIG.ENDPOINTS.USERS, {
                    method: 'DELETE',
                    body: JSON.stringify({ user_id: deleteUserId })
                });

                if (result.success) {
                    Utils.showAlert(result.message, 'success');
                    closeDeleteModal();
                    loadUsers();
                } else {
                    Utils.showAlert(result.message || 'Failed to deactivate user', 'error');
                }
            } catch (error) {
                console.error('Error deactivating user:', error);
                Utils.showAlert('Failed to deactivate user', 'error');
            }
        }

        // Logout
        document.getElementById('logoutBtn').addEventListener('click', () => Utils.logout());
    
