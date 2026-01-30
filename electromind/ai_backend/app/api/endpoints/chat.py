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
        ai_result = await generate_ai_response(request.message, context=full_context)
        
        reply_text = ""
        action = None
        action_data = None
        
        if isinstance(ai_result, dict):
            reply_text = ai_result.get("text", "")
            action = ai_result.get("action")
            action_data = ai_result.get("action_data")
        else:
            reply_text = str(ai_result)

        return ChatResponse(reply=reply_text, action=action, action_data=action_data)
    except Exception as e:
        logger.error(f"Error in chat endpoint: {e}")
        raise HTTPException(status_code=500, detail=str(e))
