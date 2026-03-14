/**
 * utils.js — AssetBeacon Thymeleaf Edition
 * Adapted for Spring Boot API (/api/*) and clean MVC routes (/login, /dashboard …)
 */
const Utils = {

    /* ─── HTTP ─────────────────────────────────────────────────────────── */
    async apiRequest(endpoint, options = {}) {
        try {
            const url   = CONFIG.API_BASE_URL + endpoint;
            const token = this.getToken();
            const headers = { 'Content-Type': 'application/json', ...options.headers };
            if (token) headers['Authorization'] = `Bearer ${token}`;

            const response = await fetch(url, { ...options, headers });
            const data     = await response.json();

            if (!data.success && (response.status === 401 || response.status === 403)) {
                this.clearStorage();
                if (!window.location.pathname.startsWith('/login')) {
                    window.location.href = '/login';
                }
            }
            return data;
        } catch (err) {
            console.error('API error:', err);
            return { success: false, message: 'Network error occurred' };
        }
    },

    /* ─── Alerts ───────────────────────────────────────────────────────── */
    showAlert(message, type = 'error', containerId = 'alert-container') {
        const el = document.getElementById(containerId);
        if (!el) return;
        const cls = type === 'success' ? 'alert-success'
                  : type === 'warning' ? 'alert-warning'
                  : type === 'info'    ? 'alert-info'
                  : 'alert-error';
        el.innerHTML = `<div class="alert ${cls}">${message}</div>`;
        setTimeout(() => { el.innerHTML = ''; }, 5000);
    },

    /* ─── Token ────────────────────────────────────────────────────────── */
    getToken()      { return localStorage.getItem(CONFIG.STORAGE_KEYS.TOKEN); },
    setToken(t)     { localStorage.setItem(CONFIG.STORAGE_KEYS.TOKEN, t); },

    /* ─── User ─────────────────────────────────────────────────────────── */
    getCurrentUser() {
        const raw = localStorage.getItem(CONFIG.STORAGE_KEYS.USER);
        if (!raw) return null;
        try   { return JSON.parse(raw); }
        catch { localStorage.removeItem(CONFIG.STORAGE_KEYS.USER); return null; }
    },
    setCurrentUser(u) { localStorage.setItem(CONFIG.STORAGE_KEYS.USER, JSON.stringify(u)); },
    clearStorage() {
        localStorage.removeItem(CONFIG.STORAGE_KEYS.TOKEN);
        localStorage.removeItem(CONFIG.STORAGE_KEYS.USER);
    },

    /* ─── Auth helpers ─────────────────────────────────────────────────── */
    isLoggedIn() { return !!this.getToken() && !!this.getCurrentUser(); },
    isAdmin()    {
        const u = this.getCurrentUser();
        return u && (u.role === CONFIG.ROLES.SUPER_ADMIN || u.role === CONFIG.ROLES.ADMIN);
    },
    isSuperAdmin() {
        const u = this.getCurrentUser();
        return u && u.role === CONFIG.ROLES.SUPER_ADMIN;
    },

    requireAuth() {
        if (!this.isLoggedIn()) {
            window.location.href = '/login';
            return false;
        }
        return true;
    },

    async logout() {
        try {
            await this.apiRequest(CONFIG.ENDPOINTS.AUTH.replace('/login', '/logout'), { method: 'POST' });
        } catch (_) { /* best-effort */ }
        this.clearStorage();
        window.location.href = '/login';
    },

    /* ─── Sidebar user info ────────────────────────────────────────────── */
    initUserInfo() {
        const user = this.getCurrentUser();
        if (!user) return;

        const nameEl   = document.getElementById('userName');
        const roleEl   = document.getElementById('userRole');
        const avatarEl = document.getElementById('userAvatar');

        if (nameEl)   nameEl.textContent   = user.full_name || user.username;
        if (roleEl)   roleEl.textContent   = (user.role || '')
            .split('_').map(w => w.charAt(0).toUpperCase() + w.slice(1)).join(' ');
        if (avatarEl) avatarEl.textContent = this.getUserInitials(user.full_name || user.username);

        // Role-gated nav items
        const umNav = document.getElementById('userManagementNav');
        if (umNav && this.isAdmin()) umNav.style.display = 'block';

        const invNav = document.getElementById('invalidInstallationDatesNav');
        if (invNav && this.isSuperAdmin()) invNav.style.display = 'block';
    },

    checkAuth() {
        if (!this.requireAuth()) return false;
        this.initUserInfo();
        return true;
    },

    initLogoutButton() {
        const btn = document.getElementById('logoutBtn');
        if (btn) btn.addEventListener('click', () => this.logout());
    },

    /* ─── Date formatting ──────────────────────────────────────────────── */
    formatDate(d) {
        if (!d) return 'N/A';
        return new Date(d).toLocaleDateString('en-US', { year:'numeric', month:'short', day:'numeric' });
    },
    formatDateTime(d) {
        if (!d) return 'N/A';
        return new Date(d).toLocaleString('en-US', { year:'numeric', month:'short', day:'numeric', hour:'2-digit', minute:'2-digit' });
    },
    getUserInitials(name) {
        if (!name) return '?';
        const p = name.split(' ');
        return p.length >= 2 ? p[0][0] + p[1][0] : name.substring(0, 2);
    },

    /* ─── Date diff ─────────────────────────────────────────────────────── */
    daysDifference(d1, d2) {
        return Math.ceil(Math.abs(new Date(d2 || Date.now()) - new Date(d1)) / 864e5);
    },
    formatDays(days) {
        if (days == null) return 'N/A';
        if (days === 0)   return 'Today';
        if (days === 1)   return '1 day';
        if (days < 30)    return `${days} days`;
        const m = Math.floor(days / 30), r = days % 30;
        const ms = m === 1 ? '1 month' : `${m} months`;
        return r ? `${ms} ${r} day${r > 1 ? 's' : ''}` : ms;
    },

    /* ─── Misc helpers ─────────────────────────────────────────────────── */
    debounce(fn, wait) {
        let t;
        return (...args) => { clearTimeout(t); t = setTimeout(() => fn(...args), wait); };
    },
    escapeHtml(text) {
        if (!text) return '';
        const d = document.createElement('div');
        d.textContent = text;
        return d.innerHTML;
    },
    truncate(text, max) {
        if (!text || text.length <= max) return text || '';
        return text.substring(0, max) + '…';
    },

    /* ─── Mobile sidebar ───────────────────────────────────────────────── */
    initMobileMenu() {
        if (window.innerWidth > 768) return;

        let toggleBtn = document.querySelector('.sidebar-toggle');
        if (!toggleBtn) {
            toggleBtn = document.createElement('button');
            toggleBtn.className = 'sidebar-toggle';
            toggleBtn.innerHTML = '<i class="fas fa-bars"></i>';
            document.body.prepend(toggleBtn);
        }

        let overlay = document.querySelector('.sidebar-overlay');
        if (!overlay) {
            overlay = document.createElement('div');
            overlay.className = 'sidebar-overlay';
            document.body.appendChild(overlay);
        }

        const sidebar = document.querySelector('.sidebar');
        const toggleFn = () => {
            if (sidebar)  sidebar.classList.toggle('open');
            overlay.classList.toggle('active');
        };
        toggleBtn.addEventListener('click', toggleFn);
        overlay.addEventListener('click', toggleFn);

        document.querySelectorAll('.sidebar-nav a').forEach(a => {
            a.addEventListener('click', () => {
                if (window.innerWidth <= 768) {
                    if (sidebar)  sidebar.classList.remove('open');
                    overlay.classList.remove('active');
                }
            });
        });
    },

    /* ─── Drag-scroll tables ────────────────────────────────────────────── */
    initDragScroll() {
        const wire = (el) => {
            if (el._dragScroll) return;
            el._dragScroll = true;
            let active = false, startX = 0, startLeft = 0;
            el.addEventListener('mousedown', (e) => {
                if (e.target.closest('a,button,input,select,textarea')) return;
                active = true; startX = e.pageX; startLeft = el.scrollLeft;
                el.classList.add('is-dragging'); e.preventDefault();
            });
            const stop = () => { active = false; el.classList.remove('is-dragging'); };
            el.addEventListener('mouseleave', stop);
            el.addEventListener('mouseup', stop);
            el.addEventListener('mousemove', (e) => { if (active) el.scrollLeft = startLeft - (e.pageX - startX); });
        };
        document.querySelectorAll('.table-container').forEach(wire);
        if (!this._dragObs) {
            this._dragObs = new MutationObserver(mutations => mutations.forEach(m =>
                m.addedNodes.forEach(n => {
                    if (n.nodeType !== 1) return;
                    if (n.classList && n.classList.contains('table-container')) wire(n);
                    if (n.querySelectorAll) n.querySelectorAll('.table-container').forEach(wire);
                })
            ));
            this._dragObs.observe(document.body, { childList: true, subtree: true });
        }
    }
};

/* ── Auto-init on every page ─────────────────────────────────────────────── */
document.addEventListener('DOMContentLoaded', () => {
    const path = window.location.pathname;
    if (path !== '/login') {
        Utils.requireAuth();
        Utils.initUserInfo();
        Utils.initLogoutButton();
        Utils.initMobileMenu();
    }
    Utils.initDragScroll();
});
