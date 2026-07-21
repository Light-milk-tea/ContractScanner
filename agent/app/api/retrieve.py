from __future__ import annotations

from fastapi import APIRouter, HTTPException

from app.rag.retriever import get_retriever
from app.schemas import HealthResponse, RetrieveRequest, RetrieveResponse

router = APIRouter()


@router.get("/health", response_model=HealthResponse)
def health() -> HealthResponse:
    retriever = get_retriever()
    return HealthResponse(
        status="ok",
        collectionCount=retriever.collection_count(),
        embeddingMode=retriever.embedding_mode,
    )


@router.post("/v1/retrieve", response_model=RetrieveResponse)
def retrieve(request: RetrieveRequest) -> RetrieveResponse:
    query = request.query.strip()
    if not query:
        raise HTTPException(status_code=400, detail="query is required")
    retriever = get_retriever()
    hits = retriever.retrieve(
        query=query,
        business_tag=request.businessTag,
        top_k=request.topK,
    )
    return RetrieveResponse(hits=hits)


@router.post("/v1/admin/rebuild")
def rebuild() -> dict:
    retriever = get_retriever()
    count = retriever.rebuild_index()
    return {
        "status": "ok",
        "indexed": count,
        "embeddingMode": retriever.embedding_mode,
    }
