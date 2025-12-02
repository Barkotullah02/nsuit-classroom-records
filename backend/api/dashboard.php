<?php
/**
 * Dashboard Statistics API
 * Get dashboard statistics
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
    // Total devices
    $total_devices_query = "SELECT COUNT(*) as count FROM devices WHERE is_deleted = FALSE";
    $total_devices = $db->query($total_devices_query)->fetch()['count'];

    // Active installations
    $active_installations_query = "SELECT COUNT(*) as count FROM device_installations 
                                   WHERE status = 'active' AND is_deleted = FALSE";
    $active_installations = $db->query($active_installations_query)->fetch()['count'];

    // Withdrawn devices
    $withdrawn_devices_query = "SELECT COUNT(*) as count FROM device_installations 
                                WHERE status = 'withdrawn' AND is_deleted = FALSE";
    $withdrawn_devices = $db->query($withdrawn_devices_query)->fetch()['count'];

    // Available devices (not currently installed or withdrawn)
    $available_devices_query = "SELECT COUNT(*) as count FROM devices d
                                WHERE d.is_deleted = FALSE 
                                AND d.device_id NOT IN (
                                    SELECT device_id FROM device_installations 
                                    WHERE (status = 'active' OR status = 'withdrawn') 
                                    AND is_deleted = FALSE
                                )";
    $available_devices = $db->query($available_devices_query)->fetch()['count'];

    // Total rooms
    $total_rooms_query = "SELECT COUNT(*) as count FROM rooms WHERE is_active = TRUE";
    $total_rooms = $db->query($total_rooms_query)->fetch()['count'];

    // Devices by type
    $devices_by_type_query = "SELECT dt.type_name, COUNT(d.device_id) as count
                             FROM device_types dt
                             LEFT JOIN devices d ON dt.type_id = d.type_id AND d.is_deleted = FALSE
                             GROUP BY dt.type_id, dt.type_name
                             ORDER BY count DESC";
    $devices_by_type_stmt = $db->query($devices_by_type_query);
    $devices_by_type = $devices_by_type_stmt->fetchAll(PDO::FETCH_ASSOC);

    // Available devices by type
    $available_by_type_query = "SELECT dt.type_name, COUNT(d.device_id) as count
                                FROM device_types dt
                                LEFT JOIN devices d ON dt.type_id = d.type_id 
                                    AND d.is_deleted = FALSE
                                    AND d.device_id NOT IN (
                                        SELECT device_id FROM device_installations 
                                        WHERE (status = 'active' OR status = 'withdrawn') 
                                        AND is_deleted = FALSE
                                    )
                                GROUP BY dt.type_id, dt.type_name
                                HAVING count > 0
                                ORDER BY count DESC";
    $available_by_type_stmt = $db->query($available_by_type_query);
    $available_by_type = $available_by_type_stmt->fetchAll(PDO::FETCH_ASSOC);

    // Recent activities
    $recent_activities_query = "SELECT 
                                   al.log_id,
                                   al.action,
                                   al.table_name,
                                   al.created_at,
                                   u.full_name as user_name
                               FROM audit_log al
                               JOIN users u ON al.user_id = u.user_id
                               ORDER BY al.created_at DESC
                               LIMIT 10";
    $recent_activities_stmt = $db->query($recent_activities_query);
    $recent_activities = $recent_activities_stmt->fetchAll(PDO::FETCH_ASSOC);

    Response::success([
        'total_devices' => $total_devices,
        'active_installations' => $active_installations,
        'withdrawn_devices' => $withdrawn_devices,
        'available_devices' => $available_devices,
        'total_rooms' => $total_rooms,
        'devices_by_type' => $devices_by_type,
        'available_by_type' => $available_by_type,
        'recent_activities' => $recent_activities
    ], 'Dashboard statistics retrieved successfully');
} catch (Exception $e) {
    Response::error('Failed to retrieve statistics: ' . $e->getMessage());
}
