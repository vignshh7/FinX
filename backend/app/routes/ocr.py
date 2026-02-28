from flask import Blueprint, request, jsonify
from werkzeug.utils import secure_filename
from flask_jwt_extended import jwt_required, get_jwt_identity
import os
from app.services.simple_ocr_service import OCRService
from app.services.simple_ml_service import ExpenseCategorizer

ocr_bp = Blueprint('ocr', __name__)

# Initialize services
ocr_service = OCRService()
categorizer = ExpenseCategorizer()

ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg'}

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@ocr_bp.route('/upload-receipt', methods=['POST'])
@jwt_required()
def upload_receipt():
    """
    Upload receipt image, perform OCR, and categorize expense
    This is the CORE FEATURE of the application
    """
    try:
        user_id = get_jwt_identity()
        
        # Check if file is present
        if 'receipt' not in request.files:
            return jsonify({'message': 'No file uploaded'}), 400
        
        file = request.files['receipt']
        
        if file.filename == '':
            return jsonify({'message': 'No file selected'}), 400
        
        if not allowed_file(file.filename):
            return jsonify({'message': 'Invalid file type. Only PNG, JPG, JPEG allowed'}), 400
        
        # Save file
        from flask import current_app
        filename = secure_filename(f"{user_id}_{file.filename}")
        filepath = os.path.join(current_app.config['UPLOAD_FOLDER'], filename)
        file.save(filepath)
        
        # Process receipt with OCR
        ocr_result = ocr_service.process_receipt(filepath)
        
        # Categorize expense using ML
        category_result = categorizer.categorize_expense(
            ocr_result['store'],
            ocr_result['items']
        )
        
        # Clean up uploaded file
        try:
            os.remove(filepath)
        except Exception:
            pass
        
        # Combine results
        response = {
            'store': ocr_result['store'],
            'items': ocr_result['items'],
            'amount': ocr_result['amount'],
            'date': ocr_result['date'],
            'predicted_category': category_result['predicted_category'],
            'confidence': category_result['confidence']
        }
        
        return jsonify(response), 200
        
    except Exception as e:
        return jsonify({'message': f'OCR processing failed: {str(e)}'}), 500
