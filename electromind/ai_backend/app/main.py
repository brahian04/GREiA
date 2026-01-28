from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(
    title="ElectroMind AI Backend",
    description="Microservice for AI/RAG operations using Gemini Pro",
    version="0.1.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

from app.api.endpoints import chat, ingest

app.include_router(chat.router, prefix="/api/v1", tags=["chat"])
app.include_router(ingest.router, prefix="/api/v1", tags=["ingest"])

@app.get("/")
def read_root():
    return {"message": "ElectroMind AI Brain is active 🧠"}

@app.get("/health")
def health_check():
    return {"status": "healthy"}
