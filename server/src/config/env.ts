export interface ServerEnv {
  port: number
  host: string
  llmApiBaseUrl: string
  llmApiKey: string
  llmModel: string
  llmTimeoutMs: number
}

const DEFAULT_PORT: number = 3000
const DEFAULT_HOST: string = '0.0.0.0'
const DEFAULT_LLM_API_BASE_URL: string = 'https://dashscope.aliyuncs.com/compatible-mode/v1'
const DEFAULT_LLM_MODEL: string = 'qwen-plus'
const DEFAULT_LLM_TIMEOUT_MS: number = 45000

function parsePort(rawPort?: string): number {
  if (rawPort === undefined || rawPort.trim().length === 0) {
    return DEFAULT_PORT
  }

  const parsed = Number(rawPort)
  if (!Number.isFinite(parsed) || parsed <= 0) {
    return DEFAULT_PORT
  }

  return Math.floor(parsed)
}

function parseTimeout(rawTimeout?: string): number {
  if (rawTimeout === undefined || rawTimeout.trim().length === 0) {
    return DEFAULT_LLM_TIMEOUT_MS
  }

  const parsed = Number(rawTimeout)
  if (!Number.isFinite(parsed) || parsed < 3000) {
    return DEFAULT_LLM_TIMEOUT_MS
  }

  return Math.floor(parsed)
}

function readTrimmed(rawValue: string | undefined, defaultValue: string): string {
  if (rawValue === undefined) {
    return defaultValue
  }

  const normalized = rawValue.trim()
  return normalized.length > 0 ? normalized : defaultValue
}

export function readServerEnv(): ServerEnv {
  return {
    port: parsePort(process.env.PORT),
    host: readTrimmed(process.env.HOST, DEFAULT_HOST),
    llmApiBaseUrl: readTrimmed(process.env.LLM_API_BASE_URL, DEFAULT_LLM_API_BASE_URL),
    llmApiKey: readTrimmed(process.env.LLM_API_KEY, ''),
    llmModel: readTrimmed(process.env.LLM_MODEL, DEFAULT_LLM_MODEL),
    llmTimeoutMs: parseTimeout(process.env.LLM_TIMEOUT_MS)
  }
}
