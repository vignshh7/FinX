# Simple OCR Service without complex dependencies
import os
import re
from datetime import datetime

class SimpleOCRService:
    def __init__(self):
        print("Initializing Simple OCR Service (Mock)")
        
    def extract_text(self, image_path):
        """
        Mock OCR text extraction for development
        Returns simulated receipt text for testing
        """
        # Simulate different types of receipts
        mock_receipts = [
            """WALMART SUPERCENTER
            STORE #1234
            123 MAIN ST
            ANYTOWN, USA 12345
            
            GROCERIES
            Bananas                  $3.48
            Milk 1 Gal              $4.28
            Bread                   $2.50
            Chicken Breast          $8.99
            
            SUBTOTAL               $19.25
            TAX                     $1.54
            TOTAL                  $20.79
            
            VISA ENDING 1234       $20.79
            
            02/15/2024  3:45 PM
            THANK YOU!""",
            
            """TARGET
            Store T-0567
            456 SHOPPING BLVD
            SHOPPING TOWN 67890
            
            Shampoo                 $5.99
            Toothpaste              $3.49
            Paper Towels            $8.99
            Laundry Detergent      $11.49
            
            SUBTOTAL               $29.96
            TAX 8.25%               $2.47
            TOTAL                  $32.43
            
            Credit Card             $32.43
            
            02/16/2024  11:22 AM""",
            
            """McDONALD'S
            Store #8901
            789 FAST FOOD DR
            
            Big Mac Meal            $8.99
            McChicken               $2.39
            Medium Fries            $2.89
            Large Coke              $1.89
            Apple Pie               $1.29
            
            SUBTOTAL               $17.45
            TAX                     $1.40
            TOTAL                  $18.85
            
            CASH                   $20.00
            CHANGE                  $1.15
            
            02/17/2024  7:30 PM"""
        ]
        
        # Return a random mock receipt
        import random
        return random.choice(mock_receipts)
    
    def extract_structured_data(self, text):
        """
        Enhanced structured data extraction from OCR text
        """
        result = {
            'store': 'Unknown Store',
            'items': [],
            'amount': 0.0,
            'date': datetime.now().strftime('%Y-%m-%d'),
            'tax': 0.0,
            'confidence': 'high'  # Mock high confidence
        }
        
        if not text:
            result['confidence'] = 'low'
            return result
        
        lines = text.split('\n')
        lines = [line.strip() for line in lines if line.strip() and len(line.strip()) > 1]
        
        # Extract store name
        store_patterns = [
            r'(WALMART|TARGET|MCDONALD\'S|COSTCO|KROGER|SAFEWAY|PUBLIX)',
            r'([A-Z][A-Za-z\s]{2,20})\s*(SUPERCENTER|STORE|MARKET|SHOP)',
        ]
        
        for line in lines[:5]:
            for pattern in store_patterns:
                match = re.search(pattern, line, re.IGNORECASE)
                if match:
                    result['store'] = match.group(1).title()
                    break
            if result['store'] != 'Unknown Store':
                break
        
        # Extract total amount
        amount_patterns = [
            r'TOTAL\s*\$?([0-9]+\.?[0-9]*)',
            r'AMOUNT\s*\$?([0-9]+\.?[0-9]*)',
            r'\$([0-9]+\.[0-9]{2})',
        ]
        
        amounts_found = []
        for line in lines:
            for pattern in amount_patterns:
                matches = re.findall(pattern, line, re.IGNORECASE)
                for match in matches:
                    try:
                        amount = float(match)
                        if 0.01 <= amount <= 10000:
                            amounts_found.append(amount)
                    except ValueError:
                        continue
        
        if amounts_found:
            result['amount'] = max(amounts_found)
        
        # Extract date
        date_patterns = [
            r'(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})',
        ]
        
        for line in lines:
            for pattern in date_patterns:
                match = re.search(pattern, line)
                if match:
                    try:
                        date_str = match.group(1)
                        parsed_date = datetime.strptime(date_str, '%m/%d/%Y')
                        result['date'] = parsed_date.strftime('%Y-%m-%d')
                        break
                    except:
                        continue
        
        # Extract items
        item_patterns = [
            r'([A-Za-z\s]{3,30})\s+\$([0-9]+\.?[0-9]*)',
        ]
        
        for line in lines:
            if any(word in line.upper() for word in ['TOTAL', 'SUBTOTAL', 'TAX', 'CHANGE']):
                continue
                
            for pattern in item_patterns:
                match = re.search(pattern, line)
                if match:
                    item_name = match.group(1).strip()
                    if len(item_name) >= 3:
                        try:
                            price = float(match.group(2))
                            result['items'].append({
                                'name': item_name.title(),
                                'price': price
                            })
                        except:
                            pass
                        break
        
        return result
    
    def process_receipt(self, image_path):
        """
        Main processing function with mock OCR
        """
        try:
            print(f"Processing receipt: {image_path}")
            
            # Mock text extraction
            extracted_text = self.extract_text(image_path)
            print(f"Mock extracted text: {extracted_text[:100]}...")
            
            # Extract structured data
            structured_data = self.extract_structured_data(extracted_text)
            
            structured_data['raw_text'] = extracted_text
            structured_data['processing_status'] = 'success'
            
            return structured_data
            
        except Exception as e:
            print(f"Error processing receipt: {e}")
            return {
                'store': 'Processing Error',
                'items': [],
                'amount': 0.0,
                'date': datetime.now().strftime('%Y-%m-%d'),
                'raw_text': f"Error: {str(e)}",
                'processing_status': 'error',
                'confidence': 'low'
            }

# Create alias for backward compatibility
OCRService = SimpleOCRService