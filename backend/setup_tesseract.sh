#!/bin/bash

echo "============================================"
echo "FinX OCR Setup - Tesseract Installation"
echo "============================================"
echo ""

# Detect OS
OS="$(uname -s)"

case "${OS}" in
    Linux*)
        echo "Detected: Linux"
        echo ""
        
        # Check if tesseract is installed
        if command -v tesseract &> /dev/null; then
            echo "[✓] Tesseract is already installed!"
            tesseract --version
        else
            echo "[✗] Tesseract not found. Installing..."
            echo ""
            
            # Detect package manager
            if command -v apt-get &> /dev/null; then
                echo "Using apt-get..."
                sudo apt-get update
                sudo apt-get install -y tesseract-ocr
            elif command -v yum &> /dev/null; then
                echo "Using yum..."
                sudo yum install -y tesseract
            elif command -v dnf &> /dev/null; then
                echo "Using dnf..."
                sudo dnf install -y tesseract
            else
                echo "[ERROR] Could not detect package manager"
                echo "Please install Tesseract manually"
                exit 1
            fi
        fi
        ;;
        
    Darwin*)
        echo "Detected: macOS"
        echo ""
        
        # Check if tesseract is installed
        if command -v tesseract &> /dev/null; then
            echo "[✓] Tesseract is already installed!"
            tesseract --version
        else
            echo "[✗] Tesseract not found. Installing..."
            echo ""
            
            # Check if Homebrew is installed
            if command -v brew &> /dev/null; then
                echo "Using Homebrew..."
                brew install tesseract
            else
                echo "[ERROR] Homebrew not found"
                echo "Install Homebrew first: https://brew.sh"
                echo "Then run: brew install tesseract"
                exit 1
            fi
        fi
        ;;
        
    *)
        echo "Unsupported OS: ${OS}"
        exit 1
        ;;
esac

# Verify installation
echo ""
echo "============================================"
if command -v tesseract &> /dev/null; then
    echo "[✓] SUCCESS! Tesseract is installed"
    echo ""
    tesseract --version
    echo ""
    echo "NEXT STEPS:"
    echo "1. Restart the Flask backend server"
    echo "2. OCR will now use real Tesseract instead of mock data"
else
    echo "[✗] Installation failed"
    echo "Please install Tesseract manually"
fi
echo "============================================"
