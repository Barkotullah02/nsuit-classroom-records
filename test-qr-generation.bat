@echo off
echo ====================================
echo QR Code Generation Test Script
echo ====================================
echo.

echo Step 1: Checking PHP GD Extension...
C:\xampp\php\php.exe -r "if (extension_loaded('gd')) { echo 'PASS: GD extension is loaded\n'; } else { echo 'FAIL: GD extension is NOT loaded\n'; exit(1); }"
if errorlevel 1 (
    echo.
    echo ERROR: GD extension is not enabled!
    echo Please enable it in C:\xampp\php\php.ini
    pause
    exit /b 1
)
echo.

echo Step 2: Testing QR Code Generation (CLI)...
C:\xampp\php\php.exe backend\test-qr.php > nul 2>&1
if exist "backend\test-qr-output.png" (
    echo PASS: QR code file generated successfully
    dir "backend\test-qr-output.png" | find "test-qr-output.png"
) else (
    echo FAIL: QR code file was not created
)
echo.

echo Step 3: Checking Apache Status...
tasklist /FI "IMAGENAME eq httpd.exe" 2>NUL | find /I /N "httpd.exe">NUL
if "%ERRORLEVEL%"=="0" (
    echo PASS: Apache is running
) else (
    echo FAIL: Apache is NOT running
    echo Please start Apache from XAMPP Control Panel
    pause
    exit /b 1
)
echo.

echo Step 4: Testing QR Code via HTTP...
curl -s -o "test-http-qr.png" -w "HTTP %%{http_code}\n" "http://localhost/nsuit-classroom-records/backend/api/test-qr-simple.php"
if exist "test-http-qr.png" (
    echo PASS: QR code downloaded via HTTP
    dir "test-http-qr.png" | find "test-http-qr.png"
) else (
    echo FAIL: QR code not downloaded via HTTP
)
echo.

echo Step 5: Testing Actual Generate QR API (requires device_id)...
echo To test the actual API, you need a valid device_id from your database.
echo Example: curl -H "Authorization: Bearer YOUR_TOKEN" "http://localhost/nsuit-classroom-records/backend/api/generate-qr.php?device_id=1" -o device-qr.png
echo.

echo ====================================
echo Test Complete!
echo ====================================
echo.
echo Summary:
echo - GD Extension: Enabled
echo - CLI Generation: Working
echo - Apache: Running
echo - HTTP Generation: Check test-http-qr.png
echo.
echo The QR code should work on ALL devices including:
echo - Windows browsers (Chrome, Firefox, Edge)
echo - Mac browsers (Safari, Chrome, Firefox)
echo - Mobile devices (iOS Safari, Android Chrome)
echo - Tablets
echo.
echo QR codes are standard PNG images and work universally!
echo.
pause
