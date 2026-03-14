<?php
// Simple QR code test without authentication
error_reporting(E_ALL);
ini_set('display_errors', 0); // Don't output errors for image generation

require_once __DIR__ . '/../phpqrcode/qrlib.php';

// Generate a simple QR code
$test_data = "Test Device QR - " . date('Y-m-d H:i:s');

try {
    header('Content-Type: image/png');
    header('Content-Disposition: inline; filename="test-qr.png"');
    
    QRcode::png($test_data, false, QR_ECLEVEL_L, 10, 2);
} catch (Exception $e) {
    header('Content-Type: text/plain');
    echo "Error: " . $e->getMessage();
}
