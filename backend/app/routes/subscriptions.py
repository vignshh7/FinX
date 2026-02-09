from flask import Blueprint, request, jsonify
from app import db
from app.models import Subscription
from flask_jwt_extended import jwt_required, get_jwt_identity
from datetime import datetime

subscriptions_bp = Blueprint('subscriptions', __name__)

@subscriptions_bp.route('/subscriptions', methods=['GET'])
@jwt_required()
def get_subscriptions():
    """Get all subscriptions for authenticated user"""
    try:
        user_id = get_jwt_identity()
        
        subscriptions = Subscription.query.filter_by(user_id=user_id).all()
        
        return jsonify({
            'subscriptions': [sub.to_dict() for sub in subscriptions]
        }), 200
        
    except Exception as e:
        return jsonify({'message': f'Failed to fetch subscriptions: {str(e)}'}), 500

@subscriptions_bp.route('/subscriptions', methods=['POST'])
@jwt_required()
def create_subscription():
    """Create a new subscription"""
    try:
        user_id = get_jwt_identity()
        data = request.get_json()
        
        # Validation
        required_fields = ['name', 'amount', 'frequency', 'renewal_date']
        if not all(k in data for k in required_fields):
            return jsonify({'message': 'Missing required fields'}), 400
        
        subscription = Subscription(
            user_id=user_id,
            name=data['name'],
            amount=float(data['amount']),
            frequency=data['frequency'],
            renewal_date=datetime.fromisoformat(data['renewal_date'].split('T')[0])
        )
        
        db.session.add(subscription)
        db.session.commit()
        
        return jsonify(subscription.to_dict()), 201
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'message': f'Failed to create subscription: {str(e)}'}), 500

@subscriptions_bp.route('/subscriptions/<int:subscription_id>', methods=['DELETE'])
@jwt_required()
def delete_subscription(subscription_id):
    """Delete a subscription"""
    try:
        user_id = get_jwt_identity()
        
        subscription = Subscription.query.filter_by(id=subscription_id, user_id=user_id).first()
        if not subscription:
            return jsonify({'message': 'Subscription not found'}), 404
        
        db.session.delete(subscription)
        db.session.commit()
        
        return jsonify({'message': 'Subscription deleted successfully'}), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'message': f'Failed to delete subscription: {str(e)}'}), 500
