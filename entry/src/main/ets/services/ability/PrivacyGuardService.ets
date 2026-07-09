import { common } from '@kit.AbilityKit'
import { window } from '@kit.ArkUI'
import { BusinessError } from '@kit.BasicServicesKit'
import { StorageKey } from '../../common/constants'
import { logError } from '../../common/logger'
import { SessionStore } from '../storage/SessionStore'

export class PrivacyGuardService {
  sessionStore: SessionStore = new SessionStore()

  async loadEnabled(context: common.UIAbilityContext): Promise<boolean> {
    const storedValue = await this.sessionStore.getString(context, StorageKey.PRIVACY_GUARD_ENABLED, 'false')
    return storedValue === 'true'
  }

  async saveEnabled(context: common.UIAbilityContext, enabled: boolean): Promise<void> {
    await this.sessionStore.putString(context, StorageKey.PRIVACY_GUARD_ENABLED, enabled ? 'true' : 'false')
  }

  async applyWindowPrivacyMode(context: common.UIAbilityContext, enabled: boolean): Promise<void> {
    try {
      const currentWindow = await window.getLastWindow(context)
      await this.setWindowPrivacyMode(currentWindow, enabled)
    } catch (error) {
      const businessError: BusinessError = error as BusinessError
      logError(
        'Apply privacy guard failed',
        `enabled=${enabled}, code=${businessError.code}, message=${businessError.message}`,
        'PrivacyGuardService'
      )
    }
  }

  async setWindowPrivacyMode(targetWindow: window.Window, enabled: boolean): Promise<void> {
    const privacyTask: Promise<void> = new Promise<void>((resolve: () => void, reject: (reason?: BusinessError) => void) => {
      targetWindow.setWindowPrivacyMode(enabled, (error: BusinessError) => {
        if (error !== undefined && error.code !== 0) {
          reject(error)
          return
        }
        resolve()
      })
    })
    await privacyTask
  }
}
