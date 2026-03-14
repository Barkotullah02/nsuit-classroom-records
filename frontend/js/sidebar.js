/**
 * sidebar.js — Shared sidebar renderer
 *
 * Injects the full sidebar HTML into any element with id="mainSidebar".
 * Load this script after utils.js and before page-specific scripts.
 *
 * To add, remove or rename a nav item edit NAV_ITEMS below — the change
 * takes effect on every page automatically.
 */
(function () {
    // ── Nav item definitions ──────────────────────────────────────────────
    // id        : optional DOM id on the <li> (admin-hidden items need one)
    // hidden    : starts with display:none (shown later by role-check code)
    const NAV_ITEMS = [
        { href: 'dashboard.html',               icon: 'fas fa-home',         label: 'Dashboard' },
        { href: 'devices.html',                 icon: 'fas fa-desktop',      label: 'Devices' },
        { href: 'installations.html',           icon: 'fas fa-plug',         label: 'Installations' },
                { href: 'invalid-installation-dates.html', icon: 'fas fa-calendar-times', label: 'Invalid Installation Dates',
                    id: 'invalidInstallationDatesNav', hidden: true },
        { href: 'gate-passes.html',             icon: 'fas fa-file-alt',     label: 'Gate Passes' },
        { href: 'rooms.html',                   icon: 'fas fa-door-open',    label: 'Rooms' },
        { href: 'building-device-history.html', icon: 'fas fa-building',     label: 'Building History' },
        { href: 'classroom-support.html',       icon: 'fas fa-headset',      label: 'Classroom Support' },
        { href: 'blog.html',                    icon: 'fas fa-newspaper',    label: 'Beacon Briefly' },
        { href: 'import-data.html',             icon: 'fas fa-file-import',  label: 'Import Data' },
        { href: 'deleted-items.html',           icon: 'fas fa-trash-restore',label: 'Deleted Items' },
        { href: 'users.html',                   icon: 'fas fa-users-cog',    label: 'User Management',
          id: 'userManagementNav', hidden: true },
    ];

    // ── Renderer ──────────────────────────────────────────────────────────
    function renderSidebar() {
        var sidebar = document.getElementById('mainSidebar');
        if (!sidebar) return;

        // Detect active page from the last path segment
        var currentPage = window.location.pathname.split('/').pop() || '';

        var liItems = NAV_ITEMS.map(function (item) {
            var liId    = item.id     ? ' id="'    + item.id    + '"' : '';
            var liStyle = item.hidden ? ' style="display:none;"'      : '';
            var aClass  = (item.href === currentPage) ? ' class="active"' : '';
            return '<li' + liId + liStyle + '>'
                + '<a href="' + item.href + '"' + aClass + '>'
                + '<i class="' + item.icon + '"></i> ' + item.label
                + '</a></li>';
        }).join('\n                ');

        sidebar.innerHTML =
            '<div class="sidebar-header">\n' +
            '            <h2><img src="images/bot.png" alt="Logo" style="height:50px;vertical-align:middle;margin-right:8px;"> AssetBeacon</h2>\n' +
            '        </div>\n' +
            '        <nav>\n' +
            '            <ul class="sidebar-nav">\n' +
            '                ' + liItems + '\n' +
            '            </ul>\n' +
            '        </nav>\n' +
            '        <div class="sidebar-footer">\n' +
            '            <div class="user-info">\n' +
            '                <div class="user-avatar" id="userAvatar"></div>\n' +
            '                <div class="user-details">\n' +
            '                    <h4 id="userName">Loading...</h4>\n' +
            '                    <p id="userRole">Role</p>\n' +
            '                </div>\n' +
            '            </div>\n' +
            '            <button class="btn btn-secondary btn-sm" id="logoutBtn" style="width:100%;">\n' +
            '                <i class="fas fa-sign-out-alt"></i> Logout\n' +
            '            </button>\n' +
            '        </div>';

        // Wire logout. Individual pages may also do this; duplicate listeners are harmless.
        var logoutBtn = document.getElementById('logoutBtn');
        if (logoutBtn && typeof Utils !== 'undefined' && typeof Utils.logout === 'function') {
            logoutBtn.addEventListener('click', function () { Utils.logout(); });
        }

        if (typeof Utils !== 'undefined' && typeof Utils.initUserInfo === 'function') {
            Utils.initUserInfo();
        }
    }

    // Run after DOM is ready (but before page-specific DOMContentLoaded handlers
    // because this script is loaded before them).
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', renderSidebar);
    } else {
        renderSidebar();
    }
})();
