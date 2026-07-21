#!/usr/bin/env python3
"""从 twang2218/law-datasets 的 laws.json 切条，写入 kb/law_snippets。"""

from __future__ import annotations

import argparse
import json
import re
import unicodedata
from pathlib import Path

AGENT_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_RAW = AGENT_ROOT / "data" / "raw_laws" / "laws.json"
DEFAULT_OUT = AGENT_ROOT / "kb" / "law_snippets" / "laws_imported.json"
CURATED = AGENT_ROOT / "kb" / "law_snippets" / "laws.json"

# 仅导入这些全国性法律（精确标题匹配）
TARGET_TITLES = {
    "中华人民共和国民法典",
    "中华人民共和国消费者权益保护法",
    "中华人民共和国个人信息保护法",
    "中华人民共和国劳动合同法",
    "中华人民共和国劳动合同法实施条例",
    "中华人民共和国民事诉讼法",
    "中华人民共和国电子商务法",
}

# 必须消费条号本身；零宽前瞻会导致 body 仍含「第X条」，拼回时重复。
ARTICLE_RE = re.compile(r"(第[零〇一二三四五六七八九十百千万两0-9]+条)")

CN_NUM = {
    "零": 0,
    "〇": 0,
    "一": 1,
    "二": 2,
    "两": 2,
    "三": 3,
    "四": 4,
    "五": 5,
    "六": 6,
    "七": 7,
    "八": 8,
    "九": 9,
}


def cn_article_to_int(token: str) -> int | None:
    """把『第五百零六』转成数字；失败返回 None。"""
    s = token
    if s.isdigit():
        return int(s)
    total = 0
    num = 0
    for ch in s:
        if ch in CN_NUM:
            num = CN_NUM[ch]
        elif ch == "十":
            total += (num or 1) * 10
            num = 0
        elif ch == "百":
            total += (num or 1) * 100
            num = 0
        elif ch == "千":
            total += (num or 1) * 1000
            num = 0
        elif ch == "万":
            total = (total + num) * 10000
            num = 0
        else:
            return None
    return total + num


def slugify_law(title: str) -> str:
    mapping = {
        "中华人民共和国民法典": "cc",
        "中华人民共和国消费者权益保护法": "consumer",
        "中华人民共和国个人信息保护法": "pipl",
        "中华人民共和国劳动合同法": "labor_contract",
        "中华人民共和国劳动合同法实施条例": "labor_contract_reg",
        "中华人民共和国民事诉讼法": "cpl",
        "中华人民共和国电子商务法": "ecommerce",
    }
    return mapping.get(title, re.sub(r"\W+", "_", title)[:24])


def guess_category(law_name: str, text: str) -> str:
    blob = law_name + text
    rules = [
        ("format_clause", ("格式条款",)),
        ("deposit", ("定金", "押金")),
        ("penalty", ("违约金",)),
        ("jurisdiction", ("管辖", "人民法院")),
        ("privacy", ("个人信息", "隐私")),
        ("consumer", ("消费者", "经营者")),
        ("lease", ("租赁", "出租人", "承租人")),
        ("labor", ("劳动合同", "工资", "工时")),
        ("ecommerce", ("电子商务", "自动续费", "网络交易")),
    ]
    for cat, kws in rules:
        if any(k in blob for k in kws):
            return cat
    return "general"


def guess_scenario(law_name: str, text: str) -> str:
    if "租赁" in text or "出租" in text:
        return "租房"
    if "个人信息" in text or "个人信息保护法" in law_name:
        return "订阅"
    if "消费者" in text or "电子商务" in law_name:
        return "订阅"
    if "劳动" in law_name or "工资" in text or "工时" in text:
        return "实习"
    return "通用"


def split_articles(content: str) -> list[tuple[str, str]]:
    content = unicodedata.normalize("NFKC", content or "").strip()
    if not content:
        return []
    # 目录里的「第X条」也会被切到；正文条通常更长，后面再按长度过滤。
    parts = ARTICLE_RE.split(content)
    # split 结果: [preamble, art1, body1, art2, body2, ...]
    articles: list[tuple[str, str]] = []
    i = 1
    while i + 1 < len(parts):
        label = parts[i].strip()
        body = parts[i + 1].strip()
        body = re.sub(r"^[\s\u3000]+", "", body)
        # 去掉 markdown 残留
        body = re.sub(r"^>\s*", "", body)
        text = f"{label}　{body}".strip() if body else label
        if len(text) >= 12:
            articles.append((label, text))
        i += 2
    return articles


def pick_laws(raw: list[dict]) -> list[dict]:
    """每个目标标题取一条有效文本（优先 status=有效，内容最长）。"""
    chosen: dict[str, dict] = {}
    for item in raw:
        title = str(item.get("title") or "").strip()
        if title not in TARGET_TITLES:
            continue
        content = str(item.get("content") or "").strip()
        if len(content) < 200:
            continue
        status = str(item.get("status") or "")
        prev = chosen.get(title)
        score = (1 if status == "有效" else 0, len(content))
        prev_score = (
            (1 if str(prev.get("status") or "") == "有效" else 0, len(str(prev.get("content") or "")))
            if prev
            else (-1, -1)
        )
        if score > prev_score:
            chosen[title] = item
    return [chosen[t] for t in TARGET_TITLES if t in chosen]


def to_snippet(law: dict, label: str, text: str) -> dict:
    law_name = str(law["title"]).strip()
    slug = slugify_law(law_name)
    m = re.match(r"第(.+?)条", label)
    num_token = m.group(1) if m else ""
    num = cn_article_to_int(num_token)
    article_id = f"law_{slug}_{num}" if num is not None else f"law_{slug}_{label}"
    citation_text = text
    # citation 摘要控制长度
    if len(citation_text) > 180:
        citation_text = citation_text[:177] + "…"
    title = f"{law_name}{label}"
    return {
        "id": article_id,
        "title": title,
        "category": guess_category(law_name, text),
        "scenario": guess_scenario(law_name, text),
        "doc_type": "law_snippet",
        "risk_level": "INFO",
        "content": text,
        "keywords": [law_name, label],
        "source": f"{law_name}{label}（twang2218/chinese-law-and-regulations）",
        "citation": {
            "law_name": law_name,
            "article_no": label,
            "text": citation_text,
        },
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--raw", type=Path, default=DEFAULT_RAW)
    parser.add_argument("--out", type=Path, default=DEFAULT_OUT)
    parser.add_argument(
        "--civil-code-only-contract",
        action="store_true",
        help="民法典仅保留合同相关条款（约第464–988条及总则格式条款等）",
    )
    args = parser.parse_args()

    raw = json.loads(args.raw.read_text(encoding="utf-8"))
    if not isinstance(raw, list):
        raise SystemExit("raw laws.json must be a JSON array")

    snippets: list[dict] = []
    best_by_id: dict[str, dict] = {}
    for law in pick_laws(raw):
        articles = split_articles(str(law.get("content") or ""))
        law_name = str(law["title"])
        for label, text in articles:
            if args.civil_code_only_contract and law_name == "中华人民共和国民法典":
                m = re.match(r"第(.+?)条", label)
                num = cn_article_to_int(m.group(1)) if m else None
                # 保留：格式条款/违约等总则常用 + 合同编主干
                keep = False
                if num is not None and (
                    464 <= num <= 988  # 合同编（含典型合同至第988附近）
                    or num in {143, 144, 146, 153, 154, 155, 157}  # 民事法律行为无效等
                    or 496 <= num <= 498  # 格式条款
                    or num in {506, 509, 563, 566, 577, 584, 585, 586, 587}
                ):
                    keep = True
                if not keep:
                    continue
            doc = to_snippet(law, label, text)
            prev = best_by_id.get(doc["id"])
            # 同一条号可能在目录与正文各出现一次，保留更长正文
            if prev is None or len(doc["content"]) > len(prev["content"]):
                best_by_id[doc["id"]] = doc

    snippets = list(best_by_id.values())
    # 与人工精选 laws.json 冲突的 id 一律跳过（ingest 不允许重复 id）
    curated_ids: set[str] = set()
    if CURATED.exists():
        curated = json.loads(CURATED.read_text(encoding="utf-8"))
        if isinstance(curated, list):
            curated_ids = {
                str(item.get("id", "")).strip()
                for item in curated
                if str(item.get("id", "")).strip()
            }
    before = len(snippets)
    snippets = [d for d in snippets if d["id"] not in curated_ids]
    skipped = before - len(snippets)
    snippets.sort(key=lambda d: d["id"])

    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(
        json.dumps(snippets, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    by_law: dict[str, int] = {}
    for s in snippets:
        name = s["citation"]["law_name"]
        by_law[name] = by_law.get(name, 0) + 1
    print(f"wrote {len(snippets)} snippets -> {args.out}")
    if skipped:
        print(f"skipped {skipped} ids already in {CURATED.name}")
    for name, n in by_law.items():
        print(f"  {name}: {n}")


if __name__ == "__main__":
    main()
