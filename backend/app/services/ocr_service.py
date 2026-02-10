import requests
import base64
import os
import re
from datetime import datetime
from PIL import Image
import io

class OCRService:
    def __init__(self):
        """Initialize Google Cloud Vision OCR service"""
        self.api_key = os.getenv('GOOGLE_VISION_API_KEY')
        self.api_endpoint = "https://vision.googleapis.com/v1/images:annotate"
        
        if not self.api_key:
            print("\n" + "="*60)
            print("⚠ WARNING: GOOGLE_VISION_API_KEY not set!")
            print("  Add GOOGLE_VISION_API_KEY in Render environment variables")
            print("="*60 + "\n")
            self.available = False
        else:
            print("\n" + "="*60)
            print("✓ SUCCESS: Google Cloud Vision API configured")
            print(f"  API Key: {self.api_key[:10]}...{self.api_key[-4:]}")
            print("="*60 + "\n")
            self.available = True
    
    def extract_text_from_image(self, image_bytes):
        """
        Extract text from image using Google Cloud Vision API
        
        Args:
            image_bytes: Raw image bytes
            
        Returns:
            str: Extracted text from image
        """
        if not self.available:
            raise Exception("Google Vision API key not configured")
        
        try:
            # Encode image to base64
            encoded_image = base64.b64encode(image_bytes).decode('utf-8')
            
            # Build request payload
            payload = {
                "requests": [
                    {
                        "image": {
                            "content": encoded_image
                        },
                        "features": [
                            {
                                "type": "TEXT_DETECTION",
                                "maxResults": 1
                            }
                        ]
                    }
                ]
            }
            
            # Call Google Vision API
            response = requests.post(
                f"{self.api_endpoint}?key={self.api_key}",
                json=payload,
                timeout=30
            )
            
            # Handle errors
            if response.status_code != 200:
                error_data = response.json()
                if 'error' in error_data:
                    error_msg = error_data['error'].get('message', 'Unknown error')
                    raise Exception(f"Google Vision API error: {error_msg}")
                raise Exception(f"API request failed with status {response.status_code}")
            
            # Parse response
            result = response.json()
            
            if 'responses' not in result or len(result['responses']) == 0:
                return ""
            
            annotations = result['responses'][0]
            
            if 'textAnnotations' not in annotations or len(annotations['textAnnotations']) == 0:
                return ""
            
            # First annotation contains full text
            full_text = annotations['textAnnotations'][0]['description']
            
            return full_text.strip()
            
        except requests.exceptions.Timeout:
            raise Exception("Google Vision API request timed out")
        except requests.exceptions.RequestException as e:
            raise Exception(f"Network error: {str(e)}")
        except Exception as e:
            raise Exception(f"OCR failed: {str(e)}")
    
    def extract_structured_data(self, text):
        """
        Parse extracted text and extract structured data
        
        Args:
            text: Raw OCR text
            
        Returns:
            dict: Structured receipt data
        """
        lines = text.split('\n')
        
        result = {
            'store': 'Unknown',
            'items': [],
            'amount': 0.0,
            'date': datetime.now().strftime('%Y-%m-%d')
        }
        
        # Extract store name (usually first non-empty line)
        for line in lines[:5]:
            clean_line = line.strip()
            if len(clean_line) > 2 and not re.match(r'^[\d\s\-\/\.]+$', clean_line):
                result['store'] = clean_line
                break
        
        # Extract amount (look for currency symbols and numbers)
        amount_patterns = [
            r'\$\s*(\d+\.?\d*)',
            r'(?:total|amount|sum)[\s:]*\$?\s*(\d+\.?\d*)',
            r'(\d+\.\d{2})\s*(?:$|total|amount)',
        ]
        
        amounts = []
        for line in lines:
            for pattern in amount_patterns:
                matches = re.findall(pattern, line, re.IGNORECASE)
                if matches:
                    try:
                        amount_val = float(matches[-1].replace(',', ''))
                        if 0 < amount_val < 100000:
                            amounts.append(amount_val)
                    except ValueError:
                        pass
        
        if amounts:
            result['amount'] = max(amounts)
        
        # Extract date
        date_patterns = [
            r'(\d{1,2}[-/]\d{1,2}[-/]\d{2,4})',
            r'(\d{4}[-/]\d{1,2}[-/]\d{1,2})',
        ]
        
        for line in lines:
            for pattern in date_patterns:
                match = re.search(pattern, line)
                if match:
                    date_str = match.group(1)
                    try:
                        # Try parsing
                        for fmt in ['%m/%d/%Y', '%d/%m/%Y', '%Y-%m-%d', '%m-%d-%Y', '%d-%m-%Y']:
                            try:
                                parsed_date = datetime.strptime(date_str, fmt)
                                result['date'] = parsed_date.strftime('%Y-%m-%d')
                                break
                            except ValueError:
                                continue
                    except Exception:
                        pass
        
        # Extract items (lines with price-like patterns)
        item_pattern = r'(.+?)\s+\$?\s*(\d+\.?\d*)\s*$'
        for line in lines:
            match = re.search(item_pattern, line.strip())
            if match:
                item_name = match.group(1).strip()
                if len(item_name) > 2 and item_name.lower() not in ['total', 'subtotal', 'tax', 'amount']:
                    result['items'].append(item_name)
        
        # Limit items to reasonable number
        result['items'] = result['items'][:10]
        
        return result
    
    def process_receipt(self, image_path):
        """
        Process receipt image: OCR + data extraction
        
        Args:
            image_path: Path to receipt image file
            
        Returns:
            dict: Extracted receipt data with OCR metadata
        """
        try:
            # Read image bytes
            with open(image_path, 'rb') as img_file:
                image_bytes = img_file.read()
            
            # Validate image
            try:
                img = Image.open(io.BytesIO(image_bytes))
                img.verify()
            except Exception:
                raise Exception("Invalid image file")
            
            # Extract text using Google Vision
            extracted_text = self.extract_text_from_image(image_bytes)
            
            if not extracted_text:
                raise Exception("No text detected in image")
            
            # Parse structured data
            structured_data = self.extract_structured_data(extracted_text)
            
            # Add metadata
            structured_data['raw_text'] = extracted_text[:500]
            structured_data['ocr_provider'] = 'google_cloud_vision'
            structured_data['ocr_mode'] = 'cloud'
            structured_data['available'] = True
            structured_data['processing_status'] = 'success'
            
            return structured_data
            
        except Exception as e:
            # Return error response
            return {
                'store': 'Unknown',
                'items': [],
                'amount': 0.0,
                'date': datetime.now().strftime('%Y-%m-%d'),
                'raw_text': '',
                'ocr_provider': 'google_cloud_vision',
                'ocr_mode': 'cloud',
                'available': self.available,
                'processing_status': 'failed',
                'error': str(e)
            }
