<?php
/**
 * Device History API
 * Get installation history for a device
 */

require_once __DIR__ . '/../config/cors.php';
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../includes/response.php';

$auth = new Auth();
$auth->requireAuth();

$database = new Database();
$db = $database->getConnection();

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    Response::error('Method not allowed', 405);
}

try {
    $device_id = $_GET['device_id'] ?? null;
    
    if (!$device_id) {
        Response::error('Device ID is required');
    }

    $query = "SELECT 
                di.installation_id,
                di.device_id,
                r.room_number,
                r.room_name,
                di.installed_date,
                di.withdrawn_date,
                DATEDIFF(IFNULL(di.withdrawn_date, CURDATE()), di.installed_date) as days_in_room,
                di.status,
                di.installation_notes,
                di.withdrawal_notes,
                di.gate_pass_number,
                di.gate_pass_date,
                COALESCE(di.installer_name, u_installed.full_name) as installed_by,
                di.installer_id as installed_by_id,
                COALESCE(di.withdrawer_name, u_withdrawn.full_name) as withdrawn_by,
                di.withdrawer_id as withdrawn_by_id,
                u_data_entry.full_name as data_entry_by
            FROM device_installations di
            JOIN rooms r ON di.room_id = r.room_id
            LEFT JOIN users u_installed ON di.installed_by = u_installed.user_id
            LEFT JOIN users u_withdrawn ON di.withdrawn_by = u_withdrawn.user_id
            LEFT JOIN users u_data_entry ON di.data_entry_by = u_data_entry.user_id
            WHERE di.device_id = :device_id AND di.is_deleted = FALSE
            ORDER BY di.installed_date DESC";

    $stmt = $db->prepare($query);
    $stmt->bindParam(':device_id', $device_id);
    $stmt->execute();
    
    $history = $stmt->fetchAll(PDO::FETCH_ASSOC);

    Response::success($history, 'Device history retrieved successfully');
} catch (Exception $e) {
    Response::error('Failed to retrieve device history: ' . $e->getMessage());
}
