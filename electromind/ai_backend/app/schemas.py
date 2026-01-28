from pydantic import BaseModel
from typing import Optional, List, Dict

class ChatRequest(BaseModel):
    message: str
    context: Optional[str] = None
    history: Optional[List[Dict[str, str]]] = [] # List of {"role": "user"|"model", "content": "..."}

class ChatResponse(BaseModel):
    reply: str
