/**
 * Configuration File
 * Global configuration settings
 */

const CONFIG = {
    API_BASE_URL: 'http://10.100.6.191/nsuit-classroom-records/backend/api',
    
    // API Endpoints
    ENDPOINTS: {
        AUTH: '/auth.php',
        DEVICES: '/devices.php',
        INSTALLATIONS: '/installations.php',
        DEVICE_HISTORY: '/device-history.php',
        ROOMS: '/rooms.php',
        ROOM_HISTORY: '/room-history.php',
        BUILDING_DEVICE_HISTORY: '/building-device-history.php',
        METADATA: '/metadata.php',
        DASHBOARD: '/dashboard.php',
        GATE_PASSES: '/gate-passes.php',
        DELETED_ITEMS: '/deleted-items.php',
        BLOG_POSTS: '/blog-posts.php',
        BLOG_COMMENTS: '/blog-comments.php',
        BLOG_REACTIONS: '/blog-reactions.php',
        BLOG_CATEGORIES: '/blog-categories.php',
        SUPPORT_TEAM: '/support-team.php',
        CLASSROOM_SUPPORT: '/classroom-support.php',
        USERS: '/users.php',
        INVALID_INSTALLATION_DATES: '/invalid-installation-dates.php'
    },

    // User roles
    ROLES: {
        SUPER_ADMIN: 'super_admin',
        ADMIN: 'admin',
        STAFF: 'staff',
        VIEWER: 'viewer'
    },

    // Session storage keys
    STORAGE_KEYS: {
        USER: 'current_user'
    }
};
