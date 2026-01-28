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
