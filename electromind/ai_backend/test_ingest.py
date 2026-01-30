import requests
from reportlab.pdfgen import canvas
import os
import sys

# Configuration
API_URL = "http://localhost:8000/api/v1/ingest/pdf"
TEST_PDF_NAME = "test_manual.pdf"

def create_dummy_pdf():
    """Create a simple PDF with test content."""
    print(f"Creating dummy PDF: {TEST_PDF_NAME}...")
    c = canvas.Canvas(TEST_PDF_NAME)
    c.drawString(100, 750, "Electromind Test Manual")
    c.drawString(100, 730, "This is a test document for the RAG system.")
    c.drawString(100, 710, "Error Code 404: Device not found.")
    c.drawString(100, 690, "Solution: Restart the system and check connections.")
    c.save()
    print("PDF created successfully.")

def test_ingestion():
    """Upload functionality test."""
    if not os.path.exists(TEST_PDF_NAME):
        create_dummy_pdf()

    print(f"Uploading {TEST_PDF_NAME} to {API_URL}...")
    
    try:
        with open(TEST_PDF_NAME, 'rb') as f:
            files = {'file': (TEST_PDF_NAME, f, 'application/pdf')}
            response = requests.post(API_URL, files=files)
            
        print(f"Status Code: {response.status_code}")
        if response.status_code == 200:
            print("Response:", response.json())
            print("\n✅ SUCCESS: PDF ingested successfully!")
        else:
            print("Response:", response.text)
            print("\n❌ FAILED: Server returned an error.")
            
    except requests.exceptions.ConnectionError:
        print(f"\n❌ ERROR: Could not connect to {API_URL}")
        print("Make sure the backend server is running using: uvicorn app.main:app --reload")

if __name__ == "__main__":
    # Check if reportlab is installed
    try:
        import reportlab
    except ImportError:
        print("Installing required library 'reportlab' for generating PDF...")
        import subprocess
        subprocess.check_call([sys.executable, "-m", "pip", "install", "reportlab", "requests"])
        print("Dependencies installed.\n")

    test_ingestion()
