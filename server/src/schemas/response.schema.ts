export type AnalyzeStatus = 'PENDING' | 'OCR_RUNNING' | 'LLM_RUNNING' | 'SUCCESS' | 'FAILED'
export type RiskLevel = 'RED' | 'YELLOW' | 'GREEN'

export interface UploadContractResponse {
  taskId: string
}

export interface TaskStatusResponse {
  taskId: string
  status: AnalyzeStatus
}

export interface ClauseAnchorResponse {
  page?: number
  paragraph?: number
}

export interface ClauseRiskResponse {
  clauseId: string
  title: string
  originalText: string
  plainText: string
  riskLevel: RiskLevel
  riskReason: string
  suggestion?: string
  anchors: ClauseAnchorResponse
}

export interface RiskStatsResponse {
  red: number
  yellow: number
  green: number
}

export interface AnalysisResultResponse {
  taskId: string
  contractName: string
  overallSummary: string
  signBeforeChecklist: string[]
  riskStats: RiskStatsResponse
  clauses: ClauseRiskResponse[]
  generatedAt: string
}

export interface ErrorResponse {
  code: string
  message: string
}
