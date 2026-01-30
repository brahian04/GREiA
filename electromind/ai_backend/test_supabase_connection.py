import os
from dotenv import load_dotenv
from supabase import create_client

def test_connection():
    load_dotenv()
    url = os.getenv("SUPABASE_URL")
    key = os.getenv("SUPABASE_KEY")
    
    print(f"URL: {url}")
    print(f"KEY: {key[:10]}..." if key else "None")
    
    if not url or not key:
        print("❌ Missing credentials in .env")
        return

    try:
        print("Connecting to Supabase...")
        supabase = create_client(url, key)
        print("Client created.")
        
        # Try a simple query
        print("Testing query...")
        response = supabase.table("knowledge_base").select("count", count="exact").execute()
        print("Query successful!")
        print("Response:", response)
        
    except Exception as e:
        print(f"❌ Connection failed: {e}")

if __name__ == "__main__":
    test_connection()
