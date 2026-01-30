import google.generativeai as genai
import os
from dotenv import load_dotenv
import time

load_dotenv()
api_key = os.getenv("GOOGLE_API_KEY")
genai.configure(api_key=api_key)

MODEL_NAME = 'gemini-2.0-flash-001'

print(f"Probing {MODEL_NAME}...")
try:
    model = genai.GenerativeModel(MODEL_NAME)
    response = model.generate_content("Hello, are you working?")
    print(f"Success! Response: {response.text}")
except Exception as e:
    print(f"Failed: {e}")
