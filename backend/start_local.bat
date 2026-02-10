@echo off
REM Quick start script for local development

echo.
echo ========================================
echo   FinX Backend - Local Development
echo ========================================
echo.

REM Check if virtual environment exists
if not exist ".venv\" (
    echo Creating virtual environment...
    python -m venv .venv
    echo.
)

REM Activate virtual environment
echo Activating virtual environment...
call .venv\Scripts\activate.bat

REM Install/update dependencies
echo.
echo Installing dependencies...
pip install -r requirements.txt --quiet

REM Check if .env exists
if not exist ".env" (
    echo.
    echo WARNING: .env file not found!
    echo Creating .env from .env.example...
    copy .env.example .env
    echo.
    echo Please edit .env file and add your Google Vision API key
    pause
)

REM Run the backend
echo.
echo ========================================
echo   Starting Flask Backend
echo ========================================
echo.
echo Running at: http://localhost:5000
echo API endpoint: http://localhost:5000/api
echo.
echo Press Ctrl+C to stop
echo.

python run.py
