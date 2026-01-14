<?php
/**
 * Room History API
 * Get comprehensive history for a specific room
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
    $room_id = $_GET['room_id'] ?? null;
    
    if (!$room_id) {
        Response::error('Room ID is required');
    }

    // Get room details
    $room_query = "SELECT 
                    room_id,
                    room_number,
                    room_name,
                    building,
                    floor,
                    capacity,
                    is_active
                FROM rooms
                WHERE room_id = :room_id AND is_active = TRUE";
    
    $room_stmt = $db->prepare($room_query);
    $room_stmt->bindParam(':room_id', $room_id);
    $room_stmt->execute();
    $room = $room_stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$room) {
        Response::error('Room not found', 404);
    }

    // Get currently active devices in this room
    $active_devices_query = "SELECT 
                            d.device_id,
                            d.device_unique_id,
                            dt.type_name,
                            db.brand_name,
                            d.model,
                            d.serial_number,
                            di.status,
                            di.installation_id,
                            di.installed_date,
                            di.installation_notes,
                            u.full_name as installed_by_name
                        FROM device_installations di
                        JOIN devices d ON di.device_id = d.device_id
                        LEFT JOIN device_types dt ON d.type_id = dt.type_id
                        LEFT JOIN device_brands db ON d.brand_id = db.brand_id
                        LEFT JOIN users u ON di.installed_by = u.user_id
                        WHERE di.room_id = :room_id 
                        AND di.status = 'active'
                        AND di.is_deleted = FALSE
                        ORDER BY di.installed_date DESC";
    
    $active_stmt = $db->prepare($active_devices_query);
    $active_stmt->bindParam(':room_id', $room_id);
    $active_stmt->execute();
    $active_devices = $active_stmt->fetchAll(PDO::FETCH_ASSOC);

    // Get withdrawn devices from this room with their current location
    $withdrawn_devices_query = "SELECT 
                                d.device_id,
                                d.device_unique_id,
                                dt.type_name,
                                db.brand_name,
                                d.model,
                                d.serial_number,
                                di.status,
                                di.installation_id,
                                di.installed_date,
                                di.withdrawn_date,
                                di.installation_notes,
                                di.withdrawal_notes,
                                u.full_name as withdrawn_by_name
                            FROM device_installations di
                            JOIN devices d ON di.device_id = d.device_id
                            LEFT JOIN device_types dt ON d.type_id = dt.type_id
                            LEFT JOIN device_brands db ON d.brand_id = db.brand_id
                            LEFT JOIN users u ON di.withdrawn_by = u.user_id
                            WHERE di.room_id = :room_id 
                            AND di.status = 'withdrawn'
                            AND di.is_deleted = FALSE
                            ORDER BY di.withdrawn_date DESC";
    
    $withdrawn_stmt = $db->prepare($withdrawn_devices_query);
    $withdrawn_stmt->bindParam(':room_id', $room_id);
    $withdrawn_stmt->execute();
    $withdrawn_devices = $withdrawn_stmt->fetchAll(PDO::FETCH_ASSOC);

    // For each withdrawn device, find its current location if it's been reinstalled
    foreach ($withdrawn_devices as &$device) {
        $current_location_query = "SELECT 
                                    r.room_id,
                                    r.room_number,
                                    r.room_name,
                                    r.building,
                                    di.installed_date,
                                    di.installation_notes
                                FROM device_installations di
                                JOIN rooms r ON di.room_id = r.room_id
                                WHERE di.device_id = :device_id
                                AND di.status = 'active'
                                AND di.is_deleted = FALSE
                                ORDER BY di.installed_date DESC
                                LIMIT 1";
        
        $location_stmt = $db->prepare($current_location_query);
        $location_stmt->bindParam(':device_id', $device['device_id']);
        $location_stmt->execute();
        $current_location = $location_stmt->fetch(PDO::FETCH_ASSOC);
        
        $device['current_location'] = $current_location ?: null;
    }

    // Get complete history of all installations in this room
    $history_query = "SELECT 
                        di.installation_id,
                        di.device_id,
                        d.device_unique_id,
                        dt.type_name,
                        db.brand_name,
                        d.model,
                        d.serial_number,
                        r.room_number,
                        r.room_name,
                        di.installed_date,
                        di.withdrawn_date,
                        DATEDIFF(IFNULL(di.withdrawn_date, CURDATE()), di.installed_date) as days_in_room,
                        di.status,
                        di.installation_notes,
                        di.withdrawal_notes,
                        COALESCE(di.installer_name, u_installed.full_name) as installed_by,
                        COALESCE(di.withdrawer_name, u_withdrawn.full_name) as withdrawn_by
                    FROM device_installations di
                    JOIN devices d ON di.device_id = d.device_id
                    JOIN rooms r ON di.room_id = r.room_id
                    LEFT JOIN device_types dt ON d.type_id = dt.type_id
                    LEFT JOIN device_brands db ON d.brand_id = db.brand_id
                    LEFT JOIN users u_installed ON di.installed_by = u_installed.user_id
                    LEFT JOIN users u_withdrawn ON di.withdrawn_by = u_withdrawn.user_id
                    WHERE di.room_id = :room_id
                    AND di.is_deleted = FALSE
                    ORDER BY di.installed_date DESC";
    
    $history_stmt = $db->prepare($history_query);
    $history_stmt->bindParam(':room_id', $room_id);
    $history_stmt->execute();
    $complete_history = $history_stmt->fetchAll(PDO::FETCH_ASSOC);

    $response = [
        'room' => $room,
        'active_devices' => $active_devices,
        'withdrawn_devices' => $withdrawn_devices,
        'complete_history' => $complete_history,
        'statistics' => [
            'active_count' => count($active_devices),
            'withdrawn_count' => count($withdrawn_devices),
            'total_history_records' => count($complete_history)
        ]
    ];

    Response::success($response, 'Room history retrieved successfully');
} catch (Exception $e) {
    Response::error('Failed to retrieve room history: ' . $e->getMessage());
}
