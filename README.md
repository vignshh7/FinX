# Smart Finance

AI-powered personal finance mobile app with receipt OCR, expense categorization, and spending insights.

## Features

### Mobile App (Flutter)
- User authentication (JWT with secure storage)
- Dashboard (monthly summary, charts, predictions, alerts)
- Receipt scanner (camera/gallery with image compression)
- OCR result review (manual correction, category selection)
- Expense history (filter, search, categorization)
- Subscription tracker (recurring payments, renewal reminders)
- Settings (budget, currency, dark mode)

### Backend API (Flask + Python)
- OCR processing (Tesseract with image preprocessing)
- ML categorization (NLP-based expense classification)
- Spending prediction (time series analysis)
- Budget alerts (notifications)
- REST API (JWT authentication)

## Architecture

```
Mobile App (Flutter)
      |
   REST APIs
      |
Backend (Flask)
      |
OCR + ML + Database (SQLite)
```

## Quick Start

### Prerequisites

- Flutter SDK 3.10.7+
- Python 3.8+
- Tesseract OCR
- Android Studio or Xcode

### Backend setup

```bash
cd backend

python -m venv venv

venv\Scripts\activate

pip install -r requirements.txt

cp .env.example .env
# Update .env with your Tesseract path

python run.py
```

Default backend URL: `https://finx-ugs5.onrender.com`

### Mobile app setup

```bash
flutter pub get

# Update backend URL in lib/services/api_service.dart
# Set baseUrl to your Render URL for production or your backend IP for local testing

flutter run
```

## How It Works

### OCR receipt flow
1. User captures or uploads a receipt image.
2. Image is compressed and sent to the backend.
3. Backend preprocesses the image (grayscale, denoise, threshold).
4. Tesseract extracts text.
5. Regex patterns extract structured data.
6. ML model predicts the expense category.
7. Results return to the app for review.

### Expense categorization
- Algorithm: Naive Bayes classifier
- Features: TF-IDF vectorization
- Categories: Food, Travel, Shopping, Bills, Entertainment, Other

### Spending prediction
- Weighted moving average (last 6 months)
- Trend analysis and adjustment
- Confidence scoring

## Documentation

See [backend/README.md](backend/README.md) for API and deployment details.

## Testing

1. Run backend: `python run.py`
2. Run app: `flutter run`
3. Register account
4. Set budget in Settings
5. Scan receipt
6. View dashboard

## Built With

- **Flutter** - Mobile framework
- **Flask** - Backend framework
- **Tesseract** - OCR engine
- **Scikit-learn** - Machine learning
- **Provider** - State management
- **FL Chart** - Data visualization

