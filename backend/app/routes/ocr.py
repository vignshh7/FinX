from flask import Blueprint, request, jsonify
from werkzeug.utils import secure_filename
from flask_jwt_extended import jwt_required, get_jwt_identity
import os
from app.services.ocr_service import OCRService  # Use real OCR service
from app.services.simple_ml_service import ExpenseCategorizer

ocr_bp = Blueprint('ocr', __name__)

# Initialize services
ocr_service = OCRService()
categorizer = ExpenseCategorizer()

ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'webp', 'heic', 'heif', 'bmp', 'gif'}

def allowed_file(filename):
    if not filename or '.' not in filename:
        return False
    ext = filename.rsplit('.', 1)[1].lower()
    return ext in ALLOWED_EXTENSIONS

@ocr_bp.route('/upload-receipt', methods=['POST'])
@jwt_required()
def upload_receipt():
    """
    Upload receipt image, perform OCR, and categorize expense
    This is the CORE FEATURE of the application
    """
    try:
        user_id = get_jwt_identity()
        print(f"\n{'='*70}")
        print(f"📸 Receipt upload request from user: {user_id}")
        print(f"{'='*70}")
        
        # Check if file is present
        if 'receipt' not in request.files:
            print("❌ No file in request")
            return jsonify({'message': 'No file uploaded'}), 400
        
        file = request.files['receipt']
        
        if file.filename == '':
            print("❌ Empty filename")
            return jsonify({'message': 'No file selected'}), 400
        
        if not allowed_file(file.filename):
            print(f"❌ Invalid file type: {file.filename}")
            return jsonify({
                'message': 'Invalid file type',
                'allowed_types': ['PNG', 'JPG', 'JPEG', 'WEBP', 'HEIC', 'BMP', 'GIF'],
                'received': file.filename.rsplit('.', 1)[1] if '.' in file.filename else 'unknown'
            }), 400
        
        print(f"✓ File received: {file.filename}")
        
        # Save file
        from flask import current_app
        filename = secure_filename(f"{user_id}_{file.filename}")
        filepath = os.path.join(current_app.config['UPLOAD_FOLDER'], filename)
        
        try:
            file.save(filepath)
            file_size = os.path.getsize(filepath)
            print(f"✓ File saved: {filepath} ({file_size} bytes)")
        except Exception as e:
            print(f"❌ Failed to save file: {str(e)}")
            return jsonify({'message': f'Failed to save file: {str(e)}'}), 500
        
        # Process receipt with OCR
        print("🔄 Starting OCR processing...")
        ocr_result = ocr_service.process_receipt(filepath)
        
        if ocr_result.get('processing_status') == 'failed':
            error_msg = ocr_result.get('error', 'Unknown OCR error')
            print(f"❌ OCR Failed: {error_msg}")
            # Clean up file
            try:
                os.remove(filepath)
            except Exception:
                pass
            return jsonify({
                'message': f'OCR processing failed: {error_msg}',
                'error_type': 'processing_error'
            }), 422
        
        print(f"✓ OCR Success - Store: {ocr_result['store']}, Amount: {ocr_result['amount']}")
        
        # Categorize expense using ML
        print("🤖 Categorizing expense...")
        category_result = categorizer.categorize_expense(
            ocr_result['store'],
            ocr_result['amount']
        )
        print(f"✓ Category: {category_result.get('category', 'Other')} (confidence: {category_result.get('confidence', 0)})")
        
        # Clean up uploaded file
        try:
            os.remove(filepath)
            print(f"✓ Cleaned up file: {filepath}")
        except Exception:
            pass
        
        # Combine results
        response = {
            'store': ocr_result['store'],
            'items': ocr_result['items'],
            'amount': ocr_result['amount'],
            'date': ocr_result['date'],
            'predicted_category': category_result.get('category', 'Other'),
            'confidence': category_result.get('confidence', 0.5),
            'raw_text': ocr_result.get('raw_text', ''),
            'ocr_provider': ocr_result.get('ocr_provider', 'ocrspace'),
            'ocr_mode': ocr_result.get('ocr_mode', 'cloud'),
            'available': ocr_result.get('available', False),
            'processing_status': ocr_result.get('processing_status', 'unknown')
        }
        
        print(f"✅ SUCCESS - Returning response")
        print(f"{'='*70}\n")
        return jsonify(response), 200
        
    except Exception as e:
        error_msg = str(e)
        print(f"\n❌ EXCEPTION in upload_receipt: {error_msg}")
        import traceback
        traceback.print_exc()
        print(f"{'='*70}\n")
        
        status_code = 500
        
        # Provide specific error codes for common issues
        if 'API key' in error_msg:
            status_code = 503
        elif 'Invalid image' in error_msg or 'Cannot read image' in error_msg:
            status_code = 400
        elif 'No text detected' in error_msg:
            status_code = 422
        
        return jsonify({
            'message': f'OCR processing failed: {error_msg}',
            'error_type': 'validation_error' if status_code == 400 else 'processing_error'
        }), status_code

@ocr_bp.route('/ocr-status', methods=['GET'])
def ocr_status():
    """
    Check OCR service status and OCR.space API availability
    """
    try:
        return jsonify({
            'ocr_provider': 'ocrspace',
            'mode': 'cloud',
            'available': ocr_service.available,
            'message': 'OCR.space API is ready' if ocr_service.available else 'OCR.space API key not configured',
            'api_endpoint': 'https://api.ocr.space/parse/image'
        }), 200
        
    except Exception as e:
        return jsonify({
            'ocr_provider': 'ocrspace',
            'mode': 'cloud',
            'available': False,
            'message': f'Error: {str(e)}'
        }), 500
