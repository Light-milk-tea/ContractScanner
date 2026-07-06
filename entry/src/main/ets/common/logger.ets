import { hilog } from '@kit.PerformanceAnalysisKit'

export const LOG_DOMAIN = 0x0000
export const LOG_TAG = 'ContractScanner'

export function logInfo(message: string, tag: string = LOG_TAG): void {
  hilog.info(LOG_DOMAIN, tag, '%{public}s', message)
}

export function logWarn(message: string, tag: string = LOG_TAG): void {
  hilog.warn(LOG_DOMAIN, tag, '%{public}s', message)
}

export function logError(message: string, details: string = '', tag: string = LOG_TAG): void {
  if (details.length === 0) {
    hilog.error(LOG_DOMAIN, tag, '%{public}s', message)
    return
  }
  hilog.error(LOG_DOMAIN, tag, '%{public}s', `${message} | ${details}`)
}
