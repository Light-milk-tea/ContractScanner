#!/usr/bin/env python3
from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from app.rag.retriever import KnowledgeRetriever


def main() -> None:
    retriever = KnowledgeRetriever()
    count = retriever.rebuild_index()
    print(f"Indexed {count} documents using embedding mode={retriever.embedding_mode}")
    print(f"Chroma path: {ROOT / 'data' / 'chroma'}")


if __name__ == "__main__":
    main()
