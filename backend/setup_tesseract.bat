@echo off
echo ============================================
echo FinX OCR Setup - Tesseract Installation
echo ============================================
echo.

REM Check if Tesseract is already installed
where tesseract >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [SUCCESS] Tesseract is already installed!
    tesseract --version
    echo.
    echo Setting environment variable...
    setx TESSERACT_CMD "tesseract" >nul 2>&1
    echo [DONE] Environment variable set
    goto :end
)

REM Check common installation paths
set TESSERACT_PATH_1=C:\Program Files\Tesseract-OCR\tesseract.exe
set TESSERACT_PATH_2=C:\Program Files (x86)\Tesseract-OCR\tesseract.exe

if exist "%TESSERACT_PATH_1%" (
    echo [FOUND] Tesseract at: %TESSERACT_PATH_1%
    setx TESSERACT_CMD "%TESSERACT_PATH_1%" >nul 2>&1
    echo [DONE] Environment variable set
    goto :end
)

if exist "%TESSERACT_PATH_2%" (
    echo [FOUND] Tesseract at: %TESSERACT_PATH_2%
    setx TESSERACT_CMD "%TESSERACT_PATH_2%" >nul 2>&1
    echo [DONE] Environment variable set
    goto :end
)

echo [NOT FOUND] Tesseract is not installed
echo.
echo INSTALLATION STEPS:
echo 1. Download Tesseract installer from:
echo    https://github.com/UB-Mannheim/tesseract/wiki
echo.
echo 2. Run the installer (tesseract-ocr-w64-setup-5.x.x.exe)
echo.
echo 3. Install to default location: C:\Program Files\Tesseract-OCR
echo.
echo 4. Re-run this setup script
echo.
echo Opening download page in browser...
start https://github.com/UB-Mannheim/tesseract/wiki
echo.

:end
echo.
echo ============================================
echo Setup Complete!
echo ============================================
echo.
echo NEXT STEPS:
echo 1. Restart your terminal/command prompt
echo 2. Restart the Flask backend server
echo 3. OCR will now use real Tesseract instead of mock data
echo.
pause
