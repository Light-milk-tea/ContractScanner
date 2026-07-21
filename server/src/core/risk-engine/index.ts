import { citationDisplayText, RagCitation, RagHit } from '../rag/client'

export interface RiskContextItem {
  id: string
  title: string
  docType: string
  riskLevel: string
  scenario: string
  content: string
  source: string
  score: number
  relatedLawIds: string[]
  citationText?: string
}

export interface RiskEngineOutput {
  contexts: RiskContextItem[]
  allowedCitations: string[]
  knowledgeBlock: string
  allowedCitationBlock: string
}

function uniquePush(target: string[], value: string): void {
  const normalized = value.trim()
  if (normalized.length === 0) {
    return
  }
  for (let i: number = 0; i < target.length; i++) {
    if (target[i] === normalized) {
      return
    }
  }
  target.push(normalized)
}

function citationFromHit(hit: RagHit): string | undefined {
  if (hit.citation === undefined) {
    return undefined
  }
  const citation: RagCitation = hit.citation
  if (!citation.law_name || !citation.article_no || !citation.text) {
    return undefined
  }
  return citationDisplayText(citation)
}

export function buildRiskEngineOutput(hits: RagHit[], maxItems: number = 8): RiskEngineOutput {
  const sorted = hits.slice().sort((left, right) => right.score - left.score)
  const contexts: RiskContextItem[] = []
  const allowedCitations: string[] = []
  const seenIds: Record<string, boolean> = {}

  for (let i: number = 0; i < sorted.length; i++) {
    const hit = sorted[i]
    if (seenIds[hit.id] === true) {
      continue
    }
    seenIds[hit.id] = true

    const citationText = citationFromHit(hit)
    if (hit.doc_type === 'law_snippet' && citationText !== undefined) {
      uniquePush(allowedCitations, citationText)
    }

    contexts.push({
      id: hit.id,
      title: hit.title,
      docType: hit.doc_type,
      riskLevel: hit.risk_level,
      scenario: hit.scenario,
      content: hit.content,
      source: hit.source,
      score: hit.score,
      relatedLawIds: hit.related_law_ids ?? [],
      citationText
    })

    if (contexts.length >= maxItems) {
      break
    }
  }

  // Expand related law citations only when those law hits are already in the batch
  // (allowedCitations already filled from law_snippet docs present in hits).
  for (let i: number = 0; i < sorted.length; i++) {
    const hit = sorted[i]
    if (hit.doc_type !== 'law_snippet') {
      continue
    }
    const citationText = citationFromHit(hit)
    if (citationText !== undefined) {
      uniquePush(allowedCitations, citationText)
    }
  }

  const knowledgeLines: string[] = []
  for (let i: number = 0; i < contexts.length; i++) {
    const item = contexts[i]
    knowledgeLines.push(
      [
        `[${i + 1}] (${item.docType}/${item.riskLevel}/${item.scenario}) ${item.title}`,
        item.content,
        item.citationText !== undefined ? `法条摘录：${item.citationText}` : ''
      ].filter((line) => line.length > 0).join('\n')
    )
  }

  const citationLines: string[] = []
  for (let i: number = 0; i < allowedCitations.length; i++) {
    citationLines.push(`${i + 1}. ${allowedCitations[i]}`)
  }

  return {
    contexts,
    allowedCitations,
    knowledgeBlock: knowledgeLines.length > 0 ? knowledgeLines.join('\n\n') : '（本次未检索到可用知识）',
    allowedCitationBlock: citationLines.length > 0
      ? citationLines.join('\n')
      : '（无：本次不得输出任何具体法律条例）'
  }
}

/**
 * Keep legalBasis only when it matches an allowed citation from this turn's RAG hits.
 * Prefer returning the canonical allowed citation text to reduce model rewriting drift.
 */
export function sanitizeLegalBasis(
  rawLegalBasis: string | undefined,
  allowedCitations: string[]
): string | undefined {
  if (rawLegalBasis === undefined) {
    return undefined
  }
  const trimmed = rawLegalBasis.trim()
  if (trimmed.length === 0) {
    return undefined
  }
  if (allowedCitations.length === 0) {
    return undefined
  }

  const matched: string[] = []
  for (let i: number = 0; i < allowedCitations.length; i++) {
    const allowed = allowedCitations[i]
    if (trimmed.indexOf(allowed) >= 0 || allowed.indexOf(trimmed) >= 0) {
      matched.push(allowed)
      continue
    }
    // Loose match on article number fragment, e.g. "第497条"
    const articleMatch = allowed.match(/第\d+条/)
    if (articleMatch !== null && trimmed.indexOf(articleMatch[0]) >= 0 && trimmed.indexOf('《') >= 0) {
      matched.push(allowed)
    }
  }

  if (matched.length === 0) {
    return undefined
  }

  const uniqueMatched: string[] = []
  for (let i: number = 0; i < matched.length; i++) {
    uniquePush(uniqueMatched, matched[i])
  }
  return uniqueMatched.slice(0, 2).join('\n')
}

export function describeRiskEngineStage(): string {
  return 'Risk engine shapes RAG hits into prompt context and allowed legal citations'
}
