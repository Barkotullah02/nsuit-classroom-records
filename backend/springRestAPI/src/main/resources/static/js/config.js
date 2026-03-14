/**
 * config.js — AssetBeacon Thymeleaf Edition
 * Points to the Spring Boot REST API at /api/*
 */
const CONFIG = {
    // Spring Boot API base (same origin, relative path)
    API_BASE_URL: '/api',

    ENDPOINTS: {
        AUTH                    : '/auth/login',
        AUTH_ME                 : '/auth/me',
        DEVICES                 : '/devices',
        INSTALLATIONS           : '/installations',
        INVALID_DATES           : '/invalid-installation-dates',
        DEVICE_HISTORY          : '/device-history',
        ROOMS                   : '/rooms',
        ROOM_HISTORY            : '/room-history',
        BUILDING_DEVICE_HISTORY : '/building-device-history',
        METADATA                : '/metadata',
        DASHBOARD               : '/dashboard',
        GATE_PASSES             : '/gate-passes',
        DELETED_ITEMS           : '/deleted-items',
        BLOG_POSTS              : '/blog-posts',
        BLOG_COMMENTS           : '/blog-comments',
        BLOG_REACTIONS          : '/blog-reactions',
        BLOG_CATEGORIES         : '/blog-categories',
        SUPPORT_TEAM            : '/support-team',
        CLASSROOM_SUPPORT       : '/classroom-support',
        USERS                   : '/users',
        GENERATE_QR             : '/generate-qr'
    },

    ROLES: {
        SUPER_ADMIN : 'super_admin',
        ADMIN       : 'admin',
        STAFF       : 'staff',
        VIEWER      : 'viewer'
    },

    STORAGE_KEYS: {
        TOKEN : 'jwt_token',
        USER  : 'current_user'
    }
};
