import { AnalysisResult } from '../domain/AnalysisResult'

export class ResultVM {
  result?: AnalysisResult

  setResult(result: AnalysisResult): void {
    this.result = result
  }

  clear(): void {
    this.result = undefined
  }
}
