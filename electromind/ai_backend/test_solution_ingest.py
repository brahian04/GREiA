import requests
import uuid

API_URL = "http://localhost:8000/api/v1/ingest/solution"

def test_solution_ingestion():
    """Test ingestion of a technical solution."""
    
    # Datos de prueba simulando un ticket cerrado
    payload = {
        "solution_text": "Se reemplazó el condensador C402 de la placa principal y se resoldó el puerto de carga. El dispositivo carga correctamente a 1.5A.",
        "ticket_id": str(uuid.uuid4()),
        "device_model": "Samsung Galaxy S21",
        "category": "power_issue"
    }
    
    print(f"Sending solution for {payload['device_model']}...")
    
    try:
        response = requests.post(API_URL, params=payload) 
        # Nota: FastAPI recibe query params por defecto si no se define Pydantic model. 
        # En mi implementacin us argumentos de funcin, que son query params por defecto.
        # Ajustemos si es necesario, pero probemos as.
        
        if response.status_code == 200:
            print("Response:", response.json())
            print("\n✅ SUCCESS: Solution ingested successfully!")
        else:
            print(f"Status Code: {response.status_code}")
            with open("last_error.txt", "w", encoding="utf-8") as f:
                f.write(response.text)
            print("❌ FAILED: Error details saved to last_error.txt")
            
    except requests.exceptions.ConnectionError:
        print(f"\n❌ ERROR: Could not connect to {API_URL}")

if __name__ == "__main__":
    test_solution_ingestion()
