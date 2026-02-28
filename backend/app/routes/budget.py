from flask import Blueprint, request, jsonify
from app import db
from app.models import Budget, CategoryBudget
from flask_jwt_extended import jwt_required, get_jwt_identity

budget_bp = Blueprint('budget', __name__)

@budget_bp.route('/budget', methods=['GET'])
@jwt_required()
def get_budget():
    """Get budget for authenticated user"""
    try:
        user_id = get_jwt_identity()
        
        budget = Budget.query.filter_by(user_id=user_id).first()
        
        if not budget:
            return jsonify({'message': 'Budget not set'}), 404
        
        return jsonify(budget.to_dict()), 200
        
    except Exception as e:
        return jsonify({'message': f'Failed to fetch budget: {str(e)}'}), 500

@budget_bp.route('/budget', methods=['PUT'])
@jwt_required()
def update_budget():
    """Create or update budget"""
    try:
        user_id = get_jwt_identity()
        data = request.get_json()
        
        if 'monthly_limit' not in data:
            return jsonify({'message': 'Missing monthly_limit'}), 400
        
        budget = Budget.query.filter_by(user_id=user_id).first()
        
        if budget:
            # Update existing budget
            budget.monthly_limit = float(data['monthly_limit'])
            budget.currency = data.get('currency', 'USD')
        else:
            # Create new budget
            budget = Budget(
                user_id=user_id,
                monthly_limit=float(data['monthly_limit']),
                currency=data.get('currency', 'USD')
            )
            db.session.add(budget)
        
        db.session.commit()
        
        return jsonify(budget.to_dict()), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'message': f'Failed to update budget: {str(e)}'}), 500


@budget_bp.route('/budget/categories', methods=['GET'])
@jwt_required()
def get_category_budgets():
    """Get per-category budgets for the authenticated user."""
    try:
        user_id = get_jwt_identity()

        rows = CategoryBudget.query.filter_by(user_id=user_id).all()
        return jsonify({'category_budgets': [cb.to_dict() for cb in rows]}), 200
    except Exception as e:
        return jsonify({'message': f'Failed to fetch category budgets: {str(e)}'}), 500


@budget_bp.route('/budget/categories', methods=['PUT'])
@jwt_required()
def upsert_category_budgets():
    """Create or update per-category budgets.

    Expects a JSON body with a list under `category_budgets`, where each
    entry has `category` and `monthly_limit`.
    """
    try:
        user_id = get_jwt_identity()
        data = request.get_json() or {}
        items = data.get('category_budgets') or []

        if not isinstance(items, list) or not items:
            return jsonify({'message': 'category_budgets must be a non-empty list'}), 400

        # Upsert each category budget
        for item in items:
            category = item.get('category')
            limit = item.get('monthly_limit')
            if not category or limit is None:
                continue

            row = CategoryBudget.query.filter_by(user_id=user_id, category=category).first()
            if row:
                row.monthly_limit = float(limit)
            else:
                row = CategoryBudget(
                    user_id=user_id,
                    category=category,
                    monthly_limit=float(limit),
                )
                db.session.add(row)

        db.session.commit()

        rows = CategoryBudget.query.filter_by(user_id=user_id).all()
        return jsonify({'category_budgets': [cb.to_dict() for cb in rows]}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'message': f'Failed to update category budgets: {str(e)}'}), 500
