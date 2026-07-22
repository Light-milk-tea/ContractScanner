import { randomUUID } from 'node:crypto'

import { AnalyzeContractRequest } from '../schemas/request.schema'
import { AnalysisResultResponse, AnalyzeStatus } from '../schemas/response.schema'

export interface AnalysisTaskRecord {
  taskId: string
  request: AnalyzeContractRequest
  createdAt: number
  status: AnalyzeStatus
  /** Cleaned full contract text retained for post-analysis Q&A. */
  cleanedText?: string
  result?: AnalysisResultResponse
  errorMessage?: string
}

export class AnalysisTaskRepo {
  private readonly tasks: Map<string, AnalysisTaskRecord> = new Map<string, AnalysisTaskRecord>()

  createTask(request: AnalyzeContractRequest): AnalysisTaskRecord {
    const taskId = `task-${randomUUID()}`
    const record: AnalysisTaskRecord = {
      taskId,
      request,
      createdAt: Date.now(),
      status: 'PENDING'
    }
    this.tasks.set(taskId, record)
    return record
  }

  getTask(taskId: string): AnalysisTaskRecord | undefined {
    return this.tasks.get(taskId)
  }

  updateStatus(taskId: string, status: AnalyzeStatus): void {
    const task = this.tasks.get(taskId)
    if (task === undefined) {
      return
    }

    task.status = status
  }

  setCleanedText(taskId: string, cleanedText: string): void {
    const task = this.tasks.get(taskId)
    if (task === undefined) {
      return
    }

    task.cleanedText = cleanedText
  }

  completeTask(taskId: string, result: AnalysisResultResponse): void {
    const task = this.tasks.get(taskId)
    if (task === undefined) {
      return
    }

    task.status = 'SUCCESS'
    task.result = {
      ...result,
      taskId
    }
    task.errorMessage = undefined
  }

  failTask(taskId: string, errorMessage: string): void {
    const task = this.tasks.get(taskId)
    if (task === undefined) {
      return
    }

    task.status = 'FAILED'
    task.errorMessage = errorMessage
  }

  resolveStatus(taskId: string): AnalyzeStatus | undefined {
    const task = this.getTask(taskId)
    if (task === undefined) {
      return undefined
    }
    return task.status
  }
}

export const analysisTaskRepo = new AnalysisTaskRepo()
