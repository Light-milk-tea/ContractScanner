from __future__ import annotations

import hashlib
import json
import math
import os
import urllib.error
import urllib.request
from pathlib import Path
from typing import Sequence


def _project_roots() -> tuple[Path, Path]:
    agent_root = Path(__file__).resolve().parents[2]
    project_root = agent_root.parent
    return agent_root, project_root


def resolve_api_key() -> str:
    env_key = os.environ.get("EMBEDDING_API_KEY") or os.environ.get("LLM_API_KEY") or ""
    env_key = env_key.strip()
    if env_key:
        return env_key

    agent_root, project_root = _project_roots()
    candidates = [
        project_root / "apikey.txt",
        agent_root / "apikey.txt",
        project_root / "server" / "apikey.txt",
    ]
    for path in candidates:
        if not path.exists():
            continue
        try:
            value = path.read_text(encoding="utf-8").strip()
            if value:
                return value
        except OSError:
            continue
    return ""


def resolve_embedding_base_url() -> str:
    return (
        os.environ.get("EMBEDDING_API_BASE_URL")
        or os.environ.get("LLM_API_BASE_URL")
        or "https://dashscope.aliyuncs.com/compatible-mode/v1"
    ).rstrip("/")


def resolve_embedding_model() -> str:
    return os.environ.get("EMBEDDING_MODEL", "text-embedding-v3").strip() or "text-embedding-v3"


class LocalHashEmbedder:
    """Deterministic local embedder used when remote embedding is unavailable."""

    def __init__(self, dim: int = 384) -> None:
        self.dim = dim

    def embed_documents(self, texts: Sequence[str]) -> list[list[float]]:
        return [self._embed_one(text) for text in texts]

    def embed_query(self, text: str) -> list[float]:
        return self._embed_one(text)

    def _embed_one(self, text: str) -> list[float]:
        vector = [0.0] * self.dim
        normalized = (text or "").strip().lower()
        if not normalized:
            return vector

        tokens: list[str] = []
        for index in range(len(normalized) - 1):
            tokens.append(normalized[index : index + 2])
        for chunk in normalized.replace("\n", " ").split(" "):
            piece = chunk.strip()
            if piece:
                tokens.append(piece)

        for token in tokens:
            digest = hashlib.sha256(token.encode("utf-8")).digest()
            bucket = int.from_bytes(digest[:4], "big") % self.dim
            sign = 1.0 if digest[4] % 2 == 0 else -1.0
            vector[bucket] += sign

        norm = math.sqrt(sum(value * value for value in vector))
        if norm <= 1e-12:
            return vector
        return [value / norm for value in vector]


class OpenAICompatibleEmbedder:
    def __init__(self, api_base_url: str, api_key: str, model: str, timeout_sec: float = 30.0) -> None:
        self.api_base_url = api_base_url.rstrip("/")
        self.api_key = api_key
        self.model = model
        self.timeout_sec = timeout_sec

    def embed_documents(self, texts: Sequence[str]) -> list[list[float]]:
        if not texts:
            return []
        return self._embed_batch(list(texts))

    def embed_query(self, text: str) -> list[float]:
        vectors = self._embed_batch([text])
        return vectors[0]

    def _embed_batch(self, texts: list[str]) -> list[list[float]]:
        payload = {
            "model": self.model,
            "input": texts,
        }
        request = urllib.request.Request(
            url=f"{self.api_base_url}/embeddings",
            data=json.dumps(payload).encode("utf-8"),
            headers={
                "Content-Type": "application/json",
                "Authorization": f"Bearer {self.api_key}",
            },
            method="POST",
        )
        try:
            with urllib.request.urlopen(request, timeout=self.timeout_sec) as response:
                body = response.read().decode("utf-8")
        except urllib.error.HTTPError as error:
            detail = error.read().decode("utf-8", errors="replace")
            raise RuntimeError(f"Embedding HTTP {error.code}: {detail}") from error
        except urllib.error.URLError as error:
            raise RuntimeError(f"Embedding request failed: {error}") from error

        parsed = json.loads(body)
        data = parsed.get("data")
        if not isinstance(data, list) or len(data) == 0:
            raise RuntimeError(f"Embedding response missing data: {body[:500]}")

        ordered = sorted(data, key=lambda item: int(item.get("index", 0)))
        vectors: list[list[float]] = []
        for item in ordered:
            embedding = item.get("embedding")
            if not isinstance(embedding, list) or len(embedding) == 0:
                raise RuntimeError("Embedding vector is empty")
            vectors.append([float(value) for value in embedding])
        if len(vectors) != len(texts):
            raise RuntimeError("Embedding count mismatch")
        return vectors


class Embedder:
    def __init__(self) -> None:
        api_key = resolve_api_key()
        if api_key:
            self.mode = "remote"
            self._impl: OpenAICompatibleEmbedder | LocalHashEmbedder = OpenAICompatibleEmbedder(
                api_base_url=resolve_embedding_base_url(),
                api_key=api_key,
                model=resolve_embedding_model(),
            )
        else:
            self.mode = "local_hash"
            self._impl = LocalHashEmbedder()

    def embed_documents(self, texts: Sequence[str]) -> list[list[float]]:
        return self._impl.embed_documents(texts)

    def embed_query(self, text: str) -> list[float]:
        return self._impl.embed_query(text)
