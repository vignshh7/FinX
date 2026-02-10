@echo off
REM Allow Flask backend through Windows Firewall

echo.
echo ========================================
echo   Configure Windows Firewall for Flask
echo ========================================
echo.
echo This will allow Python to accept connections
echo from Android Emulator on port 5000
echo.

REM Check if running as administrator
net session >nul 2>&1
if %errorLevel% NEQ 0 (
    echo ERROR: This script must be run as Administrator!
    echo.
    echo Right-click this file and select "Run as administrator"
    pause
    exit /b 1
)

REM Add firewall rule for Python on port 5000
echo Adding firewall rule...
netsh advfirewall firewall add rule name="Flask Backend - Port 5000" dir=in action=allow protocol=TCP localport=5000

echo.
echo ========================================
echo   Firewall Configured Successfully!
echo ========================================
echo.
echo Python Flask backend is now accessible on:
echo   - http://localhost:5000
echo   - http://10.0.2.2:5000 (Android Emulator)
echo.
echo You can now run:
echo   python run.py
echo.
pause
