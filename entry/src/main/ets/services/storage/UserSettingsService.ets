import { common } from '@kit.AbilityKit'
import { StorageKey } from '../../common/constants'
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
}
