# Deploy FinX Backend to Render

## Quick Deploy Steps

### 1. Push Code to GitHub
```bash
git add .
git commit -m "Add Render deployment config"
git push origin main
```

### 2. Create Render Account
- Go to [render.com](https://render.com)
- Sign up with GitHub

### 3. Deploy from Dashboard
1. Click **"New +"** → **"Blueprint"**
2. Connect your GitHub repository
3. Select `backend/render.yaml`
4. Click **"Apply"**

### 4. Configure Environment Variables
In Render Dashboard, add:

| Variable | Value | Notes |
|----------|-------|-------|
| `DATABASE_URL` | `<postgres-url>` | Render auto-creates PostgreSQL |
| `JWT_SECRET_KEY` | Auto-generated | Already in render.yaml |
| `FLASK_ENV` | `production` | Already in render.yaml |
| `TESSERACT_PATH` | `/usr/bin/tesseract` | Already in render.yaml |

### 5. Link PostgreSQL Database (Optional)
1. Click **"New +"** → **"PostgreSQL"**
2. Name: `finx-database`
3. Copy **Internal Database URL**
4. Paste into `DATABASE_URL` environment variable

---

## What's Included

✅ **Tesseract OCR** - Automatically installed during build
✅ **Python Dependencies** - From `requirements.txt`
✅ **Health Check** - `/api/health` endpoint
✅ **Auto-scaling** - Render handles it

---

## Deployment Process

When you push code:
1. Render detects changes
2. Runs build command:
   - Installs Tesseract OCR
   - Installs Python packages
3. Starts app with `python run.py`
4. Health check verifies service is running

---

## Verify Deployment

After deployment completes:

```bash
# Check health
curl https://finx-backend.onrender.com/api/health

# Check OCR status
curl https://finx-backend.onrender.com/api/ocr-status
```

Expected response:
```json
{
  "tesseract_available": true,
  "ocr_mode": "tesseract"
}
```

---

## Update Flutter App

Update [lib/services/api_service.dart](../lib/services/api_service.dart):

```dart
class ApiService {
  static const String baseUrl = 'https://finx-backend.onrender.com/api';
  // ... rest of code
}
```

---

## Troubleshooting

### Build Fails
- Check Render logs for errors
- Verify `requirements.txt` has all dependencies

### Tesseract Not Found
- Confirm `render.yaml` build command includes apt-get install
- Check logs for "tesseract: command not found"

### Database Connection Error
- Verify `DATABASE_URL` is set correctly
- Ensure PostgreSQL service is running

### App Timeout on First Request
- Free tier spins down after inactivity
- First request takes 30-60 seconds to wake up

---

## Free Tier Limitations

- **Sleep after inactivity** - App spins down after 15 min idle
- **750 hours/month** - Enough for development/testing
- **512 MB RAM** - Sufficient for Flask + ML models

Upgrade to paid plan for production use.

---

## Next Steps

1. Deploy backend to Render
2. Update Flutter app with production API URL
3. Test all features (expenses, income, OCR, AI)
4. Configure production database
5. Set up monitoring/alerts

**Your backend will be live at:** `https://finx-backend.onrender.com` 🚀
