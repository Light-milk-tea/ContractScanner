import { common } from '@kit.AbilityKit'
import { preferences } from '@kit.ArkData'
import { BusinessError } from '@kit.BasicServicesKit'
import { AppError, ErrorCode } from '../../common/errors'
import { logError } from '../../common/logger'

const SESSION_STORE_NAME: string = 'contract_scanner_session'

export class SessionStore {
  store?: preferences.Preferences = undefined

  async getString(context: common.UIAbilityContext, key: string, defaultValue: string): Promise<string> {
    try {
      const sessionStore = await this.getStore(context)
      return sessionStore.getSync(key, defaultValue) as string
    } catch (error) {
      const businessError: BusinessError = error as BusinessError
      logError('SessionStore getString failed', `key=${key}, code=${businessError.code}, message=${businessError.message}`, 'SessionStore')
      return defaultValue
    }
  }

  async putString(context: common.UIAbilityContext, key: string, value: string): Promise<void> {
    try {
      const sessionStore = await this.getStore(context)
      sessionStore.putSync(key, value)
      await this.flushStore(sessionStore)
    } catch (error) {
      const businessError: BusinessError = error as BusinessError
      logError('SessionStore putString failed', `key=${key}, code=${businessError.code}, message=${businessError.message}`, 'SessionStore')
    }
  }

  async delete(context: common.UIAbilityContext, key: string): Promise<void> {
    try {
      const sessionStore = await this.getStore(context)
      sessionStore.deleteSync(key)
      await this.flushStore(sessionStore)
    } catch (error) {
      const businessError: BusinessError = error as BusinessError
      logError('SessionStore delete failed', `key=${key}, code=${businessError.code}, message=${businessError.message}`, 'SessionStore')
    }
  }

  async getStore(context: common.UIAbilityContext): Promise<preferences.Preferences> {
    if (this.store !== undefined) {
      return this.store
    }

    try {
      const options: preferences.Options = {
        name: SESSION_STORE_NAME
      }
      this.store = await preferences.getPreferences(context, options)
      return this.store
    } catch (error) {
      const businessError: BusinessError = error as BusinessError
      logError(
        'SessionStore getStore failed',
        `name=${SESSION_STORE_NAME}, code=${businessError.code}, message=${businessError.message}`,
        'SessionStore'
      )
      throw new AppError(ErrorCode.SYS_500, '本地缓存初始化失败', businessError.message)
    }
  }

  async flushStore(store: preferences.Preferences): Promise<void> {
    const flushTask: Promise<void> = new Promise<void>((resolve: () => void, reject: (reason?: BusinessError) => void) => {
      store.flush((error: BusinessError) => {
        if (error !== undefined && error.code !== 0) {
          reject(error)
          return
        }
        resolve()
      })
    })
    await flushTask
  }
}
