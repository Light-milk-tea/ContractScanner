from __future__ import annotations

from typing import Any, Literal, Optional

from pydantic import BaseModel, Field

DocType = Literal["risk_rule", "sample_note", "law_snippet"]
RiskLevel = Literal["RED", "YELLOW", "GREEN", "INFO"]


class Citation(BaseModel):
    law_name: str
    article_no: str
    text: str

    def format_display(self) -> str:
        return f"《{self.law_name}》{self.article_no}：{self.text}"


class KnowledgeDoc(BaseModel):
    id: str
    title: str
    category: str = "general"
    scenario: str = "通用"
    doc_type: DocType
    risk_level: RiskLevel = "INFO"
    content: str
    keywords: list[str] = Field(default_factory=list)
    source: str = ""
    citation: Optional[Citation] = None
    related_law_ids: list[str] = Field(default_factory=list)

    def embedding_text(self) -> str:
        keyword_text = " ".join(self.keywords)
        citation_text = ""
        if self.citation is not None:
            citation_text = self.citation.format_display()
        return "\n".join(
            [
                self.title,
                self.scenario,
                self.category,
                self.content,
                keyword_text,
                citation_text,
            ]
        ).strip()


class RetrieveRequest(BaseModel):
    query: str = Field(..., min_length=1)
    businessTag: str = ""
    topK: int = Field(default=5, ge=1, le=20)


class RetrieveHit(BaseModel):
    id: str
    title: str
    content: str
    doc_type: DocType
    risk_level: RiskLevel
    scenario: str
    category: str
    score: float
    source: str
    citation: Optional[Citation] = None
    related_law_ids: list[str] = Field(default_factory=list)

    def model_dump_public(self) -> dict[str, Any]:
        payload = self.model_dump()
        return payload


class RetrieveResponse(BaseModel):
    hits: list[RetrieveHit]


class HealthResponse(BaseModel):
    status: str
    collectionCount: int
    embeddingMode: str
