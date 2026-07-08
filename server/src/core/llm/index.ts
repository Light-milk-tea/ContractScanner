import { readServerEnv } from '../../config/env'
import { AnalyzeContractRequest } from '../../schemas/request.schema'
import { AnalysisResultResponse, ClauseRiskResponse, RiskLevel, RiskStatsResponse } from '../../schemas/response.schema'

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

export interface LlmAnalyzeInput {
  taskId: string
  request: AnalyzeContractRequest
  contractText: string
  clauseHints: string[]
}

interface ResolvedLlmConfig {
  apiBaseUrl: string
  apiKey: string
  model: string
  timeoutMs: number
}

function resolveConfig(request: AnalyzeContractRequest): ResolvedLlmConfig {
  const env = readServerEnv()
  const requestApiKey = request.apiKey?.trim() ?? ''

  return {
    apiBaseUrl: env.llmApiBaseUrl,
    apiKey: requestApiKey.length > 0 ? requestApiKey : env.llmApiKey,
    model: env.llmModel,
    timeoutMs: env.llmTimeoutMs
  }
}

function buildSystemPrompt(): string {
  return [
    '你是一名中文合同审查助手。',
    '请基于给定合同内容，输出结构化 JSON。',
    '不要输出 markdown，不要输出额外解释，不要使用代码块。',
    '输出字段必须包含：overallSummary, signBeforeChecklist, clauses。',
    'clauses 中每一项必须包含：title, originalText, plainText, riskLevel, riskReason, suggestion。',
    'riskLevel 只能取 RED、YELLOW、GREEN。',
    'signBeforeChecklist 需要给出 3 条签署前检查建议。'
  ].join('\n')
}

function buildUserPrompt(input: LlmAnalyzeInput): string {
  const businessTag = input.request.businessTag?.trim().length ? input.request.businessTag : '通用合同'
  const clausePreview = input.clauseHints.join('\n')

  return [
    `合同名称：${input.request.fileName}`,
    `文件类型：${input.request.fileType}`,
    `业务标签：${businessTag}`,
    '请从以下合同内容中，给出整体摘要、签署前检查清单，以及 3-6 条重点条款分析。',
    '每条条款需要包含原文、白话解释、风险等级、风险原因、修改建议。',
    '返回格式示例：',
    JSON.stringify({
      overallSummary: '一句到两句中文摘要',
      signBeforeChecklist: ['检查点1', '检查点2', '检查点3'],
      clauses: [
        {
          title: '条款标题',
          originalText: '原文',
          plainText: '白话解释',
          riskLevel: 'RED',
          riskReason: '风险原因',
          suggestion: '修改建议'
        }
      ]
    }),
    '合同内容如下：',
    input.contractText,
    '条款切片参考：',
    clausePreview
  ].join('\n\n')
}

function buildRequestBody(config: ResolvedLlmConfig, input: LlmAnalyzeInput): string {
  return JSON.stringify({
    model: config.model,
    temperature: 0.2,
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
  })
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

function extractJsonObject(rawContent: string): string {
  const startIndex = rawContent.indexOf('{')
  const endIndex = rawContent.lastIndexOf('}')
  if (startIndex < 0 || endIndex <= startIndex) {
    throw new Error(`模型未返回合法 JSON：${rawContent}`)
  }
  return rawContent.substring(startIndex, endIndex + 1)
}

function normalizeRiskLevel(rawRiskLevel: string | undefined, index: number): RiskLevel {
  if (rawRiskLevel === 'RED') {
    return 'RED'
  }
  if (rawRiskLevel === 'YELLOW') {
    return 'YELLOW'
  }
  if (rawRiskLevel === 'GREEN') {
    return 'GREEN'
  }
  if (index === 0) {
    return 'RED'
  }
  if (index === 1) {
    return 'YELLOW'
  }
  return 'GREEN'
}

function normalizeChecklist(rawChecklist: unknown): string[] {
  if (!Array.isArray(rawChecklist)) {
    return [
      '确认关键金额、期限与违约责任是否一致',
      '确认是否存在单方解释权、自动续约等不利条款',
      '确认争议解决、通知送达与解除条件是否明确'
    ]
  }

  const checklist: string[] = []
  for (let i: number = 0; i < rawChecklist.length; i++) {
    const item = rawChecklist[i]
    if (typeof item !== 'string') {
      continue
    }
    const normalized = item.trim()
    if (normalized.length === 0) {
      continue
    }
    checklist.push(normalized)
    if (checklist.length >= 3) {
      break
    }
  }

  if (checklist.length >= 3) {
    return checklist
  }

  return [
    '确认关键金额、期限与违约责任是否一致',
    '确认是否存在单方解释权、自动续约等不利条款',
    '确认争议解决、通知送达与解除条件是否明确'
  ]
}

function toClauseRisks(rawClauses: unknown, clauseHints: string[]): ClauseRiskResponse[] {
  const inputClauses = Array.isArray(rawClauses) ? rawClauses : []
  const clauses: ClauseRiskResponse[] = []

  for (let i: number = 0; i < inputClauses.length; i++) {
    const current = inputClauses[i] as Record<string, unknown>
    const hintText = clauseHints[i] ?? `合同条款 ${i + 1}`
    const clause: ClauseRiskResponse = {
      clauseId: `llm-clause-${String(i + 1).padStart(3, '0')}`,
      title: typeof current.title === 'string' && current.title.trim().length > 0 ? current.title.trim() : `重点条款 ${i + 1}`,
      originalText: typeof current.originalText === 'string' && current.originalText.trim().length > 0 ? current.originalText.trim() : hintText,
      plainText: typeof current.plainText === 'string' && current.plainText.trim().length > 0 ? current.plainText.trim() : '该条款需要结合上下文进一步审阅。',
      riskLevel: normalizeRiskLevel(typeof current.riskLevel === 'string' ? current.riskLevel : undefined, i),
      riskReason: typeof current.riskReason === 'string' && current.riskReason.trim().length > 0 ? current.riskReason.trim() : '模型未给出明确原因，建议人工复核。',
      suggestion: typeof current.suggestion === 'string' && current.suggestion.trim().length > 0 ? current.suggestion.trim() : '建议补充责任边界、期限和触发条件。',
      anchors: {
        paragraph: i + 1
      }
    }
    clauses.push(clause)
    if (clauses.length >= 6) {
      break
    }
  }

  if (clauses.length > 0) {
    return clauses
  }

  return [
    {
      clauseId: 'llm-clause-001',
      title: '付款与违约责任',
      originalText: clauseHints[0] ?? '付款及违约相关条款',
      plainText: '付款时间和违约成本是签署前必须重点确认的内容。',
      riskLevel: 'YELLOW',
      riskReason: '当前内容不足以支撑更细颗粒度判断，建议结合全文复核。',
      suggestion: '补充付款节点、逾期宽限期与违约金上限。',
      anchors: {
        paragraph: 1
      }
    }
  ]
}

function buildRiskStats(clauses: ClauseRiskResponse[]): RiskStatsResponse {
  const stats: RiskStatsResponse = {
    red: 0,
    yellow: 0,
    green: 0
  }

  for (let i: number = 0; i < clauses.length; i++) {
    if (clauses[i].riskLevel === 'RED') {
      stats.red += 1
      continue
    }
    if (clauses[i].riskLevel === 'YELLOW') {
      stats.yellow += 1
      continue
    }
    stats.green += 1
  }

  return stats
}

function normalizeResult(input: LlmAnalyzeInput, rawContent: string): AnalysisResultResponse {
  const parsed = JSON.parse(extractJsonObject(rawContent)) as Record<string, unknown>
  const clauses = toClauseRisks(parsed.clauses, input.clauseHints)

  return {
    taskId: input.taskId,
    contractName: input.request.fileName,
    overallSummary: typeof parsed.overallSummary === 'string' && parsed.overallSummary.trim().length > 0
      ? parsed.overallSummary.trim()
      : '模型已完成首轮合同分析，建议重点关注高风险与边界不清的条款。',
    signBeforeChecklist: normalizeChecklist(parsed.signBeforeChecklist),
    riskStats: buildRiskStats(clauses),
    clauses,
    generatedAt: new Date().toISOString()
  }
}

export async function analyzeContractWithLlm(input: LlmAnalyzeInput): Promise<AnalysisResultResponse> {
  const config = resolveConfig(input.request)
  // #region debug-point B:resolved-config
  fetch('http://192.168.63.21:7777/event', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ sessionId: 'analyze-failed-network', runId: 'pre-fix', hypothesisId: 'B', location: 'server/src/core/llm/index.ts:277', msg: '[DEBUG] resolved llm config', data: { hasRequestApiKey: typeof input.request.apiKey === 'string' && input.request.apiKey.trim().length > 0, requestApiKeyLength: typeof input.request.apiKey === 'string' ? input.request.apiKey.trim().length : 0, resolvedApiKeyLength: config.apiKey.length, model: config.model, apiBaseUrl: config.apiBaseUrl }, ts: Date.now() }) }).catch(() => {})
  // #endregion
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
        body: buildRequestBody(config, input),
        signal: controller.signal
      })
    } catch (error) {
      const reason = error instanceof Error ? error.message : 'unknown fetch error'
      throw new Error(`无法连接模型服务 ${config.apiBaseUrl}：${reason}。请检查当前网络是否可访问该网关，或将 LLM_API_BASE_URL 改为可用的 OpenAI 兼容地址。`)
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

    return normalizeResult(input, content)
  } finally {
    clearTimeout(timeoutId)
  }
}

export function describeLlmStage(): string {
  return 'LLM stage calls OpenAI-compatible chat completions for B17'
}
