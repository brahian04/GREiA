import asyncio
from fastapi import APIRouter, UploadFile, File, HTTPException
from app.services.pdf_parser import extract_text_from_pdf, chunk_text
from app.services.rag_service import store_knowledge
import logging

router = APIRouter()
logger = logging.getLogger(__name__)

@router.post("/ingest/pdf")
async def ingest_pdf(file: UploadFile = File(...)):
    """
    Sube un PDF, extrae el texto, lo divide en chunks y genera embeddings.
    """
    if not file.filename.endswith('.pdf'):
        raise HTTPException(status_code=400, detail="File must be a PDF")

    try:
        content = await file.read()
        text = extract_text_from_pdf(content)
        
        if not text:
            raise HTTPException(status_code=400, detail="Could not extract text from PDF")

        chunks = chunk_text(text)
        
        saved_count = 0
        for i, chunk in enumerate(chunks):
            metadata = {
                "source": file.filename,
                "chunk_index": i,
                "total_chunks": len(chunks)
            }
            try:
                await store_knowledge(chunk, metadata, source_type="manual")
                saved_count += 1
                
                # Rate Limiting: Pausa de 4 segundos para respetar el límite de 15 RPM (Free Tier)
                if i < len(chunks) - 1: # No esperar en el último
                    await asyncio.sleep(4)
                    
            except Exception as e:
                logger.error(f"Error storing chunk {i}: {e}")
                # Continue preventing total failure if one chunk fails
                continue
                
        return {
            "message": f"Successfully processed {file.filename}",
            "chunks_created": len(chunks),
            "chunks_stored": saved_count
        }

    except Exception as e:
        logger.error(f"Error during ingestion: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/ingest/solution")
async def ingest_solution(
    solution_text: str,
    ticket_id: str,
    device_model: str,
    category: str = "repair_guide"
):
    """
    Ingesta una solución técnica de un ticket cerrado manualmente.
    Esto permite que la IA aprenda de las reparaciones exitosas.
    """
    if not solution_text or len(solution_text) < 10:
         raise HTTPException(status_code=400, detail="Solution text too short")

    try:
        # Formatear el contenido para que tenga contexto
        content = f"DISPOSITIVO: {device_model}\nCATEGORÍA: {category}\nSOLUCIÓN TÉCNICA: {solution_text}"
        
        metadata = {
            "source": f"ticket_{ticket_id}",
            "device_model": device_model,
            "type": "ticket_solution"
        }

        # Guardar en knowledge base
        await store_knowledge(content, metadata, source_type="ticket_solution")
        
        return {
            "message": "Solution ingested successfully",
            "ticket_id": ticket_id
        }
    except Exception as e:
        logger.error(f"Error ingesting solution for ticket {ticket_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))
