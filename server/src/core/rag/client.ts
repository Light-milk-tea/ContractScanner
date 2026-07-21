export interface RagCitation {
  law_name: string
  article_no: string
  text: string
}

export interface RagHit {
  id: string
  title: string
  content: string
  doc_type: 'risk_rule' | 'sample_note' | 'law_snippet' | string
  risk_level: string
  scenario: string
  category: string
  score: number
  source: string
  citation?: RagCitation
  related_law_ids?: string[]
}

export interface RetrieveRequestPayload {
  query: string
  businessTag?: string
  topK?: number
}

export interface RetrieveResponsePayload {
  hits: RagHit[]
}

function formatCitation(citation: RagCitation): string {
  return `《${citation.law_name}》${citation.article_no}：${citation.text}`
}

export class RagClient {
  private readonly baseUrl: string
  private readonly timeoutMs: number

  constructor(baseUrl: string, timeoutMs: number = 8000) {
    this.baseUrl = baseUrl.replace(/\/$/, '')
    this.timeoutMs = timeoutMs
  }

  async retrieve(payload: RetrieveRequestPayload): Promise<RagHit[]> {
    const controller = new AbortController()
    const timeoutId = setTimeout(() => {
      controller.abort()
    }, this.timeoutMs)

    try {
      const response = await fetch(`${this.baseUrl}/v1/retrieve`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          query: payload.query,
          businessTag: payload.businessTag ?? '',
          topK: payload.topK ?? 5
        }),
        signal: controller.signal
      })

      const text = await response.text()
      if (!response.ok) {
        throw new Error(`RAG retrieve failed: status=${response.status}, body=${text}`)
      }

      const parsed = JSON.parse(text) as RetrieveResponsePayload
      if (!Array.isArray(parsed.hits)) {
        return []
      }
      return parsed.hits
    } finally {
      clearTimeout(timeoutId)
    }
  }
}

export function citationDisplayText(citation: RagCitation): string {
  return formatCitation(citation)
}
