from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from datetime import datetime

from app import db
from app.models import Income

incomes_bp = Blueprint('incomes', __name__)


@incomes_bp.route('/incomes', methods=['GET'])
@jwt_required()
def get_incomes():
    """Get all incomes for authenticated user, optional month/year filters."""
    try:
        user_id = get_jwt_identity()

        query = Income.query.filter_by(user_id=user_id)

        month = request.args.get('month', type=int)
        year = request.args.get('year', type=int)

        if year is not None:
            if month is not None:
                query = query.filter(
                    Income.date >= datetime(year, month, 1),
                    Income.date < datetime(year + (1 if month == 12 else 0), (month % 12) + 1, 1),
                )
            else:
                query = query.filter(
                    Income.date >= datetime(year, 1, 1),
                    Income.date < datetime(year + 1, 1, 1),
                )

        incomes = query.order_by(Income.date.desc()).all()
        return jsonify({'incomes': [i.to_dict() for i in incomes]}), 200
    except Exception as e:
        return jsonify({'message': f'Failed to fetch incomes: {str(e)}'}), 500


@incomes_bp.route('/incomes', methods=['POST'])
@jwt_required()
def create_income():
    """Create a new income entry."""
    try:
        user_id = get_jwt_identity()
        data = request.get_json() or {}

        required_fields = ['source', 'amount', 'date']
        if not all(field in data for field in required_fields):
            return jsonify({'message': 'Missing required fields: source, amount, date'}), 400

        # Type conversions with validation
        try:
            amount = float(data['amount'])
            if amount <= 0:
                return jsonify({'message': 'Amount must be positive'}), 400
        except (ValueError, TypeError):
            return jsonify({'message': 'Invalid amount format'}), 400
        
        # Parse date
        try:
            date_str = data['date'].split('T')[0] if 'T' in data['date'] else data['date']
            date_obj = datetime.fromisoformat(date_str)
        except (ValueError, AttributeError):
            return jsonify({'message': 'Invalid date format. Use YYYY-MM-DD'}), 400

        # Currency defaults to INR
        currency = str(data.get('currency', 'INR')).strip().upper()
        if len(currency) != 3:
            currency = 'INR'

        income = Income(
            user_id=user_id,
            source=str(data['source']).strip(),
            category=str(data.get('category', 'Other')).strip(),
            amount=amount,
            currency=currency,
            date=date_obj,
            is_recurring=bool(data.get('is_recurring', False)),
            notes=str(data.get('notes', '')).strip() if data.get('notes') else None,
        )

        db.session.add(income)
        db.session.commit()

        return jsonify(income.to_dict()), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'message': f'Failed to create income: {str(e)}'}), 500


@incomes_bp.route('/incomes/<int:income_id>', methods=['PUT'])
@jwt_required()
def update_income(income_id: int):
    """Update an income entry."""
    try:
        user_id = get_jwt_identity()
        data = request.get_json() or {}

        income = Income.query.filter_by(id=income_id, user_id=user_id).first()
        if not income:
            return jsonify({'message': 'Income not found'}), 404

        # Update fields if provided
        if 'source' in data:
            income.source = str(data['source']).strip()
        
        if 'amount' in data:
            try:
                amount = float(data['amount'])
                if amount <= 0:
                    return jsonify({'message': 'Amount must be positive'}), 400
                income.amount = amount
            except (ValueError, TypeError):
                return jsonify({'message': 'Invalid amount format'}), 400
        
        if 'currency' in data:
            currency = str(data['currency']).strip().upper()
            if len(currency) == 3:
                income.currency = currency
        
        if 'date' in data:
            try:
                date_str = data['date'].split('T')[0] if 'T' in data['date'] else data['date']
                income.date = datetime.fromisoformat(date_str)
            except (ValueError, AttributeError):
                return jsonify({'message': 'Invalid date format. Use YYYY-MM-DD'}), 400
        
        if 'category' in data:
            income.category = str(data['category']).strip()
        
        if 'is_recurring' in data:
            income.is_recurring = bool(data['is_recurring'])
        
        if 'notes' in data:
            income.notes = str(data['notes']).strip() if data['notes'] else None
        
        income.updated_at = datetime.utcnow()
        db.session.commit()

        return jsonify(income.to_dict()), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'message': f'Failed to update income: {str(e)}'}), 500


@incomes_bp.route('/incomes/<int:income_id>', methods=['DELETE'])
@jwt_required()
def delete_income(income_id: int):
    """Delete an income entry."""
    try:
        user_id = get_jwt_identity()

        income = Income.query.filter_by(id=income_id, user_id=user_id).first()
        if not income:
            return jsonify({'message': 'Income not found'}), 404

        db.session.delete(income)
        db.session.commit()

        return jsonify({'message': 'Income deleted successfully'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'message': f'Failed to delete income: {str(e)}'}), 500
