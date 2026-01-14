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
                        gp.pass_direction,
                        gp.gate_pass_time,
                        gp.department,
                        gp.gate_name,
                        gp.vendor_destination,
                        gp.bearer_name,
                        gp.bearer_company,
                        gp.bearer_contact_no,
                        gp.bearer_signature,
                        gp.bearer_signature_date,
                        gp.security_officer_name,
                        gp.security_officer_designation,
                        gp.security_officer_ext,
                        gp.security_officer_signature,
                        gp.security_officer_signature_date,
                        gp.processing_name,
                        gp.processing_designation,
                        gp.processing_ext,
                        gp.processing_signature,
                        gp.processing_signature_date,
                        gp.authorized_name,
                        gp.authorized_designation,
                        gp.authorized_ext,
                        gp.authorized_signature,
                        gp.authorized_signature_date,
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
                        gp.pass_direction,
                        gp.department,
                        gp.gate_name,
                        gp.vendor_destination,
                        gp.bearer_name,
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

        // Backward-compatible mapping: allow older clients to still send the previous fields
        $passDirection = $data['pass_direction'] ?? 'outgoing';
        if ($passDirection !== 'incoming' && $passDirection !== 'outgoing') {
            $passDirection = 'outgoing';
        }

        $department = $data['department'] ?? ($data['consignee_name'] ?? null);
        $gateName = $data['gate_name'] ?? null;
        $vendorDestination = $data['vendor_destination'] ?? ($data['destination'] ?? null);

        $bearerName = $data['bearer_name'] ?? ($data['carrier_name'] ?? null);
        $bearerCompany = $data['bearer_company'] ?? ($data['carrier_department'] ?? null);
        $bearerContactNo = $data['bearer_contact_no'] ?? ($data['carrier_telephone'] ?? null);

        $securityOfficerName = $data['security_officer_name'] ?? ($data['security_name'] ?? null);
        $securityOfficerDesignation = $data['security_officer_designation'] ?? ($data['security_appointment'] ?? null);
        $securityOfficerExt = $data['security_officer_ext'] ?? null;

        $processingName = $data['processing_name'] ?? ($data['receiver_name'] ?? null);
        $processingDesignation = $data['processing_designation'] ?? ($data['receiver_appointment'] ?? null);
        $processingExt = $data['processing_ext'] ?? null;

        $authorizedName = $data['authorized_name'] ?? null;
        $authorizedDesignation = $data['authorized_designation'] ?? null;
        $authorizedExt = $data['authorized_ext'] ?? null;

        // Validate required fields
        if (empty($data['devices']) || !is_array($data['devices']) || empty($data['gate_pass_number']) || empty($data['gate_pass_date'])) {
            Response::error('Missing required fields');
        }

        // New format required fields (kept fairly strict for printing)
        if (empty($department) || empty($vendorDestination) || empty($bearerName) || empty($bearerCompany) || empty($bearerContactNo)) {
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
         (gate_pass_number, gate_pass_date, pass_direction, gate_pass_time, department, gate_name, vendor_destination,
          bearer_name, bearer_company, bearer_contact_no, bearer_signature, bearer_signature_date,
          security_officer_name, security_officer_designation, security_officer_ext, security_officer_signature, security_officer_signature_date,
          processing_name, processing_designation, processing_ext, processing_signature, processing_signature_date,
          authorized_name, authorized_designation, authorized_ext, authorized_signature, authorized_signature_date,
          consignee_name, destination,
          carrier_name, carrier_appointment, carrier_department, carrier_telephone,
          security_name, security_appointment, security_department, security_telephone,
          receiver_name, receiver_appointment, receiver_department, receiver_telephone,
          purpose, remarks,
          created_by, status) 
         VALUES 
         (:gate_pass_number, :gate_pass_date, :pass_direction, :gate_pass_time, :department, :gate_name, :vendor_destination,
          :bearer_name, :bearer_company, :bearer_contact_no, :bearer_signature, :bearer_signature_date,
          :security_officer_name, :security_officer_designation, :security_officer_ext, :security_officer_signature, :security_officer_signature_date,
          :processing_name, :processing_designation, :processing_ext, :processing_signature, :processing_signature_date,
          :authorized_name, :authorized_designation, :authorized_ext, :authorized_signature, :authorized_signature_date,
          :consignee_name, :destination,
          :carrier_name, :carrier_appointment, :carrier_department, :carrier_telephone,
          :security_name, :security_appointment, :security_department, :security_telephone,
          :receiver_name, :receiver_appointment, :receiver_department, :receiver_telephone,
          :purpose, :remarks,
          :created_by, 'active')";

        $stmt = $db->prepare($query);
        $stmt->bindParam(':gate_pass_number', $data['gate_pass_number']);
        $stmt->bindParam(':gate_pass_date', $data['gate_pass_date']);

        $stmt->bindParam(':pass_direction', $passDirection);
        $stmt->bindParam(':gate_pass_time', $data['gate_pass_time']);
        $stmt->bindParam(':department', $department);
        $stmt->bindParam(':gate_name', $gateName);
        $stmt->bindParam(':vendor_destination', $vendorDestination);

        $stmt->bindParam(':bearer_name', $bearerName);
        $stmt->bindParam(':bearer_company', $bearerCompany);
        $stmt->bindParam(':bearer_contact_no', $bearerContactNo);
        $stmt->bindParam(':bearer_signature', $data['bearer_signature']);
        $stmt->bindParam(':bearer_signature_date', $data['bearer_signature_date']);

        $stmt->bindParam(':security_officer_name', $securityOfficerName);
        $stmt->bindParam(':security_officer_designation', $securityOfficerDesignation);
        $stmt->bindParam(':security_officer_ext', $securityOfficerExt);
        $stmt->bindParam(':security_officer_signature', $data['security_officer_signature']);
        $stmt->bindParam(':security_officer_signature_date', $data['security_officer_signature_date']);

        $stmt->bindParam(':processing_name', $processingName);
        $stmt->bindParam(':processing_designation', $processingDesignation);
        $stmt->bindParam(':processing_ext', $processingExt);
        $stmt->bindParam(':processing_signature', $data['processing_signature']);
        $stmt->bindParam(':processing_signature_date', $data['processing_signature_date']);

        $stmt->bindParam(':authorized_name', $authorizedName);
        $stmt->bindParam(':authorized_designation', $authorizedDesignation);
        $stmt->bindParam(':authorized_ext', $authorizedExt);
        $stmt->bindParam(':authorized_signature', $data['authorized_signature']);
        $stmt->bindParam(':authorized_signature_date', $data['authorized_signature_date']);

        // Keep older fields populated too (for backward compatibility with existing UI)
        $consigneeNameCompat = $data['consignee_name'] ?? $department;
        $destinationCompat = $data['destination'] ?? $vendorDestination;
        $carrierNameCompat = $data['carrier_name'] ?? $bearerName;
        $carrierAppointmentCompat = $data['carrier_appointment'] ?? null;
        $carrierDepartmentCompat = $data['carrier_department'] ?? $bearerCompany;
        $carrierTelephoneCompat = $data['carrier_telephone'] ?? $bearerContactNo;
        $securityDepartmentCompat = $data['security_department'] ?? 'Duty Security Officer';

        $stmt->bindParam(':consignee_name', $consigneeNameCompat);
        $stmt->bindParam(':destination', $destinationCompat);
        $stmt->bindParam(':carrier_name', $carrierNameCompat);
        $stmt->bindParam(':carrier_appointment', $carrierAppointmentCompat);
        $stmt->bindParam(':carrier_department', $carrierDepartmentCompat);
        $stmt->bindParam(':carrier_telephone', $carrierTelephoneCompat);
        $stmt->bindParam(':security_name', $data['security_name']);
        $stmt->bindParam(':security_appointment', $data['security_appointment']);
        $stmt->bindParam(':security_department', $securityDepartmentCompat);
        $stmt->bindParam(':security_telephone', $data['security_telephone']);
        $stmt->bindParam(':receiver_name', $data['receiver_name']);
        $stmt->bindParam(':receiver_appointment', $data['receiver_appointment']);
        $stmt->bindParam(':receiver_department', $data['receiver_department']);
        $stmt->bindParam(':receiver_telephone', $data['receiver_telephone']);

        // Some DBs still have these columns as NOT NULL (older schema)
        $purposeCompat = $data['purpose'] ?? 'Other';
        $remarksCompat = $data['remarks'] ?? null;
        $stmt->bindParam(':purpose', $purposeCompat);
        $stmt->bindParam(':remarks', $remarksCompat);

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
