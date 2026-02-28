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

2. **Activate virtual environment**
```bash
# Windows
venv\Scripts\activate

# Mac/Linux
source venv/bin/activate
```

3. **Install dependencies**
```bash
pip install -r requirements.txt
```

4. **Configure environment**
```bash
# Copy example env file
cp .env.example .env

# Edit .env and update:
# - TESSERACT_CMD path (if different)
# - SECRET_KEY (change in production)
# - JWT_SECRET_KEY (change in production)
```

5. **Run the application**
```bash
python run.py
```

The API will be available at: `http://localhost:5000`

## API Endpoints

### Authentication

**POST /api/register**
- Register new user
- Body: `{ "name": "John", "email": "john@email.com", "password": "password123" }`

**POST /api/login**
- Login and get JWT token
- Body: `{ "email": "john@email.com", "password": "password123" }`
- Returns: `{ "id", "name", "email", "token" }`

### OCR (Core Feature)

**POST /api/upload-receipt**
- Upload receipt image for OCR processing
- Headers: `Authorization: Bearer <token>`
- Body: `multipart/form-data` with `receipt` file
- Returns:
```json
{
  "store": "ABC Supermarket",
  "items": ["Milk", "Bread"],
  "amount": 450.00,
  "date": "2026-01-20",
  "predicted_category": "Food",
  "confidence": 0.95
}
```

### Expenses

**GET /api/expenses**
- Get all expenses (with optional filters)
- Headers: `Authorization: Bearer <token>`
- Query params: `?category=Food&start_date=2026-01-01&end_date=2026-01-31`

**POST /api/expenses**
- Create new expense
- Headers: `Authorization: Bearer <token>`
- Body: `{ "store", "amount", "category", "date", "items", "raw_ocr_text" }`

**DELETE /api/expenses/<id>**
- Delete expense
- Headers: `Authorization: Bearer <token>`

### Predictions

**GET /api/predict**
- Get AI prediction for next month's spending
- Headers: `Authorization: Bearer <token>`
- Returns: `{ "predicted_amount", "confidence", "based_on_months" }`

**GET /api/alerts**
- Get budget alerts
- Headers: `Authorization: Bearer <token>`
- Returns: `{ "alerts": [...] }`

### Subscriptions

**GET /api/subscriptions**
- Get all subscriptions
- Headers: `Authorization: Bearer <token>`

**POST /api/subscriptions**
- Create subscription
- Headers: `Authorization: Bearer <token>`
- Body: `{ "name", "amount", "frequency", "renewal_date" }`

**DELETE /api/subscriptions/<id>**
- Delete subscription
- Headers: `Authorization: Bearer <token>`

### Budget

**GET /api/budget**
- Get user budget
- Headers: `Authorization: Bearer <token>`

**PUT /api/budget**
- Create/update budget
- Headers: `Authorization: Bearer <token>`
- Body: `{ "monthly_limit", "currency" }`

## OCR Pipeline

### Image Preprocessing
1. **Grayscale Conversion** - Simplifies image processing
2. **Denoising** - Removes noise using Non-Local Means Denoising
3. **Adaptive Thresholding** - Converts to binary image
4. **Resizing** - Scales image to optimal size for OCR

### Text Extraction
- Uses Tesseract OCR engine
- PSM mode 6 (uniform block of text)

### Data Extraction
- **Store Name**: First non-empty line
- **Amount**: Regex patterns for currency values
- **Date**: Multiple date format patterns
- **Items**: Heuristic-based item detection

## ML Categorization

### Model
- **Algorithm**: Naive Bayes with TF-IDF vectorization
- **Categories**: Food, Travel, Shopping, Bills, Entertainment, Other
- **Features**: Store name + item names (combined text)

### Training
- Pre-trained on sample data
- Can be retrained with user data
- Model saved to `app/ml_models/categorizer.pkl`

## Spending Prediction

### Algorithm
- **Method**: Weighted moving average with trend analysis
- **Data**: Last 6 months of expenses
- **Weighting**: Recent months have higher weight
- **Trend Adjustment**: Linear trend added to prediction

## Database Schema

### Users
- id, name, email, password_hash, created_at

### Expenses
- id, user_id, store, amount, category, date, items, raw_ocr_text, created_at

### Subscriptions
- id, user_id, name, amount, frequency, renewal_date, created_at

### Budgets
- id, user_id, monthly_limit, currency, created_at, updated_at

## Project Structure

```
backend/
├── app/
│   ├── __init__.py           # Flask app factory
│   ├── models.py             # SQLAlchemy models
│   ├── routes/
│   │   ├── auth.py           # Authentication endpoints
│   │   ├── expenses.py       # Expense management
│   │   ├── ocr.py           # OCR upload endpoint
│   │   ├── subscriptions.py  # Subscription management
│   │   └── budget.py         # Budget management
│   ├── services/
│   │   ├── ocr_service.py    # OCR processing
│   │   ├── ml_service.py     # ML categorization
│   │   └── prediction_service.py  # Predictions & alerts
│   └── ml_models/            # Trained ML models
├── uploads/                  # Temporary file uploads
├── requirements.txt          # Python dependencies
├── .env.example             # Environment template
└── run.py                   # Application entry point
```

## Testing

### Test OCR Endpoint

```bash
curl -X POST http://localhost:5000/api/upload-receipt \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "receipt=@receipt.jpg"
```

### Test Registration

```bash
curl -X POST http://localhost:5000/api/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@test.com","password":"password123"}'
```

## Production Deployment

### Recommended Changes

1. **Change SECRET_KEY and JWT_SECRET_KEY** in .env
2. **Use PostgreSQL** instead of SQLite
3. **Set up HTTPS**
4. **Enable CORS properly** for production domain
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

AI-Powered Smart Finance Team
