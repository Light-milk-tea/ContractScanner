import { randomUUID } from 'node:crypto'

import { AnalyzeContractRequest } from '../schemas/request.schema'
import { AnalysisResultResponse, AnalyzeStatus } from '../schemas/response.schema'

export interface AnalysisTaskRecord {
  taskId: string
  request: AnalyzeContractRequest
  createdAt: number
  result: AnalysisResultResponse
}

const OCR_DELAY_MS: number = 1500
const LLM_DELAY_MS: number = 3500
const SUCCESS_DELAY_MS: number = 5500

export class AnalysisTaskRepo {
  private readonly tasks: Map<string, AnalysisTaskRecord> = new Map<string, AnalysisTaskRecord>()

  createTask(request: AnalyzeContractRequest, result: AnalysisResultResponse): AnalysisTaskRecord {
    const taskId = `task-${randomUUID()}`
    const record: AnalysisTaskRecord = {
      taskId,
      request,
      createdAt: Date.now(),
      result: {
        ...result,
        taskId
      }
    }
    this.tasks.set(taskId, record)
    return record
  }

  getTask(taskId: string): AnalysisTaskRecord | undefined {
    return this.tasks.get(taskId)
  }

  resolveStatus(taskId: string): AnalyzeStatus | undefined {
    const task = this.getTask(taskId)
    if (task === undefined) {
      return undefined
    }

    const elapsedMs = Date.now() - task.createdAt
    if (elapsedMs < OCR_DELAY_MS) {
      return 'PENDING'
    }
    if (elapsedMs < LLM_DELAY_MS) {
      return 'OCR_RUNNING'
    }
    if (elapsedMs < SUCCESS_DELAY_MS) {
      return 'LLM_RUNNING'
    }
    return 'SUCCESS'
  }
}

export const analysisTaskRepo = new AnalysisTaskRepo()
