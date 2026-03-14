/**
 * Utility Functions
 * Common helper functions used across the application
 */

const Utils = {
    /**
     * Make API request with JWT token
     */
    async apiRequest(endpoint, options = {}) {
        try {
            const url = CONFIG.API_BASE_URL + endpoint;
            const token = this.getToken();
            
            const headers = {
                'Content-Type': 'application/json',
                ...options.headers
            };
            
            // Add Authorization header if token exists
            if (token) {
                headers['Authorization'] = `Bearer ${token}`;
            }
            
            const response = await fetch(url, {
                ...options,
                headers: headers
            });

            const data = await response.json();
            
            // If token expired or invalid, redirect to login
            if (!data.success && (response.status === 401 || response.status === 403)) {
                this.clearToken();
                if (!window.location.pathname.includes('login.html')) {
                    window.location.href = 'login.html';
                }
            }
            
            return data;
        } catch (error) {
            console.error('API Request Error:', error);
            return { success: false, message: 'Network error occurred' };
        }
    },

    /**
     * Show alert message
     */
    showAlert(message, type = 'error', containerId = 'alert-container') {
        const container = document.getElementById(containerId);
        if (!container) return;

        const alertClass = type === 'success' ? 'alert-success' : 'alert-error';
        container.innerHTML = `
            <div class="alert ${alertClass}">
                ${message}
            </div>
        `;

        // Auto-hide after 5 seconds
        setTimeout(() => {
            container.innerHTML = '';
        }, 5000);
    },

    /**
     * Get JWT token from localStorage
     */
    getToken() {
        return localStorage.getItem('jwt_token');
    },

    /**
     * Set JWT token in localStorage
     */
    setToken(token) {
        localStorage.setItem('jwt_token', token);
    },

    /**
     * Clear JWT token from localStorage
     */
    clearToken() {
        localStorage.removeItem('jwt_token');
        localStorage.removeItem(CONFIG.STORAGE_KEYS.USER);
    },

    /**
     * Get current user from localStorage
     */
    getCurrentUser() {
        const userStr = localStorage.getItem(CONFIG.STORAGE_KEYS.USER);
        if (!userStr) return null;

        try {
            return JSON.parse(userStr);
        } catch (error) {
            console.error('Invalid current_user in localStorage:', error);
            localStorage.removeItem(CONFIG.STORAGE_KEYS.USER);
            return null;
        }
    },

    /**
     * Set current user in localStorage
     */
    setCurrentUser(user) {
        localStorage.setItem(CONFIG.STORAGE_KEYS.USER, JSON.stringify(user));
    },

    /**
     * Clear current user from localStorage
     */
    clearCurrentUser() {
        this.clearToken();
    },

    /**
     * Check if user is logged in
     */
    isLoggedIn() {
        return this.getCurrentUser() !== null;
    },

    /**
     * Check if user is admin
     */
    isAdmin() {
        const user = this.getCurrentUser();
        return user && (user.role === CONFIG.ROLES.SUPER_ADMIN || user.role === CONFIG.ROLES.ADMIN);
    },

    /**
     * Check if user is super admin
     */
    isSuperAdmin() {
        const user = this.getCurrentUser();
        return user && user.role === CONFIG.ROLES.SUPER_ADMIN;
    },

    /**
     * Redirect to login if not authenticated
     */
    requireAuth() {
        if (!this.isLoggedIn()) {
            window.location.href = 'login.html';
            return false;
        }
        return true;
    },

    /**
     * Logout user
     */
    async logout() {
        await Utils.apiRequest(CONFIG.ENDPOINTS.AUTH, {
            method: 'DELETE'
        });

        Utils.clearToken();
        Utils.clearCurrentUser();
        window.location.href = 'login.html';
    },

    /**
     * Format date
     */
    formatDate(dateString) {
        if (!dateString) return 'N/A';
        const date = new Date(dateString);
        return date.toLocaleDateString('en-US', {
            year: 'numeric',
            month: 'short',
            day: 'numeric'
        });
    },

    /**
     * Format datetime
     */
    formatDateTime(dateString) {
        if (!dateString) return 'N/A';
        const date = new Date(dateString);
        return date.toLocaleString('en-US', {
            year: 'numeric',
            month: 'short',
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        });
    },

    /**
     * Get user initials for avatar
     */
    getUserInitials(name) {
        if (!name) return '?';
        const parts = name.split(' ');
        if (parts.length >= 2) {
            return parts[0][0] + parts[1][0];
        }
        return name.substring(0, 2);
    },

    /**
     * Initialize user info in sidebar
     */
    initUserInfo() {
        const user = this.getCurrentUser();
        if (!user) return;

        const userNameEl = document.getElementById('userName');
        const userRoleEl = document.getElementById('userRole');
        const userAvatarEl = document.getElementById('userAvatar');

        if (userNameEl) userNameEl.textContent = user.full_name || user.username;
        if (userRoleEl) {
            const roleDisplay = user.role
                .split('_')
                .map(part => part.charAt(0).toUpperCase() + part.slice(1))
                .join(' ');
            userRoleEl.textContent = roleDisplay;
        }
        if (userAvatarEl) {
            userAvatarEl.textContent = this.getUserInitials(user.full_name || user.username);
        }

        // Show User Management menu for admins only
        const userManagementNav = document.getElementById('userManagementNav');
        if (userManagementNav && (user.role === CONFIG.ROLES.SUPER_ADMIN || user.role === CONFIG.ROLES.ADMIN)) {
            userManagementNav.style.display = 'block';
        }

        const invalidInstallationDatesNav = document.getElementById('invalidInstallationDatesNav');
        if (invalidInstallationDatesNav && user.role === CONFIG.ROLES.SUPER_ADMIN) {
            invalidInstallationDatesNav.style.display = 'block';
        }
    },

    /**
     * Check authentication and initialize user info
     */
    checkAuth() {
        if (!this.requireAuth()) {
            return false;
        }
        this.initUserInfo();
        return true;
    },

    /**
     * Initialize logout button
     */
    initLogoutButton() {
        const logoutBtn = document.getElementById('logoutBtn');
        if (logoutBtn) {
            logoutBtn.addEventListener('click', () => this.logout());
        }
    },

    /**
     * Debounce function
     */
    debounce(func, wait) {
        let timeout;
        return function executedFunction(...args) {
            const later = () => {
                clearTimeout(timeout);
                func(...args);
            };
            clearTimeout(timeout);
            timeout = setTimeout(later, wait);
        };
    },

    /**
     * Show/hide element
     */
    toggleElement(elementId, show) {
        const element = document.getElementById(elementId);
        if (element) {
            element.classList.toggle('hidden', !show);
        }
    },

    /**
     * Calculate days difference
     */
    daysDifference(date1, date2) {
        const d1 = new Date(date1);
        const d2 = date2 ? new Date(date2) : new Date();
        const diffTime = Math.abs(d2 - d1);
        return Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    },

    /**
     * Format days to readable text
     */
    formatDays(days) {
        if (days === null || days === undefined) return 'N/A';
        if (days === 0) return 'Today';
        if (days === 1) return '1 day';
        if (days < 30) return `${days} days`;
        
        const months = Math.floor(days / 30);
        const remainingDays = days % 30;
        
        if (months === 1) {
            return remainingDays > 0 ? `1 month ${remainingDays} days` : '1 month';
        }
        
        return remainingDays > 0 ? `${months} months ${remainingDays} days` : `${months} months`;
    },

    /**
     * Initialize mobile menu
     */
    initMobileMenu() {
        // Add mobile menu toggle button
        if (window.innerWidth <= 768 && !document.querySelector('.mobile-menu-toggle')) {
            const toggleBtn = document.createElement('button');
            toggleBtn.className = 'mobile-menu-toggle';
            toggleBtn.innerHTML = '<i class="fas fa-bars"></i>';
            toggleBtn.onclick = () => this.toggleMobileMenu();
            document.body.appendChild(toggleBtn);

            // Add overlay
            const overlay = document.createElement('div');
            overlay.className = 'sidebar-overlay';
            overlay.onclick = () => this.toggleMobileMenu();
            document.body.appendChild(overlay);
        }

        // Close sidebar when clicking nav links on mobile
        const navLinks = document.querySelectorAll('.sidebar-nav a');
        navLinks.forEach(link => {
            link.addEventListener('click', () => {
                if (window.innerWidth <= 768) {
                    this.toggleMobileMenu();
                }
            });
        });
    },

    /**
     * Toggle mobile menu
     */
    toggleMobileMenu() {
        const sidebar = document.querySelector('.sidebar');
        const overlay = document.querySelector('.sidebar-overlay');
        
        if (sidebar) {
            sidebar.classList.toggle('active');
        }
        if (overlay) {
            overlay.classList.toggle('active');
        }
    },

    /**
     * Show notification toast
     */
    showNotification(message, type = 'info') {
        // Create notification element
        const notification = document.createElement('div');
        notification.className = `notification notification-${type}`;
        notification.innerHTML = `
            <i class="fas fa-${type === 'success' ? 'check-circle' : type === 'error' ? 'exclamation-circle' : 'info-circle'}"></i>
            <span>${message}</span>
        `;
        
        document.body.appendChild(notification);
        
        // Trigger animation
        setTimeout(() => notification.classList.add('show'), 10);
        
        // Remove after 3 seconds
        setTimeout(() => {
            notification.classList.remove('show');
            setTimeout(() => notification.remove(), 300);
        }, 3000);
    },

    /**
     * Escape HTML to prevent XSS attacks
     */
    escapeHtml(text) {
        if (!text) return '';
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    },

    /**
     * Truncate text to specified length
     */
    truncate(text, maxLength) {
        if (!text) return '';
        if (text.length <= maxLength) return text;
        return text.substring(0, maxLength) + '...';
    },

    /**
     * Enable click-and-drag horizontal scrolling on .table-container elements.
     * Safe to call multiple times — already-wired elements are skipped.
     * A MutationObserver picks up containers injected dynamically after load.
     */
    initDragScroll() {
        const wire = (el) => {
            if (el._dragScroll) return;
            el._dragScroll = true;
            let active = false, startX = 0, startLeft = 0;
            el.addEventListener('mousedown', (e) => {
                // Ignore clicks on buttons / links / inputs inside the table
                if (e.target.closest('a, button, input, select, textarea')) return;
                active    = true;
                startX    = e.pageX;
                startLeft = el.scrollLeft;
                el.classList.add('is-dragging');
                e.preventDefault();
            });
            const stop = () => { active = false; el.classList.remove('is-dragging'); };
            el.addEventListener('mouseleave', stop);
            el.addEventListener('mouseup',    stop);
            el.addEventListener('mousemove',  (e) => {
                if (!active) return;
                el.scrollLeft = startLeft - (e.pageX - startX);
            });
        };

        // Wire any containers already in the DOM
        document.querySelectorAll('.table-container').forEach(wire);

        // Wire containers injected later (dynamic table renders)
        if (!this._dragScrollObserver) {
            this._dragScrollObserver = new MutationObserver((mutations) => {
                mutations.forEach((m) => {
                    m.addedNodes.forEach((node) => {
                        if (node.nodeType !== 1) return;
                        if (node.classList && node.classList.contains('table-container')) wire(node);
                        if (node.querySelectorAll) node.querySelectorAll('.table-container').forEach(wire);
                    });
                });
            });
            this._dragScrollObserver.observe(document.body, { childList: true, subtree: true });
        }
    }
};

// Initialize on every page
document.addEventListener('DOMContentLoaded', () => {
    // Only initialize user info if not on login page
    if (!window.location.pathname.includes('login.html')) {
        Utils.requireAuth();
        Utils.initUserInfo();
        Utils.initLogoutButton();
        Utils.initMobileMenu();
    }
    Utils.initDragScroll();
});
