import { Request, Response } from 'express'

import { splitClauses } from '../../core/clause-splitter'
import { cleanContractText } from '../../core/cleaner'
import { analyzeContractWithLlm } from '../../core/llm'
import { extractContractText } from '../../core/ocr'
import { RagClient, RagHit } from '../../core/rag/client'
import { buildRiskEngineOutput } from '../../core/risk-engine'
import { readServerEnv } from '../../config/env'
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

function mergeHits(target: RagHit[], incoming: RagHit[]): void {
  const seen: Record<string, boolean> = {}
  for (let i: number = 0; i < target.length; i++) {
    seen[target[i].id] = true
  }
  for (let i: number = 0; i < incoming.length; i++) {
    const hit = incoming[i]
    if (seen[hit.id] === true) {
      continue
    }
    seen[hit.id] = true
    target.push(hit)
  }
}

async function retrieveKnowledgeContext(
  contractText: string,
  clauseHints: string[],
  businessTag: string | undefined
): Promise<{ knowledgeBlock: string, allowedCitationBlock: string, allowedCitations: string[] }> {
  const env = readServerEnv()
  if (!env.ragEnabled) {
    const empty = buildRiskEngineOutput([])
    return {
      knowledgeBlock: empty.knowledgeBlock,
      allowedCitationBlock: empty.allowedCitationBlock,
      allowedCitations: empty.allowedCitations
    }
  }

  const client = new RagClient(env.ragBaseUrl, env.ragTimeoutMs)
  const hits: RagHit[] = []
  const tag = businessTag?.trim() ?? ''

  try {
    const headQuery = contractText.substring(0, Math.min(contractText.length, 800))
    const primary = await client.retrieve({
      query: headQuery.length > 0 ? headQuery : '合同风险条款',
      businessTag: tag,
      topK: env.ragTopK
    })
    mergeHits(hits, primary)

    const hintLimit = Math.min(clauseHints.length, 8)
    for (let i: number = 0; i < hintLimit; i++) {
      const hint = clauseHints[i].trim()
      if (hint.length < 8) {
        continue
      }
      try {
        const hintHits = await client.retrieve({
          query: hint,
          businessTag: tag,
          topK: 1
        })
        mergeHits(hits, hintHits)
      } catch (_hintError) {
        // Ignore single-hint failures; keep primary hits.
      }
    }
  } catch (error) {
    const message = error instanceof Error ? error.message : 'unknown rag error'
    console.warn(`[RAG] retrieve degraded: ${message}`)
    const empty = buildRiskEngineOutput([])
    return {
      knowledgeBlock: empty.knowledgeBlock,
      allowedCitationBlock: empty.allowedCitationBlock,
      allowedCitations: empty.allowedCitations
    }
  }

  const engine = buildRiskEngineOutput(hits, 8)
  return {
    knowledgeBlock: engine.knowledgeBlock,
    allowedCitationBlock: engine.allowedCitationBlock,
    allowedCitations: engine.allowedCitations
  }
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

    const ragContext = await retrieveKnowledgeContext(
      cleanedText,
      clauseHints,
      taskRecord.request.businessTag
    )

    analysisTaskRepo.updateStatus(taskId, 'LLM_RUNNING')
    const analysisResult = await analyzeContractWithLlm({
      taskId,
      request: taskRecord.request,
      contractText: cleanedText,
      clauseHints,
      knowledgeBlock: ragContext.knowledgeBlock,
      allowedCitationBlock: ragContext.allowedCitationBlock,
      allowedCitations: ragContext.allowedCitations
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
    sendError(response, 409, 'RESULT_001', `Task is not ready: ${status}`)
    return
  }

  if (task.result === undefined) {
    sendError(response, 500, 'RESULT_001', `Task result missing: ${taskId}`)
    return
  }

  response.json(task.result)
}
