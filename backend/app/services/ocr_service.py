import pytesseract
from PIL import Image, ImageEnhance, ImageFilter
import cv2
import numpy as np
import re
from datetime import datetime
import os

class OCRService:
    def __init__(self):
        # Set Tesseract path (update based on installation)
        tesseract_path = os.getenv('TESSERACT_CMD', 'tesseract')
        if os.path.exists(tesseract_path):
            pytesseract.pytesseract.tesseract_cmd = tesseract_path
    
    def preprocess_image(self, image_path):
        """
        Enhanced preprocessing for better OCR results
        Multiple preprocessing techniques for receipt images
        """
        try:
            # Read image with PIL first for better format support
            pil_image = Image.open(image_path)
            
            # Convert to RGB if needed
            if pil_image.mode != 'RGB':
                pil_image = pil_image.convert('RGB')
            
            # Enhance contrast and sharpness
            enhancer = ImageEnhance.Contrast(pil_image)
            pil_image = enhancer.enhance(1.5)
            
            enhancer = ImageEnhance.Sharpness(pil_image)
            pil_image = enhancer.enhance(2.0)
            
            # Convert PIL to OpenCV
            image = cv2.cvtColor(np.array(pil_image), cv2.COLOR_RGB2BGR)
            
            # Multiple preprocessing approaches
            processed_images = []
            
            # Method 1: Standard grayscale + threshold
            gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
            denoised = cv2.fastNlMeansDenoising(gray, None, 10, 7, 21)
            
            # Adaptive threshold
            thresh1 = cv2.adaptiveThreshold(
                denoised, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, 
                cv2.THRESH_BINARY, 11, 2
            )
            processed_images.append(thresh1)
            
            # Method 2: OTSU threshold
            _, thresh2 = cv2.threshold(denoised, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
            processed_images.append(thresh2)
            
            # Method 3: Morphological operations for receipt structure
            kernel = np.ones((2,2), np.uint8)
            morphed = cv2.morphologyEx(thresh1, cv2.MORPH_CLOSE, kernel)
            processed_images.append(morphed)
            
            return processed_images
            
        except Exception as e:
            print(f"Error in image preprocessing: {e}")
            # Fallback to original image
            image = cv2.imread(image_path)
            if image is not None:
                gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
                return [gray]
            return [np.zeros((100, 100), dtype=np.uint8)]
    
    def extract_text(self, image_path):
        """
        Extract text from receipt image with multiple OCR attempts
        """
        try:
            processed_images = self.preprocess_image(image_path)
            best_text = ""
            best_confidence = 0
            
            # OCR configurations for different scenarios
            ocr_configs = [
                '--psm 6 --oem 3 -c tessedit_char_whitelist=0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz$.,:/- ',
                '--psm 4 --oem 3',
                '--psm 3 --oem 3',
                '--psm 11 --oem 3',
                '--psm 13 --oem 3'
            ]
            
            all_texts = []
            
            # Try OCR on each processed image with different configs
            for img in processed_images:
                for config in ocr_configs:
                    try:
                        # Extract text with confidence
                        data = pytesseract.image_to_data(img, config=config, output_type=pytesseract.Output.DICT)
                        
                        # Filter high confidence words
                        confident_words = []
                        for i, conf in enumerate(data['conf']):
                            if int(conf) > 30:  # Confidence threshold
                                word = data['text'][i].strip()
                                if word and len(word) > 1:
                                    confident_words.append(word)
                        
                        if confident_words:
                            text = ' '.join(confident_words)
                            all_texts.append(text)
                            
                            # Calculate average confidence
                            avg_conf = sum(int(c) for c in data['conf'] if int(c) > 30) / max(1, len([c for c in data['conf'] if int(c) > 30]))
                            
                            if avg_conf > best_confidence:
                                best_confidence = avg_conf
                                best_text = text
                                
                    except Exception as e:
                        print(f"OCR attempt failed: {e}")
                        continue
            
            # Combine all extracted texts for better parsing
            combined_text = best_text
            if len(all_texts) > 1:
                # Use the longest text as base, supplement with others
                all_texts.sort(key=len, reverse=True)
                combined_text = all_texts[0]
                
                # Add missing information from other attempts
                for text in all_texts[1:]:
                    for word in text.split():
                        if word not in combined_text and len(word) > 2:
                            combined_text += " " + word
            
            return combined_text if combined_text else "No text detected"
            
        except Exception as e:
            print(f"Error extracting text: {e}")
            return f"OCR Error: {str(e)}"
            new_width = int(width * scale)
            thresh = cv2.resize(thresh, (new_width, 1000), interpolation=cv2.INTER_CUBIC)
        
        return thresh
    
    def extract_text(self, image_path):
        """
        Extract text from receipt using Tesseract OCR
        """
        try:
            # Preprocess image
            processed_image = self.preprocess_image(image_path)
            
            # Convert numpy array to PIL Image
            pil_image = Image.fromarray(processed_image)
            
            # Perform OCR
            text = pytesseract.image_to_string(
                pil_image,
                config='--psm 6'  # Assume a single uniform block of text
            )
            
            return text
        except Exception as e:
            raise Exception(f"OCR extraction failed: {str(e)}")
    
    
    def extract_structured_data(self, text):
        """
        Enhanced structured data extraction from OCR text
        Returns: store, items, amount, date with improved parsing
        """
        result = {
            'store': 'Unknown Store',
            'items': [],
            'amount': 0.0,
            'date': datetime.now().strftime('%Y-%m-%d'),
            'tax': 0.0,
            'confidence': 'medium'
        }
        
        if not text or text == "No text detected":
            result['confidence'] = 'low'
            return result
        
        lines = text.split('\n')
        lines = [line.strip() for line in lines if line.strip() and len(line.strip()) > 1]
        
        # Enhanced store name extraction
        store_patterns = [
            r'(walmart|target|costco|kroger|safeway|publix|meijer|aldi)',
            r'([A-Z][A-Za-z\s]{2,20})\s*(store|market|shop|mart)',
            r'^([A-Z\s]{3,25})$'  # All caps short lines (often store names)
        ]
        
        for line in lines[:5]:  # Check first 5 lines for store name
            for pattern in store_patterns:
                match = re.search(pattern, line, re.IGNORECASE)
                if match:
                    result['store'] = match.group(1).title()
                    break
            if result['store'] != 'Unknown Store':
                break
        
        # Enhanced amount extraction with multiple patterns
        amount_patterns = [
            r'total[:\s]*\$?([0-9]+\.?[0-9]*)',
            r'amount[:\s]*\$?([0-9]+\.?[0-9]*)',
            r'subtotal[:\s]*\$?([0-9]+\.?[0-9]*)',
            r'\$([0-9]+\.[0-9]{2})',  # Standard currency format
            r'([0-9]+\.[0-9]{2})',    # Decimal amounts
        ]
        
        amounts_found = []
        for line in lines:
            for pattern in amount_patterns:
                matches = re.findall(pattern, line, re.IGNORECASE)
                for match in matches:
                    try:
                        amount = float(match)
                        if 0.01 <= amount <= 10000:  # Reasonable range
                            amounts_found.append(amount)
                    except ValueError:
                        continue
        
        # Use the largest reasonable amount as total
        if amounts_found:
            result['amount'] = max(amounts_found)
            result['confidence'] = 'high' if len(amounts_found) >= 2 else 'medium'
        
        # Enhanced date extraction
        date_patterns = [
            r'(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})',
            r'(\d{2,4}[/-]\d{1,2}[/-]\d{1,2})',
            r'(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s*\d{1,2},?\s*\d{2,4}',
        ]
        
        for line in lines:
            for pattern in date_patterns:
                match = re.search(pattern, line, re.IGNORECASE)
                if match:
                    try:
                        date_str = match.group(1)
                        # Try to parse various date formats
                        for fmt in ['%m/%d/%Y', '%m-%d-%Y', '%Y/%m/%d', '%Y-%m-%d', '%m/%d/%y', '%m-%d-%y']:
                            try:
                                parsed_date = datetime.strptime(date_str, fmt)
                                result['date'] = parsed_date.strftime('%Y-%m-%d')
                                break
                            except ValueError:
                                continue
                        break
                    except:
                        continue
            if result['date'] != datetime.now().strftime('%Y-%m-%d'):
                break
        
        # Enhanced item extraction
        item_patterns = [
            r'([A-Za-z\s]{3,30})\s+([0-9]+\.?[0-9]*)',  # Item name + price
            r'^([A-Z\s]{3,20})\s*$',  # All caps lines (potential items)
            r'(\w+\s+\w+)\s+\$?([0-9]+\.[0-9]{2})',    # Two words + price
        ]
        
        for line in lines:
            # Skip lines that look like headers or totals
            if any(word in line.lower() for word in ['total', 'subtotal', 'tax', 'change', 'credit', 'cash', 'thank you']):
                continue
                
            for pattern in item_patterns:
                match = re.search(pattern, line)
                if match:
                    item_name = match.group(1).strip()
                    if len(item_name) >= 3 and not re.match(r'^\d+$', item_name):
                        price = 0.0
                        if len(match.groups()) > 1:
                            try:
                                price = float(match.group(2))
                            except:
                                price = 0.0
                        result['items'].append({
                            'name': item_name.title(),
                            'price': price
                        })
                        break
        
        # Remove duplicate items
        seen_items = set()
        unique_items = []
        for item in result['items']:
            if item['name'] not in seen_items:
                seen_items.add(item['name'])
                unique_items.append(item)
        
        result['items'] = unique_items[:10]  # Limit to 10 items
        
        # Adjust confidence based on extracted data quality
        confidence_score = 0
        if result['store'] != 'Unknown Store':
            confidence_score += 25
        if result['amount'] > 0:
            confidence_score += 30
        if result['items']:
            confidence_score += 25
        if result['date'] != datetime.now().strftime('%Y-%m-%d'):
            confidence_score += 20
        
        if confidence_score >= 70:
            result['confidence'] = 'high'
        elif confidence_score >= 40:
            result['confidence'] = 'medium'
        else:
            result['confidence'] = 'low'
        
        return result
        
        # Extract store name (usually first non-empty line)
        if lines:
            result['store'] = lines[0][:100]  # Limit to 100 chars
        
        # Extract amount (look for currency patterns)
        amount_patterns = [
            r'\$?\s*(\d+[,.]?\d*\.?\d+)',  # $123.45 or 123.45
            r'total[:\s]*\$?\s*(\d+[,.]?\d*\.?\d+)',  # Total: 123.45
            r'amount[:\s]*\$?\s*(\d+[,.]?\d*\.?\d+)',  # Amount: 123.45
        ]
        
        for line in lines:
            line_lower = line.lower()
            for pattern in amount_patterns:
                match = re.search(pattern, line_lower)
                if match:
                    amount_str = match.group(1).replace(',', '')
                    try:
                        amount = float(amount_str)
                        if amount > result['amount']:  # Take the largest amount
                            result['amount'] = amount
                    except ValueError:
                        pass
        
        # Extract date
        date_patterns = [
            r'(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})',  # MM/DD/YYYY or DD-MM-YYYY
            r'(\d{4}[/-]\d{1,2}[/-]\d{1,2})',    # YYYY-MM-DD
        ]
        
        for line in lines:
            for pattern in date_patterns:
                match = re.search(pattern, line)
                if match:
                    date_str = match.group(1)
                    try:
                        # Try different date formats
                        for fmt in ['%m/%d/%Y', '%d-%m-%Y', '%Y-%m-%d', '%m/%d/%y']:
                            try:
                                parsed_date = datetime.strptime(date_str, fmt)
                                result['date'] = parsed_date.strftime('%Y-%m-%d')
                                break
                            except ValueError:
                                continue
                    except Exception:
                        pass
        
        # Extract items (look for item-like patterns)
        # This is a simple heuristic - could be improved
        item_keywords = ['milk', 'bread', 'eggs', 'coffee', 'tea', 'juice', 'water']
        for line in lines:
            line_lower = line.lower()
            # Skip lines with amounts or dates
            if re.search(r'\$|\d+\.\d{2}', line) or re.search(r'\d{1,2}[/-]\d{1,2}', line):
                continue
            # Check if line contains common item keywords or looks like an item
            if any(keyword in line_lower for keyword in item_keywords) or (len(line.split()) <= 4 and len(line) > 3):
                if line not in [result['store']] and len(result['items']) < 10:
                    result['items'].append(line)
        
        return result
    
    def process_receipt(self, image_path):
        """
        Enhanced OCR pipeline: preprocess -> extract -> structure
        """
        try:
            print(f"Processing receipt: {image_path}")
            
            # Extract text with improved OCR
            raw_text = self.extract_text(image_path)
            print(f"Extracted text: {raw_text[:200]}...")  # First 200 chars for debug
            
            # Extract structured data with enhanced parsing
            structured_data = self.extract_structured_data(raw_text)
            
            # Add processing metadata
            structured_data['raw_text'] = raw_text
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
