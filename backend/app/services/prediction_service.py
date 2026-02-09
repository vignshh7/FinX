import numpy as np
from datetime import datetime, timedelta
from sqlalchemy import func
from app.models import Expense

class PredictionService:
    @staticmethod
    def predict_next_month_spending(user_id, db):
        """
        Predict next month's spending using historical data
        Simple moving average with trend analysis
        """
        # Get last 6 months of expenses
        six_months_ago = datetime.now() - timedelta(days=180)
        
        # Query monthly totals
        monthly_totals = db.session.query(
            func.strftime('%Y-%m', Expense.date).label('month'),
            func.sum(Expense.amount).label('total')
        ).filter(
            Expense.user_id == user_id,
            Expense.date >= six_months_ago
        ).group_by('month').all()
        
        if not monthly_totals:
            return {
                'predicted_amount': 0.0,
                'confidence': 0.0,
                'based_on_months': 0
            }
        
        # Extract amounts
        amounts = [total for _, total in monthly_totals]
        
        # Calculate simple moving average
        if len(amounts) >= 3:
            # Use weighted average (recent months have more weight)
            weights = np.array([1, 2, 3])[-len(amounts):]
            weights = weights / weights.sum()
            predicted_amount = np.average(amounts, weights=weights)
        else:
            predicted_amount = np.mean(amounts)
        
        # Calculate trend
        if len(amounts) >= 2:
            trend = (amounts[-1] - amounts[0]) / len(amounts)
            predicted_amount += trend
        
        # Confidence based on data availability
        confidence = min(len(amounts) / 6.0, 1.0)
        
        return {
            'predicted_amount': round(float(predicted_amount), 2),
            'confidence': round(confidence, 2),
            'based_on_months': len(amounts),
            'historical_average': round(np.mean(amounts), 2)
        }
    
    @staticmethod
    def get_budget_alerts(user_id, db):
        """
        Generate budget alerts based on current spending
        """
        from app.models import Budget
        
        alerts = []
        
        # Get user's budget
        budget = Budget.query.filter_by(user_id=user_id).first()
        if not budget:
            return alerts
        
        # Get current month's spending
        now = datetime.now()
        month_start = datetime(now.year, now.month, 1)
        
        current_spending = db.session.query(
            func.sum(Expense.amount)
        ).filter(
            Expense.user_id == user_id,
            Expense.date >= month_start
        ).scalar() or 0.0
        
        # Calculate percentage
        percentage = (current_spending / budget.monthly_limit) * 100 if budget.monthly_limit > 0 else 0
        
        # Generate alerts
        if percentage >= 100:
            alerts.append({
                'type': 'danger',
                'message': f'Budget exceeded! You have spent {budget.currency} {current_spending:.2f} of {budget.currency} {budget.monthly_limit:.2f}',
                'percentage': round(percentage, 1)
            })
        elif percentage >= 80:
            alerts.append({
                'type': 'warning',
                'message': f'Almost at budget limit! {percentage:.1f}% spent',
                'percentage': round(percentage, 1)
            })
        elif percentage >= 50:
            alerts.append({
                'type': 'info',
                'message': f'Halfway through budget: {percentage:.1f}% spent',
                'percentage': round(percentage, 1)
            })
        
        return alerts
