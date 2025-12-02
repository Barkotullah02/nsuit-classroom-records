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
        return userStr ? JSON.parse(userStr) : null;
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
        return user && user.role === CONFIG.ROLES.ADMIN;
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
        await this.apiRequest(CONFIG.ENDPOINTS.AUTH, {
            method: 'DELETE'
        });

        this.clearToken();
        this.clearCurrentUser();
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

        if (userNameEl) userNameEl.textContent = user.full_name;
        if (userRoleEl) userRoleEl.textContent = user.role.charAt(0).toUpperCase() + user.role.slice(1);
        if (userAvatarEl) userAvatarEl.textContent = this.getUserInitials(user.full_name);
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
});
