import { AnalysisResult } from '../domain/AnalysisResult'
import { ClauseRisk } from '../domain/ClauseRisk'
import { DTOMapper } from '../../services/api/DTOMapper'
import { ContractApi } from '../../services/api/ContractApi'

export class ResultVM {
  result?: AnalysisResult
  taskId: string = ''
  baseUrl: string = ''
  selectedClauseId: string = ''
  errorText: string = ''
  isLoading: boolean = false

  setResult(result: AnalysisResult): void {
    this.result = result
    this.errorText = ''
    this.isLoading = false
  }

  setRouteContext(taskId: string, baseUrl: string): void {
    this.taskId = taskId
    this.baseUrl = baseUrl
  }

  setSelectedClauseId(clauseId: string): void {
    this.selectedClauseId = clauseId
  }

  setLoading(isLoading: boolean): void {
    this.isLoading = isLoading
  }

  setError(errorText: string): void {
    this.errorText = errorText
  }

  hasResult(): boolean {
    return this.result !== undefined
  }

  findClauseById(clauseId: string): ClauseRisk | undefined {
    if (this.result === undefined) {
      return undefined
    }

    for (let i: number = 0; i < this.result.clauses.length; i++) {
      const clause = this.result.clauses[i]
      if (clause.clauseId === clauseId) {
        return clause
      }
    }
    return undefined
  }

  loadDemoResult(taskId: string): AnalysisResult {
    const effectiveTaskId: string = taskId.length > 0 ? taskId : ContractApi.buildMockTaskId()
    const mapper = new DTOMapper()
    const result: AnalysisResult = mapper.mapAnalysisResult(ContractApi.getMockAnalysisResult(effectiveTaskId))
    this.result = result
    return result
  }

  clear(): void {
    this.result = undefined
    this.taskId = ''
    this.baseUrl = ''
    this.selectedClauseId = ''
    this.errorText = ''
    this.isLoading = false
  }
}
