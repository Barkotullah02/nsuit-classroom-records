<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

require_once __DIR__ . '/phpqrcode/qrlib.php';

echo "Testing QR Code Generation...\n\n";

// Test 1: Check if GD library is available
if (extension_loaded('gd')) {
    echo "✓ GD library is loaded\n";
} else {
    echo "✗ GD library is NOT loaded - REQUIRED!\n";
    exit(1);
}

// Test 2: Check cache directory
$cache_dir = __DIR__ . '/phpqrcode/cache/';
if (is_dir($cache_dir)) {
    echo "✓ Cache directory exists: $cache_dir\n";
    if (is_writable($cache_dir)) {
        echo "✓ Cache directory is writable\n";
    } else {
        echo "✗ Cache directory is NOT writable\n";
    }
} else {
    echo "✗ Cache directory does NOT exist\n";
}

// Test 3: Generate a simple QR code
try {
    $test_data = "Test QR Code - " . date('Y-m-d H:i:s');
    $output_file = __DIR__ . '/test-qr-output.png';
    
    echo "\nGenerating QR code to file: $output_file\n";
    QRcode::png($test_data, $output_file, QR_ECLEVEL_L, 10, 2);
    
    if (file_exists($output_file)) {
        echo "✓ QR code file generated successfully\n";
        echo "File size: " . filesize($output_file) . " bytes\n";
    } else {
        echo "✗ QR code file was NOT created\n";
    }
} catch (Exception $e) {
    echo "✗ Error generating QR code: " . $e->getMessage() . "\n";
}

// Test 4: Generate QR code to browser (PNG output)
echo "\n===========================================\n";
echo "Now generating QR code to browser output...\n";
echo "===========================================\n\n";

header('Content-Type: image/png');
QRcode::png($test_data, false, QR_ECLEVEL_L, 10, 2);
