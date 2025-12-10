<?php
/**
 * Device Types and Brands API
 * Get device types and brands for filters
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
        // Get device types
        $types_query = "SELECT type_id, type_name, description FROM device_types ORDER BY type_name";
        $types_stmt = $db->prepare($types_query);
        $types_stmt->execute();
        $types = $types_stmt->fetchAll(PDO::FETCH_ASSOC);

        // Get device brands
        $brands_query = "SELECT brand_id, brand_name FROM device_brands ORDER BY brand_name";
        $brands_stmt = $db->prepare($brands_query);
        $brands_stmt->execute();
        $brands = $brands_stmt->fetchAll(PDO::FETCH_ASSOC);

        // Get device statuses (from ENUM) - removed as these columns don't exist in current schema
        $device_statuses = [];

        // Get installation types
        $installation_types = [
            ['value' => 'NEW_INSTALLATION', 'label' => 'New Installation'],
            ['value' => 'REPAIRED', 'label' => 'Repaired Device'],
            ['value' => 'OLD_REINSTALL', 'label' => 'Old Device Reinstall']
        ];

        Response::success([
            'types' => $types,
            'brands' => $brands,
            'device_statuses' => $device_statuses,
            'installation_types' => $installation_types
        ], 'Metadata retrieved successfully');
    } catch (Exception $e) {
        Response::error('Failed to retrieve metadata: ' . $e->getMessage());
    }
} elseif ($method === 'POST') {
    // Admin only
    $user = $auth->getCurrentUser();
    if ($user['role'] !== 'admin') {
        Response::error('Unauthorized. Admin access required.', 403);
    }

    try {
        $data = json_decode(file_get_contents('php://input'), true);
        
        if (empty($data['type'])) {
            Response::error('Type parameter is required (brand or device_type)');
        }

        if ($data['type'] === 'brand') {
            if (empty($data['brand_name'])) {
                Response::error('Brand name is required');
            }

            $query = "INSERT INTO device_brands (brand_name) VALUES (:brand_name)";
            $stmt = $db->prepare($query);
            $stmt->bindParam(':brand_name', $data['brand_name']);
            
            if ($stmt->execute()) {
                $newId = $db->lastInsertId();
                Response::success(['brand_id' => $newId], 'Brand created successfully');
            } else {
                Response::error('Failed to create brand');
            }
        } elseif ($data['type'] === 'device_type') {
            if (empty($data['type_name'])) {
                Response::error('Type name is required');
            }

            $query = "INSERT INTO device_types (type_name, description) VALUES (:type_name, :description)";
            $stmt = $db->prepare($query);
            $stmt->bindParam(':type_name', $data['type_name']);
            $stmt->bindParam(':description', $data['description']);
            
            if ($stmt->execute()) {
                $newId = $db->lastInsertId();
                Response::success(['type_id' => $newId], 'Device type created successfully');
            } else {
                Response::error('Failed to create device type');
            }
        } else {
            Response::error('Invalid type parameter');
        }
    } catch (Exception $e) {
        Response::error('Failed to create metadata: ' . $e->getMessage());
    }
} else {
    Response::error('Method not allowed', 405);
}
