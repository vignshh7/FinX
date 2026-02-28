import requests
import base64
import os
import re
from datetime import datetime
from PIL import Image
import io

class OCRService:
    def __init__(self):
        """Initialize OCR.space OCR service"""
        # Use provided API key as default, can be overridden with env variable
        self.api_key = os.getenv('OCR_SPACE_API_KEY', 'K89677956988957')
        self.api_endpoint = "https://api.ocr.space/parse/image"
        
        print("\n" + "="*60)
        print("✓ SUCCESS: OCR.space API configured")
        print(f"  API Key: {self.api_key[:10]}...{self.api_key[-4:]}")
        print("="*60 + "\n")
        self.available = True
    
    def extract_text_from_image(self, image_bytes):
        """
        Extract text from image using OCR.space API
        
        Args:
            image_bytes: Raw image bytes
            
        Returns:
            str: Extracted text from image
        """
        if not self.available:
            raise Exception("OCR.space API key not configured")
        
        try:
            # Encode image to base64
            encoded_image = base64.b64encode(image_bytes).decode('utf-8')
            
            # Build request payload for OCR.space
            payload = {
                'base64Image': f'data:image/jpeg;base64,{encoded_image}',
                'language': 'eng',
                'isOverlayRequired': False,
                'detectOrientation': True,
                'scale': True,
                'OCREngine': 2  # OCR.space engine 2 is more accurate
            }
            
            headers = {
                'apikey': self.api_key
            }
            
            # Call OCR.space API
            response = requests.post(
                self.api_endpoint,
                data=payload,
                headers=headers,
                timeout=30
            )
            
            # Handle errors
            if response.status_code != 200:
                raise Exception(f"API request failed with status {response.status_code}")
            
            # Parse response
            result = response.json()
            
            # Check if OCR was successful
            if not result.get('IsErroredOnProcessing', True):
                parsed_results = result.get('ParsedResults', [])
                if parsed_results and len(parsed_results) > 0:
                    full_text = parsed_results[0].get('ParsedText', '')
                    return full_text.strip()
            
            # Handle error in response
            error_message = result.get('ErrorMessage', ['Unknown error'])
            if isinstance(error_message, list):
                error_message = ', '.join(error_message)
            raise Exception(f"OCR.space API error: {error_message}")
            
        except requests.exceptions.Timeout:
            raise Exception("OCR.space API request timed out")
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
            
            # Validate image - lenient check
            if len(image_bytes) == 0:
                raise Exception("Empty image file")
            
            try:
                # Just verify we can open it, don't use verify()
                img = Image.open(io.BytesIO(image_bytes))
                # Check format is supported
                if img.format not in ['JPEG', 'PNG', 'JPG', 'WEBP', 'BMP', 'GIF']:
                    # Still try to process, OCR.space supports many formats
                    pass
            except Exception as e:
                # If we can't even open it, it's truly invalid
                raise Exception(f"Cannot read image file: {str(e)}")
            
            # Extract text using OCR.space
            extracted_text = self.extract_text_from_image(image_bytes)
            
            if not extracted_text:
                raise Exception("No text detected in image")
            
            # Parse structured data
            structured_data = self.extract_structured_data(extracted_text)
            
            # Add metadata
            structured_data['raw_text'] = extracted_text[:500]
            structured_data['ocr_provider'] = 'ocrspace'
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
                'ocr_provider': 'ocrspace',
                'ocr_mode': 'cloud',
                'available': self.available,
                'processing_status': 'failed',
                'error': str(e)
            }
