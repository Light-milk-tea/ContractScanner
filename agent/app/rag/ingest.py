from __future__ import annotations

import json
from pathlib import Path
from typing import Iterable

from app.schemas import Citation, KnowledgeDoc


def agent_root() -> Path:
    return Path(__file__).resolve().parents[2]


def kb_root() -> Path:
    return agent_root() / "kb"


def chroma_dir() -> Path:
    path = agent_root() / "data" / "chroma"
    path.mkdir(parents=True, exist_ok=True)
    return path


def _load_json_array(path: Path) -> list[dict]:
    raw = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(raw, list):
        raise ValueError(f"Knowledge file must be a JSON array: {path}")
    return raw


def _parse_doc(raw: dict) -> KnowledgeDoc:
    citation_raw = raw.get("citation")
    citation = None
    if isinstance(citation_raw, dict):
        citation = Citation(
            law_name=str(citation_raw.get("law_name", "")).strip(),
            article_no=str(citation_raw.get("article_no", "")).strip(),
            text=str(citation_raw.get("text", "")).strip(),
        )
        if not citation.law_name or not citation.article_no or not citation.text:
            citation = None

    related = raw.get("related_law_ids") or []
    if not isinstance(related, list):
        related = []

    keywords = raw.get("keywords") or []
    if not isinstance(keywords, list):
        keywords = []

    return KnowledgeDoc(
        id=str(raw.get("id", "")).strip(),
        title=str(raw.get("title", "")).strip(),
        category=str(raw.get("category", "general")).strip() or "general",
        scenario=str(raw.get("scenario", "通用")).strip() or "通用",
        doc_type=raw.get("doc_type"),
        risk_level=raw.get("risk_level") or "INFO",
        content=str(raw.get("content", "")).strip(),
        keywords=[str(item).strip() for item in keywords if str(item).strip()],
        source=str(raw.get("source", "")).strip(),
        citation=citation,
        related_law_ids=[str(item).strip() for item in related if str(item).strip()],
    )


def iter_knowledge_files() -> Iterable[Path]:
    root = kb_root()
    patterns = [
        root / "risk_rules" / "*.json",
        root / "samples_annotated" / "*.json",
        root / "law_snippets" / "*.json",
    ]
    for pattern in patterns:
        yield from sorted(pattern.parent.glob(pattern.name))


def load_all_documents() -> list[KnowledgeDoc]:
    documents: list[KnowledgeDoc] = []
    seen: set[str] = set()
    for path in iter_knowledge_files():
        for raw in _load_json_array(path):
            doc = _parse_doc(raw)
            if not doc.id or not doc.content:
                continue
            if doc.doc_type == "law_snippet" and doc.citation is None:
                raise ValueError(f"law_snippet missing citation: {doc.id}")
            if doc.id in seen:
                raise ValueError(f"Duplicate knowledge id: {doc.id}")
            seen.add(doc.id)
            documents.append(doc)
    return documents
