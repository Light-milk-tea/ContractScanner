import { common } from '@kit.AbilityKit'
import { StorageKey } from '../../common/constants'
import { DemoFaultMode } from '../../model/enums/DemoMode'
import { SessionStore } from './SessionStore'

export class UserSettingsService {
  sessionStore: SessionStore = new SessionStore()

  async loadApiKey(context: common.UIAbilityContext): Promise<string> {
    return await this.sessionStore.getString(context, StorageKey.MODEL_API_KEY, '')
  }

  async saveApiKey(context: common.UIAbilityContext, apiKey: string): Promise<void> {
    const normalizedApiKey: string = apiKey.trim()
    await this.sessionStore.putString(context, StorageKey.MODEL_API_KEY, normalizedApiKey)
  }

  async clearApiKey(context: common.UIAbilityContext): Promise<void> {
    await this.sessionStore.delete(context, StorageKey.MODEL_API_KEY)
  }

  async loadServiceBaseUrl(context: common.UIAbilityContext, defaultValue: string): Promise<string> {
    return await this.sessionStore.getString(context, StorageKey.SERVICE_BASE_URL, defaultValue)
  }

  async saveServiceBaseUrl(context: common.UIAbilityContext, baseUrl: string): Promise<void> {
    const normalizedBaseUrl: string = baseUrl.trim()
    await this.sessionStore.putString(context, StorageKey.SERVICE_BASE_URL, normalizedBaseUrl)
  }

  async clearServiceBaseUrl(context: common.UIAbilityContext): Promise<void> {
    await this.sessionStore.delete(context, StorageKey.SERVICE_BASE_URL)
  }

  async loadDemoFaultMode(context: common.UIAbilityContext): Promise<DemoFaultMode> {
    const rawValue = await this.sessionStore.getString(context, StorageKey.DEMO_FAULT_MODE, DemoFaultMode.NONE)
    return this.isDemoFaultMode(rawValue) ? rawValue as DemoFaultMode : DemoFaultMode.NONE
  }

  async saveDemoFaultMode(context: common.UIAbilityContext, demoFaultMode: DemoFaultMode): Promise<void> {
    await this.sessionStore.putString(context, StorageKey.DEMO_FAULT_MODE, demoFaultMode)
  }

  async clearDemoFaultMode(context: common.UIAbilityContext): Promise<void> {
    await this.sessionStore.delete(context, StorageKey.DEMO_FAULT_MODE)
  }

  private isDemoFaultMode(rawValue: string): boolean {
    return rawValue === DemoFaultMode.NONE
      || rawValue === DemoFaultMode.WEAK_NETWORK
      || rawValue === DemoFaultMode.TIMEOUT
      || rawValue === DemoFaultMode.SERVICE_ERROR
      || rawValue === DemoFaultMode.DEGRADE_TO_DEMO
  }
}
