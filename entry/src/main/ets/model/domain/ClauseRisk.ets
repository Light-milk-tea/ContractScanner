import { RiskLevel } from '../enums/RiskLevel'

export interface ClauseAnchor {
  page?: number
  paragraph?: number
}

export interface ClauseRisk {
  clauseId: string
  title: string
  originalText: string
  plainText: string
  riskLevel: RiskLevel
  riskReason: string
  suggestion?: string
  /** Grounded legal citation from RAG; omit when unavailable. */
  legalBasis?: string
  anchors: ClauseAnchor
}
