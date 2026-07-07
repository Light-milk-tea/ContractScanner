import { Request, Response } from 'express'

import { buildMockAnalysisResult } from '../../mock/mockAnalysisFactory'
import { analysisTaskRepo } from '../../repository/analysisTaskRepo'
import { AnalyzeContractRequest, validateAnalyzeContractRequest } from '../../schemas/request.schema'
import { ErrorResponse, TaskStatusResponse, UploadContractResponse } from '../../schemas/response.schema'

function sendError(response: Response, statusCode: number, code: string, message: string): void {
  const payload: ErrorResponse = {
    code,
    message
  }
  response.status(statusCode).json(payload)
}

function readTaskId(request: Request): string {
  const rawTaskId = request.params.taskId
  if (Array.isArray(rawTaskId)) {
    return rawTaskId[0] ?? ''
  }
  return rawTaskId ?? ''
}

export function uploadContract(request: Request, response: Response): void {
  const payload = request.body as Partial<AnalyzeContractRequest>
  const validation = validateAnalyzeContractRequest(payload)

  if (!validation.isValid) {
    sendError(response, 400, 'IMPORT_001', validation.message ?? 'Invalid request payload')
    return
  }

  const typedPayload: AnalyzeContractRequest = {
    fileName: payload.fileName ?? '',
    fileType: payload.fileType ?? '',
    fileUri: payload.fileUri ?? '',
    businessTag: payload.businessTag
  }
  const initialResult = buildMockAnalysisResult('pending-task-id', typedPayload)
  const taskRecord = analysisTaskRepo.createTask(typedPayload, initialResult)
  const result = buildMockAnalysisResult(taskRecord.taskId, typedPayload)
  taskRecord.result = result

  const responseBody: UploadContractResponse = {
    taskId: taskRecord.taskId
  }
  response.status(202).json(responseBody)
}

export function getTaskStatus(request: Request, response: Response): void {
  const taskId = readTaskId(request)
  const status = analysisTaskRepo.resolveStatus(taskId)

  if (status === undefined) {
    sendError(response, 404, 'RESULT_001', `Task not found: ${taskId}`)
    return
  }

  const responseBody: TaskStatusResponse = {
    taskId,
    status
  }
  response.json(responseBody)
}

export function getAnalysisResult(request: Request, response: Response): void {
  const taskId = readTaskId(request)
  const task = analysisTaskRepo.getTask(taskId)

  if (task === undefined) {
    sendError(response, 404, 'RESULT_001', `Task not found: ${taskId}`)
    return
  }

  const status = analysisTaskRepo.resolveStatus(taskId)
  if (status !== 'SUCCESS') {
    sendError(response, 409, 'RESULT_001', `Task ${taskId} is not ready yet`)
    return
  }

  response.json(task.result)
}
