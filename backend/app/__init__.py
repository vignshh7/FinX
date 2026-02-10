from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_jwt_extended import JWTManager
from flask_cors import CORS
from dotenv import load_dotenv
import os

# Load environment variables
load_dotenv()

# Initialize extensions
db = SQLAlchemy()
jwt = JWTManager()

def create_app():
    app = Flask(__name__)
    
    # Configuration
    app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'dev-secret-key')
    app.config['SQLALCHEMY_DATABASE_URI'] = os.getenv('DATABASE_URL', 'sqlite:///finance.db')
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
    app.config['JWT_SECRET_KEY'] = os.getenv('JWT_SECRET_KEY', 'jwt-secret-key')
    app.config['UPLOAD_FOLDER'] = os.getenv('UPLOAD_FOLDER', 'uploads')
    app.config['MAX_CONTENT_LENGTH'] = int(os.getenv('MAX_FILE_SIZE', 16777216))
    
    # Initialize extensions
    db.init_app(app)
    jwt.init_app(app)
    
    # CORS Configuration - works for both local and production
    cors_origins = os.getenv('CORS_ORIGINS', '*')
    if cors_origins == '*':
        CORS(app)
    else:
        CORS(app, origins=cors_origins.split(','))
    
    # Create upload folder
    os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)
    
    # Register blueprints
    from app.routes.auth import auth_bp
    from app.routes.expenses import expenses_bp
    from app.routes.ocr import ocr_bp
    from app.routes.subscriptions import subscriptions_bp
    from app.routes.budget import budget_bp
    from app.routes.income import incomes_bp
    from app.routes.analytics import analytics_bp
    from app.routes.ai_routes import ai_bp
    
    app.register_blueprint(auth_bp, url_prefix='/api')
    app.register_blueprint(expenses_bp, url_prefix='/api')
    app.register_blueprint(ocr_bp, url_prefix='/api')
    app.register_blueprint(subscriptions_bp, url_prefix='/api')
    app.register_blueprint(budget_bp, url_prefix='/api')
    app.register_blueprint(incomes_bp, url_prefix='/api')
    app.register_blueprint(analytics_bp, url_prefix='/api')
    app.register_blueprint(ai_bp, url_prefix='/api')
    
    # Create tables
    with app.app_context():
        db.create_all()
    
    @app.route('/')
    def index():
        return {'message': 'Smart Finance API', 'version': '1.0.0'}
    
    @app.route('/api/health')
    def health():
        return {'status': 'healthy', 'service': 'finx-backend'}, 200
    
    return app

if __name__ == '__main__':
    app = create_app()
    app.run(debug=True, host='0.0.0.0', port=5000)
