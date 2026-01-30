import os
import google.generativeai as genai
from dotenv import load_dotenv
import logging
import asyncio
from functools import wraps

# Configurar logging
logger = logging.getLogger(__name__)

# Cargar variables de entorno
load_dotenv()

api_key = os.getenv("GOOGLE_API_KEY")

if not api_key:
    logger.warning("GOOGLE_API_KEY no encontrada en variables de entorno.")
else:
    genai.configure(api_key=api_key)

def retry_with_backoff(retries=3, backoff_in_seconds=2):
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            x = 0
            while True:
                try:
                    # Si la funcion es sincrona, la envolvemos. Pero mejor hacerla async.
                    if asyncio.iscoroutinefunction(func):
                        return await func(*args, **kwargs)
                    else:
                        return func(*args, **kwargs)
                except Exception as e:
                    if "429" in str(e) and x < retries:
                        sleep_time = (backoff_in_seconds * (2 ** x))
                        logger.warning(f"Gemini LLM Rate Limit (429). Retrying in {sleep_time}s... (Attempt {x+1}/{retries})")
                        await asyncio.sleep(sleep_time)
                        x += 1
                    else:
                        raise e
        return wrapper
    return decorator

from typing import Dict, Any

@retry_with_backoff(retries=2)
async def generate_ai_response(message: str, context: str = None) -> Dict[str, Any]:
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
                },
                {
                    "name": "list_tickets",
                    "description": "Search and list tickets from the database based on status, client name, or general filters.",
                    "parameters": {
                        "type": "OBJECT",
                        "properties": {
                            "status": {"type": "STRING", "description": "Filter by status: 'pendiente', 'revision', 'reparando', 'terminado', 'entregado'"},
                            "client_name": {"type": "STRING", "description": "Filter by client name (partial match)"},
                            "limit": {"type": "INTEGER", "description": "Max number of tickets to return (default 5)"}
                        }
                    }
                }
            ]
        }

        model = genai.GenerativeModel('gemini-2.5-flash', tools=[register_ticket_tool])
        
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
                if part.function_call:
                    fc = part.function_call
                    
                    if fc.name == "register_ticket":
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
                    
                    elif fc.name == "list_tickets":
                        # 1. Ejecutar la herramienta
                        tool_result = await _handle_list_tickets(fc.args)
                        tickets_info = tool_result["text"]
                        
                    elif fc.name == "list_tickets":
                        # 1. Ejecutar la herramienta
                        tool_result = await _handle_list_tickets(fc.args)
                        tickets_info = tool_result["text"]
                        
                        # 2. Optimización de Cuota (20 RPD Limit):
                        # Devolvemos el resultado directo sin re-procesar por la IA para ahorrar 1 llamada.
                        # El cliente recibirá el texto formateado por la función python.
                        logger.info("Herramienta list_tickets ejecutada. Retornando resultado directo para ahorrar cuota.")
                        
                        return {"text": tickets_info, "action": None}

        return {"text": response.text, "action": None}
                         
    except Exception as e:
        print(f"-------- CRITICAL AI ERROR --------: {e}") 
        logger.error(f"Error generando respuesta AI: {e}")
        return {"text": f"Error interno: {str(e)}", "action": None}

# Helper para ejecutar la consulta de tickets
from supabase import create_client

async def _handle_list_tickets(args):
    try:
        url = os.environ.get("SUPABASE_URL")
        key = os.environ.get("SUPABASE_KEY")
        supabase = create_client(url, key)

        query = supabase.table("tickets").select("id, human_id, device_type, brand, model, status, problem_description, clients(full_name)")
        
        if "status" in args:
            query = query.eq("status", args["status"])
        
        if "client_name" in args:
            # Busqueda en tabla relacionada es compleja en supabase-py simple, 
            # hacemos filtro post-fetch o asumimos búsqueda exacta. 
            # Por simplicidad en este MVP, filtraremos solo por status o traeremos los ultimos.
            pass 

        # Ordenar por fecha de creación descendente
        query = query.order("created_at", desc=True)
        
        limit = args.get("limit", 5)
        query = query.limit(limit)

        result = query.execute()
        
        tickets = result.data
        if not tickets:
            return {"text": "No encontré tickets con esos criterios.", "action": None}

        # Formatear respuesta para que la IA la presente
        # Nota: Como es una function calling, idealmente deberíamos alimentar esto DE VUELTA a la IA.
        # Pero para este MVP, devolveremos el texto formateado directamente.
        
        summary = "📋 **Resultados de la búsqueda:**\n\n"
        for t in tickets:
            client_name = t.get('clients', {}).get('full_name', 'Sin Cliente')
            summary += (
                f"**Ticket #{t['human_id']}**\n"
                f"- Dispositivo: {t['device_type']} {t['brand']} {t['model']}\n"
                f"- Cliente: {client_name}\n"
                f"- Estado: *{t['status']}*\n"
                f"- Falla: {t['problem_description']}\n\n"
            )
        
        summary += "\n*Nota: Mostrando los últimos resultados encontrados.*"
        return {"text": summary, "action": None}

    except Exception as e:
        logger.error(f"Error listing tickets: {e}")
        return {"text": "Hubo un error consultando la base de datos.", "action": None}
