import { ClauseRisk } from './ClauseRisk'

export interface RiskStats {
  red: number
  yellow: number
  green: number
}

export interface AnalysisResult {
  taskId: string
  contractName: string
  overallSummary: string
  signBeforeChecklist: string[]
  riskStats: RiskStats
  clauses: ClauseRisk[]
  generatedAt: string
}
