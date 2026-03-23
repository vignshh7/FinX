from flask import Blueprint, request, jsonify
from werkzeug.utils import secure_filename
from flask_jwt_extended import jwt_required, get_jwt_identity
import os
from app.services.ocr_service import OCRService
from app.services.ml_service import ExpenseCategorizer as AIExpenseCategorizer
from app.services.simple_ml_service import ExpenseCategorizer as RuleExpenseCategorizer

ocr_bp = Blueprint('ocr', __name__)

# Initialize services
ocr_service = OCRService()
ai_categorizer = AIExpenseCategorizer()
rule_categorizer = RuleExpenseCategorizer()

ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg'}

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS


def _build_ai_text_payload(ocr_result):
    item_names = [
        str(item.get('name', '')).strip()
        for item in (ocr_result.get('items') or [])
        if isinstance(item, dict)
    ]
    parts = [
        str(ocr_result.get('store', '')).strip(),
        ' '.join(item_names),
        str(ocr_result.get('raw_text', '')).strip(),
    ]
    return ' '.join(part for part in parts if part).strip()

@ocr_bp.route('/upload-receipt', methods=['POST'])
@jwt_required()
def upload_receipt():
    """
    Upload receipt image, perform OCR, and categorize expense
    This is the CORE FEATURE of the application
    """
    try:
        user_id = int(get_jwt_identity())
        
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
        
        try:
            # Process receipt with OCR
            ocr_result = ocr_service.process_receipt(filepath)

            # Send full OCR text + extracted entities to AI categorizer.
            ai_text_payload = _build_ai_text_payload(ocr_result)
            ai_category, ai_confidence = ai_categorizer.predict(ai_text_payload)
            model_source = 'ml_model'

            predicted_category = ai_category or 'Other'
            confidence = ai_confidence if ai_confidence is not None else 0.0

            # Fallback to rule model when ML confidence is weak.
            if confidence < 0.45:
                fallback = rule_categorizer.categorize_expense(
                    ai_text_payload,
                    ocr_result.get('amount', 0.0),
                )
                predicted_category = (
                    fallback.get('predicted_category')
                    or fallback.get('category')
                    or predicted_category
                    or 'Other'
                )
                confidence = max(confidence, float(fallback.get('confidence', 0.5)))
                model_source = 'rule_fallback'

        finally:
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
            'ocr_amount': ocr_result.get('ocr_amount', ocr_result['amount']),
            'ai_predicted_amount': ocr_result.get('ai_predicted_amount', ocr_result['amount']),
            'amount_confidence': ocr_result.get('amount_confidence', 'low'),
            'amount_reason': ocr_result.get('amount_reason', ''),
            'amount_model_source': 'ocr_text_ai_scorer',
            'selected_amount_line': ocr_result.get('selected_amount_line', ''),
            'selected_amount_score': ocr_result.get('selected_amount_score', 0.0),
            'date': ocr_result['date'],
            'predicted_category': predicted_category,
            'confidence': confidence,
            'category_model_source': model_source,
            'ocr_text_length': len(ocr_result.get('raw_text', '')),
        }
        
        return jsonify(response), 200
        
    except Exception as e:
        return jsonify({'message': f'OCR processing failed: {str(e)}'}), 500
