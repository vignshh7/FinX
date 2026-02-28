# Smart Finance - Backend API

AI-Powered Personal Finance Application with OCR Receipt Scanning

## Features

- ✅ **User Authentication** (JWT-based)
- ✅ **OCR Receipt Scanning** (Tesseract)
- ✅ **AI Expense Categorization** (ML/NLP)
- ✅ **Spending Prediction** (Time Series Analysis)
- ✅ **Budget Alerts**
- ✅ **Subscription Tracking**
- ✅ **RESTful API**

## Tech Stack

- **Framework**: Flask
- **Database**: SQLite (SQLAlchemy ORM)
- **Authentication**: JWT (Flask-JWT-Extended)
- **OCR**: Tesseract OCR + OpenCV
- **ML**: Scikit-learn, NLTK

## Installation

### Prerequisites

1. **Python 3.8+**
2. **Tesseract OCR**
   - Windows: Download from https://github.com/UB-Mannheim/tesseract/wiki
   - Install to: `C:\Program Files\Tesseract-OCR\`
   - Mac: `brew install tesseract`
   - Linux: `sudo apt-get install tesseract-ocr`

### Setup

1. **Create virtual environment**
```bash
cd backend
python -m venv venv
```
# Smart Finance Backend

Flask backend for the Smart Finance mobile app. Provides OCR receipt processing, expense categorization, and analytics APIs.

## Features

- User authentication (JWT)
- Receipt OCR (Tesseract)
- Expense categorization (ML/NLP)
- Spending prediction and alerts
- Subscriptions, budgets, incomes, savings goals
- REST API for the Flutter app

## Tech Stack

- Flask, SQLAlchemy, Flask-JWT-Extended
- SQLite (local), PostgreSQL-ready for production
- Tesseract OCR + OpenCV
- Scikit-learn, NLTK

## Setup

### Prerequisites

- Python 3.8+
- Tesseract OCR
  - Windows: https://github.com/UB-Mannheim/tesseract/wiki
  - macOS: `brew install tesseract`
  - Linux: `sudo apt-get install tesseract-ocr`

### Local install

```bash
cd backend
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env
# Update .env with your Tesseract path and secrets
python run.py
```

Default API URL: `https://finx-ugs5.onrender.com`

## API Overview

### Health

- GET /api/health
- GET /api/ocr-status

### Auth

- POST /api/register
- POST /api/login

### OCR

- POST /api/upload-receipt

### Expenses

- GET /api/expenses
- POST /api/expenses
- DELETE /api/expenses/<id>
- POST /api/expenses/<id>/feedback

### Predictions and Alerts

- GET /api/predict
- GET /api/alerts

### Subscriptions

- GET /api/subscriptions
- POST /api/subscriptions
- DELETE /api/subscriptions/<id>

### Incomes

- GET /api/incomes
- POST /api/incomes
- PUT /api/incomes/<id>
- DELETE /api/incomes/<id>

### Budget

- GET /api/budget
- PUT /api/budget
- GET /api/budget/categories

### Savings Goals

- GET /api/savings-goals
- POST /api/savings-goals
- GET /api/savings-goals/<id>
- PUT /api/savings-goals/<id>
- DELETE /api/savings-goals/<id>
- POST /api/savings-goals/<id>/contribute
- POST /api/savings-contributions
- GET /api/savings-reports/monthly

## OCR Pipeline

- Preprocess image (grayscale, denoise, threshold, resize)
- Extract text with Tesseract (PSM 6)
- Parse store, amount, date, and items with regex heuristics

## ML Categorization

- Model: Naive Bayes + TF-IDF
- Categories: Food, Travel, Shopping, Bills, Entertainment, Other
- Model file: app/ml_models/categorizer.pkl

## Spending Prediction

- Weighted moving average over the last 6 months
- Trend adjustment based on recent change

## Project Structure

```
backend/
  app/
    __init__.py
    models.py
    routes/
    services/
    ml_models/
  uploads/
  requirements.txt
  .env.example
  run.py
```

## Testing

```bash
curl -X POST https://finx-ugs5.onrender.com/api/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@test.com","password":"password123"}'
```

```bash
curl -X POST https://finx-ugs5.onrender.com/api/upload-receipt \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "receipt=@receipt.jpg"
```

## Production Notes

- Change `SECRET_KEY` and `JWT_SECRET_KEY` in `.env`
- Use PostgreSQL instead of SQLite
- Enforce CORS for your production domain
- Use Gunicorn or a production WSGI server

## Troubleshooting

- Tesseract not found: update `TESSERACT_CMD` in `.env`
- Import errors: re-activate venv and reinstall requirements
- Database issues: delete `finance.db` to recreate tables


