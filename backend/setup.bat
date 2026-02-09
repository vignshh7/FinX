@echo off
echo ================================
echo Smart Finance - Backend Setup
echo ================================
echo.

echo Step 1: Creating virtual environment...
python -m venv venv
if %errorlevel% neq 0 (
    echo ERROR: Failed to create virtual environment
    pause
    exit /b 1
)

echo Step 2: Activating virtual environment...
call venv\Scripts\activate.bat

echo Step 3: Installing dependencies...
pip install -r requirements.txt
if %errorlevel% neq 0 (
    echo ERROR: Failed to install dependencies
    pause
    exit /b 1
)

echo Step 4: Setting up environment...
if not exist .env (
    copy .env.example .env
    echo Created .env file - Please update TESSERACT_CMD path
)

echo Step 5: Creating directories...
if not exist uploads mkdir uploads
if not exist app\ml_models mkdir app\ml_models

echo.
echo ================================
echo Setup Complete!
echo ================================
echo.
echo Next steps:
echo 1. Edit .env file and update TESSERACT_CMD path
echo 2. Run: python run.py
echo.
pause
