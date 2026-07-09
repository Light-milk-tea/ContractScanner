import { existsSync, readFileSync } from 'fs'
import path from 'path'

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
const SERVER_ROOT_DIR: string = path.resolve(__dirname, '..', '..')
const PROJECT_ROOT_DIR: string = path.resolve(SERVER_ROOT_DIR, '..')

function parseEnvValue(rawValue: string): string {
  const normalized = rawValue.trim()
  if (
    normalized.length >= 2 &&
    ((normalized.startsWith('"') && normalized.endsWith('"')) ||
      (normalized.startsWith('\'') && normalized.endsWith('\'')))
  ) {
    return normalized.substring(1, normalized.length - 1).trim()
  }
  return normalized
}

function loadEnvFile(filePath: string): void {
  if (!existsSync(filePath)) {
    return
  }

  try {
    const content = readFileSync(filePath, 'utf8')
    const lines = content.split(/\r?\n/)

    for (let i: number = 0; i < lines.length; i++) {
      const line = lines[i].trim()
      if (line.length === 0 || line.startsWith('#')) {
        continue
      }

      const separatorIndex = line.indexOf('=')
      if (separatorIndex <= 0) {
        continue
      }

      const key = line.substring(0, separatorIndex).trim()
      const value = parseEnvValue(line.substring(separatorIndex + 1))

      if (key.length === 0 || process.env[key] !== undefined) {
        continue
      }

      process.env[key] = value
    }
  } catch (_error) {
    // Ignore local env parsing errors and continue with existing process.env values.
  }
}

loadEnvFile(path.join(SERVER_ROOT_DIR, '.env'))

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

function readApiKeyFromFile(filePath: string): string {
  if (!existsSync(filePath)) {
    return ''
  }

  try {
    return readFileSync(filePath, 'utf8').trim()
  } catch (_error) {
    return ''
  }
}

function resolveApiKey(): string {
  const envApiKey = readTrimmed(process.env.LLM_API_KEY, '')
  if (envApiKey.length > 0) {
    return envApiKey
  }

  const candidatePaths: string[] = [
    path.join(PROJECT_ROOT_DIR, 'apikey.txt'),
    path.join(SERVER_ROOT_DIR, 'apikey.txt')
  ]

  for (let i: number = 0; i < candidatePaths.length; i++) {
    const apiKey = readApiKeyFromFile(candidatePaths[i])
    if (apiKey.length > 0) {
      return apiKey
    }
  }

  return ''
}

export function readServerEnv(): ServerEnv {
  return {
    port: parsePort(process.env.PORT),
    host: readTrimmed(process.env.HOST, DEFAULT_HOST),
    llmApiBaseUrl: readTrimmed(process.env.LLM_API_BASE_URL, DEFAULT_LLM_API_BASE_URL),
    llmApiKey: resolveApiKey(),
    llmModel: readTrimmed(process.env.LLM_MODEL, DEFAULT_LLM_MODEL),
    llmTimeoutMs: parseTimeout(process.env.LLM_TIMEOUT_MS)
  }
}
