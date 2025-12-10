<?php
/**
 * Devices API
 * CRUD operations for devices
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
$data = json_decode(file_get_contents("php://input"), true);

switch ($method) {
    case 'GET':
        // Get devices with filters
        try {
            $filters = [];
            $params = [];
            
            // Build WHERE clause based on filters
            $where = "WHERE d.is_deleted = FALSE";
            
            if (isset($_GET['device_id'])) {
                $where .= " AND d.device_id = :device_id";
                $params[':device_id'] = $_GET['device_id'];
            }
            
            if (isset($_GET['device_unique_id'])) {
                $where .= " AND d.device_unique_id LIKE :device_unique_id";
                $params[':device_unique_id'] = '%' . $_GET['device_unique_id'] . '%';
            }
            
            if (isset($_GET['type_id'])) {
                $where .= " AND d.type_id = :type_id";
                $params[':type_id'] = $_GET['type_id'];
            }
            
            if (isset($_GET['brand_id'])) {
                $where .= " AND d.brand_id = :brand_id";
                $params[':brand_id'] = $_GET['brand_id'];
            }
            
            if (isset($_GET['room_id'])) {
                $where .= " AND di.room_id = :room_id AND di.status = 'active'";
                $params[':room_id'] = $_GET['room_id'];
            }

            $query = "SELECT 
                        d.device_id,
                        d.device_unique_id,
                        d.type_id,
                        dt.type_name,
                        d.brand_id,
                        db.brand_name,
                        d.model,
                        d.serial_number,
                        d.purchase_date,
                        d.warranty_period,
                        d.notes,
                        d.is_active,
                        d.created_at,
                        r.room_id as current_room_id,
                        r.room_number as current_room_number,
                        r.room_name as current_room_name,
                        r.building as current_building,
                        di.installed_date as current_installation_date,
                        DATEDIFF(CURDATE(), di.installed_date) as days_in_current_room,
                        (SELECT MIN(inst.installed_date) 
                         FROM device_installations inst 
                         WHERE inst.device_id = d.device_id 
                         AND inst.is_deleted = FALSE) as first_installation_date,
                        DATEDIFF(CURDATE(), (SELECT MIN(inst.installed_date) 
                                            FROM device_installations inst 
                                            WHERE inst.device_id = d.device_id 
                                            AND inst.is_deleted = FALSE)) as total_lifetime_days
                    FROM devices d
                    LEFT JOIN device_types dt ON d.type_id = dt.type_id
                    LEFT JOIN device_brands db ON d.brand_id = db.brand_id
                    LEFT JOIN device_installations di ON d.device_id = di.device_id 
                        AND di.status = 'active' 
                        AND di.is_deleted = FALSE
                    LEFT JOIN rooms r ON di.room_id = r.room_id
                    {$where}
                    ORDER BY d.device_unique_id";

            $stmt = $db->prepare($query);
            
            foreach ($params as $key => $value) {
                $stmt->bindValue($key, $value);
            }
            
            $stmt->execute();
            $devices = $stmt->fetchAll(PDO::FETCH_ASSOC);

            Response::success($devices, 'Devices retrieved successfully');
        } catch (Exception $e) {
            Response::error('Failed to retrieve devices: ' . $e->getMessage());
        }
        break;

    case 'POST':
        // Create new device
        $auth->requireAdmin();
        
        try {
            // Validate required fields
            $required = ['device_unique_id', 'type_id', 'brand_id'];
            $errors = [];
            
            foreach ($required as $field) {
                if (!isset($data[$field]) || empty($data[$field])) {
                    $errors[$field] = ucfirst(str_replace('_', ' ', $field)) . ' is required';
                }
            }
            
            if (!empty($errors)) {
                Response::validationError($errors);
            }

            // Check if device_unique_id already exists
            $check_query = "SELECT device_id FROM devices WHERE device_unique_id = :device_unique_id";
            $check_stmt = $db->prepare($check_query);
            $check_stmt->bindParam(':device_unique_id', $data['device_unique_id']);
            $check_stmt->execute();
            
            if ($check_stmt->rowCount() > 0) {
                Response::error('Device with this unique ID already exists', 409);
            }

            $query = "INSERT INTO devices 
                     (device_unique_id, type_id, brand_id, model, serial_number, purchase_date, warranty_period, notes) 
                     VALUES 
                     (:device_unique_id, :type_id, :brand_id, :model, :serial_number, :purchase_date, :warranty_period, :notes)";

            $stmt = $db->prepare($query);
            $stmt->bindParam(':device_unique_id', $data['device_unique_id']);
            $stmt->bindParam(':type_id', $data['type_id']);
            $stmt->bindParam(':brand_id', $data['brand_id']);
            $stmt->bindParam(':model', $data['model']);
            $stmt->bindParam(':serial_number', $data['serial_number']);
            $stmt->bindParam(':purchase_date', $data['purchase_date']);
            $stmt->bindParam(':warranty_period', $data['warranty_period']);
            $stmt->bindParam(':notes', $data['notes']);

            if ($stmt->execute()) {
                $device_id = $db->lastInsertId();
                
                // Log action
                $user = $auth->getCurrentUser();
                $log_query = "INSERT INTO audit_log (user_id, action, table_name, record_id, new_values) 
                             VALUES (:user_id, 'CREATE', 'devices', :record_id, :new_values)";
                $log_stmt = $db->prepare($log_query);
                $log_stmt->execute([
                    ':user_id' => $user['user_id'],
                    ':record_id' => $device_id,
                    ':new_values' => json_encode($data)
                ]);

                Response::success(['device_id' => $device_id], 'Device created successfully', 201);
            }
        } catch (Exception $e) {
            Response::error('Failed to create device: ' . $e->getMessage());
        }
        break;

    case 'PUT':
        // Update device
        $auth->requireAdmin();
        
        try {
            if (!isset($data['device_id'])) {
                Response::error('Device ID is required');
            }

            // Get old values for audit
            $old_query = "SELECT * FROM devices WHERE device_id = :device_id";
            $old_stmt = $db->prepare($old_query);
            $old_stmt->bindParam(':device_id', $data['device_id']);
            $old_stmt->execute();
            $old_values = $old_stmt->fetch(PDO::FETCH_ASSOC);

            $query = "UPDATE devices SET 
                     device_unique_id = :device_unique_id,
                     type_id = :type_id,
                     brand_id = :brand_id,
                     model = :model,
                     serial_number = :serial_number,
                     purchase_date = :purchase_date,
                     warranty_period = :warranty_period,
                     notes = :notes,
                     is_active = :is_active
                     WHERE device_id = :device_id";

            $stmt = $db->prepare($query);
            $stmt->bindParam(':device_id', $data['device_id']);
            $stmt->bindParam(':device_unique_id', $data['device_unique_id']);
            $stmt->bindParam(':type_id', $data['type_id']);
            $stmt->bindParam(':brand_id', $data['brand_id']);
            $stmt->bindParam(':model', $data['model']);
            $stmt->bindParam(':serial_number', $data['serial_number']);
            $stmt->bindParam(':purchase_date', $data['purchase_date']);
            $stmt->bindParam(':warranty_period', $data['warranty_period']);
            $stmt->bindParam(':notes', $data['notes']);
            $stmt->bindParam(':is_active', $data['is_active']);

            if ($stmt->execute()) {
                // Log action
                $user = $auth->getCurrentUser();
                $log_query = "INSERT INTO audit_log (user_id, action, table_name, record_id, old_values, new_values) 
                             VALUES (:user_id, 'UPDATE', 'devices', :record_id, :old_values, :new_values)";
                $log_stmt = $db->prepare($log_query);
                $log_stmt->execute([
                    ':user_id' => $user['user_id'],
                    ':record_id' => $data['device_id'],
                    ':old_values' => json_encode($old_values),
                    ':new_values' => json_encode($data)
                ]);

                Response::success([], 'Device updated successfully');
            }
        } catch (Exception $e) {
            Response::error('Failed to update device: ' . $e->getMessage());
        }
        break;

    case 'DELETE':
        // Soft delete device
        $auth->requireAdmin();
        
        try {
            $data = json_decode(file_get_contents('php://input'), true);
            $device_id = $data['device_id'] ?? null;
            
            if (!$device_id) {
                Response::error('Device ID is required');
            }

            // Check if device has active installations
            $check_query = "SELECT COUNT(*) as count FROM device_installations 
                           WHERE device_id = :device_id AND status = 'active' AND is_deleted = FALSE";
            $check_stmt = $db->prepare($check_query);
            $check_stmt->bindParam(':device_id', $device_id);
            $check_stmt->execute();
            $result = $check_stmt->fetch(PDO::FETCH_ASSOC);
            
            if ($result['count'] > 0) {
                Response::error('Cannot delete device with active installations. Please withdraw the device first.', 409);
            }

            $user = $auth->getCurrentUser();
            
            $query = "UPDATE devices 
                     SET is_deleted = TRUE, deleted_at = NOW(), deleted_by = :deleted_by 
                     WHERE device_id = :device_id";
            
            $stmt = $db->prepare($query);
            $stmt->bindParam(':device_id', $device_id);
            $stmt->bindParam(':deleted_by', $user['user_id']);

            if ($stmt->execute() && $stmt->rowCount() > 0) {
                // Log action
                $log_query = "INSERT INTO audit_log (user_id, action, table_name, record_id) 
                             VALUES (:user_id, 'SOFT_DELETE', 'devices', :record_id)";
                $log_stmt = $db->prepare($log_query);
                $log_stmt->execute([
                    ':user_id' => $user['user_id'],
                    ':record_id' => $device_id
                ]);

                Response::success(['device_id' => $device_id], 'Device deleted successfully');
            } else {
                Response::error('Failed to delete device or device not found');
            }
        } catch (Exception $e) {
            Response::error('Failed to delete device: ' . $e->getMessage());
        }
        break;

    default:
        Response::error('Method not allowed', 405);
        break;
}
