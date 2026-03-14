<?php
/**
 * Authentication Helper
 * Handles user authentication using JWT tokens
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/jwt.php';

class Auth {
    private $db;
    private $conn;

    public function __construct() {
        $this->db = new Database();
        $this->conn = $this->db->getConnection();

        if (!$this->conn) {
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'message' => 'Database connection failed'
            ]);
            exit();
        }
    }

    /**
     * Login user
     */
    public function login($username, $password) {
        try {
            $query = "SELECT user_id, username, password_hash, full_name, email, role, is_active
                      FROM users
                      WHERE username = :username AND is_active = TRUE";

            $stmt = $this->conn->prepare($query);
            $stmt->bindParam(':username', $username);
            $stmt->execute();

            $user = $stmt->fetch(PDO::FETCH_ASSOC);

            if ($user && password_verify($password, $user['password_hash'])) {
                // JWT payload
                $payload = [
                    'user_id' => $user['user_id'],
                    'username' => $user['username'],
                    'full_name' => $user['full_name'],
                    'email' => $user['email'],
                    'role' => $user['role']
                ];

                $token = JWT::encode($payload);

                $this->logAction($user['user_id'], 'LOGIN', 'users', $user['user_id']);

                return [
                    'success' => true,
                    'token' => $token,
                    'user' => $payload
                ];
            }

            return ['success' => false, 'message' => 'Invalid username or password'];

        } catch (Exception $e) {
            return ['success' => false, 'message' => 'Login failed: ' . $e->getMessage()];
        }
    }

    /**
     * Logout user
     */
    public function logout() {
        $user = $this->getCurrentUser();
        if ($user) {
            $this->logAction($user['user_id'], 'LOGOUT', 'users', $user['user_id']);
        }

        return ['success' => true, 'message' => 'Logged out successfully'];
    }

    /**
     * Get current user from JWT token
     */
    public function getCurrentUser() {
        $token = JWT::getBearerToken();
        if (!$token) return null;

        $payload = JWT::decode($token);
        if (!$payload) return null;

        return [
            'user_id' => $payload['user_id'],
            'username' => $payload['username'],
            'full_name' => $payload['full_name'],
            'email' => $payload['email'],
            'role' => $payload['role']
        ];
    }

    /**
     * Permission checks
     */
    public function isAdmin() { $user = $this->getCurrentUser(); return $user && in_array($user['role'], ['super_admin', 'admin']); }
    public function isSuperAdmin() { $user = $this->getCurrentUser(); return $user && $user['role'] === 'super_admin'; }
    public function isStaff() { $user = $this->getCurrentUser(); return $user && $user['role'] === 'staff'; }
    public function isViewer() { $user = $this->getCurrentUser(); return $user && $user['role'] === 'viewer'; }
    public function canCreate() { $user = $this->getCurrentUser(); return $user && in_array($user['role'], ['super_admin', 'admin','staff']); }

    /**
     * Require authentication
     */
    public function requireAuth() {
        if (!$this->getCurrentUser()) {
            http_response_code(401);
            echo json_encode(['success' => false, 'message' => 'Authentication required']);
            exit();
        }
    }

    /**
     * Require create permission (staff, admin, super_admin)
     */
    public function requireCreate() {
        $this->requireAuth();
        if (!$this->canCreate()) {
            http_response_code(403);
            echo json_encode(['success' => false, 'message' => 'Insufficient permissions to create records']);
            exit();
        }
    }

    /**
     * Require admin role
     */
    public function requireAdmin() {
        $this->requireAuth();
        if (!$this->isAdmin()) {
            http_response_code(403);
            echo json_encode(['success' => false, 'message' => 'Admin access required']);
            exit();
        }
    }

    /**
     * Require super admin role
     */
    public function requireSuperAdmin() {
        $this->requireAuth();
        if (!$this->isSuperAdmin()) {
            http_response_code(403);
            echo json_encode(['success' => false, 'message' => 'Super admin access required']);
            exit();
        }
    }

    /**
     * Log user actions
     */
    private function logAction($user_id, $action, $table_name, $record_id) {
        try {
            $ip_address = $_SERVER['REMOTE_ADDR'] ?? 'unknown';
            $user_agent = $_SERVER['HTTP_USER_AGENT'] ?? 'unknown';

            $query = "INSERT INTO audit_log (user_id, action, table_name, record_id, ip_address, user_agent)
                      VALUES (:user_id, :action, :table_name, :record_id, :ip_address, :user_agent)";

            $stmt = $this->conn->prepare($query);
            $stmt->bindParam(':user_id', $user_id);
            $stmt->bindParam(':action', $action);
            $stmt->bindParam(':table_name', $table_name);
            $stmt->bindParam(':record_id', $record_id);
            $stmt->bindParam(':ip_address', $ip_address);
            $stmt->bindParam(':user_agent', $user_agent);
            $stmt->execute();
        } catch (Exception $e) {
            error_log("Audit log error: " . $e->getMessage());
        }
    }
}
