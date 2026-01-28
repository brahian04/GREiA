import pypdf
import io

def extract_text_from_pdf(file_bytes: bytes) -> str:
    """Extrae todo el texto de un PDF."""
    try:
        pdf = pypdf.PdfReader(io.BytesIO(file_bytes))
        text = ""
        for page in pdf.pages:
            text += page.extract_text() + "\n"
        return text
    except Exception as e:
        print(f"Error parsing PDF: {e}")
        return ""

def chunk_text(text: str, chunk_size: int = 1500, overlap: int = 200) -> list[str]:
    """
    Divide el texto en fragmentos (chunks) para que quepan en la ventana de contexto.
    Simple sliding window.
    """
    chunks = []
    start = 0
    text_len = len(text)
    
    while start < text_len:
        end = start + chunk_size
        chunk = text[start:end]
        chunks.append(chunk)
        # Avanzar el inicio, retrocediendo por el overlap
        start += chunk_size - overlap
        
    return chunks
