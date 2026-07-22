import { readServerEnv } from '../../config/env'
import { ChatHistoryMessage } from '../../schemas/request.schema'
import { AnalysisResultResponse, ChatAnswerResponse } from '../../schemas/response.schema'
import { sanitizeLegalBasis } from '../risk-engine'

const CONTRACT_TEXT_LIMIT = 12000
const HISTORY_LIMIT = 6
const DISCLAIMER = '以上内容仅基于本次合同分析结果的解读辅助，不构成正式法律意见。'

interface OpenAiCompatibleMessage {
  content?: string | OpenAiCompatibleContentPart[]
}

interface OpenAiCompatibleContentPart {
  text?: string
}

interface OpenAiCompatibleChoice {
  message?: OpenAiCompatibleMessage
}

interface OpenAiCompatibleResponse {
  choices?: OpenAiCompatibleChoice[]
  error?: {
    message?: string
  }
}

interface ResolvedLlmConfig {
  apiBaseUrl: string
  apiKey: string
  model: string
  timeoutMs: number
}

export interface LlmChatInput {
  taskId: string
  question: string
  history?: ChatHistoryMessage[]
  apiKey?: string
  contractName: string
  cleanedText: string
  analysisResult: AnalysisResultResponse
  knowledgeBlock?: string
  allowedCitationBlock?: string
  allowedCitations?: string[]
}

function resolveConfig(apiKeyFromRequest?: string): ResolvedLlmConfig {
  const env = readServerEnv()
  const requestApiKey = apiKeyFromRequest?.trim() ?? ''

  return {
    apiBaseUrl: env.llmApiBaseUrl,
    apiKey: requestApiKey.length > 0 ? requestApiKey : env.llmApiKey,
    model: env.llmModel,
    timeoutMs: env.llmTimeoutMs
  }
}

function truncateText(text: string, maxLength: number): string {
  if (text.length <= maxLength) {
    return text
  }
  return `${text.substring(0, maxLength)}\n…（合同原文已截断）`
}

function buildSystemPrompt(): string {
  return [
    '你是「法言白话」合同解读助手，基于用户本次已完成的合同分析结果回答问题。',
    '只依据给定的合同原文、分析结果与检索知识作答；不要编造合同中未出现的内容。',
    '硬约束：',
    '1) 不得编造法律名称、条号或条文；若需引用法条，只能使用「允许引用的法律条例」列表中的原文。',
    '2) 列表为空或不相关时，不要输出具体法条，可说明“本次知识库未检索到可引用法条”。',
    '3) 不确定时明确说明不确定，并建议用户结合原文或咨询专业人士。',
    '4) 不要输出 markdown 代码块；回答用简洁中文。',
    '5) 回答末尾必须包含免责声明：' + DISCLAIMER,
    '6) answer 正文面向用户，禁止出现 clauseId、relatedClauseIds 等技术字段或括号标记；相关条款只写入 relatedClauseIds。',
    '请输出轻量 JSON（不要 markdown）：{"answer":"...","relatedClauseIds":["clause-id-1"]}',
    'relatedClauseIds 只能从分析结果条款的 clauseId 中选取，最多 3 个；无关则输出空数组。'
  ].join('\n')
}

function buildClauseSummary(result: AnalysisResultResponse): string {
  const lines: string[] = []
  for (let i: number = 0; i < result.clauses.length; i++) {
    const clause = result.clauses[i]
    lines.push(
      [
        `- clauseId=${clause.clauseId}`,
        `  标题：${clause.title}`,
        `  风险：${clause.riskLevel}`,
        `  原因：${clause.riskReason}`,
        `  白话：${clause.plainText}`,
        clause.suggestion !== undefined ? `  建议：${clause.suggestion}` : '',
        clause.legalBasis !== undefined ? `  已标注法条：${clause.legalBasis}` : ''
      ].filter((line) => line.length > 0).join('\n')
    )
  }
  return lines.length > 0 ? lines.join('\n') : '（无条款分析结果）'
}

function buildUserPrompt(input: LlmChatInput): string {
  const knowledgeBlock = input.knowledgeBlock?.trim().length
    ? input.knowledgeBlock.trim()
    : '（本次未检索到可用知识）'
  const allowedCitationBlock = input.allowedCitationBlock?.trim().length
    ? input.allowedCitationBlock.trim()
    : '（无：本次不得输出任何具体法律条例）'
  const history = (input.history ?? []).slice(-HISTORY_LIMIT)
  const historyLines: string[] = []
  for (let i: number = 0; i < history.length; i++) {
    const item = history[i]
    historyLines.push(`${item.role === 'user' ? '用户' : '助手'}：${item.content}`)
  }

  return [
    `合同名称：${input.contractName}`,
    `分析摘要：${input.analysisResult.overallSummary}`,
    `签署前检查：${input.analysisResult.signBeforeChecklist.join('；')}`,
    '重点条款：',
    buildClauseSummary(input.analysisResult),
    '检索到的风险知识（可参考，法条只能引用下一节允许列表）：',
    knowledgeBlock,
    '允许引用的法律条例：',
    allowedCitationBlock,
    '合同原文（可能截断）：',
    truncateText(input.cleanedText, CONTRACT_TEXT_LIMIT),
    historyLines.length > 0 ? '近期对话：\n' + historyLines.join('\n') : '近期对话：（无）',
    `用户当前问题：${input.question}`
  ].join('\n\n')
}

function readMessageContent(response: OpenAiCompatibleResponse): string {
  const firstChoice = response.choices?.[0]
  const content = firstChoice?.message?.content
  if (typeof content === 'string') {
    return content
  }
  if (Array.isArray(content)) {
    let merged = ''
    for (let i: number = 0; i < content.length; i++) {
      merged += content[i].text ?? ''
    }
    return merged
  }
  return ''
}

function extractJsonObject(rawContent: string): string | undefined {
  const fencedContent = rawContent.replace(/```json|```/gi, '').trim()
  const startIndex = fencedContent.indexOf('{')
  if (startIndex < 0) {
    return undefined
  }

  let depth: number = 0
  let inString: boolean = false
  let escaped: boolean = false

  for (let i: number = startIndex; i < fencedContent.length; i++) {
    const currentChar = fencedContent[i]

    if (escaped) {
      escaped = false
      continue
    }

    if (currentChar === '\\') {
      escaped = true
      continue
    }

    if (currentChar === '"') {
      inString = !inString
      continue
    }

    if (inString) {
      continue
    }

    if (currentChar === '{') {
      depth += 1
      continue
    }

    if (currentChar === '}') {
      depth -= 1
      if (depth === 0) {
        return fencedContent.substring(startIndex, i + 1)
      }
    }
  }

  return undefined
}

function ensureDisclaimer(answer: string): string {
  const trimmed = answer.trim()
  if (trimmed.indexOf('不构成正式法律意见') >= 0) {
    return trimmed
  }
  return `${trimmed}\n\n${DISCLAIMER}`
}

/**
 * Strip invented legal citations from free-form answers when they are not in the allowed list.
 */
export function sanitizeAnswerCitations(answer: string, allowedCitations: string[]): string {
  const citationPattern = /《[^》]+》第\d+条[^。；;\n]*/g
  return answer.replace(citationPattern, (matched) => {
    const kept = sanitizeLegalBasis(matched, allowedCitations)
    return kept ?? ''
  }).replace(/[ \t]+\n/g, '\n').replace(/\n{3,}/g, '\n\n').trim()
}

/**
 * Remove leaked technical clause markers from user-facing answer text.
 * relatedClauseIds stays in the structured response field only.
 */
export function sanitizeAnswerClauseIds(answer: string): string {
  return answer
    .replace(/[（(]\s*clauseId\s*[=:：]\s*[^）)]+[）)]/gi, '')
    .replace(/\bclauseId\s*[=:：]\s*[A-Za-z0-9_-]+/gi, '')
    .replace(/[ \t]{2,}/g, ' ')
    .replace(/[ \t]+\n/g, '\n')
    .replace(/\n{3,}/g, '\n\n')
    .trim()
}

function sanitizeUserFacingAnswer(answer: string, allowedCitations: string[]): string {
  return sanitizeAnswerClauseIds(sanitizeAnswerCitations(answer, allowedCitations))
}

function normalizeRelatedClauseIds(
  rawIds: unknown,
  result: AnalysisResultResponse
): string[] {
  if (!Array.isArray(rawIds)) {
    return []
  }
  const allowed: Record<string, boolean> = {}
  for (let i: number = 0; i < result.clauses.length; i++) {
    allowed[result.clauses[i].clauseId] = true
  }

  const selected: string[] = []
  for (let i: number = 0; i < rawIds.length; i++) {
    const id = rawIds[i]
    if (typeof id !== 'string') {
      continue
    }
    const trimmed = id.trim()
    if (trimmed.length === 0 || allowed[trimmed] !== true) {
      continue
    }
    let exists = false
    for (let j: number = 0; j < selected.length; j++) {
      if (selected[j] === trimmed) {
        exists = true
        break
      }
    }
    if (!exists) {
      selected.push(trimmed)
    }
    if (selected.length >= 3) {
      break
    }
  }
  return selected
}

function normalizeChatResult(input: LlmChatInput, rawContent: string): ChatAnswerResponse {
  const allowedCitations = input.allowedCitations ?? []
  const jsonText = extractJsonObject(rawContent)

  if (jsonText !== undefined) {
    try {
      const parsed = JSON.parse(jsonText) as Record<string, unknown>
      const rawAnswer = typeof parsed.answer === 'string' ? parsed.answer.trim() : ''
      if (rawAnswer.length > 0) {
        const sanitized = sanitizeUserFacingAnswer(rawAnswer, allowedCitations)
        const relatedClauseIds = normalizeRelatedClauseIds(parsed.relatedClauseIds, input.analysisResult)
        const response: ChatAnswerResponse = {
          taskId: input.taskId,
          answer: ensureDisclaimer(sanitized.length > 0 ? sanitized : sanitizeAnswerClauseIds(rawAnswer))
        }
        if (relatedClauseIds.length > 0) {
          response.relatedClauseIds = relatedClauseIds
        }
        return response
      }
    } catch (_parseError) {
      // Fall through to plain-text handling.
    }
  }

  const sanitized = sanitizeUserFacingAnswer(rawContent.trim(), allowedCitations)
  return {
    taskId: input.taskId,
    answer: ensureDisclaimer(sanitized.length > 0 ? sanitized : sanitizeAnswerClauseIds(rawContent.trim()))
  }
}

export async function answerContractQuestion(input: LlmChatInput): Promise<ChatAnswerResponse> {
  const config = resolveConfig(input.apiKey)
  if (config.apiKey.length === 0) {
    throw new Error('缺少可用的 LLM_API_KEY，请在服务端环境变量或客户端设置中提供 API Key')
  }

  const controller = new AbortController()
  const timeoutId = setTimeout(() => {
    controller.abort()
  }, config.timeoutMs)

  try {
    let response: Response
    try {
      response = await fetch(`${config.apiBaseUrl}/chat/completions`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${config.apiKey}`
        },
        body: JSON.stringify({
          model: config.model,
          temperature: 0.3,
          messages: [
            {
              role: 'system',
              content: buildSystemPrompt()
            },
            {
              role: 'user',
              content: buildUserPrompt(input)
            }
          ]
        }),
        signal: controller.signal
      })
    } catch (error) {
      const reason = error instanceof Error ? error.message : 'unknown fetch error'
      throw new Error(`无法连接模型服务 ${config.apiBaseUrl}：${reason}`)
    }

    const responseText = await response.text()
    if (!response.ok) {
      throw new Error(`LLM 请求失败: status=${response.status}, body=${responseText}`)
    }

    const parsed = JSON.parse(responseText) as OpenAiCompatibleResponse
    if (parsed.error?.message !== undefined && parsed.error.message.trim().length > 0) {
      throw new Error(parsed.error.message)
    }

    const content = readMessageContent(parsed)
    if (content.trim().length === 0) {
      throw new Error('LLM 返回内容为空')
    }

    return normalizeChatResult(input, content)
  } finally {
    clearTimeout(timeoutId)
  }
}
