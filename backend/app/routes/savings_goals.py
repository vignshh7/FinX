from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app import db
from app.models import SavingsGoal, SavingsContribution
from datetime import datetime

savings_goals_bp = Blueprint('savings_goals', __name__)


def _parse_iso_date(value):
    if not value:
        return None

    if isinstance(value, (int, float)):
        return datetime.fromtimestamp(value)

    try:
        return datetime.fromisoformat(str(value).replace('Z', '+00:00'))
    except ValueError:
        try:
            return datetime.strptime(str(value), '%Y-%m-%d')
        except ValueError:
            return None


def _build_monthly_report(user_id, year, month):
    start = datetime(year, month, 1)
    if month == 12:
        end = datetime(year + 1, 1, 1)
    else:
        end = datetime(year, month + 1, 1)

    goals = SavingsGoal.query.filter_by(user_id=user_id).all()
    contributions = SavingsContribution.query.filter(
        SavingsContribution.user_id == user_id,
        SavingsContribution.date >= start,
        SavingsContribution.date < end,
    ).all()

    contributed_by_goal = {}
    total_contributed = 0.0
    for item in contributions:
        contributed_by_goal[item.goal_id] = contributed_by_goal.get(item.goal_id, 0.0) + item.amount
        total_contributed += item.amount

    goals_summary = []
    total_remaining = 0.0
    for goal in goals:
        remaining = max(goal.target_amount - (goal.current_amount or 0.0), 0.0)
        total_remaining += remaining
        goals_summary.append({
            'goal_id': goal.id,
            'title': goal.title,
            'contributed': contributed_by_goal.get(goal.id, 0.0),
            'remaining': remaining,
            'target_amount': goal.target_amount,
            'current_amount': goal.current_amount or 0.0,
            'is_completed': bool(goal.is_completed),
        })

    return {
        'year': year,
        'month': month,
        'total_contributed': total_contributed,
        'total_remaining': total_remaining,
        'goals': goals_summary,
    }


@savings_goals_bp.route('/savings-goals', methods=['GET', 'OPTIONS'])
@jwt_required(optional=True)
def get_savings_goals():
    if request.method == 'OPTIONS':
        return jsonify({'message': 'ok'}), 200

    user_id = get_jwt_identity()
    if not user_id:
        return jsonify({'message': 'Missing or invalid token'}), 401

    user_id = int(user_id)
    goals = SavingsGoal.query.filter_by(user_id=user_id).order_by(SavingsGoal.created_at.desc()).all()
    return jsonify({'goals': [g.to_dict() for g in goals]}), 200


@savings_goals_bp.route('/savings-goals', methods=['POST', 'OPTIONS'])
@jwt_required(optional=True)
def create_savings_goal():
    if request.method == 'OPTIONS':
        return jsonify({'message': 'ok'}), 200

    user_id = get_jwt_identity()
    if not user_id:
        return jsonify({'success': False, 'message': 'Missing or invalid token'}), 401

    user_id = int(user_id)
    data = request.get_json()

    if not data:
        return jsonify({'success': False, 'message': 'No data provided'}), 400

    required_fields = ['title', 'target_amount']
    for field in required_fields:
        if field not in data:
            return jsonify({'success': False, 'message': f'Missing required field: {field}'}), 400

    target_date = None
    if data.get('target_date'):
        try:
            target_date = datetime.fromisoformat(data['target_date'].replace('Z', '+00:00'))
        except ValueError:
            try:
                target_date = datetime.strptime(data['target_date'], '%Y-%m-%d')
            except ValueError:
                return jsonify({'success': False, 'message': 'Invalid target_date format'}), 400

    goal = SavingsGoal(
        user_id=user_id,
        title=data['title'],
        description=data.get('description'),
        target_amount=float(data['target_amount']),
        current_amount=float(data.get('current_amount', 0.0)),
        target_date=target_date,
        category=data.get('category'),
        priority=data.get('priority', 'medium'),
        is_completed=bool(data.get('is_completed', False)),
        currency=data.get('currency', 'USD'),
    )

    db.session.add(goal)
    db.session.commit()
    return jsonify({'success': True, 'goal': goal.to_dict()}), 201


@savings_goals_bp.route('/savings-goals/<int:goal_id>', methods=['GET', 'OPTIONS'])
@jwt_required(optional=True)
def get_savings_goal(goal_id):
    if request.method == 'OPTIONS':
        return jsonify({'message': 'ok'}), 200

    user_id = get_jwt_identity()
    if not user_id:
        return jsonify({'success': False, 'message': 'Missing or invalid token'}), 401

    user_id = int(user_id)
    goal = SavingsGoal.query.filter_by(id=goal_id, user_id=user_id).first()
    if not goal:
        return jsonify({'success': False, 'message': 'Savings goal not found'}), 404
    return jsonify({'success': True, 'goal': goal.to_dict()}), 200


@savings_goals_bp.route('/savings-goals/<int:goal_id>', methods=['PUT', 'OPTIONS'])
@jwt_required(optional=True)
def update_savings_goal(goal_id):
    if request.method == 'OPTIONS':
        return jsonify({'message': 'ok'}), 200

    user_id = get_jwt_identity()
    if not user_id:
        return jsonify({'success': False, 'message': 'Missing or invalid token'}), 401

    user_id = int(user_id)
    goal = SavingsGoal.query.filter_by(id=goal_id, user_id=user_id).first()
    if not goal:
        return jsonify({'success': False, 'message': 'Savings goal not found'}), 404

    data = request.get_json()
    if not data:
        return jsonify({'success': False, 'message': 'No data provided'}), 400

    if 'title' in data:
        goal.title = data['title']
    if 'description' in data:
        goal.description = data['description']
    if 'target_amount' in data:
        goal.target_amount = float(data['target_amount'])
    if 'current_amount' in data:
        goal.current_amount = float(data['current_amount'])
    if 'target_date' in data:
        if data['target_date']:
            try:
                goal.target_date = datetime.fromisoformat(data['target_date'].replace('Z', '+00:00'))
            except ValueError:
                goal.target_date = datetime.strptime(data['target_date'], '%Y-%m-%d')
        else:
            goal.target_date = None
    if 'category' in data:
        goal.category = data['category']
    if 'priority' in data:
        goal.priority = data['priority']
    if 'is_completed' in data:
        goal.is_completed = bool(data['is_completed'])
    if 'currency' in data:
        goal.currency = data['currency']

    goal.updated_at = datetime.utcnow()
    db.session.commit()
    return jsonify({'success': True, 'goal': goal.to_dict()}), 200


@savings_goals_bp.route('/savings-goals/<int:goal_id>', methods=['DELETE', 'OPTIONS'])
@jwt_required(optional=True)
def delete_savings_goal(goal_id):
    if request.method == 'OPTIONS':
        return jsonify({'message': 'ok'}), 200

    user_id = get_jwt_identity()
    if not user_id:
        return jsonify({'success': False, 'message': 'Missing or invalid token'}), 401

    user_id = int(user_id)
    goal = SavingsGoal.query.filter_by(id=goal_id, user_id=user_id).first()
    if not goal:
        return jsonify({'success': False, 'message': 'Savings goal not found'}), 404

    db.session.delete(goal)
    db.session.commit()
    return jsonify({'success': True, 'message': 'Savings goal deleted successfully'}), 200


@savings_goals_bp.route('/savings-goals/<int:goal_id>/contribute', methods=['POST', 'OPTIONS'])
@jwt_required(optional=True)
def contribute_to_goal(goal_id):
    """Add a contribution amount to the current_amount of a savings goal."""
    if request.method == 'OPTIONS':
        return jsonify({'message': 'ok'}), 200

    user_id = get_jwt_identity()
    if not user_id:
        return jsonify({'success': False, 'message': 'Missing or invalid token'}), 401

    user_id = int(user_id)
    goal = SavingsGoal.query.filter_by(id=goal_id, user_id=user_id).first()
    if not goal:
        return jsonify({'success': False, 'message': 'Savings goal not found'}), 404

    data = request.get_json() or {}
    amount = data.get('amount', 0)
    if amount <= 0:
        return jsonify({'success': False, 'message': 'Amount must be positive'}), 400

    contribution_date = _parse_iso_date(data.get('date')) or datetime.utcnow()
    note = data.get('note')
    contribution_type = data.get('type', 'manual')

    contribution = SavingsContribution(
        user_id=user_id,
        goal_id=goal.id,
        amount=float(amount),
        date=contribution_date,
        note=note,
        type=contribution_type,
    )
    db.session.add(contribution)

    goal.current_amount = (goal.current_amount or 0.0) + float(amount)
    if goal.current_amount >= goal.target_amount:
        goal.is_completed = True
    goal.updated_at = datetime.utcnow()
    db.session.commit()
    monthly_report = _build_monthly_report(user_id, contribution_date.year, contribution_date.month)
    return jsonify({
        'success': True,
        'goal': goal.to_dict(),
        'contribution': contribution.to_dict(),
        'monthly_report': monthly_report,
    }), 200


@savings_goals_bp.route('/savings-contributions', methods=['POST', 'OPTIONS'])
@jwt_required(optional=True)
def add_savings_contribution():
    if request.method == 'OPTIONS':
        return jsonify({'message': 'ok'}), 200

    user_id = get_jwt_identity()
    if not user_id:
        return jsonify({'success': False, 'message': 'Missing or invalid token'}), 401

    user_id = int(user_id)
    data = request.get_json() or {}
    goal_id = data.get('goal_id')
    amount = data.get('amount', 0)

    if not goal_id or amount <= 0:
        return jsonify({'success': False, 'message': 'goal_id and positive amount are required'}), 400

    goal = SavingsGoal.query.filter_by(id=goal_id, user_id=user_id).first()
    if not goal:
        return jsonify({'success': False, 'message': 'Savings goal not found'}), 404

    contribution_date = _parse_iso_date(data.get('date')) or datetime.utcnow()
    note = data.get('note')
    contribution_type = data.get('type', 'manual')

    contribution = SavingsContribution(
        user_id=user_id,
        goal_id=goal.id,
        amount=float(amount),
        date=contribution_date,
        note=note,
        type=contribution_type,
    )
    db.session.add(contribution)

    goal.current_amount = (goal.current_amount or 0.0) + float(amount)
    if goal.current_amount >= goal.target_amount:
        goal.is_completed = True
    goal.updated_at = datetime.utcnow()

    db.session.commit()

    monthly_report = _build_monthly_report(user_id, contribution_date.year, contribution_date.month)
    return jsonify({
        'success': True,
        'goal': goal.to_dict(),
        'contribution': contribution.to_dict(),
        'monthly_report': monthly_report,
    }), 200


@savings_goals_bp.route('/savings-reports/monthly', methods=['GET', 'OPTIONS'])
@jwt_required(optional=True)
def get_monthly_savings_report():
    if request.method == 'OPTIONS':
        return jsonify({'message': 'ok'}), 200

    user_id = get_jwt_identity()
    if not user_id:
        return jsonify({'success': False, 'message': 'Missing or invalid token'}), 401

    user_id = int(user_id)
    now = datetime.utcnow()
    year = int(request.args.get('year', now.year))
    month = int(request.args.get('month', now.month))

    report = _build_monthly_report(user_id, year, month)
    return jsonify({'success': True, 'report': report}), 200
