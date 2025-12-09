/**
 * Configuration File
 * Global configuration settings
 */

const CONFIG = {
    API_BASE_URL: 'http://localhost/nsuit-classroom-records/backend/api',
    
    // API Endpoints
    ENDPOINTS: {
        AUTH: '/auth.php',
        DEVICES: '/devices.php',
        INSTALLATIONS: '/installations.php',
        DEVICE_HISTORY: '/device-history.php',
        ROOMS: '/rooms.php',
        METADATA: '/metadata.php',
        DASHBOARD: '/dashboard.php',
        GATE_PASSES: '/gate-passes.php',
        DELETED_ITEMS: '/deleted-items.php',
        BLOG_POSTS: '/blog-posts.php',
        BLOG_COMMENTS: '/blog-comments.php',
        BLOG_REACTIONS: '/blog-reactions.php',
        BLOG_CATEGORIES: '/blog-categories.php',
        SUPPORT_TEAM: '/support-team.php',
        CLASSROOM_SUPPORT: '/classroom-support.php'
    },

    // User roles
    ROLES: {
        ADMIN: 'admin',
        VIEWER: 'viewer'
    },

    // Session storage keys
    STORAGE_KEYS: {
        USER: 'current_user'
    }
};
