import { http } from '@kit.NetworkKit'

import { buildServiceBaseUrlCandidates, networkFailureHint } from '../../common/ServiceBaseUrl'
import { logError, logInfo } from '../../common/logger'
import { HttpClient } from './HttpClient'

export interface ServiceProbeResult {
  ok: boolean
  baseUrl: string
  tried: string[]
  message: string
}

export class ServiceHealthProbe {
  private static readonly HEALTH_PATH: string = '/health'
  private static readonly LOG_TAG: string = 'ServiceHealthProbe'
  private static readonly TIMEOUT_MS: number = 4000

  async findReachableBaseUrl(preferredBaseUrl: string): Promise<ServiceProbeResult> {
    const candidates = buildServiceBaseUrlCandidates(preferredBaseUrl)
    const tried: string[] = []

    for (let i = 0; i < candidates.length; i++) {
      const candidate = candidates[i]
      tried.push(candidate)
      const healthy = await this.isHealthy(candidate)
      if (healthy) {
        logInfo(`Service reachable: ${candidate}`, ServiceHealthProbe.LOG_TAG)
        return {
          ok: true,
          baseUrl: candidate,
          tried: tried,
          message: `服务已连通：${candidate}`
        }
      }
      logInfo(`Service unreachable: ${candidate}`, ServiceHealthProbe.LOG_TAG)
    }

    const hint = networkFailureHint('code=2300007')
    logError('No reachable service base URL', tried.join(' | '), ServiceHealthProbe.LOG_TAG)
    return {
      ok: false,
      baseUrl: preferredBaseUrl,
      tried: tried,
      message: `${hint} 已尝试：${tried.join('、')}`
    }
  }

  async isHealthy(baseUrl: string): Promise<boolean> {
    const client = new HttpClient(baseUrl)
    try {
      const response = await client.request({
        path: ServiceHealthProbe.HEALTH_PATH,
        method: http.RequestMethod.GET,
        readTimeout: ServiceHealthProbe.TIMEOUT_MS,
        connectTimeout: ServiceHealthProbe.TIMEOUT_MS
      })
      return response.statusCode >= 200 && response.statusCode < 300
    } catch (_error) {
      return false
    }
  }
}
