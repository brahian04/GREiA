import os
import google.generativeai as genai
from dotenv import load_dotenv
import logging

# Configurar logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Cargar variables de entorno
load_dotenv()

api_key = os.getenv("GOOGLE_API_KEY")

if not api_key:
    logger.warning("GOOGLE_API_KEY no encontrada en variables de entorno.")
else:
    genai.configure(api_key=api_key)

from typing import Dict, Any

def generate_ai_response(message: str, context: str = None) -> Dict[str, Any]:
    """
    Genera una respuesta utilizando Gemini Pro.
    """
    if not api_key:
        return "Error de configuración: API Key de Google no encontrada. Por favor configura el backend."

    try:
        # Definir la personalidad del asistente
        system_instruction = (
            "Eres Electromind AI, un asistente experto y técnico especializado en reparación de dispositivos electrónicos "
            "(celulares, tablets, laptops, consolas). "
            "Tu objetivo es ayudar a los técnicos a diagnosticar fallas, sugerir soluciones, encontrar repuestos "
            "y estimar tiempos o costos. "
            "Sé preciso, técnico pero claro, y usa un tono profesional y amable. "
            "Si te dan un contexto de un ticket, úsalo para dar una respuesta específica."
        )

        # Definir la herramienta de registro
        register_ticket_tool = {
            "function_declarations": [
                {
                    "name": "register_ticket",
                    "description": "Registers a new repair ticket when the user provides all necessary device and client information.",
                    "parameters": {
                        "type": "OBJECT",
                        "properties": {
                            "client_name": {"type": "STRING", "description": "Full name of the client"},
                            "phone": {"type": "STRING", "description": "Phone number or WhatsApp"},
                            "device_type": {"type": "STRING", "description": "Type of device (Smartphone, Laptop, Tablet, TV, Consola, Otro)"},
                            "brand": {"type": "STRING", "description": "Device brand"},
                            "model": {"type": "STRING", "description": "Device model"},
                            "problem_description": {"type": "STRING", "description": "Detailed description of the problem (minimum 10 chars)"}
                        },
                        "required": ["client_name", "phone", "device_type", "brand", "model", "problem_description"]
                    }
                }
            ]
        }

        model = genai.GenerativeModel('gemini-flash-latest', tools=[register_ticket_tool])
        
        # Construir el prompt completo
        prompt_parts = [system_instruction]
        
        if context:
            prompt_parts.append(f"\nCONTEXTO DEL TICKET/SITUACIÓN:\n{context}")
            
        prompt_parts.append(f"\nCONSULTA DEL TÉCNICO:\n{message}")
        
        full_prompt = "\n".join(prompt_parts)
        
        logger.info(f"Enviando prompt a Gemini: {full_prompt[:100]}...")

        response = model.generate_content(full_prompt)
        
        # Verificar bloqueo
        if response.prompt_feedback and response.prompt_feedback.block_reason:
            return {"text": f"Bloqueado: {response.prompt_feedback.block_reason}", "action": None}

        # Verificar llamadas a funciones
        if response.parts:
            for part in response.parts:
                if part.function_call and part.function_call.name == "register_ticket":
                    fc = part.function_call
                    return {
                        "text": "He capturado los datos. Por favor confirma el registro en la pantalla.",
                        "action": "register_ticket",
                        "action_data": {
                            "client_name": fc.args.get("client_name"),
                            "phone": fc.args.get("phone"),
                            "device_type": fc.args.get("device_type"),
                            "brand": fc.args.get("brand"),
                            "model": fc.args.get("model"),
                            "problem_description": fc.args.get("problem_description"),
                        }
                    }

        return {"text": response.text, "action": None}
                         
    except Exception as e:
        print(f"-------- CRITICAL AI ERROR --------: {e}") 
        logger.error(f"Error generando respuesta AI: {e}")
        return {"text": f"Error interno: {str(e)}", "action": None}
