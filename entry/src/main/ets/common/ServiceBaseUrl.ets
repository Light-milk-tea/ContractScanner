import { deviceInfo } from '@kit.BasicServicesKit'

export const API_SERVICE_PORT: number = 3000
const LOOPBACK_HOST: string = '127.0.0.1'
const EMULATOR_HOST_GATEWAY: string = '10.0.2.2'

/**
 * 开发机局域网 IP，作为模拟器 10.0.2.2 不通时的自动回退地址。
 * 电脑换网后请更新这里（终端执行：ipconfig getifaddr en0）。
 */
export const DEV_HOST_LAN_IP: string = '192.168.63.21'

export function isEmulatorRuntime(): boolean {
  const model: string = deviceInfo.productModel
  if (model === 'emulator') {
    return true
  }
  return model.toLowerCase().indexOf('emulator') >= 0
}

export function isLoopbackBaseUrl(baseUrl: string): boolean {
  const lower: string = baseUrl.trim().toLowerCase()
  return lower.indexOf('127.0.0.1') >= 0 || lower.indexOf('localhost') >= 0
}

export function resolveDefaultApiBaseUrl(): string {
  if (isEmulatorRuntime()) {
    // 优先走局域网 IP：部分模拟器在开启代理后，10.0.2.2:非80 端口会失败
    return buildHttpBaseUrl(DEV_HOST_LAN_IP, API_SERVICE_PORT)
  }
  return buildHttpBaseUrl(LOOPBACK_HOST, API_SERVICE_PORT)
}

/**
 * 将已配置地址解析为当前设备可用的服务地址。
 * 模拟器上会把 127.0.0.1 / localhost 自动改写为开发机局域网 IP。
 */
export function resolveEffectiveApiBaseUrl(configuredBaseUrl: string): string {
  return resolveEffectiveApiBaseUrlFor(configuredBaseUrl, isEmulatorRuntime())
}

export function resolveEffectiveApiBaseUrlFor(configuredBaseUrl: string, isEmulator: boolean): string {
  const trimmed: string = configuredBaseUrl.trim()
  if (trimmed.length === 0) {
    if (isEmulator) {
      return buildHttpBaseUrl(DEV_HOST_LAN_IP, API_SERVICE_PORT)
    }
    return buildHttpBaseUrl(LOOPBACK_HOST, API_SERVICE_PORT)
  }
  if (isEmulator && isLoopbackBaseUrl(trimmed)) {
    return rewriteLoopbackToHost(trimmed, DEV_HOST_LAN_IP)
  }
  if (isEmulator && isEmulatorGatewayBaseUrl(trimmed)) {
    // 旧默认网关地址保留为候选，解析时优先切到局域网 IP
    return buildHttpBaseUrl(DEV_HOST_LAN_IP, extractPort(trimmed, API_SERVICE_PORT))
  }
  return trimmed
}

export function buildServiceBaseUrlCandidates(preferredBaseUrl: string): string[] {
  return buildServiceBaseUrlCandidatesFor(preferredBaseUrl, isEmulatorRuntime())
}

export function buildServiceBaseUrlCandidatesFor(preferredBaseUrl: string, isEmulator: boolean): string[] {
  const candidates: string[] = []
  const preferred = preferredBaseUrl.trim()
  if (preferred.length > 0) {
    pushUnique(candidates, preferred)
  }

  if (isEmulator) {
    const port = extractPort(preferred, API_SERVICE_PORT)
    pushUnique(candidates, buildHttpBaseUrl(DEV_HOST_LAN_IP, port))
    pushUnique(candidates, buildHttpBaseUrl(EMULATOR_HOST_GATEWAY, port))
    pushUnique(candidates, buildHttpBaseUrl(LOOPBACK_HOST, port))
  } else {
    pushUnique(candidates, buildHttpBaseUrl(LOOPBACK_HOST, API_SERVICE_PORT))
    pushUnique(candidates, buildHttpBaseUrl(DEV_HOST_LAN_IP, API_SERVICE_PORT))
  }

  return candidates
}

export function rewriteLoopbackToHost(baseUrl: string, host: string): string {
  let result: string = baseUrl
  result = replaceAllLiteral(result, '127.0.0.1', host)
  result = replaceAllLiteral(result, 'localhost', host)
  result = replaceAllLiteral(result, 'LOCALHOST', host)
  return result
}

export function buildHttpBaseUrl(host: string, port: number): string {
  return `http://${host}:${port}`
}

export function isEmulatorGatewayBaseUrl(baseUrl: string): boolean {
  return baseUrl.trim().toLowerCase().indexOf(EMULATOR_HOST_GATEWAY) >= 0
}

export function networkFailureHint(details?: string): string {
  const detailText = details ?? ''
  const lower = detailText.toLowerCase()
  if (lower.indexOf('proxy') >= 0 || lower.indexOf('2300029') >= 0 || lower.indexOf('2300007') >= 0) {
    return '连接失败。请把模拟器代理设为「无代理」，并确认电脑服务已启动；或改用电脑局域网 IP。'
  }
  return '连接失败。请确认：1) server 已启动 2) 模拟器代理为「无代理」3) 服务地址可用。'
}

function extractPort(baseUrl: string, fallbackPort: number): number {
  const schemeIndex = baseUrl.indexOf('://')
  const hostStart = schemeIndex >= 0 ? schemeIndex + 3 : 0
  const pathIndex = baseUrl.indexOf('/', hostStart)
  const hostPart = pathIndex >= 0 ? baseUrl.substring(hostStart, pathIndex) : baseUrl.substring(hostStart)
  const colonIndex = hostPart.lastIndexOf(':')
  if (colonIndex < 0) {
    return fallbackPort
  }
  const portText = hostPart.substring(colonIndex + 1)
  const parsed = Number(portText)
  if (!(parsed > 0) || `${Math.floor(parsed)}` !== portText) {
    return fallbackPort
  }
  return Math.floor(parsed)
}

function pushUnique(target: string[], value: string): void {
  if (value.length === 0) {
    return
  }
  for (let i = 0; i < target.length; i++) {
    if (target[i] === value) {
      return
    }
  }
  target.push(value)
}

function replaceAllLiteral(source: string, from: string, to: string): string {
  if (from.length === 0) {
    return source
  }
  let result: string = source
  let index: number = result.indexOf(from)
  while (index >= 0) {
    result = `${result.substring(0, index)}${to}${result.substring(index + from.length)}`
    index = result.indexOf(from, index + to.length)
  }
  return result
}
