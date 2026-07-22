import { Request, Response } from 'express'

import { readServerEnv } from '../../config/env'
import { answerContractQuestion } from '../../core/llm/chat'
import { RagClient, RagHit } from '../../core/rag/client'
import { buildRiskEngineOutput } from '../../core/risk-engine'
import { analysisTaskRepo } from '../../repository/analysisTaskRepo'
import {
  ChatHistoryMessage,
  ChatQuestionRequest,
  validateChatQuestionRequest
} from '../../schemas/request.schema'
import { ChatAnswerResponse, ErrorResponse } from '../../schemas/response.schema'

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

function normalizeHistory(rawHistory: ChatHistoryMessage[] | undefined): ChatHistoryMessage[] {
  if (rawHistory === undefined) {
    return []
  }
  const history: ChatHistoryMessage[] = []
  const start = Math.max(0, rawHistory.length - 6)
  for (let i: number = start; i < rawHistory.length; i++) {
    const item = rawHistory[i]
    history.push({
      role: item.role,
      content: item.content.trim()
    })
  }
  return history
}

async function retrieveChatKnowledge(
  question: string,
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
  try {
    const hits: RagHit[] = await client.retrieve({
      query: question,
      businessTag: businessTag?.trim() ?? '',
      topK: env.ragTopK
    })
    const engine = buildRiskEngineOutput(hits, 6)
    return {
      knowledgeBlock: engine.knowledgeBlock,
      allowedCitationBlock: engine.allowedCitationBlock,
      allowedCitations: engine.allowedCitations
    }
  } catch (error) {
    const message = error instanceof Error ? error.message : 'unknown rag error'
    console.warn(`[RAG] chat retrieve degraded: ${message}`)
    const empty = buildRiskEngineOutput([])
    return {
      knowledgeBlock: empty.knowledgeBlock,
      allowedCitationBlock: empty.allowedCitationBlock,
      allowedCitations: empty.allowedCitations
    }
  }
}

export async function askContractQuestion(request: Request, response: Response): Promise<void> {
  const taskId = readTaskId(request)
  const payload = request.body as Partial<ChatQuestionRequest>
  const validation = validateChatQuestionRequest(payload)

  if (!validation.isValid) {
    sendError(response, 400, 'CHAT_001', validation.message ?? 'Invalid chat request')
    return
  }

  const task = analysisTaskRepo.getTask(taskId)
  if (task === undefined) {
    sendError(response, 404, 'RESULT_001', `Task not found: ${taskId}`)
    return
  }

  if (task.status !== 'SUCCESS' || task.result === undefined) {
    sendError(response, 409, 'CHAT_002', `Task is not ready for chat: ${task.status}`)
    return
  }

  const cleanedText = task.cleanedText?.trim() ?? ''
  if (cleanedText.length === 0) {
    sendError(response, 409, 'CHAT_003', 'Task cleaned text is missing; cannot answer questions about this contract')
    return
  }

  const question = (payload.question ?? '').trim()
  const history = normalizeHistory(payload.history)
  const apiKey = payload.apiKey?.trim() ?? task.request.apiKey

  try {
    const ragContext = await retrieveChatKnowledge(question, task.request.businessTag)
    const answer: ChatAnswerResponse = await answerContractQuestion({
      taskId,
      question,
      history,
      apiKey,
      contractName: task.result.contractName,
      cleanedText,
      analysisResult: task.result,
      knowledgeBlock: ragContext.knowledgeBlock,
      allowedCitationBlock: ragContext.allowedCitationBlock,
      allowedCitations: ragContext.allowedCitations
    })
    response.json(answer)
  } catch (error) {
    const message = error instanceof Error ? error.message : '未知问答异常'
    sendError(response, 500, 'LLM_001', message)
  }
}
