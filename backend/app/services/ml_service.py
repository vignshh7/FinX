import pickle
import os
import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.naive_bayes import MultinomialNB
from sklearn.pipeline import Pipeline
import joblib

class ExpenseCategorizer:
    def __init__(self):
        self.model = None
        self.categories = ['Food', 'Travel', 'Shopping', 'Bills', 'Entertainment', 'Other']
        self.model_path = 'app/ml_models/categorizer.pkl'
        
        # Load model if exists, otherwise train a basic one
        if os.path.exists(self.model_path):
            self.load_model()
        else:
            self.train_basic_model()
    
    def train_basic_model(self):
        """
        Train a basic categorization model with sample data
        In production, this should be trained on real user data
        """
        # Sample training data
        training_data = [
            # Food
            ('restaurant dinner lunch breakfast', 'Food'),
            ('supermarket grocery store food mart', 'Food'),
            ('cafe coffee starbucks dunkin', 'Food'),
            ('pizza burger sandwich meal', 'Food'),
            ('walmart grocery target food', 'Food'),
            
            # Travel
            ('uber lyft taxi cab transport', 'Travel'),
            ('gas station fuel petrol shell', 'Travel'),
            ('airline flight ticket airport', 'Travel'),
            ('hotel motel accommodation stay', 'Travel'),
            ('parking toll highway', 'Travel'),
            
            # Shopping
            ('amazon ebay shopping online', 'Shopping'),
            ('clothing store fashion apparel', 'Shopping'),
            ('electronics best buy apple', 'Shopping'),
            ('mall department store', 'Shopping'),
            ('nike adidas shoes store', 'Shopping'),
            
            # Bills
            ('electricity power utility bill', 'Bills'),
            ('water bill utility', 'Bills'),
            ('internet wifi broadband', 'Bills'),
            ('phone mobile cellular', 'Bills'),
            ('insurance premium payment', 'Bills'),
            
            # Entertainment
            ('netflix spotify subscription', 'Entertainment'),
            ('movie cinema theater', 'Entertainment'),
            ('game gaming xbox playstation', 'Entertainment'),
            ('concert ticket event', 'Entertainment'),
            ('gym fitness membership', 'Entertainment'),
        ]
        
        texts = [text for text, _ in training_data]
        labels = [label for _, label in training_data]
        
        # Create pipeline with TF-IDF and Naive Bayes
        self.model = Pipeline([
            ('tfidf', TfidfVectorizer(max_features=100, ngram_range=(1, 2))),
            ('clf', MultinomialNB()),
        ])
        
        # Train model
        self.model.fit(texts, labels)
        
        # Save model
        os.makedirs(os.path.dirname(self.model_path), exist_ok=True)
        joblib.dump(self.model, self.model_path)
    
    def load_model(self):
        """Load trained model from disk"""
        self.model = joblib.load(self.model_path)
    
    def predict(self, text):
        """
        Predict category from text
        Returns: (category, confidence)
        """
        if not text or not self.model:
            return 'Other', 0.0
        
        # Get prediction probabilities
        probabilities = self.model.predict_proba([text.lower()])[0]
        
        # Get predicted class
        predicted_idx = np.argmax(probabilities)
        predicted_category = self.model.classes_[predicted_idx]
        confidence = probabilities[predicted_idx]
        
        return predicted_category, float(confidence)
    
    def categorize_expense(self, store_name, items=None):
        """
        Categorize expense based on store name and items
        """
        # Combine store name and items for better prediction
        text = store_name.lower()
        if items:
            text += ' ' + ' '.join(items).lower()
        
        category, confidence = self.predict(text)
        
        return {
            'predicted_category': category,
            'confidence': confidence
        }
