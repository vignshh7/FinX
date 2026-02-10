#!/bin/bash
# Quick start script for local development

echo ""
echo "========================================"
echo "  FinX Backend - Local Development"
echo "========================================"
echo ""

# Check if virtual environment exists
if [ ! -d ".venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv .venv
    echo ""
fi

# Activate virtual environment
echo "Activating virtual environment..."
source .venv/bin/activate

# Install/update dependencies
echo ""
echo "Installing dependencies..."
pip install -r requirements.txt --quiet

# Check if .env exists
if [ ! -f ".env" ]; then
    echo ""
    echo "WARNING: .env file not found!"
    echo "Creating .env from .env.example..."
    cp .env.example .env
    echo ""
    echo "Please edit .env file and add your Google Vision API key"
    read -p "Press enter to continue..."
fi

# Run the backend
echo ""
echo "========================================"
echo "  Starting Flask Backend"
echo "========================================"
echo ""
echo "Running at: http://localhost:5000"
echo "API endpoint: http://localhost:5000/api"
echo ""
echo "Press Ctrl+C to stop"
echo ""

python run.py
