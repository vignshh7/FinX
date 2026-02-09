import re
from typing import List, Dict, Any

class SimpleExpenseCategorizer:
    """
    Simplified expense categorization without sklearn dependency
    Uses rule-based categorization for development
    """
    
    def __init__(self):
        # Define category mapping based on keywords
        self.category_keywords = {
            'Food': [
                'restaurant', 'mcdonalds', 'kfc', 'pizza', 'burger', 'subway', 'starbucks',
                'grocery', 'walmart', 'target', 'kroger', 'safeway', 'publix', 'costco',
                'food', 'meal', 'dining', 'cafe', 'deli', 'bakery', 'market', 'supermarket'
            ],
            'Transport': [
                'gas', 'fuel', 'uber', 'lyft', 'taxi', 'bus', 'train', 'metro', 'parking',
                'car', 'auto', 'vehicle', 'transport', 'shell', 'exxon', 'chevron', 'bp'
            ],
            'Shopping': [
                'amazon', 'ebay', 'mall', 'store', 'shop', 'retail', 'clothing', 'electronics',
                'best buy', 'apple store', 'macy', 'nike', 'adidas', 'fashion', 'shoes'
            ],
            'Bills': [
                'electric', 'electricity', 'water', 'gas bill', 'phone', 'internet', 'cable',
                'utility', 'rent', 'mortgage', 'insurance', 'verizon', 'att', 'comcast'
            ],
            'Healthcare': [
                'hospital', 'doctor', 'pharmacy', 'medical', 'health', 'medicine', 'cvs',
                'walgreens', 'clinic', 'dental', 'dentist', 'prescription'
            ],
            'Entertainment': [
                'movie', 'cinema', 'netflix', 'spotify', 'game', 'concert', 'theater',
                'amusement', 'park', 'entertainment', 'ticket', 'subscription'
            ]
        }
        
        # Trained category priorities (simulated)
        self.category_priorities = {
            'Food': 0.95,
            'Transport': 0.90,
            'Shopping': 0.85,
            'Bills': 0.88,
            'Healthcare': 0.92,
            'Entertainment': 0.80
        }
    
    def categorize_expense(self, description: str, amount: float = None) -> Dict[str, Any]:
        """
        Categorize expense based on description and optional amount
        """
        if not description:
            return {
                'category': 'Other',
                'confidence': 0.5,
                'subcategory': None,
                'reasoning': 'No description provided'
            }
        
        description_lower = description.lower().strip()
        
        # Score each category
        category_scores = {}
        for category, keywords in self.category_keywords.items():
            score = 0
            matched_keywords = []
            
            for keyword in keywords:
                if keyword in description_lower:
                    # Weighted scoring based on keyword relevance
                    if len(keyword) > 6:  # Longer keywords get higher weight
                        score += 0.3
                    else:
                        score += 0.2
                    matched_keywords.append(keyword)
            
            if score > 0:
                # Apply priority multiplier
                score *= self.category_priorities.get(category, 0.7)
                category_scores[category] = {
                    'score': score,
                    'keywords': matched_keywords
                }
        
        # Determine best category
        if not category_scores:
            return {
                'category': 'Other',
                'confidence': 0.5,
                'subcategory': None,
                'reasoning': 'No matching keywords found'
            }
        
        # Get highest scoring category
        best_category = max(category_scores, key=lambda x: category_scores[x]['score'])
        best_score = category_scores[best_category]['score']
        matched_keywords = category_scores[best_category]['keywords']
        
        # Calculate confidence (normalized score)
        confidence = min(0.95, max(0.6, best_score))
        
        # Determine subcategory for Food
        subcategory = None
        if best_category == 'Food':
            if any(kw in description_lower for kw in ['restaurant', 'dining', 'cafe']):
                subcategory = 'Dining Out'
            elif any(kw in description_lower for kw in ['grocery', 'market', 'walmart', 'target']):
                subcategory = 'Groceries'
            elif any(kw in description_lower for kw in ['starbucks', 'coffee', 'cafe']):
                subcategory = 'Coffee & Drinks'
        
        return {
            'category': best_category,
            'confidence': confidence,
            'subcategory': subcategory,
            'reasoning': f"Matched keywords: {', '.join(matched_keywords[:3])}",
            'score': best_score
        }
    
    def bulk_categorize(self, expenses: List[Dict]) -> List[Dict]:
        """
        Categorize multiple expenses at once
        """
        results = []
        for expense in expenses:
            description = expense.get('description', '')
            amount = expense.get('amount', 0)
            
            categorization = self.categorize_expense(description, amount)
            
            result = expense.copy()
            result.update(categorization)
            results.append(result)
        
        return results
    
    def get_category_stats(self, expenses: List[Dict]) -> Dict[str, Any]:
        """
        Get statistics about categorized expenses
        """
        if not expenses:
            return {}
        
        category_amounts = {}
        category_counts = {}
        total_amount = 0
        
        for expense in expenses:
            category = expense.get('category', 'Other')
            amount = expense.get('amount', 0)
            
            category_amounts[category] = category_amounts.get(category, 0) + amount
            category_counts[category] = category_counts.get(category, 0) + 1
            total_amount += amount
        
        # Calculate percentages
        category_percentages = {}
        for category, amount in category_amounts.items():
            category_percentages[category] = (amount / total_amount * 100) if total_amount > 0 else 0
        
        return {
            'total_amount': total_amount,
            'category_amounts': category_amounts,
            'category_counts': category_counts,
            'category_percentages': category_percentages,
            'top_category': max(category_amounts, key=category_amounts.get) if category_amounts else None
        }

# Create alias for backward compatibility
ExpenseCategorizer = SimpleExpenseCategorizer