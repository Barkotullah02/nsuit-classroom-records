<?php
/**
 * Rooms API
 * Manage rooms
 */

require_once __DIR__ . '/../config/cors.php';
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../includes/response.php';

$auth = new Auth();
$auth->requireAuth();

$database = new Database();
$db = $database->getConnection();

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    try {
        $room_id = $_GET['room_id'] ?? null;
        
        if ($room_id) {
            // Get room details with devices
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
            
            // Get devices installed in this room (active)
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
            
            // Get withdrawn devices from this room (get all, not just 10)
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
            
            $room['active_devices'] = $active_devices;
            $room['withdrawn_devices'] = $withdrawn_devices;
            $room['active_device_count'] = count($active_devices);
            $room['withdrawn_device_count'] = count($withdrawn_devices);
            
            Response::success($room, 'Room details retrieved successfully');
        } else {
            // Get all rooms (existing logic)
            $query = "SELECT 
                        room_id,
                        room_number,
                        room_name,
                        building,
                        floor,
                        capacity,
                        is_active,
                        (SELECT COUNT(*) FROM device_installations di 
                         WHERE di.room_id = r.room_id 
                         AND di.status = 'active' 
                         AND di.is_deleted = FALSE) as device_count
                    FROM rooms r
                    WHERE is_active = TRUE
                    ORDER BY room_number";

            $stmt = $db->prepare($query);
            $stmt->execute();
            
            $rooms = $stmt->fetchAll(PDO::FETCH_ASSOC);

            Response::success($rooms, 'Rooms retrieved successfully');
        }
    } catch (Exception $e) {
        Response::error('Failed to retrieve rooms: ' . $e->getMessage());
    }
} elseif ($method === 'POST') {
    // Staff or admin can create rooms
    $auth->requireCreate();

    try {
        $data = json_decode(file_get_contents('php://input'), true);
        
        if (empty($data['room_number']) || empty($data['room_name'])) {
            Response::error('Room number and name are required');
        }

        // Check if room_number already exists
        $check_query = "SELECT room_id FROM rooms WHERE room_number = :room_number";
        $check_stmt = $db->prepare($check_query);
        $check_stmt->bindParam(':room_number', $data['room_number']);
        $check_stmt->execute();
        
        if ($check_stmt->rowCount() > 0) {
            Response::error('Room with this number already exists', 409);
        }

        $query = "INSERT INTO rooms (room_number, room_name, building, floor, capacity) 
                  VALUES (:room_number, :room_name, :building, :floor, :capacity)";
        
        $stmt = $db->prepare($query);
        $stmt->bindParam(':room_number', $data['room_number']);
        $stmt->bindParam(':room_name', $data['room_name']);
        $stmt->bindParam(':building', $data['building']);
        $stmt->bindParam(':floor', $data['floor']);
        $stmt->bindParam(':capacity', $data['capacity']);
        
        if ($stmt->execute()) {
            $newRoomId = $db->lastInsertId();
            Response::success(['room_id' => $newRoomId], 'Room created successfully');
        } else {
            Response::error('Failed to create room');
        }
    } catch (Exception $e) {
        Response::error('Failed to create room: ' . $e->getMessage());
    }
} elseif ($method === 'PUT') {
    // Only admin can update rooms
    $auth->requireAdmin();

    try {
        $data = json_decode(file_get_contents('php://input'), true);
        
        if (empty($data['room_id']) || empty($data['room_number']) || empty($data['room_name'])) {
            Response::error('Room ID, room number and name are required');
        }

        // Check if room_number already exists for another room
        $check_query = "SELECT room_id FROM rooms WHERE room_number = :room_number AND room_id != :room_id";
        $check_stmt = $db->prepare($check_query);
        $check_stmt->bindParam(':room_number', $data['room_number']);
        $check_stmt->bindParam(':room_id', $data['room_id']);
        $check_stmt->execute();
        
        if ($check_stmt->rowCount() > 0) {
            Response::error('Room with this number already exists', 409);
        }

        $query = "UPDATE rooms 
                  SET room_number = :room_number,
                      room_name = :room_name,
                      building = :building,
                      floor = :floor,
                      capacity = :capacity
                  WHERE room_id = :room_id AND is_active = TRUE";
        
        $stmt = $db->prepare($query);
        $stmt->bindParam(':room_id', $data['room_id']);
        $stmt->bindParam(':room_number', $data['room_number']);
        $stmt->bindParam(':room_name', $data['room_name']);
        $stmt->bindParam(':building', $data['building']);
        $stmt->bindParam(':floor', $data['floor']);
        $stmt->bindParam(':capacity', $data['capacity']);
        
        if ($stmt->execute() && $stmt->rowCount() > 0) {
            Response::success(['room_id' => $data['room_id']], 'Room updated successfully');
        } else {
            Response::error('Failed to update room or room not found');
        }
    } catch (Exception $e) {
        Response::error('Failed to update room: ' . $e->getMessage());
    }
} elseif ($method === 'DELETE') {
    // Admin only - Soft delete room
    $user = $auth->getCurrentUser();
    if (!in_array($user['role'], ['super_admin', 'admin'])) {
        Response::error('Unauthorized. Admin access required.', 403);
    }

    try {
        $data = json_decode(file_get_contents('php://input'), true);
        
        if (empty($data['room_id'])) {
            Response::error('Room ID is required');
        }

        // Check if room has active installations
        $check_query = "SELECT COUNT(*) as count FROM device_installations 
                       WHERE room_id = :room_id AND status = 'active' AND is_deleted = FALSE";
        $check_stmt = $db->prepare($check_query);
        $check_stmt->bindParam(':room_id', $data['room_id']);
        $check_stmt->execute();
        $result = $check_stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($result['count'] > 0) {
            Response::error('Cannot delete room with active installations. Please withdraw all devices first.', 409);
        }

        // Soft delete - set is_active to FALSE
        $query = "UPDATE rooms SET is_active = FALSE WHERE room_id = :room_id";
        $stmt = $db->prepare($query);
        $stmt->bindParam(':room_id', $data['room_id']);
        
        if ($stmt->execute() && $stmt->rowCount() > 0) {
            Response::success(['room_id' => $data['room_id']], 'Room deleted successfully');
        } else {
            Response::error('Failed to delete room or room not found');
        }
    } catch (Exception $e) {
        Response::error('Failed to delete room: ' . $e->getMessage());
    }
} else {
    Response::error('Method not allowed', 405);
}
