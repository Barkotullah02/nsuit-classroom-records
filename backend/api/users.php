<?php
/**
 * User Management API
 * Manage users (admin only)
 */

require_once __DIR__ . '/../config/cors.php';
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../includes/response.php';

$auth = new Auth();
$database = new Database();
$db = $database->getConnection();

$method = $_SERVER['REQUEST_METHOD'];

// All user management requires admin access
if ($method === 'GET') {
    // Allow authenticated users to get their own info
    // But listing all users requires admin
    $user_id = $_GET['user_id'] ?? null;
    $current_user = $auth->getCurrentUser();
    
    if (!$current_user) {
        Response::error('Authentication required', 401);
    }
    
    // If requesting specific user, check if it's self or if requester is admin
    if ($user_id) {
        if ($user_id != $current_user['user_id'] && !$auth->isAdmin()) {
            Response::error('Admin access required', 403);
        }
        
        try {
            $query = "SELECT user_id, username, full_name, email, role, is_active, created_at 
                     FROM users WHERE user_id = :user_id";
            $stmt = $db->prepare($query);
            $stmt->bindParam(':user_id', $user_id);
            $stmt->execute();
            
            $user = $stmt->fetch(PDO::FETCH_ASSOC);
            
            if (!$user) {
                Response::error('User not found', 404);
            }
            
            Response::success($user, 'User retrieved successfully');
        } catch (Exception $e) {
            Response::error('Failed to retrieve user: ' . $e->getMessage());
        }
    } else {
        // List all users - admin only
        $auth->requireAdmin();
        
        try {
            $query = "SELECT user_id, username, full_name, email, role, is_active, created_at 
                     FROM users 
                     ORDER BY created_at DESC";
            $stmt = $db->prepare($query);
            $stmt->execute();
            
            $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            Response::success($users, 'Users retrieved successfully');
        } catch (Exception $e) {
            Response::error('Failed to retrieve users: ' . $e->getMessage());
        }
    }
} elseif ($method === 'POST') {
    // Create user - admin only
    $auth->requireAdmin();
    
    try {
        $data = json_decode(file_get_contents('php://input'), true);
        
        // Validate required fields
        if (empty($data['username']) || empty($data['password']) || empty($data['full_name']) || empty($data['email'])) {
            Response::error('Username, password, full name, and email are required');
        }
        
        // Validate role
        $valid_roles = ['admin', 'staff', 'viewer'];
        $role = $data['role'] ?? 'viewer';
        if (!in_array($role, $valid_roles)) {
            Response::error('Invalid role. Must be: admin, staff, or viewer');
        }
        
        // Check if username already exists
        $check_query = "SELECT user_id FROM users WHERE username = :username";
        $check_stmt = $db->prepare($check_query);
        $check_stmt->bindParam(':username', $data['username']);
        $check_stmt->execute();
        
        if ($check_stmt->rowCount() > 0) {
            Response::error('Username already exists', 409);
        }
        
        // Check if email already exists
        $check_query = "SELECT user_id FROM users WHERE email = :email";
        $check_stmt = $db->prepare($check_query);
        $check_stmt->bindParam(':email', $data['email']);
        $check_stmt->execute();
        
        if ($check_stmt->rowCount() > 0) {
            Response::error('Email already exists', 409);
        }
        
        // Validate password strength
        if (strlen($data['password']) < 6) {
            Response::error('Password must be at least 6 characters long');
        }
        
        // Hash password
        $password_hash = password_hash($data['password'], PASSWORD_DEFAULT);
        
        // Insert user
        $query = "INSERT INTO users (username, password_hash, full_name, email, role, is_active) 
                 VALUES (:username, :password_hash, :full_name, :email, :role, :is_active)";
        
        $stmt = $db->prepare($query);
        $stmt->bindParam(':username', $data['username']);
        $stmt->bindParam(':password_hash', $password_hash);
        $stmt->bindParam(':full_name', $data['full_name']);
        $stmt->bindParam(':email', $data['email']);
        $stmt->bindParam(':role', $role);
        $is_active = isset($data['is_active']) ? ($data['is_active'] ? 1 : 0) : 1;
        $stmt->bindParam(':is_active', $is_active);
        
        if ($stmt->execute()) {
            $newUserId = $db->lastInsertId();
            
            Response::success([
                'user_id' => $newUserId,
                'username' => $data['username'],
                'full_name' => $data['full_name'],
                'email' => $data['email'],
                'role' => $role
            ], 'User created successfully');
        } else {
            Response::error('Failed to create user');
        }
    } catch (Exception $e) {
        Response::error('Failed to create user: ' . $e->getMessage());
    }
} elseif ($method === 'PUT') {
    // Update user - admin only
    $auth->requireAdmin();
    
    try {
        $data = json_decode(file_get_contents('php://input'), true);
        
        if (empty($data['user_id'])) {
            Response::error('User ID is required');
        }
        
        // Build update query dynamically
        $updates = [];
        $params = ['user_id' => $data['user_id']];
        
        if (isset($data['username'])) {
            // Check if username is taken by another user
            $check_query = "SELECT user_id FROM users WHERE username = :username AND user_id != :user_id";
            $check_stmt = $db->prepare($check_query);
            $check_stmt->bindParam(':username', $data['username']);
            $check_stmt->bindParam(':user_id', $data['user_id']);
            $check_stmt->execute();
            
            if ($check_stmt->rowCount() > 0) {
                Response::error('Username already exists', 409);
            }
            
            $updates[] = "username = :username";
            $params['username'] = $data['username'];
        }
        
        if (isset($data['full_name'])) {
            $updates[] = "full_name = :full_name";
            $params['full_name'] = $data['full_name'];
        }
        
        if (isset($data['email'])) {
            // Check if email is taken by another user
            $check_query = "SELECT user_id FROM users WHERE email = :email AND user_id != :user_id";
            $check_stmt = $db->prepare($check_query);
            $check_stmt->bindParam(':email', $data['email']);
            $check_stmt->bindParam(':user_id', $data['user_id']);
            $check_stmt->execute();
            
            if ($check_stmt->rowCount() > 0) {
                Response::error('Email already exists', 409);
            }
            
            $updates[] = "email = :email";
            $params['email'] = $data['email'];
        }
        
        if (isset($data['role'])) {
            $valid_roles = ['admin', 'staff', 'viewer'];
            if (!in_array($data['role'], $valid_roles)) {
                Response::error('Invalid role. Must be: admin, staff, or viewer');
            }
            $updates[] = "role = :role";
            $params['role'] = $data['role'];
        }
        
        if (isset($data['is_active'])) {
            $updates[] = "is_active = :is_active";
            $params['is_active'] = $data['is_active'] ? 1 : 0;
        }
        
        if (isset($data['password']) && !empty($data['password'])) {
            if (strlen($data['password']) < 6) {
                Response::error('Password must be at least 6 characters long');
            }
            $updates[] = "password_hash = :password_hash";
            $params['password_hash'] = password_hash($data['password'], PASSWORD_DEFAULT);
        }
        
        if (empty($updates)) {
            Response::error('No fields to update');
        }
        
        $query = "UPDATE users SET " . implode(', ', $updates) . " WHERE user_id = :user_id";
        $stmt = $db->prepare($query);
        
        foreach ($params as $key => $value) {
            $stmt->bindValue(':' . $key, $value);
        }
        
        if ($stmt->execute() && $stmt->rowCount() > 0) {
            Response::success(['user_id' => $data['user_id']], 'User updated successfully');
        } else {
            Response::error('Failed to update user or no changes made');
        }
    } catch (Exception $e) {
        Response::error('Failed to update user: ' . $e->getMessage());
    }
} elseif ($method === 'DELETE') {
    // Delete user - admin only
    $auth->requireAdmin();
    
    try {
        $data = json_decode(file_get_contents('php://input'), true);
        
        if (empty($data['user_id'])) {
            Response::error('User ID is required');
        }
        
        $current_user = $auth->getCurrentUser();
        
        // Prevent self-deletion
        if ($data['user_id'] == $current_user['user_id']) {
            Response::error('Cannot delete your own account', 403);
        }
        
        // Soft delete - set is_active to FALSE
        $query = "UPDATE users SET is_active = FALSE WHERE user_id = :user_id";
        $stmt = $db->prepare($query);
        $stmt->bindParam(':user_id', $data['user_id']);
        
        if ($stmt->execute() && $stmt->rowCount() > 0) {
            Response::success(['user_id' => $data['user_id']], 'User deactivated successfully');
        } else {
            Response::error('Failed to deactivate user or user not found');
        }
    } catch (Exception $e) {
        Response::error('Failed to deactivate user: ' . $e->getMessage());
    }
} else {
    Response::error('Method not allowed', 405);
}
