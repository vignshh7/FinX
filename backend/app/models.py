from app import db
from werkzeug.security import generate_password_hash, check_password_hash
from datetime import datetime

class User(db.Model):
    __tablename__ = 'users'
    
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password_hash = db.Column(db.String(255), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Relationships
    expenses = db.relationship('Expense', backref='user', lazy=True, cascade='all, delete-orphan')
    subscriptions = db.relationship('Subscription', backref='user', lazy=True, cascade='all, delete-orphan')
    budget = db.relationship('Budget', backref='user', uselist=False, cascade='all, delete-orphan')
    
    def set_password(self, password):
        self.password_hash = generate_password_hash(password)
    
    def check_password(self, password):
        return check_password_hash(self.password_hash, password)
    
    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'email': self.email,
            'created_at': self.created_at.isoformat()
        }

class Expense(db.Model):
    __tablename__ = 'expenses'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    store = db.Column(db.String(200), nullable=False)
    amount = db.Column(db.Float, nullable=False)
    category = db.Column(db.String(50), nullable=False)
    date = db.Column(db.Date, nullable=False)
    items = db.Column(db.Text)  # JSON string
    raw_ocr_text = db.Column(db.Text)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    def to_dict(self):
        import json
        return {
            'id': self.id,
            'user_id': self.user_id,
            'store': self.store,
            'amount': self.amount,
            'category': self.category,
            'date': self.date.isoformat(),
            'items': json.loads(self.items) if self.items else None,
            'raw_ocr_text': self.raw_ocr_text,
            'created_at': self.created_at.isoformat()
        }

class Subscription(db.Model):
    __tablename__ = 'subscriptions'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    name = db.Column(db.String(200), nullable=False)
    amount = db.Column(db.Float, nullable=False)
    frequency = db.Column(db.String(20), nullable=False)  # monthly, yearly
    renewal_date = db.Column(db.Date, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'name': self.name,
            'amount': self.amount,
            'frequency': self.frequency,
            'renewal_date': self.renewal_date.isoformat(),
            'created_at': self.created_at.isoformat()
        }

class Budget(db.Model):
    __tablename__ = 'budgets'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, unique=True)
    monthly_limit = db.Column(db.Float, nullable=False)
    currency = db.Column(db.String(10), default='USD')
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'monthly_limit': self.monthly_limit,
            'currency': self.currency,
            'updated_at': self.updated_at.isoformat()
        }


class Income(db.Model):
    __tablename__ = 'incomes'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    source = db.Column(db.String(150), nullable=False)
    category = db.Column(db.String(50), nullable=False, default='Other')
    amount = db.Column(db.Float, nullable=False)
    currency = db.Column(db.String(3), nullable=False, default='INR')
    date = db.Column(db.Date, nullable=False)
    is_recurring = db.Column(db.Boolean, default=False)
    notes = db.Column(db.Text)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'source': self.source,
            'category': self.category,
            'amount': self.amount,
            'currency': self.currency,
            'date': self.date.isoformat(),
            'is_recurring': self.is_recurring,
            'notes': self.notes,
            'created_at': self.created_at.isoformat(),
            'updated_at': self.updated_at.isoformat() if self.updated_at else self.created_at.isoformat(),
        }


class CategoryBudget(db.Model):
    __tablename__ = 'category_budgets'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    category = db.Column(db.String(50), nullable=False)
    monthly_limit = db.Column(db.Float, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    __table_args__ = (
        db.UniqueConstraint('user_id', 'category', name='uq_user_category_budget'),
    )

    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'category': self.category,
            'monthly_limit': self.monthly_limit,
            'created_at': self.created_at.isoformat(),
            'updated_at': self.updated_at.isoformat(),
        }


class CategorizationFeedback(db.Model):
    __tablename__ = 'categorization_feedback'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    expense_id = db.Column(db.Integer, db.ForeignKey('expenses.id'), nullable=False)
    original_category = db.Column(db.String(50), nullable=False)
    corrected_category = db.Column(db.String(50), nullable=False)
    confidence = db.Column(db.Float)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'expense_id': self.expense_id,
            'original_category': self.original_category,
            'corrected_category': self.corrected_category,
            'confidence': self.confidence,
            'created_at': self.created_at.isoformat(),
        }


class SavingsGoal(db.Model):
    __tablename__ = 'savings_goals'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    title = db.Column(db.String(100), nullable=False)
    description = db.Column(db.Text)
    target_amount = db.Column(db.Float, nullable=False)
    current_amount = db.Column(db.Float, default=0.0)
    target_date = db.Column(db.DateTime)
    category = db.Column(db.String(50))
    priority = db.Column(db.String(20), default='medium')  # low, medium, high
    is_completed = db.Column(db.Boolean, default=False)
    currency = db.Column(db.String(10), default='USD')
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    contributions = db.relationship(
        'SavingsContribution',
        backref='goal',
        lazy=True,
        cascade='all, delete-orphan'
    )

    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'title': self.title,
            'description': self.description,
            'target_amount': self.target_amount,
            'current_amount': self.current_amount,
            'target_date': self.target_date.isoformat() if self.target_date else None,
            'category': self.category,
            'priority': self.priority,
            'is_completed': self.is_completed,
            'currency': self.currency,
            'created_at': self.created_at.isoformat(),
            'updated_at': self.updated_at.isoformat() if self.updated_at else None,
            'contributions': [c.to_dict() for c in self.contributions],
        }


class SavingsContribution(db.Model):
    __tablename__ = 'savings_contributions'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    goal_id = db.Column(db.Integer, db.ForeignKey('savings_goals.id'), nullable=False)
    amount = db.Column(db.Float, nullable=False)
    date = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)
    note = db.Column(db.Text)
    type = db.Column(db.String(20), default='manual')
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            'id': self.id,
            'goal_id': self.goal_id,
            'amount': self.amount,
            'date': self.date.isoformat() if self.date else None,
            'note': self.note,
            'type': self.type,
            'created_at': self.created_at.isoformat(),
        }


class BillReminder(db.Model):
    __tablename__ = 'bill_reminders'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    title = db.Column(db.String(100), nullable=False)
    description = db.Column(db.Text)
    amount = db.Column(db.Float, nullable=False)
    due_date = db.Column(db.DateTime, nullable=False)
    frequency = db.Column(db.String(20), default='monthly')  # once, daily, weekly, monthly, yearly
    category = db.Column(db.String(50))
    priority = db.Column(db.String(20), default='medium')  # low, medium, high
    is_recurring = db.Column(db.Boolean, default=False)
    is_paid = db.Column(db.Boolean, default=False)
    paid_date = db.Column(db.DateTime)
    payment_method = db.Column(db.String(50))
    status = db.Column(db.String(20), default='pending')  # pending, paid, overdue
    currency = db.Column(db.String(10), default='USD')
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'title': self.title,
            'description': self.description,
            'amount': self.amount,
            'due_date': self.due_date.isoformat() if self.due_date else None,
            'frequency': self.frequency,
            'category': self.category,
            'priority': self.priority,
            'is_recurring': self.is_recurring,
            'is_paid': self.is_paid,
            'paid_date': self.paid_date.isoformat() if self.paid_date else None,
            'payment_method': self.payment_method,
            'status': self.status,
            'currency': self.currency,
            'created_at': self.created_at.isoformat(),
            'updated_at': self.updated_at.isoformat() if self.updated_at else None,
        }
