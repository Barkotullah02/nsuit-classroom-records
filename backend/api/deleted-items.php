<?php
/**
 * Deleted Items API
 * Manage deleted rooms and devices (restore functionality)
 */

require_once __DIR__ . '/../config/cors.php';
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../includes/response.php';

$auth = new Auth();
$auth->requireAuth();
$auth->requireAdmin(); // Only admins can manage deleted items

$database = new Database();
$db = $database->getConnection();

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    try {
        // Get deleted devices
        $devices_query = "SELECT 
                            d.device_id,
                            d.device_unique_id,
                            d.type_id,
                            dt.type_name,
                            d.brand_id,
                            db.brand_name,
                            d.model,
                            d.serial_number,
                            d.deleted_at,
                            u.full_name as deleted_by_name
                        FROM devices d
                        LEFT JOIN device_types dt ON d.type_id = dt.type_id
                        LEFT JOIN device_brands db ON d.brand_id = db.brand_id
                        LEFT JOIN users u ON d.deleted_by = u.user_id
                        WHERE d.is_deleted = TRUE
                        ORDER BY d.deleted_at DESC";
        
        $devices_stmt = $db->prepare($devices_query);
        $devices_stmt->execute();
        $deleted_devices = $devices_stmt->fetchAll(PDO::FETCH_ASSOC);

        // Get deleted rooms (marked as inactive)
        $rooms_query = "SELECT 
                          r.room_id,
                          r.room_number,
                          r.room_name,
                          r.building,
                          r.floor,
                          r.capacity,
                          r.updated_at as deleted_at
                      FROM rooms r
                      WHERE r.is_active = FALSE
                      ORDER BY r.updated_at DESC";
        
        $rooms_stmt = $db->prepare($rooms_query);
        $rooms_stmt->execute();
        $deleted_rooms = $rooms_stmt->fetchAll(PDO::FETCH_ASSOC);

        Response::success([
            'devices' => $deleted_devices,
            'rooms' => $deleted_rooms
        ], 'Deleted items retrieved successfully');
    } catch (Exception $e) {
        Response::error('Failed to retrieve deleted items: ' . $e->getMessage());
    }
} elseif ($method === 'POST') {
    // Restore deleted item
    try {
        $data = json_decode(file_get_contents('php://input'), true);
        
        if (empty($data['type']) || empty($data['id'])) {
            Response::error('Type and ID are required');
        }

        $user = $auth->getCurrentUser();

        if ($data['type'] === 'device') {
            // Restore device
            $query = "UPDATE devices 
                     SET is_deleted = FALSE, deleted_at = NULL, deleted_by = NULL 
                     WHERE device_id = :device_id AND is_deleted = TRUE";
            
            $stmt = $db->prepare($query);
            $stmt->bindParam(':device_id', $data['id']);
            
            if ($stmt->execute() && $stmt->rowCount() > 0) {
                // Log action
                $log_query = "INSERT INTO audit_log (user_id, action, table_name, record_id) 
                             VALUES (:user_id, 'RESTORE', 'devices', :record_id)";
                $log_stmt = $db->prepare($log_query);
                $log_stmt->execute([
                    ':user_id' => $user['user_id'],
                    ':record_id' => $data['id']
                ]);

                Response::success(['device_id' => $data['id']], 'Device restored successfully');
            } else {
                Response::error('Failed to restore device or device not found');
            }
        } elseif ($data['type'] === 'room') {
            // Restore room
            $query = "UPDATE rooms 
                     SET is_active = TRUE 
                     WHERE room_id = :room_id AND is_active = FALSE";
            
            $stmt = $db->prepare($query);
            $stmt->bindParam(':room_id', $data['id']);
            
            if ($stmt->execute() && $stmt->rowCount() > 0) {
                // Log action
                $log_query = "INSERT INTO audit_log (user_id, action, table_name, record_id) 
                             VALUES (:user_id, 'RESTORE', 'rooms', :record_id)";
                $log_stmt = $db->prepare($log_query);
                $log_stmt->execute([
                    ':user_id' => $user['user_id'],
                    ':record_id' => $data['id']
                ]);

                Response::success(['room_id' => $data['id']], 'Room restored successfully');
            } else {
                Response::error('Failed to restore room or room not found');
            }
        } else {
            Response::error('Invalid type. Must be "device" or "room"');
        }
    } catch (Exception $e) {
        Response::error('Failed to restore item: ' . $e->getMessage());
    }
} elseif ($method === 'DELETE') {
    // Permanent delete
    try {
        $data = json_decode(file_get_contents('php://input'), true);
        
        if (empty($data['type']) || empty($data['id'])) {
            Response::error('Type and ID are required');
        }

        $user = $auth->getCurrentUser();

        if ($data['type'] === 'device') {
            // Permanently delete device and related records
            $db->beginTransaction();
            
            try {
                // Delete related installation records
                $delete_installations = "DELETE FROM device_installations WHERE device_id = :device_id";
                $stmt1 = $db->prepare($delete_installations);
                $stmt1->bindParam(':device_id', $data['id']);
                $stmt1->execute();
                
                // Delete device
                $delete_device = "DELETE FROM devices WHERE device_id = :device_id AND is_deleted = TRUE";
                $stmt2 = $db->prepare($delete_device);
                $stmt2->bindParam(':device_id', $data['id']);
                $stmt2->execute();
                
                if ($stmt2->rowCount() > 0) {
                    $db->commit();
                    
                    // Log action
                    $log_query = "INSERT INTO audit_log (user_id, action, table_name, record_id) 
                                 VALUES (:user_id, 'PERMANENT_DELETE', 'devices', :record_id)";
                    $log_stmt = $db->prepare($log_query);
                    $log_stmt->execute([
                        ':user_id' => $user['user_id'],
                        ':record_id' => $data['id']
                    ]);
                    
                    Response::success([], 'Device permanently deleted');
                } else {
                    $db->rollBack();
                    Response::error('Device not found or not deleted');
                }
            } catch (Exception $e) {
                $db->rollBack();
                throw $e;
            }
        } elseif ($data['type'] === 'room') {
            // Permanently delete room
            $delete_room = "DELETE FROM rooms WHERE room_id = :room_id AND is_active = FALSE";
            $stmt = $db->prepare($delete_room);
            $stmt->bindParam(':room_id', $data['id']);
            
            if ($stmt->execute() && $stmt->rowCount() > 0) {
                // Log action
                $log_query = "INSERT INTO audit_log (user_id, action, table_name, record_id) 
                             VALUES (:user_id, 'PERMANENT_DELETE', 'rooms', :record_id)";
                $log_stmt = $db->prepare($log_query);
                $log_stmt->execute([
                    ':user_id' => $user['user_id'],
                    ':record_id' => $data['id']
                ]);
                
                Response::success([], 'Room permanently deleted');
            } else {
                Response::error('Room not found or not deleted');
            }
        } else {
            Response::error('Invalid type. Must be "device" or "room"');
        }
    } catch (Exception $e) {
        Response::error('Failed to permanently delete item: ' . $e->getMessage());
    }
} else {
    Response::error('Method not allowed', 405);
}
