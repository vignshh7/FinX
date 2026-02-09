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

        required_fields = ['source', 'amount', 'date', 'category']
        if not all(field in data for field in required_fields):
            return jsonify({'message': 'Missing required fields'}), 400

        income = Income(
            user_id=user_id,
            source=data['source'],
            category=data.get('category', 'Other'),
            amount=float(data['amount']),
            date=datetime.fromisoformat(data['date'].split('T')[0]),
            is_recurring=bool(data.get('is_recurring', False)),
            notes=data.get('notes'),
        )

        db.session.add(income)
        db.session.commit()

        return jsonify(income.to_dict()), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'message': f'Failed to create income: {str(e)}'}), 500


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
