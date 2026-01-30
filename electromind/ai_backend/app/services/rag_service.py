import os
import google.generativeai as genai
from supabase import create_client, Client
from dotenv import load_dotenv
import logging

load_dotenv()

# Configurar logs
logger = logging.getLogger(__name__)

# Configurar Supabase globals
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")
supabase: Client = None

def get_supabase_client():
    global supabase
    if supabase:
        return supabase
        
    SUPABASE_URL = os.getenv("SUPABASE_URL")
    SUPABASE_KEY = os.getenv("SUPABASE_KEY")
    
    if not SUPABASE_URL or not SUPABASE_KEY:
        logger.error("Supabase credentials missing in .env")
        return None
        
    try:
        supabase = create_client(SUPABASE_URL, SUPABASE_KEY)
        return supabase
    except Exception as e:
        logger.error(f"Error initializing Supabase client: {e}")
        return None

# Configurar Gemini
GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY")
if GOOGLE_API_KEY:
    try:
        genai.configure(api_key=GOOGLE_API_KEY)
    except Exception as e:
        logger.error(f"Error configuring Gemini: {e}")

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
    Verifica duplicados antes de guardar (Similitud > 0.95).
    """
    client = get_supabase_client()
    if not client:
        # Intenta recargar .env por si acaso
        load_dotenv()
        client = get_supabase_client()
        if not client:
            raise Exception("Supabase no está configurado (Error de cliente o faltan keys)")

    try:
        # 1. Generar Embedding
        embedding = await generate_embedding(content)
        
        # 2. Verificar Duplicados
        # Usamos la misma función RPC pero con un umbral muy alto (0.95)
        # para encontrar contenido prácticamente idéntico.
        duplicate_check_params = {
            "query_embedding": embedding,
            "match_threshold": 0.95, 
            "match_count": 1
        }
        
        potential_dupes = client.rpc("match_knowledge", duplicate_check_params).execute()
        
        if potential_dupes.data and len(potential_dupes.data) > 0:
            logger.info(f"Duplicate content detected (Similarity > 0.95). Skipping ingestion. Source: {metadata.get('source', 'unknown')}")
            return {
                "status": "skipped", 
                "reason": "duplicate_detected",
                "similar_id": potential_dupes.data[0]['id']
            }

        # 3. Guardar si no es duplicado
        data = {
            "content_chunk": content,
            "metadata": metadata,
            "source_type": source_type,
            "embedding": embedding,
            # source_id opcional si vinculamos con documents table
        }
        
        response = client.table("knowledge_base").insert(data).execute()
        return response
    except Exception as e:
        logger.error(f"Error guardando en vector DB: {e}")
        raise e

async def search_knowledge(query: str, match_threshold: float = 0.7, match_count: int = 5):
    """
    Busca contexto relevante para la query usando RPC 'match_knowledge'.
    """
    client = get_supabase_client()
    if not client:
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
        
        response = client.rpc("match_knowledge", params).execute()
        
        # Devolver una lista de textos encontrados
        matches = []
        if response.data:
            for item in response.data:
                matches.append(item['content_chunk'])
                
        return matches

    except Exception as e:
        logger.error(f"Error buscando en knowledge base: {e}")
        return []
