from __future__ import annotations

import os
from contextlib import asynccontextmanager

from fastapi import FastAPI

from app.api.retrieve import router as retrieve_router
from app.rag.retriever import get_retriever


@asynccontextmanager
async def lifespan(_app: FastAPI):
    retriever = get_retriever()
    if retriever.collection_count() == 0:
        retriever.rebuild_index()
    yield


app = FastAPI(
    title="ContractScanner RAG Agent",
    version="0.1.0",
    lifespan=lifespan,
)
app.include_router(retrieve_router)


def run() -> None:
    import uvicorn

    host = os.environ.get("AGENT_HOST", "0.0.0.0")
    port = int(os.environ.get("AGENT_PORT", "8000"))
    uvicorn.run("app.main:app", host=host, port=port, reload=False)


if __name__ == "__main__":
    run()
