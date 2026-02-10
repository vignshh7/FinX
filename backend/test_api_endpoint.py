"""
Test the OCR upload endpoint to verify it's working
"""
import requests
import os
from pathlib import Path

# First, login to get a token
def get_auth_token():
    """Login and get auth token"""
    response = requests.post(
        'http://127.0.0.1:5000/api/register',
        json={
            'name': 'Test User',
            'email': 'test@example.com',
            'password': 'test123'
        }
    )
    
    if response.status_code == 201:
        data = response.json()
        return data.get('access_token') or data.get('token')
    
    # If user exists, try login
    response = requests.post(
        'http://127.0.0.1:5000/api/login',
        json={
            'email': 'test@example.com',
            'password': 'test123'
        }
    )
    
    if response.status_code == 200:
        data = response.json()
        return data.get('access_token') or data.get('token')
    
    raise Exception(f'Failed to get auth token: {response.text}')

def test_upload_receipt():
    """Test uploading a receipt"""
    
    # Get auth token
    print("Getting auth token...")
    token = get_auth_token()
    print(f"✓ Got token: {token[:20]}...")
    
    # Path to test image
    image_path = Path(__file__).parent.parent / 'bill.jpg'
    
    if not image_path.exists():
        print(f"❌ Image not found: {image_path}")
        return
    
    print(f"\nUploading receipt: {image_path}")
    
    # Upload receipt
    with open(image_path, 'rb') as f:
        files = {'receipt': ('bill.jpg', f, 'image/jpeg')}
        headers = {'Authorization': f'Bearer {token}'}
        
        response = requests.post(
            'http://127.0.0.1:5000/api/upload-receipt',
            files=files,
            headers=headers
        )
    
    print(f"\nResponse Status: {response.status_code}")
    print(f"Response Headers: {response.headers}")
    print(f"\nResponse Body:")
    print(response.text)
    
    if response.status_code == 200:
        data = response.json()
        print("\n✓ SUCCESS!")
        print(f"Store: {data.get('store')}")
        print(f"Amount: {data.get('amount')}")
        print(f"Date: {data.get('date')}")
        print(f"Category: {data.get('predicted_category')}")
        print(f"OCR Provider: {data.get('ocr_provider')}")
    else:
        print(f"\n❌ FAILED")
        try:
            error_data = response.json()
            print(f"Error: {error_data}")
        except:
            print(f"Raw error: {response.text}")

if __name__ == '__main__':
    test_upload_receipt()
