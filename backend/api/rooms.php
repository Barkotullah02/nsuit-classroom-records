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
    } catch (Exception $e) {
        Response::error('Failed to retrieve rooms: ' . $e->getMessage());
    }
} elseif ($method === 'POST') {
    // Admin only
    $user = $auth->getCurrentUser();
    if ($user['role'] !== 'admin') {
        Response::error('Unauthorized. Admin access required.', 403);
    }

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
    // Admin only - Update room
    $user = $auth->getCurrentUser();
    if ($user['role'] !== 'admin') {
        Response::error('Unauthorized. Admin access required.', 403);
    }

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
    if ($user['role'] !== 'admin') {
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
