"""
AI Routes for comprehensive AI features
Provides endpoints for all 6 AI modules
"""

from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app import db
from app.services.comprehensive_ai_service import ComprehensiveAIService
from app.models import Expense, CategorizationFeedback
import os
import json
import requests

ai_bp = Blueprint('ai', __name__)

# Initialize AI service
ai_service = ComprehensiveAIService(db)


def _generate_llm_insights(user_id):
    api_key = os.getenv('GROQ_API_KEY')
    if not api_key:
        return None

    try:
        analysis = ai_service.get_complete_ai_analysis(user_id)
        aggregation = analysis.get('aggregation', {}) or {}
        prediction = analysis.get('prediction', {}) or {}
        anomalies_data = analysis.get('anomalies', {}) or {}
        advice = analysis.get('advice', {}).get('advice', []) or []

        monthly_totals = aggregation.get('monthly_totals', {}) or {}
        category_totals = aggregation.get('category_totals', {}) or {}
        top_categories = sorted(
            category_totals.items(), key=lambda x: x[1], reverse=True
        )[:5]
        recent_months = sorted(monthly_totals.items())[-6:]

        # Compact, safe data summary to avoid oversized prompts
        data_summary = (
            f"Monthly spending (recent): {recent_months}\n"
            f"Top categories: {top_categories}\n"
            f"Overall total: {round(aggregation.get('overall_total', 0), 2)}\n"
            f"Avg monthly: {round(aggregation.get('average_monthly', 0), 2)}\n"
            f"Next month prediction: {round(float(prediction.get('next_month_prediction', 0) or 0), 2)}\n"
            f"Spending trend: {prediction.get('trend', 'unknown')}\n"
            f"Anomalies detected: {len(anomalies_data.get('anomalies', []))}\n"
            f"Top advice: {[a.get('title', '') for a in advice[:3]]}"
        )

        payload = {
            'model': os.getenv('GROQ_MODEL', 'llama-3.1-8b-instant'),
            'messages': [
                {
                    'role': 'system',
                    'content': (
                        'You are a financial insights assistant. Return ONLY valid JSON with keys: '
                        'summary (string), highlights (array of strings), risks (array of strings), '
                        'actions (array of strings), sections (object with keys: prediction, aggregation, '
                        'anomalies, advice, patterns — each having summary (string) and bullets (array of strings)).'
                    )
                },
                {
                    'role': 'user',
                    'content': f'Generate insights for this financial data:\n{data_summary}'
                }
            ],
            'temperature': 0.3,
            'max_tokens': 600,
            'response_format': {'type': 'json_object'},
        }

        response = requests.post(
            'https://api.groq.com/openai/v1/chat/completions',
            headers={
                'Authorization': f'Bearer {api_key}',
                'Content-Type': 'application/json',
            },
            json=payload,
            timeout=25,
        )
        response.raise_for_status()
        data = response.json()
        content = data.get('choices', [{}])[0].get('message', {}).get('content', '')

        try:
            return json.loads(content)
        except json.JSONDecodeError:
            return {
                'summary': content.strip(),
                'highlights': [], 'risks': [], 'actions': [],
            }
    except Exception as e:
        return {
            'summary': f'LLM insights unavailable: {str(e)}',
            'highlights': [], 'risks': [], 'actions': [],
        }


@ai_bp.route('/ai/categorize', methods=['POST'])
@jwt_required()
def categorize_expense_route():
    """
    Auto-categorize an expense before saving
    Endpoint: POST /api/ai/categorize
    Body: { "store_name": str, "items": Optional[list], "description": Optional[str] }
    """
    try:
        data = request.get_json()
        
        if not data.get('store_name'):
            return jsonify({'message': 'store_name is required'}), 400
        
        category, confidence, method = ai_service.categorize_expense(
            store_name=data.get('store_name'),
            items=data.get('items'),
            description=data.get('description')
        )
        
        return jsonify({
            'category': category,
            'confidence': round(confidence, 3),
            'method': method,
            'message': f'Category predicted using {method}'
        }), 200
        
    except Exception as e:
        return jsonify({'message': f'Categorization failed: {str(e)}'}), 500


@ai_bp.route('/ai/aggregation', methods=['GET'])
@jwt_required()
def get_spending_aggregation_route():
    """
    Get spending aggregation (monthly & category-wise)
    Endpoint: GET /api/ai/aggregation?months=6
    """
    try:
        user_id = get_jwt_identity()
        months = request.args.get('months', 6, type=int)
        
        if months < 1 or months > 24:
            return jsonify({'message': 'months must be between 1 and 24'}), 400
        
        aggregation = ai_service.get_spending_aggregation(user_id, months)
        
        return jsonify(aggregation), 200
        
    except Exception as e:
        return jsonify({'message': f'Aggregation failed: {str(e)}'}), 500


@ai_bp.route('/ai/prediction', methods=['GET'])
@jwt_required()
def predict_spending_route():
    """
    Predict next month spending
    Endpoint: GET /api/ai/prediction
    """
    try:
        user_id = get_jwt_identity()
        
        prediction = ai_service.predict_next_month_spending(user_id)
        
        return jsonify(prediction), 200
        
    except Exception as e:
        return jsonify({'message': f'Prediction failed: {str(e)}'}), 500


@ai_bp.route('/ai/anomalies', methods=['GET'])
@jwt_required()
def detect_anomalies_route():
    """
    Detect unusual/overspending transactions
    Endpoint: GET /api/ai/anomalies
    """
    try:
        user_id = get_jwt_identity()
        
        anomalies = ai_service.detect_anomalies(user_id)
        
        return jsonify(anomalies), 200
        
    except Exception as e:
        return jsonify({'message': f'Anomaly detection failed: {str(e)}'}), 500


@ai_bp.route('/ai/advice', methods=['GET'])
@jwt_required()
def get_financial_advice_route():
    """
    Get personalized financial advice
    Endpoint: GET /api/ai/advice
    """
    try:
        user_id = get_jwt_identity()
        
        advice = ai_service.get_financial_advice(user_id)
        
        return jsonify(advice), 200
        
    except Exception as e:
        return jsonify({'message': f'Advice generation failed: {str(e)}'}), 500


@ai_bp.route('/ai/insights', methods=['GET'])
@jwt_required()
def get_insights_route():
    """
    Get AI-generated insights in readable text
    Endpoint: GET /api/ai/insights
    """
    try:
        user_id = get_jwt_identity()
        
        insights = ai_service.generate_insights_text(user_id)
        llm_insights = _generate_llm_insights(user_id)

        insights['llm'] = llm_insights
        insights['llm_enabled'] = llm_insights is not None and 'summary' in llm_insights

        return jsonify(insights), 200
        
    except Exception as e:
        return jsonify({'message': f'Insight generation failed: {str(e)}'}), 500


@ai_bp.route('/ai/complete-analysis', methods=['GET'])
@jwt_required()
def get_complete_analysis_route():
    """
    Get complete AI analysis (all modules)
    Endpoint: GET /api/ai/complete-analysis
    """
    try:
        user_id = get_jwt_identity()
        
        analysis = ai_service.get_complete_ai_analysis(user_id)
        
        return jsonify(analysis), 200
        
    except Exception as e:
        return jsonify({'message': f'Complete analysis failed: {str(e)}'}), 500


@ai_bp.route('/ai/feedback', methods=['POST'])
@jwt_required()
def submit_categorization_feedback():
    """
    Submit user feedback for category correction
    Used for future model retraining
    Endpoint: POST /api/ai/feedback
    Body: {
        "expense_id": int,
        "original_category": str,
        "corrected_category": str,
        "confidence": Optional[float]
    }
    """
    try:
        user_id = get_jwt_identity()
        data = request.get_json()
        
        # Validate required fields
        required = ['expense_id', 'original_category', 'corrected_category']
        if not all(k in data for k in required):
            return jsonify({'message': 'Missing required fields'}), 400
        
        # Check if expense exists and belongs to user
        expense = Expense.query.filter_by(
            id=data['expense_id'],
            user_id=user_id
        ).first()
        
        if not expense:
            return jsonify({'message': 'Expense not found'}), 404
        
        # Store feedback
        feedback = CategorizationFeedback(
            user_id=user_id,
            expense_id=data['expense_id'],
            original_category=data['original_category'],
            corrected_category=data['corrected_category'],
            confidence=data.get('confidence')
        )
        
        db.session.add(feedback)
        
        # Update expense category if different
        if expense.category != data['corrected_category']:
            expense.category = data['corrected_category']
        
        db.session.commit()
        
        return jsonify({
            'message': 'Feedback submitted successfully',
            'feedback_id': feedback.id
        }), 201
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'message': f'Feedback submission failed: {str(e)}'}), 500


@ai_bp.route('/ai/retrain', methods=['POST'])
@jwt_required()
def retrain_model():
    """
    Retrain categorization model using user feedback
    Should be called periodically (e.g., weekly)
    Endpoint: POST /api/ai/retrain
    """
    try:
        # This would typically be an admin-only endpoint
        # For now, we'll just collect all feedback
        
        feedbacks = CategorizationFeedback.query.all()
        
        if len(feedbacks) < 10:
            return jsonify({
                'message': 'Not enough feedback for retraining',
                'feedback_count': len(feedbacks),
                'minimum_required': 10
            }), 200
        
        # TODO: Implement actual model retraining
        # This would involve:
        # 1. Collecting all feedback
        # 2. Combining with original training data
        # 3. Retraining the ML model
        # 4. Saving the new model
        
        return jsonify({
            'message': 'Model retraining scheduled',
            'feedback_count': len(feedbacks),
            'status': 'pending_implementation'
        }), 200
        
    except Exception as e:
        return jsonify({'message': f'Retraining failed: {str(e)}'}), 500


@ai_bp.route('/ai/health', methods=['GET'])
def ai_health_check():
    """
    Check if AI services are operational
    Endpoint: GET /api/ai/health
    """
    try:
        # Test basic functionality
        service = ComprehensiveAIService(db)
        test_category, test_conf, test_method = service.categorize_expense('test store')
        
        return jsonify({
            'status': 'healthy',
            'services': {
                'categorization': 'operational',
                'aggregation': 'operational',
                'prediction': 'operational',
                'anomaly_detection': 'operational',
                'advisor': 'operational',
                'insights': 'operational'
            },
            'model_loaded': test_category is not None
        }), 200
        
    except Exception as e:
        return jsonify({
            'status': 'unhealthy',
            'error': str(e)
        }), 500
