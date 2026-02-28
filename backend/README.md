# Smart Finance Backend

Flask backend for the Smart Finance app. Provides OCR receipt processing, expense categorization, and analytics APIs.

## Features

- User authentication (JWT)
- Receipt OCR (Tesseract)
- Expense categorization (ML/NLP)
- Spending prediction and alerts
- Subscriptions and budgets
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

API runs at: `http://localhost:5000`

## API Overview

### Auth

- POST /api/register
- POST /api/login

### OCR

- POST /api/upload-receipt

### Expenses

- GET /api/expenses
- POST /api/expenses
- DELETE /api/expenses/<id>

### Predictions and Alerts

- GET /api/predict
- GET /api/alerts

### Subscriptions

- GET /api/subscriptions
- POST /api/subscriptions
- DELETE /api/subscriptions/<id>

### Budget

- GET /api/budget
- PUT /api/budget

## OCR Pipeline

- Preprocess image (grayscale, denoise, threshold, resize)
- Extract text with Tesseract (PSM 6)
- Parse store, amount, date, and items with regex heuristics

## ML Categorization

- Model: Naive Bayes + TF-IDF
- Categories: Food, Travel, Shopping, Bills, Entertainment, Other
- Model file: app/ml_models/categorizer.pkl

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
curl -X POST http://localhost:5000/api/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@test.com","password":"password123"}'
```

```bash
curl -X POST http://localhost:5000/api/upload-receipt \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "receipt=@receipt.jpg"
```

## Production Notes

- Change `SECRET_KEY` and `JWT_SECRET_KEY` in `.env`
- Use PostgreSQL instead of SQLite
- Enforce CORS for your production domain

## License

MIT
5. **Use Gunicorn** as production server:
   ```bash
   pip install gunicorn
   gunicorn -w 4 -b 0.0.0.0:5000 run:app
   ```
6. **Set up logging** to file
7. **Add rate limiting**
8. **Configure file upload limits**

## Troubleshooting

### Tesseract Not Found
- Ensure Tesseract is installed
- Update `TESSERACT_CMD` in .env with correct path

### Import Errors
- Activate virtual environment
- Reinstall requirements: `pip install -r requirements.txt`

### Database Errors
- Delete `finance.db` and restart to recreate tables

### OCR Low Accuracy
- Ensure good image quality
- Proper lighting
- Clear, flat receipts
- Adjust preprocessing parameters in `ocr_service.py`

## License

MIT License

## Author

Vignesh
