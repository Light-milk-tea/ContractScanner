import { Request, Response } from 'express'

import { splitClauses } from '../../core/clause-splitter'
import { cleanContractText } from '../../core/cleaner'
import { analyzeContractWithLlm } from '../../core/llm'
import { extractContractText } from '../../core/ocr'
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

async function processAnalysisTask(taskId: string): Promise<void> {
  const taskRecord = analysisTaskRepo.getTask(taskId)
  if (taskRecord === undefined) {
    return
  }

  try {
    analysisTaskRepo.updateStatus(taskId, 'OCR_RUNNING')
    const ocrResult = extractContractText(taskRecord.request)
    const cleanedText = cleanContractText(ocrResult.text)
    const clauseHints = splitClauses(cleanedText)

    analysisTaskRepo.updateStatus(taskId, 'LLM_RUNNING')
    const analysisResult = await analyzeContractWithLlm({
      taskId,
      request: taskRecord.request,
      contractText: cleanedText,
      clauseHints
    })

    analysisTaskRepo.completeTask(taskId, analysisResult)
  } catch (error) {
    const message = error instanceof Error ? error.message : '未知分析异常'
    analysisTaskRepo.failTask(taskId, message)
  }
}

export function uploadContract(request: Request, response: Response): void {
  const payload = request.body as Partial<AnalyzeContractRequest>
  // #region debug-point A:upload-payload
  fetch('http://192.168.63.21:7777/event', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ sessionId: 'analyze-failed-network', runId: 'pre-fix', hypothesisId: 'A', location: 'server/src/api/controllers/analysisController.ts:56', msg: '[DEBUG] upload payload received', data: { fileName: payload.fileName ?? '', hasApiKey: typeof payload.apiKey === 'string' && payload.apiKey.trim().length > 0, apiKeyLength: typeof payload.apiKey === 'string' ? payload.apiKey.trim().length : 0, businessTag: payload.businessTag ?? '' }, ts: Date.now() }) }).catch(() => {})
  // #endregion
  const validation = validateAnalyzeContractRequest(payload)

  if (!validation.isValid) {
    sendError(response, 400, 'IMPORT_001', validation.message ?? 'Invalid request payload')
    return
  }

  const typedPayload: AnalyzeContractRequest = {
    fileName: payload.fileName ?? '',
    fileType: payload.fileType ?? '',
    fileUri: payload.fileUri ?? '',
    businessTag: payload.businessTag,
    apiKey: payload.apiKey
  }
  // #region debug-point B:typed-payload
  fetch('http://192.168.63.21:7777/event', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ sessionId: 'analyze-failed-network', runId: 'pre-fix', hypothesisId: 'B', location: 'server/src/api/controllers/analysisController.ts:72', msg: '[DEBUG] typed payload built', data: { taskApiKeyPresent: typeof typedPayload.apiKey === 'string' && typedPayload.apiKey.trim().length > 0, taskApiKeyLength: typeof typedPayload.apiKey === 'string' ? typedPayload.apiKey.trim().length : 0, fileType: typedPayload.fileType }, ts: Date.now() }) }).catch(() => {})
  // #endregion
  const taskRecord = analysisTaskRepo.createTask(typedPayload)
  void processAnalysisTask(taskRecord.taskId)

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
  if (status === 'FAILED') {
    responseBody.errorMessage = analysisTaskRepo.getTask(taskId)?.errorMessage
  }
  // #region debug-point C:status-response
  fetch('http://192.168.63.21:7777/event', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ sessionId: 'analyze-failed-network', runId: 'pre-fix', hypothesisId: 'C', location: 'server/src/api/controllers/analysisController.ts:98', msg: '[DEBUG] task status response', data: { taskId, status, hasErrorMessage: typeof responseBody.errorMessage === 'string' && responseBody.errorMessage.length > 0, errorMessage: responseBody.errorMessage ?? '' }, ts: Date.now() }) }).catch(() => {})
  // #endregion
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
    if (status === 'FAILED') {
      const errorMessage = task.errorMessage ?? `Task ${taskId} failed`
      sendError(response, 500, 'LLM_001', errorMessage)
      return
    }
    sendError(response, 409, 'RESULT_001', `Task ${taskId} is not ready yet`)
    return
  }

  if (task.result === undefined) {
    sendError(response, 500, 'RESULT_001', `Task ${taskId} has no analysis result`)
    return
  }

  response.json(task.result)
}
