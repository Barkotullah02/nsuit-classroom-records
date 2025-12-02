<?php
/**
 * Authentication API
 * Handles login, logout, and session management
 */

require_once __DIR__ . '/../config/cors.php';
require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../includes/response.php';

$auth = new Auth();
$method = $_SERVER['REQUEST_METHOD'];

// Get request data
$data = json_decode(file_get_contents("php://input"), true);

switch ($method) {
    case 'POST':
        // Login
        if (!isset($data['username']) || !isset($data['password'])) {
            Response::validationError(['username' => 'Username is required', 'password' => 'Password is required']);
        }

        $result = $auth->login($data['username'], $data['password']);
        
        if ($result['success']) {
            Response::success([
                'token' => $result['token'],
                'user' => $result['user']
            ], 'Login successful');
        } else {
            Response::error($result['message'], 401);
        }
        break;

    case 'DELETE':
        // Logout
        $result = $auth->logout();
        Response::success([], $result['message']);
        break;

    case 'GET':
        // Get current user
        $user = $auth->getCurrentUser();
        
        if ($user) {
            Response::success($user, 'User authenticated');
        } else {
            Response::unauthorized('Not authenticated');
        }
        break;

    default:
        Response::error('Method not allowed', 405);
        break;
}
