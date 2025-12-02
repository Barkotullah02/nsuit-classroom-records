<?php
/**
 * Gate Passes API
 * Standalone gate pass management (independent of installations)
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

try {
    if ($method === 'GET') {
        // Get gate pass with all its devices
        $gate_pass_id = $_GET['gate_pass_id'] ?? null;
        
        if ($gate_pass_id) {
            // Get gate pass details
            $query = "SELECT 
                        gp.gate_pass_id,
                        gp.gate_pass_number,
                        gp.gate_pass_date,
                        gp.consignee_name,
                        gp.destination,
                        gp.carrier_name,
                        gp.carrier_appointment,
                        gp.carrier_department,
                        gp.carrier_telephone,
                        gp.security_name,
                        gp.security_appointment,
                        gp.security_department,
                        gp.security_telephone,
                        gp.receiver_name,
                        gp.receiver_appointment,
                        gp.receiver_department,
                        gp.receiver_telephone,
                        gp.status,
                        u_created.full_name as created_by_name,
                        gp.created_at
                    FROM gate_passes gp
                    LEFT JOIN users u_created ON gp.created_by = u_created.user_id
                    WHERE gp.gate_pass_id = :gate_pass_id AND gp.is_deleted = FALSE";
            
            $stmt = $db->prepare($query);
            $stmt->bindParam(':gate_pass_id', $gate_pass_id);
            $stmt->execute();
            $gatePass = $stmt->fetch(PDO::FETCH_ASSOC);
            
            if (!$gatePass) {
                Response::error('Gate pass not found');
            }
            
            // Get all devices for this gate pass
            $devicesQuery = "SELECT 
                                d.device_id,
                                d.device_unique_id,
                                dt.type_name,
                                db.brand_name,
                                d.model,
                                d.serial_number,
                                current_room.room_number as current_room_number,
                                current_room.room_name as current_room_name
                            FROM gate_pass_devices gpd
                            JOIN devices d ON gpd.device_id = d.device_id
                            JOIN device_types dt ON d.type_id = dt.type_id
                            JOIN device_brands db ON d.brand_id = db.brand_id
                            LEFT JOIN device_installations di ON d.device_id = di.device_id AND di.status = 'active' AND di.is_deleted = FALSE
                            LEFT JOIN rooms current_room ON di.room_id = current_room.room_id
                            WHERE gpd.gate_pass_id = :gate_pass_id";
            
            $devicesStmt = $db->prepare($devicesQuery);
            $devicesStmt->bindParam(':gate_pass_id', $gate_pass_id);
            $devicesStmt->execute();
            $devices = $devicesStmt->fetchAll(PDO::FETCH_ASSOC);
            
            $gatePass['devices'] = $devices;
            
            Response::success([$gatePass], 'Gate pass retrieved successfully');
        } else {
            // Get all gate passes with device count
            $query = "SELECT 
                        gp.gate_pass_id,
                        gp.gate_pass_number,
                        gp.gate_pass_date,
                        gp.consignee_name,
                        gp.destination,
                        gp.carrier_name,
                        gp.status,
                        u_created.full_name as created_by_name,
                        gp.created_at,
                        COUNT(gpd.device_id) as device_count
                    FROM gate_passes gp
                    LEFT JOIN gate_pass_devices gpd ON gp.gate_pass_id = gpd.gate_pass_id
                    LEFT JOIN users u_created ON gp.created_by = u_created.user_id
                    WHERE gp.is_deleted = FALSE
                    GROUP BY gp.gate_pass_id
                    ORDER BY gp.created_at DESC";
            
            $stmt = $db->prepare($query);
            $stmt->execute();
            $gatePasses = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            Response::success($gatePasses, 'Gate passes retrieved successfully');
        }

    } elseif ($method === 'POST') {
        // Create new gate pass
        $user = $auth->getCurrentUser();
        $data = json_decode(file_get_contents('php://input'), true);

        // Validate required fields
        if (empty($data['devices']) || !is_array($data['devices']) || empty($data['gate_pass_number']) || 
            empty($data['gate_pass_date']) || empty($data['consignee_name']) ||
            empty($data['destination']) || empty($data['carrier_name']) ||
            empty($data['carrier_appointment']) || empty($data['carrier_department']) ||
            empty($data['carrier_telephone'])) {
            Response::error('Missing required fields');
        }

        // Check if gate pass number already exists
        $checkQuery = "SELECT gate_pass_id FROM gate_passes WHERE gate_pass_number = :gate_pass_number AND is_deleted = FALSE";
        $checkStmt = $db->prepare($checkQuery);
        $checkStmt->bindParam(':gate_pass_number', $data['gate_pass_number']);
        $checkStmt->execute();
        
        if ($checkStmt->fetch()) {
            Response::error('Gate pass number already exists');
        }

        $query = "INSERT INTO gate_passes 
                 (gate_pass_number, gate_pass_date, consignee_name, destination,
                  carrier_name, carrier_appointment, carrier_department, carrier_telephone,
                  security_name, security_appointment, security_department, security_telephone,
                  receiver_name, receiver_appointment, receiver_department, receiver_telephone,
                  created_by, status) 
                 VALUES 
                 (:gate_pass_number, :gate_pass_date, :consignee_name, :destination,
                  :carrier_name, :carrier_appointment, :carrier_department, :carrier_telephone,
                  :security_name, :security_appointment, :security_department, :security_telephone,
                  :receiver_name, :receiver_appointment, :receiver_department, :receiver_telephone,
                  :created_by, 'active')";

        $stmt = $db->prepare($query);
        $stmt->bindParam(':gate_pass_number', $data['gate_pass_number']);
        $stmt->bindParam(':gate_pass_date', $data['gate_pass_date']);
        $stmt->bindParam(':consignee_name', $data['consignee_name']);
        $stmt->bindParam(':destination', $data['destination']);
        $stmt->bindParam(':carrier_name', $data['carrier_name']);
        $stmt->bindParam(':carrier_appointment', $data['carrier_appointment']);
        $stmt->bindParam(':carrier_department', $data['carrier_department']);
        $stmt->bindParam(':carrier_telephone', $data['carrier_telephone']);
        $stmt->bindParam(':security_name', $data['security_name']);
        $stmt->bindParam(':security_appointment', $data['security_appointment']);
        $stmt->bindParam(':security_department', $data['security_department']);
        $stmt->bindParam(':security_telephone', $data['security_telephone']);
        $stmt->bindParam(':receiver_name', $data['receiver_name']);
        $stmt->bindParam(':receiver_appointment', $data['receiver_appointment']);
        $stmt->bindParam(':receiver_department', $data['receiver_department']);
        $stmt->bindParam(':receiver_telephone', $data['receiver_telephone']);
        $stmt->bindParam(':created_by', $user['user_id']);
        $stmt->execute();

        $gatePassId = $db->lastInsertId();

        // Insert devices into junction table
        $deviceQuery = "INSERT INTO gate_pass_devices (gate_pass_id, device_id) VALUES (:gate_pass_id, :device_id)";
        $deviceStmt = $db->prepare($deviceQuery);
        
        foreach ($data['devices'] as $deviceId) {
            $deviceStmt->bindParam(':gate_pass_id', $gatePassId);
            $deviceStmt->bindParam(':device_id', $deviceId);
            $deviceStmt->execute();
        }

        // Log audit
        $auditQuery = "INSERT INTO audit_log (table_name, record_id, action, user_id) 
                      VALUES ('gate_passes', :record_id, 'INSERT', :user_id)";
        $auditStmt = $db->prepare($auditQuery);
        $auditStmt->bindParam(':record_id', $gatePassId);
        $auditStmt->bindParam(':user_id', $user['user_id']);
        $auditStmt->execute();

        Response::success([
            'gate_pass_id' => $gatePassId,
            'gate_pass_number' => $data['gate_pass_number']
        ], 'Gate pass created successfully');

    } elseif ($method === 'DELETE') {
        // Soft delete gate pass
        $user = $auth->getCurrentUser();
        $data = json_decode(file_get_contents('php://input'), true);

        if (empty($data['gate_pass_id'])) {
            Response::error('Gate pass ID is required');
        }

        $query = "UPDATE gate_passes SET 
                 is_deleted = TRUE,
                 deleted_at = CURRENT_TIMESTAMP,
                 deleted_by = :deleted_by
                 WHERE gate_pass_id = :gate_pass_id";

        $stmt = $db->prepare($query);
        $stmt->bindParam(':gate_pass_id', $data['gate_pass_id']);
        $stmt->bindParam(':deleted_by', $user['user_id']);
        $stmt->execute();

        // Log audit
        $auditQuery = "INSERT INTO audit_log (table_name, record_id, action, user_id) 
                      VALUES ('gate_passes', :record_id, 'DELETE', :user_id)";
        $auditStmt = $db->prepare($auditQuery);
        $auditStmt->bindParam(':record_id', $data['gate_pass_id']);
        $auditStmt->bindParam(':user_id', $user['user_id']);
        $auditStmt->execute();

        Response::success(null, 'Gate pass deleted successfully');

    } else {
        Response::error('Method not allowed', 405);
    }
} catch (Exception $e) {
    Response::error('Operation failed: ' . $e->getMessage());
}
