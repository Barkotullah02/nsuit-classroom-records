/**
 * sidebar.js — AssetBeacon Thymeleaf Edition
 * Injects the shared sidebar into any element with id="mainSidebar".
 * Uses clean MVC routes (/dashboard, /devices …) instead of .html files.
 */
(function () {
    const NAV_ITEMS = [
        { href: '/dashboard',                   icon: 'fas fa-home',           label: 'Dashboard' },
        { href: '/devices',                     icon: 'fas fa-desktop',        label: 'Devices' },
        { href: '/installations',               icon: 'fas fa-plug',           label: 'Installations' },
        { href: '/invalid-installation-dates',  icon: 'fas fa-calendar-times', label: 'Invalid Install Dates',
          id: 'invalidInstallationDatesNav', hidden: true },
        { href: '/gate-passes',                 icon: 'fas fa-file-alt',       label: 'Gate Passes' },
        { href: '/rooms',                       icon: 'fas fa-door-open',      label: 'Rooms' },
        { href: '/building-device-history',     icon: 'fas fa-building',       label: 'Building History' },
        { href: '/classroom-support',           icon: 'fas fa-headset',        label: 'Classroom Support' },
        { href: '/blog',                        icon: 'fas fa-newspaper',      label: 'Beacon Briefly' },
        { href: '/import-data',                 icon: 'fas fa-file-import',    label: 'Import Data' },
        { href: '/deleted-items',               icon: 'fas fa-trash-restore',  label: 'Deleted Items' },
        { href: '/users',                       icon: 'fas fa-users-cog',      label: 'User Management',
          id: 'userManagementNav', hidden: true },
    ];

    function renderSidebar() {
        const sidebar = document.getElementById('mainSidebar');
        if (!sidebar) return;

        const currentPath = window.location.pathname;

        const liItems = NAV_ITEMS.map(item => {
            const liId    = item.id     ? ` id="${item.id}"`          : '';
            const liStyle = item.hidden ? ' style="display:none;"'    : '';
            const aClass  = currentPath === item.href ? ' class="active"' : '';
            return `<li${liId}${liStyle}><a href="${item.href}"${aClass}><i class="${item.icon}"></i> ${item.label}</a></li>`;
        }).join('\n');

        sidebar.innerHTML = `
<div class="sidebar-header">
  <h2><img src="/images/bot.png" alt="Logo" onerror="this.style.display='none'"> AssetBeacon</h2>
</div>
<nav>
  <ul class="sidebar-nav">
    ${liItems}
  </ul>
</nav>
<div class="sidebar-footer">
  <div class="user-info">
    <div class="user-avatar" id="userAvatar"></div>
    <div class="user-details">
      <h4 id="userName">Loading…</h4>
      <p id="userRole">Role</p>
    </div>
  </div>
  <button class="btn btn-secondary btn-sm" id="logoutBtn" style="width:100%; margin-top:4px;">
    <i class="fas fa-sign-out-alt"></i> Logout
  </button>
</div>`;

        // Wire logout
        const logoutBtn = document.getElementById('logoutBtn');
        if (logoutBtn && typeof Utils !== 'undefined') {
            logoutBtn.addEventListener('click', () => Utils.logout());
        }

        // Populate user info if Utils is available
        if (typeof Utils !== 'undefined') {
            Utils.initUserInfo();
        }
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', renderSidebar);
    } else {
        renderSidebar();
    }
})();
