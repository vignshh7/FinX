from flask import Blueprint, request, jsonify
from app import db
from app.models import Budget, CategoryBudget
from flask_jwt_extended import jwt_required, get_jwt_identity

budget_bp = Blueprint('budget', __name__)


def _category_budget_to_budget_json(category_budget):
    return {
        'id': category_budget.id,
        'category': category_budget.category,
        'amount': category_budget.monthly_limit,
        'period': 'monthly',
        'created_at': category_budget.created_at.isoformat(),
        'updated_at': category_budget.updated_at.isoformat() if category_budget.updated_at else None,
        'is_active': True,
        'alert_threshold': 0.8,
        'notes': None,
        'tags': None,
    }

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


# Compatibility endpoints for the Flutter app
@budget_bp.route('/budgets', methods=['GET', 'OPTIONS'])
@jwt_required(optional=True)
def list_budgets():
    if request.method == 'OPTIONS':
        return jsonify({'message': 'ok'}), 200

    try:
        user_id = get_jwt_identity()
        if not user_id:
            return jsonify({'message': 'Missing or invalid token'}), 401
        rows = CategoryBudget.query.filter_by(user_id=user_id).all()
        budgets = [_category_budget_to_budget_json(row) for row in rows]
        return jsonify({'budgets': budgets}), 200
    except Exception as e:
        return jsonify({'message': f'Failed to load budgets: {str(e)}'}), 500


@budget_bp.route('/budgets', methods=['POST', 'OPTIONS'])
@jwt_required(optional=True)
def create_budget():
    if request.method == 'OPTIONS':
        return jsonify({'message': 'ok'}), 200

    try:
        user_id = get_jwt_identity()
        if not user_id:
            return jsonify({'success': False, 'message': 'Missing or invalid token'}), 401
        data = request.get_json() or {}
        category = data.get('category')
        amount = data.get('amount')

        if not category or amount is None:
            return jsonify({'success': False, 'message': 'category and amount are required'}), 400

        existing = CategoryBudget.query.filter_by(user_id=user_id, category=category).first()
        if existing:
            existing.monthly_limit = float(amount)
            db.session.commit()
            return jsonify({'success': True, 'budget': _category_budget_to_budget_json(existing)}), 200

        row = CategoryBudget(
            user_id=user_id,
            category=category,
            monthly_limit=float(amount),
        )
        db.session.add(row)
        db.session.commit()

        return jsonify({'success': True, 'budget': _category_budget_to_budget_json(row)}), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': f'Failed to create budget: {str(e)}'}), 500


@budget_bp.route('/budgets/<int:budget_id>', methods=['PUT', 'OPTIONS'])
@jwt_required(optional=True)
def update_budget_item(budget_id):
    if request.method == 'OPTIONS':
        return jsonify({'message': 'ok'}), 200

    try:
        user_id = get_jwt_identity()
        if not user_id:
            return jsonify({'success': False, 'message': 'Missing or invalid token'}), 401
        data = request.get_json() or {}
        amount = data.get('amount')

        row = CategoryBudget.query.filter_by(user_id=user_id, id=budget_id).first()
        if not row:
            return jsonify({'success': False, 'message': 'Budget not found'}), 404

        if amount is not None:
            row.monthly_limit = float(amount)

        db.session.commit()
        return jsonify({'success': True, 'budget': _category_budget_to_budget_json(row)}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': f'Failed to update budget: {str(e)}'}), 500


@budget_bp.route('/budgets/<int:budget_id>', methods=['DELETE', 'OPTIONS'])
@jwt_required(optional=True)
def delete_budget_item(budget_id):
    if request.method == 'OPTIONS':
        return jsonify({'message': 'ok'}), 200

    try:
        user_id = get_jwt_identity()
        if not user_id:
            return jsonify({'success': False, 'message': 'Missing or invalid token'}), 401
        row = CategoryBudget.query.filter_by(user_id=user_id, id=budget_id).first()
        if not row:
            return jsonify({'success': False, 'message': 'Budget not found'}), 404

        db.session.delete(row)
        db.session.commit()
        return jsonify({'success': True}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': f'Failed to delete budget: {str(e)}'}), 500
