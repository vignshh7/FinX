from flask import Blueprint, request, jsonify
from app import db
from app.models import Expense, CategorizationFeedback
from flask_jwt_extended import jwt_required, get_jwt_identity
from datetime import datetime
import json

expenses_bp = Blueprint('expenses', __name__)

@expenses_bp.route('/expenses', methods=['GET'])
@jwt_required()
def get_expenses():
    """Get all expenses for authenticated user with optional filters"""
    try:
        user_id = get_jwt_identity()
        
        # Build query
        query = Expense.query.filter_by(user_id=user_id)
        
        # Apply filters
        category = request.args.get('category')
        if category:
            query = query.filter_by(category=category)
        
        start_date = request.args.get('start_date')
        if start_date:
            query = query.filter(Expense.date >= datetime.fromisoformat(start_date))
        
        end_date = request.args.get('end_date')
        if end_date:
            query = query.filter(Expense.date <= datetime.fromisoformat(end_date))
        
        # Order by date descending
        expenses = query.order_by(Expense.date.desc()).all()
        
        return jsonify({
            'expenses': [expense.to_dict() for expense in expenses]
        }), 200
        
    except Exception as e:
        return jsonify({'message': f'Failed to fetch expenses: {str(e)}'}), 500

@expenses_bp.route('/expenses', methods=['POST'])
@jwt_required()
def create_expense():
    """Create a new expense"""
    try:
        user_id = get_jwt_identity()
        data = request.get_json()
        
        # Validation
        required_fields = ['store', 'amount', 'category', 'date']
        if not all(k in data for k in required_fields):
            return jsonify({'message': 'Missing required fields'}), 400
        
        # Create expense
        expense = Expense(
            user_id=user_id,
            store=data['store'],
            amount=float(data['amount']),
            category=data['category'],
            date=datetime.fromisoformat(data['date'].split('T')[0]),
            items=json.dumps(data.get('items')) if data.get('items') else None,
            raw_ocr_text=data.get('raw_ocr_text')
        )
        
        db.session.add(expense)
        db.session.commit()
        
        return jsonify(expense.to_dict()), 201
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'message': f'Failed to create expense: {str(e)}'}), 500

@expenses_bp.route('/expenses/<int:expense_id>', methods=['DELETE'])
@jwt_required()
def delete_expense(expense_id):
    """Delete an expense"""
    try:
        user_id = get_jwt_identity()
        
        expense = Expense.query.filter_by(id=expense_id, user_id=user_id).first()
        if not expense:
            return jsonify({'message': 'Expense not found'}), 404
        
        db.session.delete(expense)
        db.session.commit()
        
        return jsonify({'message': 'Expense deleted successfully'}), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'message': f'Failed to delete expense: {str(e)}'}), 500


@expenses_bp.route('/expenses/<int:expense_id>/feedback', methods=['POST'])
@jwt_required()
def submit_expense_feedback(expense_id: int):
    """Store user feedback for expense categorization and optionally update category.

    This supports adaptive learning: corrections are stored and can be used for
    periodic model retraining while immediately improving the expense record.
    """
    try:
        user_id = get_jwt_identity()
        data = request.get_json() or {}

        expense = Expense.query.filter_by(id=expense_id, user_id=user_id).first()
        if not expense:
            return jsonify({'message': 'Expense not found'}), 404

        corrected_category = data.get('correct_category')
        if not corrected_category:
            return jsonify({'message': 'correct_category is required'}), 400

        confidence = data.get('confidence')

        feedback = CategorizationFeedback(
            user_id=user_id,
            expense_id=expense.id,
            original_category=expense.category,
            corrected_category=corrected_category,
            confidence=float(confidence) if confidence is not None else None,
        )

        # Immediately update the stored category to reflect user intent
        expense.category = corrected_category

        db.session.add(feedback)
        db.session.commit()

        return jsonify({'message': 'Feedback recorded successfully'}), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'message': f'Failed to record feedback: {str(e)}'}), 500

@expenses_bp.route('/predict', methods=['GET'])
@jwt_required()
def predict_spending():
    """Get AI prediction for next month's spending"""
    try:
        user_id = get_jwt_identity()
        
        from app.services.prediction_service import PredictionService
        prediction = PredictionService.predict_next_month_spending(user_id, db)
        
        return jsonify(prediction), 200
        
    except Exception as e:
        return jsonify({'message': f'Prediction failed: {str(e)}'}), 500

@expenses_bp.route('/alerts', methods=['GET'])
@jwt_required()
def get_alerts():
    """Get budget alerts for user"""
    try:
        user_id = get_jwt_identity()
        
        from app.services.prediction_service import PredictionService
        alerts = PredictionService.get_budget_alerts(user_id, db)
        
        return jsonify({'alerts': alerts}), 200
        
    except Exception as e:
        return jsonify({'message': f'Failed to fetch alerts: {str(e)}'}), 500
