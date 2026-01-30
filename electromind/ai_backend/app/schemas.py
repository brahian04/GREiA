from pydantic import BaseModel
from typing import Optional, List, Dict

class ChatRequest(BaseModel):
    message: str
    context: Optional[str] = None
    history: Optional[List[Dict[str, str]]] = [] # List of {"role": "user"|"model", "content": "..."}

class ChatResponse(BaseModel):
    reply: str
    action: Optional[str] = None # Ejemplo: "register_ticket"
    action_data: Optional[Dict] = None # Datos para la acción

class TicketRegistration(BaseModel):
    client_name: str
    phone: str
    device_type: str
    brand: str
    model: str
    problem_description: str
