from fastapi import APIRouter, HTTPException
from app.schemas import ChatRequest, ChatResponse
from app.services.llm_service import generate_ai_response
from app.services.rag_service import search_knowledge
import logging

logger = logging.getLogger(__name__)

router = APIRouter()

@router.post("/chat", response_model=ChatResponse)
async def chat_endpoint(request: ChatRequest):
    """
    Recibe un mensaje y un contexto opcional, y devuelve la respuesta de la IA.
    Ahora busca info en la base de conocimientos (RAG).
    """
    try:
        # 1. Buscar contexto relevante en la base de conocimientos
        relevant_docs = await search_knowledge(request.message)
        
        context_text = ""
        if relevant_docs:
            context_text = "\n\n".join(relevant_docs)
            logger.info(f"Found {len(relevant_docs)} relevant docs for query")
        
        # 2. Combinar contexto explícito (si viene del request) con el encontrado
        full_context = ""
        if request.context:
            full_context += f"Contexto de la App:\n{request.context}\n\n"
        
        if context_text:
            full_context += f"Información de Manuales/Base de Conocimiento:\n{context_text}"

        # 3. Generar respuesta
        # Nota: generate_ai_response es sincrono, idealmente hacerlo async o en threadpool
        reply = generate_ai_response(request.message, context=full_context)
        return ChatResponse(reply=reply)
    except Exception as e:
        logger.error(f"Error in chat endpoint: {e}")
        raise HTTPException(status_code=500, detail=str(e))
