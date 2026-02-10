"""
Comprehensive AI Service for FinX
Implements all 6 AI modules as per specification:
1. Expense Categorization (Rule-based + ML)
2. Spending Aggregation (Monthly totals)
3. Spending Prediction (Linear Regression)
4. Anomaly Detection (Statistical)
5. Financial Advisor (Rule-based with ML outputs)
6. AI Insight Generation (Text summarization)
"""

import numpy as np
import pandas as pd
from datetime import datetime, timedelta
from sqlalchemy import func, extract
from sklearn.linear_model import Ridge
from sklearn.ensemble import IsolationForest
import joblib
import os


class ComprehensiveAIService:
    
    def __init__(self, db):
        self.db = db
        
        # Category keywords for rule-based classification
        self.category_keywords = {
            'Food': ['restaurant', 'cafe', 'food', 'grocery', 'lunch', 'dinner', 'breakfast', 
                    'pizza', 'burger', 'mcdonalds', 'kfc', 'starbucks', 'subway', 'dominos',
                    'supermarket', 'walmart', 'kroger', 'whole foods', 'trader joe'],
            'Travel': ['uber', 'lyft', 'taxi', 'gas', 'fuel', 'airline', 'flight', 'hotel',
                      'parking', 'toll', 'car', 'transport', 'shell', 'chevron', 'exxon'],
            'Shopping': ['amazon', 'ebay', 'shopping', 'mall', 'store', 'clothing', 'fashion',
                        'target', 'bestbuy', 'nike', 'adidas', 'walmart', 'electronics'],
            'Bills': ['electricity', 'water', 'internet', 'phone', 'insurance', 'utility',
                     'bill', 'payment', 'verizon', 'att', 'tmobile', 'comcast'],
            'Entertainment': ['netflix', 'spotify', 'movie', 'cinema', 'game', 'gym',
                            'fitness', 'concert', 'theater', 'xbox', 'playstation', 'steam'],
            'Healthcare': ['pharmacy', 'hospital', 'doctor', 'clinic', 'medical', 'cvs', 
                          'walgreens', 'health', 'medicine', 'dental'],
        }
    
    # =====================================================================
    # MODULE 1: EXPENSE CATEGORIZATION (Rule-based + ML)
    # =====================================================================
    
    def categorize_expense(self, store_name, items=None, description=None):
        """
        Categorize expense using rule-based keywords first, then ML fallback
        Returns: (category, confidence, method)
        """
        # Combine text for matching
        text = store_name.lower()
        if items:
            text += ' ' + ' '.join(items).lower() if isinstance(items, list) else ' ' + items.lower()
        if description:
            text += ' ' + description.lower()
        
        # STEP 1: Rule-based keyword matching
        for category, keywords in self.category_keywords.items():
            for keyword in keywords:
                if keyword in text:
                    return category, 0.95, 'rule-based'
        
        # STEP 2: ML Classifier fallback
        try:
            from app.services.ml_service import ExpenseCategorizer
            categorizer = ExpenseCategorizer()
            result = categorizer.categorize_expense(store_name, items)
            return result['predicted_category'], result['confidence'], 'ml-classifier'
        except Exception as e:
            print(f"ML categorization failed: {e}")
            return 'Other', 0.5, 'default'
    
    # =====================================================================
    # MODULE 2: SPENDING AGGREGATION
    # =====================================================================
    
    def get_spending_aggregation(self, user_id, months=6):
        """
        Aggregate expenses by month and category
        Returns structured data for prediction and analysis
        """
        from app.models import Expense
        
        # Calculate date range
        end_date = datetime.now()
        start_date = end_date - timedelta(days=months * 30)
        
        # Get expenses
        expenses = Expense.query.filter(
            Expense.user_id == user_id,
            Expense.date >= start_date,
            Expense.date <= end_date
        ).all()
        
        if not expenses:
            return {
                'monthly_totals': [],
                'category_totals': {},
                'overall_total': 0.0,
                'months_analyzed': 0
            }
        
        # Convert to DataFrame for easy aggregation
        df = pd.DataFrame([{
            'date': e.date,
            'amount': e.amount,
            'category': e.category,
            'month': e.date.strftime('%Y-%m')
        } for e in expenses])
        
        # Monthly aggregation
        monthly = df.groupby('month')['amount'].sum().to_dict()
        
        # Category-wise aggregation
        category = df.groupby('category')['amount'].sum().to_dict()
        
        # Overall statistics
        overall_total = df['amount'].sum()
        
        return {
            'monthly_totals': monthly,
            'category_totals': category,
            'overall_total': float(overall_total),
            'months_analyzed': len(monthly),
            'average_monthly': float(overall_total / len(monthly)) if monthly else 0.0
        }
    
    # =====================================================================
    # MODULE 3: SPENDING PREDICTION (Linear/Ridge Regression)
    # =====================================================================
    
    def predict_next_month_spending(self, user_id):
        """
        Predict next month spending using Ridge Regression
        Input: Historical monthly spending
        Output: Predicted amount + confidence range
        """
        # Get aggregated data
        aggregation = self.get_spending_aggregation(user_id, months=12)
        monthly_totals = aggregation['monthly_totals']
        
        if len(monthly_totals) < 3:
            return {
                'predicted_amount': 0.0,
                'confidence': 'low',
                'confidence_range': (0.0, 0.0),
                'based_on_months': len(monthly_totals),
                'message': 'Not enough data for prediction'
            }
        
        # Prepare data for regression
        months_list = sorted(monthly_totals.keys())
        X = np.array(range(len(months_list))).reshape(-1, 1)
        y = np.array([monthly_totals[m] for m in months_list])
        
        # Use Ridge Regression (handles small datasets well)
        model = Ridge(alpha=1.0)
        model.fit(X, y)
        
        # Predict next month
        next_month_index = len(months_list)
        predicted = model.predict([[next_month_index]])[0]
        
        # Calculate confidence range using standard deviation
        residuals = y - model.predict(X)
        std_error = np.std(residuals)
        
        confidence_range = (
            max(0, predicted - std_error),
            predicted + std_error
        )
        
        # Confidence level based on data availability
        confidence = 'high' if len(monthly_totals) >= 6 else 'medium'
        
        return {
            'predicted_amount': round(float(predicted), 2),
            'confidence': confidence,
            'confidence_range': (round(confidence_range[0], 2), round(confidence_range[1], 2)),
            'based_on_months': len(monthly_totals),
            'historical_average': round(np.mean(y), 2),
            'trend': 'increasing' if predicted > np.mean(y) else 'decreasing'
        }
    
    # =====================================================================
    # MODULE 4: ANOMALY/OVERSPENDING DETECTION
    # =====================================================================
    
    def detect_anomalies(self, user_id):
        """
        Detect unusual spending using statistical threshold
        Method: Mean + 2 × Standard Deviation
        Returns: List of anomalous expenses
        """
        from app.models import Expense
        
        # Get last 3 months of expenses
        three_months_ago = datetime.now() - timedelta(days=90)
        expenses = Expense.query.filter(
            Expense.user_id == user_id,
            Expense.date >= three_months_ago
        ).all()
        
        if len(expenses) < 10:
            return {
                'anomalies': [],
                'threshold': 0.0,
                'message': 'Not enough data for anomaly detection'
            }
        
        # Calculate statistics
        amounts = [e.amount for e in expenses]
        mean = np.mean(amounts)
        std = np.std(amounts)
        
        # Threshold: Mean + 2 * Std Dev
        threshold = mean + (2 * std)
        
        # Find anomalies
        anomalies = []
        for expense in expenses:
            if expense.amount > threshold:
                anomalies.append({
                    'id': expense.id,
                    'store': expense.store,
                    'amount': expense.amount,
                    'category': expense.category,
                    'date': expense.date.isoformat(),
                    'deviation': round(((expense.amount - mean) / std), 2),
                    'message': f'Unusually high expense: {expense.amount:.2f} (avg: {mean:.2f})'
                })
        
        return {
            'anomalies': anomalies,
            'threshold': round(threshold, 2),
            'mean': round(mean, 2),
            'std_dev': round(std, 2),
            'total_analyzed': len(expenses)
        }
    
    # =====================================================================
    # MODULE 5: FINANCIAL ADVISOR (Rule-based using ML outputs)
    # =====================================================================
    
    def get_financial_advice(self, user_id):
        """
        Generate explainable financial advice using rule-based logic
        Uses outputs from prediction, anomaly detection, and aggregation
        """
        from app.models import Budget, Income
        
        # Get all necessary data
        prediction = self.predict_next_month_spending(user_id)
        aggregation = self.get_spending_aggregation(user_id, months=3)
        anomalies = self.detect_anomalies(user_id)
        
        # Get budget and income
        budget = Budget.query.filter_by(user_id=user_id).first()
        
        # Get current month income
        month_start = datetime(datetime.now().year, datetime.now().month, 1)
        monthly_income = self.db.session.query(func.sum(Income.amount)).filter(
            Income.user_id == user_id,
            Income.date >= month_start
        ).scalar() or 0.0
        
        advice = []
        
        # RULE 1: Predicted spend > Income
        if monthly_income > 0 and prediction['predicted_amount'] > monthly_income:
            advice.append({
                'type': 'warning',
                'category': 'budget',
                'title': 'Spending May Exceed Income',
                'message': f"Based on your spending pattern, you're predicted to spend "
                          f"${prediction['predicted_amount']:.2f} next month, which exceeds "
                          f"your current monthly income of ${monthly_income:.2f}.",
                'recommendation': 'Consider reducing discretionary spending or finding additional income sources.',
                'priority': 'high'
            })
        
        # RULE 2: Category exceeds reasonable percentage
        for category, amount in aggregation['category_totals'].items():
            percentage = (amount / aggregation['overall_total']) * 100 if aggregation['overall_total'] > 0 else 0
            
            if category == 'Food' and percentage > 30:
                advice.append({
                    'type': 'suggestion',
                    'category': 'spending_pattern',
                    'title': 'High Food Expenses',
                    'message': f"Your food spending is {percentage:.1f}% of total expenses "
                              f"(${amount:.2f}), which is higher than recommended.",
                    'recommendation': 'Consider meal planning and cooking at home to reduce food costs.',
                    'priority': 'medium'
                })
            elif category == 'Entertainment' and percentage > 15:
                advice.append({
                    'type': 'suggestion',
                    'category': 'spending_pattern',
                    'title': 'High Entertainment Costs',
                    'message': f"Entertainment expenses are {percentage:.1f}% of your total spending.",
                    'recommendation': 'Look for free or low-cost entertainment alternatives.',
                    'priority': 'low'
                })
        
        # RULE 3: Repeated anomalies
        if len(anomalies['anomalies']) > 3:
            advice.append({
                'type': 'alert',
                'category': 'anomaly',
                'title': 'Frequent High-Value Transactions',
                'message': f"Detected {len(anomalies['anomalies'])} unusually high expenses recently.",
                'recommendation': 'Review these transactions to ensure they align with your financial goals.',
                'priority': 'medium'
            })
        
        # RULE 4: Budget limit warning
        if budget:
            current_month_spending = aggregation.get('monthly_totals', {}).get(
                datetime.now().strftime('%Y-%m'), 0
            )
            if current_month_spending > budget.monthly_limit * 0.9:
                advice.append({
                    'type': 'warning',
                    'category': 'budget',
                    'title': 'Approaching Budget Limit',
                    'message': f"You've spent ${current_month_spending:.2f} of your "
                              f"${budget.monthly_limit:.2f} monthly budget.",
                    'recommendation': 'Limit non-essential purchases for the rest of the month.',
                    'priority': 'high'
                })
        
        # RULE 5: Positive savings trend
        if prediction['trend'] == 'decreasing':
            advice.append({
                'type': 'positive',
                'category': 'savings',
                'title': 'Great Job! Spending is Decreasing',
                'message': f"Your spending trend is downward. Keep up the good work!",
                'recommendation': 'Consider saving the extra money or investing it.',
                'priority': 'low'
            })
        
        return {
            'advice': advice,
            'summary': f"{len(advice)} insights generated",
            'analyzed_date': datetime.now().isoformat()
        }
    
    # =====================================================================
    # MODULE 6: AI INSIGHT TEXT GENERATION
    # =====================================================================
    
    def generate_insights_text(self, user_id):
        """
        Generate human-readable insight text using backend logic
        NO external AI API - only structured data to text
        """
        # Get all data
        prediction = self.predict_next_month_spending(user_id)
        aggregation = self.get_spending_aggregation(user_id, months=3)
        anomalies = self.detect_anomalies(user_id)
        advice = self.get_financial_advice(user_id)
        
        # Generate insight text
        insights = []
        
        # Overview insight
        if aggregation['months_analyzed'] > 0:
            avg_monthly = aggregation['average_monthly']
            insights.append({
                'title': 'Spending Overview',
                'text': f"Over the last {aggregation['months_analyzed']} months, you've spent "
                       f"an average of ${avg_monthly:.2f} per month, totaling ${aggregation['overall_total']:.2f}."
            })
        
        # Prediction insight
        if prediction['based_on_months'] >= 3:
            insights.append({
                'title': 'Next Month Forecast',
                'text': f"Based on your spending pattern, you're likely to spend "
                       f"${prediction['predicted_amount']:.2f} next month. "
                       f"Your spending trend is {prediction['trend']}."
            })
        
        # Category breakdown
        if aggregation['category_totals']:
            top_category = max(aggregation['category_totals'].items(), key=lambda x: x[1])
            percentage = (top_category[1] / aggregation['overall_total']) * 100
            insights.append({
                'title': 'Top Spending Category',
                'text': f"Your highest expense category is {top_category[0]} at "
                       f"${top_category[1]:.2f} ({percentage:.1f}% of total spending)."
            })
        
        # Anomaly insight
        if anomalies['anomalies']:
            insights.append({
                'title': 'Unusual Transactions',
                'text': f"Found {len(anomalies['anomalies'])} unusually high transactions. "
                       f"The threshold for normal spending is ${anomalies['threshold']:.2f}."
            })
        
        # Key advice
        high_priority_advice = [a for a in advice['advice'] if a['priority'] == 'high']
        if high_priority_advice:
            insights.append({
                'title': 'Important Alert',
                'text': high_priority_advice[0]['message']
            })
        
        return {
            'insights': insights,
            'generated_at': datetime.now().isoformat(),
            'data_quality': 'good' if aggregation['months_analyzed'] >= 3 else 'limited'
        }
    
    # =====================================================================
    # COMPLETE AI PIPELINE
    # =====================================================================
    
    def get_complete_ai_analysis(self, user_id):
        """
        Execute complete AI pipeline for a user
        Returns all module outputs in single call
        """
        return {
            'categorization': 'Auto-categorization enabled',
            'aggregation': self.get_spending_aggregation(user_id),
            'prediction': self.predict_next_month_spending(user_id),
            'anomalies': self.detect_anomalies(user_id),
            'advice': self.get_financial_advice(user_id),
            'insights': self.generate_insights_text(user_id),
            'timestamp': datetime.now().isoformat()
        }
