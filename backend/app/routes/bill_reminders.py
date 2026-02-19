from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app import db
from app.models import BillReminder
from datetime import datetime

bill_reminders_bp = Blueprint('bill_reminders', __name__)


@bill_reminders_bp.route('/bill-reminders', methods=['GET'])
@jwt_required()
def get_bill_reminders():
    user_id = int(get_jwt_identity())
    reminders = BillReminder.query.filter_by(user_id=user_id).order_by(BillReminder.due_date.asc()).all()
    return jsonify([r.to_dict() for r in reminders]), 200


@bill_reminders_bp.route('/bill-reminders', methods=['POST'])
@jwt_required()
def create_bill_reminder():
    user_id = int(get_jwt_identity())
    data = request.get_json()

    if not data:
        return jsonify({'error': 'No data provided'}), 400

    required_fields = ['title', 'amount', 'due_date']
    for field in required_fields:
        if field not in data:
            return jsonify({'error': f'Missing required field: {field}'}), 400

    try:
        due_date = datetime.fromisoformat(data['due_date'].replace('Z', '+00:00'))
    except ValueError:
        try:
            due_date = datetime.strptime(data['due_date'], '%Y-%m-%d')
        except ValueError:
            return jsonify({'error': 'Invalid due_date format'}), 400

    reminder = BillReminder(
        user_id=user_id,
        title=data['title'],
        description=data.get('description'),
        amount=float(data['amount']),
        due_date=due_date,
        frequency=data.get('frequency', 'monthly'),
        category=data.get('category'),
        priority=data.get('priority', 'medium'),
        is_recurring=bool(data.get('is_recurring', False)),
        is_paid=bool(data.get('is_paid', False)),
        status=data.get('status', 'pending'),
        currency=data.get('currency', 'USD'),
    )

    db.session.add(reminder)
    db.session.commit()
    return jsonify(reminder.to_dict()), 201


@bill_reminders_bp.route('/bill-reminders/<int:reminder_id>', methods=['GET'])
@jwt_required()
def get_bill_reminder(reminder_id):
    user_id = int(get_jwt_identity())
    reminder = BillReminder.query.filter_by(id=reminder_id, user_id=user_id).first()
    if not reminder:
        return jsonify({'error': 'Bill reminder not found'}), 404
    return jsonify(reminder.to_dict()), 200


@bill_reminders_bp.route('/bill-reminders/<int:reminder_id>', methods=['PUT'])
@jwt_required()
def update_bill_reminder(reminder_id):
    user_id = int(get_jwt_identity())
    reminder = BillReminder.query.filter_by(id=reminder_id, user_id=user_id).first()
    if not reminder:
        return jsonify({'error': 'Bill reminder not found'}), 404

    data = request.get_json()
    if not data:
        return jsonify({'error': 'No data provided'}), 400

    if 'title' in data:
        reminder.title = data['title']
    if 'description' in data:
        reminder.description = data['description']
    if 'amount' in data:
        reminder.amount = float(data['amount'])
    if 'due_date' in data:
        try:
            reminder.due_date = datetime.fromisoformat(data['due_date'].replace('Z', '+00:00'))
        except ValueError:
            reminder.due_date = datetime.strptime(data['due_date'], '%Y-%m-%d')
    if 'frequency' in data:
        reminder.frequency = data['frequency']
    if 'category' in data:
        reminder.category = data['category']
    if 'priority' in data:
        reminder.priority = data['priority']
    if 'is_recurring' in data:
        reminder.is_recurring = bool(data['is_recurring'])
    if 'is_paid' in data:
        reminder.is_paid = bool(data['is_paid'])
    if 'status' in data:
        reminder.status = data['status']
    if 'currency' in data:
        reminder.currency = data['currency']

    reminder.updated_at = datetime.utcnow()
    db.session.commit()
    return jsonify(reminder.to_dict()), 200


@bill_reminders_bp.route('/bill-reminders/<int:reminder_id>', methods=['DELETE'])
@jwt_required()
def delete_bill_reminder(reminder_id):
    user_id = int(get_jwt_identity())
    reminder = BillReminder.query.filter_by(id=reminder_id, user_id=user_id).first()
    if not reminder:
        return jsonify({'error': 'Bill reminder not found'}), 404

    db.session.delete(reminder)
    db.session.commit()
    return jsonify({'message': 'Bill reminder deleted successfully'}), 200


@bill_reminders_bp.route('/bill-reminders/<int:reminder_id>/pay', methods=['PUT'])
@jwt_required()
def mark_bill_paid(reminder_id):
    """Mark a bill reminder as paid."""
    user_id = int(get_jwt_identity())
    reminder = BillReminder.query.filter_by(id=reminder_id, user_id=user_id).first()
    if not reminder:
        return jsonify({'error': 'Bill reminder not found'}), 404

    data = request.get_json(silent=True) or {}
    reminder.is_paid = True
    reminder.status = 'paid'
    reminder.paid_date = datetime.utcnow()
    reminder.payment_method = data.get('payment_method')
    reminder.updated_at = datetime.utcnow()
    db.session.commit()
    return jsonify(reminder.to_dict()), 200
