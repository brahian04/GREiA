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

def generate_ai_response(message: str, context: str = None) -> str:
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

        model = genai.GenerativeModel('gemini-flash-latest')
        
        # Construir el prompt completo
        prompt_parts = [system_instruction]
        
        if context:
            prompt_parts.append(f"\nCONTEXTO DEL TICKET/SITUACIÓN:\n{context}")
            
        prompt_parts.append(f"\nCONSULTA DEL TÉCNICO:\n{message}")
        
        full_prompt = "\n".join(prompt_parts)
        
        logger.info(f"Enviando prompt a Gemini: {full_prompt[:100]}...")

        response = model.generate_content(full_prompt)
        
        # Verificar si la respuesta fue bloqueada o es nula
        if response.prompt_feedback and response.prompt_feedback.block_reason:
            return f"La consulta fue bloqueada por seguridad: {response.prompt_feedback.block_reason}"
            
        return response.text
    except Exception as e:
        print(f"-------- CRITICAL AI ERROR --------: {e}") 
        logger.error(f"Error generando respuesta AI: {e}")
        return f"Error interno: {str(e)}"
