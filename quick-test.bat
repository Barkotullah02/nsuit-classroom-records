@echo off
cd /d c:\xampp\htdocs\nsuit-classroom-records
echo Testing QR Code Generation...
echo.
C:\xampp\php\php.exe -r "echo extension_loaded('gd') ? 'GD Extension: ENABLED' : 'GD Extension: DISABLED'; echo PHP_EOL;"
echo.
C:\xampp\php\php.exe backend\test-qr.php 2>&1 | findstr /C:"GD library" /C:"generated successfully" /C:"File size"
echo.
if exist "backend\test-qr-output.png" (
    echo QR Code file created successfully!
) else (
    echo QR Code file NOT created
)
echo.
pause
