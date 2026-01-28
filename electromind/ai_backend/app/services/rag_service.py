import os
import google.generativeai as genai
from supabase import create_client, Client
from dotenv import load_dotenv
import logging

load_dotenv()

# Configurar logs
logger = logging.getLogger(__name__)

# Configurar Supabase
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY") # Preferiblemente Service Role Key para escritura

supabase: Client = None

if SUPABASE_URL and SUPABASE_KEY:
    try:
        supabase = create_client(SUPABASE_URL, SUPABASE_KEY)
    except Exception as e:
        logger.error(f"Error inicializando Supabase: {e}")

# Configurar Gemini (ya configurado en llm_service, pero aseguramos la key)
GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY")
if GOOGLE_API_KEY:
    genai.configure(api_key=GOOGLE_API_KEY)

EMBEDDING_MODEL = "models/embedding-001"

async def generate_embedding(text: str) -> list[float]:
    """Genera un embedding vectorial para el texto dado usando Gemini."""
    try:
        # Limpiar texto (saltos de línea excesivos, etc)
        text = text.replace("\n", " ")
        
        result = genai.embed_content(
            model=EMBEDDING_MODEL,
            content=text,
            task_type="retrieval_document",
            title="Electromind Knowledge"
        )
        return result['embedding']
    except Exception as e:
        logger.error(f"Error generando embedding: {e}")
        raise e

async def store_knowledge(content: str, metadata: dict, source_type: str = "manual"):
    """
    Genera embedding y guarda el fragmento en Supabase 'knowledge_base'.
    """
    if not supabase:
        raise Exception("Supabase no está configurado (Faltan keys en .env)")

    try:
        embedding = await generate_embedding(content)
        
        data = {
            "content_chunk": content,
            "metadata": metadata,
            "source_type": source_type,
            "embedding": embedding,
            # source_id opcional si vinculamos con documents table
        }
        
        response = supabase.table("knowledge_base").insert(data).execute()
        return response
    except Exception as e:
        logger.error(f"Error guardando en vector DB: {e}")
        raise e

async def search_knowledge(query: str, match_threshold: float = 0.7, match_count: int = 5):
    """
    Busca contexto relevante para la query usando RPC 'match_knowledge'.
    """
    if not supabase:
        logger.warning("Supabase no configurado, retornando lista vacía.")
        return []

    try:
        # Embedding de la consulta (task_type retrieval_query es mejor para preguntas)
        query_embedding_result = genai.embed_content(
            model=EMBEDDING_MODEL,
            content=query,
            task_type="retrieval_query"
        )
        query_vector = query_embedding_result['embedding']
        
        # Llamar a la función RPC de Postgres (definida en Fase 1)
        params = {
            "query_embedding": query_vector,
            "match_threshold": match_threshold,
            "match_count": match_count
        }
        
        response = supabase.rpc("match_knowledge", params).execute()
        
        # Devolver una lista de textos encontrados
        matches = []
        if response.data:
            for item in response.data:
                matches.append(item['content_chunk'])
                
        return matches

    except Exception as e:
        logger.error(f"Error buscando en knowledge base: {e}")
        return []
