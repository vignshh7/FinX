#!/bin/bash

echo "================================"
echo "Smart Finance - Backend Setup"
echo "================================"
echo ""

echo "Step 1: Creating virtual environment..."
python3 -m venv venv
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to create virtual environment"
    exit 1
fi

echo "Step 2: Activating virtual environment..."
source venv/bin/activate

echo "Step 3: Installing dependencies..."
pip install -r requirements.txt
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to install dependencies"
    exit 1
fi

echo "Step 4: Setting up environment..."
if [ ! -f .env ]; then
    cp .env.example .env
    echo "Created .env file - Please update TESSERACT_CMD path if needed"
fi

echo "Step 5: Creating directories..."
mkdir -p uploads
mkdir -p app/ml_models

echo ""
echo "================================"
echo "Setup Complete!"
echo "================================"
echo ""
echo "Next steps:"
echo "1. Edit .env file if needed"
echo "2. Run: python run.py"
echo ""
