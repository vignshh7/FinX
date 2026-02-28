# Smart Finance - AI-Powered Personal Finance Mobile App

Complete end-to-end mobile application with OCR receipt scanning, AI expense categorization, and spending predictions.

## 🎯 Features

### Mobile App (Flutter)
- ✅ **User Authentication** (JWT with secure storage)
- ✅ **Dashboard** (Monthly summary, charts, predictions, alerts)
- ✅ **Receipt Scanner** (Camera/Gallery with image compression)
- ✅ **OCR Result Review** (Manual correction, category selection)
- ✅ **Expense History** (Filter, search, categorization)
- ✅ **Subscription Tracker** (Recurring payments, renewal reminders)
- ✅ **Settings** (Budget, currency, dark mode)

### Backend API (Flask + Python)
- ✅ **OCR Processing** (Tesseract with image preprocessing)
- ✅ **ML Categorization** (NLP-based expense classification)
- ✅ **Spending Prediction** (Time series analysis)
- ✅ **Budget Alerts** (Smart notifications)
- ✅ **RESTful API** (JWT authentication)

## 🏗️ Architecture

```
Mobile App (Flutter)
      ↓
   REST APIs
      ↓
Backend (Flask)
      ↓
┌─────────┬──────────┬─────────┐
│   OCR   │    ML    │Database │
│Tesseract│Sklearn   │ SQLite  │
└─────────┴──────────┴─────────┘
```

## 🚀 Quick Start

### Prerequisites

- **Flutter SDK** (3.10.7+)
- **Python** (3.8+)
- **Tesseract OCR**
- **Android Studio** / **Xcode** (for mobile development)

### 1. Backend Setup

```bash
cd backend

# Create virtual environment
python -m venv venv

# Activate (Windows)
venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Configure environment
cp .env.example .env
# Edit .env with your Tesseract path

# Run server
python run.py
```

Backend runs at: `http://localhost:5000`

### 2. Mobile App Setup

```bash
# Get Flutter dependencies
flutter pub get

# Update backend URL in lib/services/api_service.dart
# Change baseUrl to your backend IP (use computer IP, not localhost for device testing)

# Run on emulator/device
flutter run
```

## 🎨 Key Features Explained

### 1. OCR Receipt Scanning (CORE FEATURE)

**How it works:**
1. User captures/uploads receipt image
2. Image is compressed and sent to backend
3. Backend preprocesses image (grayscale, denoise, threshold)
4. Tesseract extracts text
5. Regex patterns extract structured data
6. ML model predicts expense category
7. Results sent back to app for review

### 2. AI Expense Categorization

**ML Model:**
- Algorithm: Naive Bayes Classifier
- Features: TF-IDF vectorization
- Categories: Food, Travel, Shopping, Bills, Entertainment, Other

### 3. Spending Prediction

**Algorithm:**
- Weighted moving average (last 6 months)
- Trend analysis and adjustment
- Confidence scoring

## 📚 Full Documentation

See [backend/README.md](backend/README.md) for complete API documentation and deployment guide.

## 🧪 Testing

1. Run backend: `python run.py`
2. Run app: `flutter run`
3. Register account
4. Set budget in Settings
5. Scan receipt
6. View dashboard

## 📦 Built With

- **Flutter** - Mobile framework
- **Flask** - Backend framework
- **Tesseract** - OCR engine
- **Scikit-learn** - Machine learning
- **Provider** - State management
- **FL Chart** - Data visualization

## 📄 License

MIT License

---

**⭐ Key Achievement: Fully functional OCR-based receipt scanning with AI categorization!**
