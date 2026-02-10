"""
Manual OCR test script to check what response we're getting from OCR.space API
"""
import os
import sys
from pathlib import Path

# Add parent directory to path to import app modules
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.services.ocr_service import OCRService

# Set OCR.space API key for testing
os.environ['OCRSPACE_API_KEY'] = 'K89677956988957'

def test_ocr_with_bill_image():
    """Test OCR with the bill.jpg image"""
    
    # Path to the bill image
    bill_image_path = Path(__file__).parent.parent / 'bill.jpg'
    
    if not bill_image_path.exists():
        print(f"❌ Error: Image file not found at {bill_image_path}")
        return
    
    print(f"📄 Testing OCR with image: {bill_image_path}")
    print(f"📏 File size: {bill_image_path.stat().st_size / 1024:.2f} KB")
    print("="*70)
    
    # Initialize OCR service
    ocr_service = OCRService()
    
    if not ocr_service.available:
        print("❌ OCR Service not available - OCR.space API key not configured")
        print("\nPlease ensure OCRSPACE_API_KEY is set in .env file")
        return
    
    print("✅ OCR Service initialized successfully")
    print("="*70)
    
    # Process the receipt
    try:
        print("\n🔄 Processing receipt...")
        result = ocr_service.process_receipt(str(bill_image_path))
        
        print("\n" + "="*70)
        print("📊 OCR RESULT:")
        print("="*70)
        
        print(f"\n🏪 Store: {result.get('store', 'N/A')}")
        print(f"💰 Amount: {result.get('amount', 'N/A')}")
        print(f"📅 Date: {result.get('date', 'N/A')}")
        print(f"📋 Items: {result.get('items', [])}")
        print(f"🔧 OCR Provider: {result.get('ocr_provider', 'N/A')}")
        print(f"🌐 OCR Mode: {result.get('ocr_mode', 'N/A')}")
        print(f"✓ Available: {result.get('available', 'N/A')}")
        print(f"📊 Status: {result.get('processing_status', 'N/A')}")
        
        if 'error' in result:
            print(f"\n❌ Error: {result['error']}")
        
        if 'raw_text' in result and result['raw_text']:
            print(f"\n📝 Raw OCR Text:")
            print("-"*70)
            print(result['raw_text'])
            print("-"*70)
        
        print("\n" + "="*70)
        print("✅ TEST COMPLETED")
        print("="*70)
        
    except Exception as e:
        print(f"\n❌ Error processing receipt: {str(e)}")
        import traceback
        print("\n🔍 Full traceback:")
        traceback.print_exc()

if __name__ == '__main__':
    test_ocr_with_bill_image()
