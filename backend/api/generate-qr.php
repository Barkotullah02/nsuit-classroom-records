<?php
/**
 * Generate QR Code API
 * Generates QR code with comprehensive device information
 */

require_once __DIR__ . '/../config/cors.php';
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../phpqrcode/qrlib.php';

$auth = new Auth();
$auth->requireAuth();

$database = new Database();
$db = $database->getConnection();

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    exit;
}

try {
    $device_id = $_GET['device_id'] ?? null;
    
    if (!$device_id) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Device ID is required']);
        exit;
    }

    // Get comprehensive device information
    $query = "SELECT 
                d.device_id,
                d.device_unique_id,
                dt.type_name,
                db.brand_name,
                d.model,
                d.serial_number,
                d.purchase_date,
                d.notes,
                r.room_number,
                r.room_name,
                r.building,
                di.installed_date,
                di.installation_notes
            FROM devices d
            LEFT JOIN device_types dt ON d.type_id = dt.type_id
            LEFT JOIN device_brands db ON d.brand_id = db.brand_id
            LEFT JOIN device_installations di ON d.device_id = di.device_id AND di.status = 'active' AND di.is_deleted = FALSE
            LEFT JOIN rooms r ON di.room_id = r.room_id
            WHERE d.device_id = :device_id AND d.is_deleted = FALSE";
    
    $stmt = $db->prepare($query);
    $stmt->bindParam(':device_id', $device_id);
    $stmt->execute();
    $device = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$device) {
        http_response_code(404);
        echo json_encode(['success' => false, 'message' => 'Device not found']);
        exit;
    }

    // Get installation history
    $history_query = "SELECT 
                        r.room_number,
                        r.room_name,
                        r.building,
                        di.installed_date,
                        di.withdrawn_date,
                        di.status
                    FROM device_installations di
                    JOIN rooms r ON di.room_id = r.room_id
                    WHERE di.device_id = :device_id AND di.is_deleted = FALSE
                    ORDER BY di.installed_date DESC";
    
    $history_stmt = $db->prepare($history_query);
    $history_stmt->bindParam(':device_id', $device_id);
    $history_stmt->execute();
    $installation_history = $history_stmt->fetchAll(PDO::FETCH_ASSOC);

    // Build comprehensive data as formatted text for QR code
    $qr_text = "DEVICE INFORMATION\n";
    $qr_text .= "==================\n\n";
    $qr_text .= "Device UID: " . $device['device_unique_id'] . "\n";
    $qr_text .= "Type: " . ($device['type_name'] ?? 'N/A') . "\n";
    $qr_text .= "Brand: " . ($device['brand_name'] ?? 'N/A') . "\n";
    $qr_text .= "Model: " . ($device['model'] ?? 'N/A') . "\n";
    $qr_text .= "Serial: " . ($device['serial_number'] ?? 'N/A') . "\n";
    $qr_text .= "Purchase Date: " . ($device['purchase_date'] ?? 'N/A') . "\n\n";
    
    // Current location
    $qr_text .= "CURRENT LOCATION\n";
    $qr_text .= "----------------\n";
    if ($device['room_number']) {
        $qr_text .= "Room: " . ($device['building'] ? $device['building'] . ' ' : '') . $device['room_number'] . ' - ' . $device['room_name'] . "\n";
        $qr_text .= "Installed: " . ($device['installed_date'] ?? 'N/A') . "\n";
    } else {
        $qr_text .= "Status: Not Installed\n";
    }
    
    // Notes
    if (!empty($device['notes']) || !empty($device['installation_notes'])) {
        $qr_text .= "\nNOTES/ISSUES\n";
        $qr_text .= "------------\n";
        $qr_text .= !empty($device['notes']) ? $device['notes'] : $device['installation_notes'];
        $qr_text .= "\n";
    }
    
    // Installation history
    if (!empty($installation_history)) {
        $qr_text .= "\nINSTALLATION HISTORY\n";
        $qr_text .= "--------------------\n";
        foreach ($installation_history as $h) {
            $room = ($h['building'] ? $h['building'] . ' ' : '') . $h['room_number'] . ' - ' . $h['room_name'];
            $qr_text .= "• " . $room . "\n";
            $qr_text .= "  " . $h['installed_date'] . " → " . ($h['withdrawn_date'] ?? 'Current') . "\n";
        }
    } else {
        $qr_text .= "\nNo previous installation history.\n";
    }
    
    // Generate QR code and output as PNG
    header('Content-Type: image/png');
    header('Content-Disposition: inline; filename="device-' . $device['device_unique_id'] . '-qr.png"');
    
    // Parameters: data, filename(false=output to browser), error correction level, size, margin
    // Using QR_ECLEVEL_L (Low) for more data capacity
    QRcode::png($qr_text, false, QR_ECLEVEL_L, 10, 2);
    
} catch (Exception $e) {
    http_response_code(500);
    header('Content-Type: application/json');
    echo json_encode([
        'success' => false, 
        'message' => 'Failed to generate QR code: ' . $e->getMessage()
    ]);
}
