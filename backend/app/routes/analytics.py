from datetime import datetime, timedelta

from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from sqlalchemy import func

from app import db
from app.models import Expense, Income, Budget, CategoryBudget
from app.services.prediction_service import PredictionService

analytics_bp = Blueprint('analytics', __name__)


def _month_range(year: int, month: int):
    start = datetime(year, month, 1)
    if month == 12:
        end = datetime(year + 1, 1, 1)
    else:
        end = datetime(year, month + 1, 1)
    return start, end


@analytics_bp.route('/dashboard', methods=['GET'])
@jwt_required()
def get_dashboard():
    """Return aggregated dashboard metrics for the given month.

    Includes totals, savings estimate, category breakdown, and
    6-month expense trend. All values are computed on-demand to keep
    the endpoint stateless and explainable.
    """
    try:
        user_id = get_jwt_identity()
        now = datetime.now()
        month = request.args.get('month', type=int) or now.month
        year = request.args.get('year', type=int) or now.year

        month_start, month_end = _month_range(year, month)

        # Totals for current month
        total_expenses = (
            db.session.query(func.coalesce(func.sum(Expense.amount), 0.0))
            .filter(
                Expense.user_id == user_id,
                Expense.date >= month_start,
                Expense.date < month_end,
            )
            .scalar()
        )

        total_income = (
            db.session.query(func.coalesce(func.sum(Income.amount), 0.0))
            .filter(
                Income.user_id == user_id,
                Income.date >= month_start,
                Income.date < month_end,
            )
            .scalar()
        )

        savings_estimate = total_income - total_expenses

        # Category breakdown (expenses)
        category_rows = (
            db.session.query(Expense.category, func.sum(Expense.amount))
            .filter(
                Expense.user_id == user_id,
                Expense.date >= month_start,
                Expense.date < month_end,
            )
            .group_by(Expense.category)
            .all()
        )
        category_spend = [
            {"category": c, "amount": float(a)} for c, a in category_rows
        ]

        # 6-month trend
        six_months_ago = month_start - timedelta(days=180)
        trend_rows = (
            db.session.query(
                func.strftime('%Y-%m', Expense.date).label('month'),
                func.sum(Expense.amount).label('total'),
            )
            .filter(Expense.user_id == user_id, Expense.date >= six_months_ago)
            .group_by('month')
            .order_by('month')
            .all()
        )
        trend = [
            {"month": m, "total": float(t) if t is not None else 0.0}
            for m, t in trend_rows
        ]

        # Budget + per-category budgets
        budget = Budget.query.filter_by(user_id=user_id).first()
        category_budget_rows = CategoryBudget.query.filter_by(user_id=user_id).all()

        budget_info = None
        if budget:
            used_pct = (
                (total_expenses / budget.monthly_limit) * 100.0
                if budget.monthly_limit > 0
                else 0.0
            )
            budget_info = {
                "monthly_limit": budget.monthly_limit,
                "currency": budget.currency,
                "used_percentage": round(used_pct, 1),
            }

        per_category_budgets = [
            {
                "category": cb.category,
                "monthly_limit": cb.monthly_limit,
            }
            for cb in category_budget_rows
        ]

        return (
            jsonify(
                {
                    "period": {"month": month, "year": year},
                    "totals": {
                        "income": float(total_income),
                        "expenses": float(total_expenses),
                        "savings_estimate": float(savings_estimate),
                    },
                    "category_spend": category_spend,
                    "trend_6m": trend,
                    "budget": budget_info,
                    "category_budgets": per_category_budgets,
                    "explanation": {
                        "text": "Dashboard metrics are based on your recorded incomes and expenses for the selected month and the last 6 months of history.",
                    },
                }
            ),
            200,
        )
    except Exception as e:
        return jsonify({"message": f"Failed to load dashboard: {str(e)}"}), 500


@analytics_bp.route('/ai-insights', methods=['GET'])
@jwt_required()
def get_ai_insights():
    """Return explainable AI-style financial insights for the user.

    Combines spending pattern analysis, forecast, budget recommendations,
    and simple anomaly detection into a single response that the client
    can render as a premium insights experience.
    """
    try:
        user_id = get_jwt_identity()
        now = datetime.now()
        month = request.args.get('month', type=int) or now.month
        year = request.args.get('year', type=int) or now.year

        # Current and previous month windows
        current_start, current_end = _month_range(year, month)
        last_month_dt = current_start - timedelta(days=1)
        last_start, last_end = _month_range(last_month_dt.year, last_month_dt.month)

        # Load expenses
        current_expenses = (
            Expense.query.filter(
                Expense.user_id == user_id,
                Expense.date >= current_start,
                Expense.date < current_end,
            )
            .order_by(Expense.date.desc())
            .all()
        )
        last_expenses = (
            Expense.query.filter(
                Expense.user_id == user_id,
                Expense.date >= last_start,
                Expense.date < last_end,
            )
            .order_by(Expense.date.desc())
            .all()
        )

        current_total = sum(e.amount for e in current_expenses)
        last_total = sum(e.amount for e in last_expenses)

        change_pct = (
            ((current_total - last_total) / last_total) * 100.0
            if last_total > 0
            else 0.0
        )

        # Category totals for current month
        category_totals = {}
        for e in current_expenses:
            category_totals[e.category] = category_totals.get(e.category, 0.0) + e.amount

        # Top category
        top_category = None
        if category_totals:
            top_category = max(category_totals.items(), key=lambda kv: kv[1])[0]

        # Forecast (reuse existing prediction service)
        forecast = PredictionService.predict_next_month_spending(user_id, db)
        forecast_explanation = (
            "Prediction is based on your last "
            f"{forecast.get('based_on_months', 0)} month(s) of expenses with recent months weighted more."
        )

        # Split forecast by category proportionally to recent distribution
        category_forecast = []
        if current_total > 0 and forecast.get('predicted_amount', 0) > 0:
            for cat, amt in category_totals.items():
                share = amt / current_total
                category_forecast.append(
                    {
                        "category": cat,
                        "predicted_amount": round(
                            forecast['predicted_amount'] * share, 2
                        ),
                        "share": round(share * 100.0, 1),
                    }
                )

        # Simple anomaly detection: unusually large single expenses
        anomalies = []
        if current_expenses:
            values = [e.amount for e in current_expenses]
            avg = sum(values) / len(values)
            threshold = avg * 2.5 if avg > 0 else 0
            for e in current_expenses:
                if threshold and e.amount >= threshold:
                    anomalies.append(
                        {
                            "expense_id": e.id,
                            "store": e.store,
                            "amount": float(e.amount),
                            "date": e.date.isoformat(),
                            "category": e.category,
                            "severity": "warning",
                            "message": "Unusually high expense compared to your other transactions this month.",
                            "explanation": "Flagged because this amount is significantly higher than your average expense value this month.",
                        }
                    )

        # Budget-aware recommendations
        budget = Budget.query.filter_by(user_id=user_id).first()
        recommendations = []

        if change_pct > 10:
            recommendations.append(
                {
                    "suggestion": "Review and tighten budgets in your top spending categories.",
                    "reason": f"You spent {change_pct:.1f}% more than last month.",
                }
            )
        elif change_pct < -10:
            recommendations.append(
                {
                    "suggestion": "Consider increasing your savings target this month.",
                    "reason": f"You spent {abs(change_pct):.1f}% less than last month.",
                }
            )

        if budget and current_total >= 0.8 * budget.monthly_limit:
            recommendations.append(
                {
                    "suggestion": "Reduce discretionary categories (like Shopping or Entertainment) for the rest of the month.",
                    "reason": "You have already used more than 80% of your monthly budget.",
                }
            )

        summary_text = (
            "Your spending is consistent with last month."
        )
        if change_pct > 10:
            summary_text = (
                f"You spent {change_pct:.1f}% more this month compared to last month. "
                "Consider reviewing categories with the biggest increases."
            )
        elif change_pct < -10:
            summary_text = (
                f"Great job! You spent {abs(change_pct):.1f}% less this month compared to last month."
            )

        return (
            jsonify(
                {
                    "period": {"month": month, "year": year},
                    "spending_pattern": {
                        "current_total": float(current_total),
                        "last_total": float(last_total),
                        "change_percentage": round(change_pct, 2),
                        "trend": "increasing"
                        if change_pct > 0
                        else "decreasing"
                        if change_pct < 0
                        else "stable",
                        "top_category": top_category,
                        "explanation": "Spending pattern analysis compares this month to the previous month and highlights categories where you spend the most.",
                    },
                    "forecast": {
                        **forecast,
                        "by_category": category_forecast,
                        "explanation": forecast_explanation,
                    },
                    "budget_recommendations": recommendations,
                    "anomalies": anomalies,
                    "explainability": {
                        "what": summary_text,
                        "why": "Insights are generated from your last two months of expenses and your configured budget.",
                        "next_steps": "Use these insights to adjust category budgets, reduce high-risk expenses, and increase savings when your spending decreases.",
                    },
                }
            ),
            200,
        )
    except Exception as e:
        return jsonify({"message": f"Failed to generate AI insights: {str(e)}"}), 500
