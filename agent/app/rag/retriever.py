from __future__ import annotations

import json
from typing import Optional

import chromadb
from chromadb.api.models.Collection import Collection

from app.rag.embedder import Embedder
from app.rag.ingest import chroma_dir, load_all_documents
from app.schemas import Citation, KnowledgeDoc, RetrieveHit

COLLECTION_NAME = "contract_kb"


class KnowledgeRetriever:
    def __init__(self) -> None:
        self.embedder = Embedder()
        self._client = chromadb.PersistentClient(path=str(chroma_dir()))
        self._collection: Optional[Collection] = None
        self._docs_by_id: dict[str, KnowledgeDoc] = {}

    @property
    def embedding_mode(self) -> str:
        return self.embedder.mode

    def collection_count(self) -> int:
        collection = self._ensure_collection()
        return int(collection.count())

    def rebuild_index(self) -> int:
        try:
            self._client.delete_collection(COLLECTION_NAME)
        except Exception:
            pass

        collection = self._client.get_or_create_collection(
            name=COLLECTION_NAME,
            metadata={"hnsw:space": "cosine"},
        )
        documents = load_all_documents()
        if len(documents) == 0:
            self._collection = collection
            self._docs_by_id = {}
            return 0

        ids = [doc.id for doc in documents]
        texts = [doc.embedding_text() for doc in documents]
        embeddings = self.embedder.embed_documents(texts)
        metadatas = [self._to_metadata(doc) for doc in documents]

        batch_size = 32
        for start in range(0, len(ids), batch_size):
            end = start + batch_size
            collection.add(
                ids=ids[start:end],
                documents=texts[start:end],
                embeddings=embeddings[start:end],
                metadatas=metadatas[start:end],
            )

        self._collection = collection
        self._docs_by_id = {doc.id: doc for doc in documents}
        return len(documents)

    def ensure_ready(self) -> None:
        collection = self._ensure_collection()
        if collection.count() == 0:
            self.rebuild_index()
        else:
            self._docs_by_id = {doc.id: doc for doc in load_all_documents()}

    def retrieve(self, query: str, business_tag: str = "", top_k: int = 5) -> list[RetrieveHit]:
        self.ensure_ready()
        collection = self._ensure_collection()
        if collection.count() == 0:
            return []

        enriched_query = query.strip()
        tag = business_tag.strip()
        if tag:
            enriched_query = f"{tag}\n{enriched_query}"

        query_embedding = self.embedder.embed_query(enriched_query)
        result = collection.query(
            query_embeddings=[query_embedding],
            n_results=min(max(top_k * 3, top_k), max(collection.count(), 1)),
            include=["documents", "metadatas", "distances"],
        )

        ids = (result.get("ids") or [[]])[0]
        distances = (result.get("distances") or [[]])[0]
        metadatas = (result.get("metadatas") or [[]])[0]

        hits: list[RetrieveHit] = []
        for index, doc_id in enumerate(ids):
            distance = float(distances[index]) if index < len(distances) else 1.0
            score = 1.0 / (1.0 + max(distance, 0.0))
            metadata = metadatas[index] if index < len(metadatas) else {}
            doc = self._docs_by_id.get(doc_id) or self._doc_from_metadata(doc_id, metadata)
            if doc is None:
                continue
            score = self._boost_score(score, doc, tag, query)
            hits.append(
                RetrieveHit(
                    id=doc.id,
                    title=doc.title,
                    content=doc.content,
                    doc_type=doc.doc_type,
                    risk_level=doc.risk_level,
                    scenario=doc.scenario,
                    category=doc.category,
                    score=round(score, 6),
                    source=doc.source,
                    citation=doc.citation,
                    related_law_ids=doc.related_law_ids,
                )
            )

        hits.sort(key=lambda item: item.score, reverse=True)
        primary = hits[:top_k]
        return self._expand_related_laws(primary, top_k=top_k)

    def _expand_related_laws(self, hits: list[RetrieveHit], top_k: int) -> list[RetrieveHit]:
        """Attach related law_snippet docs referenced by risk/sample hits."""
        by_id = {hit.id: hit for hit in hits}
        related_ids: list[str] = []
        for hit in hits:
            for law_id in hit.related_law_ids:
                if law_id and law_id not in by_id and law_id not in related_ids:
                    related_ids.append(law_id)

        for law_id in related_ids:
            doc = self._docs_by_id.get(law_id)
            if doc is None or doc.doc_type != "law_snippet" or doc.citation is None:
                continue
            by_id[law_id] = RetrieveHit(
                id=doc.id,
                title=doc.title,
                content=doc.content,
                doc_type=doc.doc_type,
                risk_level=doc.risk_level,
                scenario=doc.scenario,
                category=doc.category,
                score=max((hit.score for hit in hits), default=0.5) * 0.95,
                source=doc.source,
                citation=doc.citation,
                related_law_ids=doc.related_law_ids,
            )

        merged = list(by_id.values())
        merged.sort(key=lambda item: item.score, reverse=True)
        # Keep primary top_k non-law first preference, but always include expanded laws.
        non_law = [item for item in merged if item.doc_type != "law_snippet"][:top_k]
        laws = [item for item in merged if item.doc_type == "law_snippet"]
        result = non_law[:]
        for law in laws:
            if all(existing.id != law.id for existing in result):
                result.append(law)
        return result

    def _ensure_collection(self) -> Collection:
        if self._collection is None:
            self._collection = self._client.get_or_create_collection(
                name=COLLECTION_NAME,
                metadata={"hnsw:space": "cosine"},
            )
        return self._collection

    def _boost_score(self, score: float, doc: KnowledgeDoc, business_tag: str, query: str) -> float:
        boosted = score
        tag = business_tag.strip()
        if tag and (tag in doc.scenario or tag in doc.title or tag in doc.content):
            boosted += 0.08
        lowered_query = query.lower()
        for keyword in doc.keywords:
            if keyword and keyword.lower() in lowered_query:
                boosted += 0.03
        if doc.doc_type == "law_snippet":
            boosted += 0.01
        return boosted

    def _to_metadata(self, doc: KnowledgeDoc) -> dict:
        citation_json = ""
        if doc.citation is not None:
            citation_json = json.dumps(doc.citation.model_dump(), ensure_ascii=False)
        return {
            "title": doc.title,
            "category": doc.category,
            "scenario": doc.scenario,
            "doc_type": doc.doc_type,
            "risk_level": doc.risk_level,
            "source": doc.source,
            "content": doc.content[:1000],
            "citation_json": citation_json,
            "related_law_ids": ",".join(doc.related_law_ids),
            "keywords": ",".join(doc.keywords),
        }

    def _doc_from_metadata(self, doc_id: str, metadata: dict) -> Optional[KnowledgeDoc]:
        if not metadata:
            return None
        citation = None
        citation_json = str(metadata.get("citation_json") or "").strip()
        if citation_json:
            try:
                raw = json.loads(citation_json)
                citation = Citation(
                    law_name=str(raw.get("law_name", "")),
                    article_no=str(raw.get("article_no", "")),
                    text=str(raw.get("text", "")),
                )
            except json.JSONDecodeError:
                citation = None

        related_raw = str(metadata.get("related_law_ids") or "")
        related = [item for item in related_raw.split(",") if item]
        keywords_raw = str(metadata.get("keywords") or "")
        keywords = [item for item in keywords_raw.split(",") if item]

        try:
            return KnowledgeDoc(
                id=doc_id,
                title=str(metadata.get("title") or doc_id),
                category=str(metadata.get("category") or "general"),
                scenario=str(metadata.get("scenario") or "通用"),
                doc_type=metadata.get("doc_type") or "risk_rule",
                risk_level=metadata.get("risk_level") or "INFO",
                content=str(metadata.get("content") or ""),
                keywords=keywords,
                source=str(metadata.get("source") or ""),
                citation=citation,
                related_law_ids=related,
            )
        except Exception:
            return None


_retriever: Optional[KnowledgeRetriever] = None


def get_retriever() -> KnowledgeRetriever:
    global _retriever
    if _retriever is None:
        _retriever = KnowledgeRetriever()
        _retriever.ensure_ready()
    return _retriever
