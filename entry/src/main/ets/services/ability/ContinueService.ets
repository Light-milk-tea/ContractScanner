import { AbilityConstant, Want, common } from '@kit.AbilityKit'
import { RouteParams } from '../../app/AppRouter'
import { RoutePath, StorageKey } from '../../common/constants'
import { logError } from '../../common/logger'
import { SessionStore } from '../storage/SessionStore'

export interface ContinuePayload {
  pageUrl: string
  taskId: string
  baseUrl: string
  contractName: string
  generatedAt: string
  source: string
}

interface ContinuableContext {
  setMissionContinueState(state: AbilityConstant.ContinueState): void
}

export class ContinueService {
  sessionStore: SessionStore = new SessionStore()

  async saveLastViewedResult(context: common.UIAbilityContext, payload: ContinuePayload): Promise<void> {
    await this.sessionStore.putString(context, StorageKey.LAST_VIEWED_RESULT, JSON.stringify(payload))
  }

  async loadLastViewedResult(context: common.UIAbilityContext): Promise<ContinuePayload | undefined> {
    const serialized = await this.sessionStore.getString(context, StorageKey.LAST_VIEWED_RESULT, '')
    return this.parseSerializedPayload(serialized)
  }

  async clearLastViewedResult(context: common.UIAbilityContext): Promise<void> {
    await this.sessionStore.delete(context, StorageKey.LAST_VIEWED_RESULT)
  }

  async savePendingRoute(context: common.UIAbilityContext, payload: ContinuePayload): Promise<void> {
    await this.sessionStore.putString(context, StorageKey.PENDING_ROUTE_PARAMS, JSON.stringify(payload))
  }

  async consumePendingRoute(context: common.UIAbilityContext): Promise<ContinuePayload | undefined> {
    const serialized = await this.sessionStore.getString(context, StorageKey.PENDING_ROUTE_PARAMS, '')
    await this.sessionStore.delete(context, StorageKey.PENDING_ROUTE_PARAMS)
    return this.parseSerializedPayload(serialized)
  }

  fillWantParams(wantParam: Record<string, Object>, payload: ContinuePayload): void {
    wantParam['continuePayload'] = JSON.stringify(payload)
  }

  parseWantPayload(want: Want): ContinuePayload | undefined {
    const parameters = want.parameters
    if (parameters === undefined) {
      return undefined
    }

    const continuePayload = this.parseSerializedPayload(parameters['continuePayload'] as string | undefined)
    if (continuePayload !== undefined) {
      return continuePayload
    }

    const cardPayload = this.parseCardPayload(parameters)
    if (cardPayload !== undefined) {
      return cardPayload
    }

    return undefined
  }

  toRouteParams(payload: ContinuePayload): RouteParams {
    const params: RouteParams = new RouteParams()
    params.taskId = payload.taskId
    params.baseUrl = payload.baseUrl
    return params
  }

  buildResultPayload(taskId: string, baseUrl: string, contractName: string, generatedAt: string): ContinuePayload {
    const payload: ContinuePayload = {
      pageUrl: RoutePath.RESULT_OVERVIEW,
      taskId: taskId,
      baseUrl: baseUrl,
      contractName: contractName,
      generatedAt: generatedAt,
      source: 'continuation'
    }
    return payload
  }

  setMissionContinueActive(context: common.UIAbilityContext, active: boolean): void {
    try {
      const missionContext = context as ContinuableContext
      missionContext.setMissionContinueState(active ? AbilityConstant.ContinueState.ACTIVE : AbilityConstant.ContinueState.INACTIVE)
    } catch (error) {
      logError('Set mission continuation state failed', JSON.stringify(error), 'ContinueService')
    }
  }

  parseSerializedPayload(serialized: string | undefined): ContinuePayload | undefined {
    if (serialized === undefined || serialized.length === 0) {
      return undefined
    }

    try {
      const record = JSON.parse(serialized) as Record<string, Object>
      return this.mapRecordToPayload(record)
    } catch (error) {
      logError('Parse continuation payload failed', JSON.stringify(error), 'ContinueService')
      return undefined
    }
  }

  parseCardPayload(parameters: Record<string, Object>): ContinuePayload | undefined {
    const rawParams = parameters['params']
    if (typeof rawParams !== 'string' || rawParams.length === 0) {
      return undefined
    }

    try {
      const record = JSON.parse(rawParams) as Record<string, Object>
      const route = (record['route'] as string) ?? RoutePath.HOME
      const taskId = (record['taskId'] as string) ?? ''
      const baseUrl = (record['baseUrl'] as string) ?? ''
      const source = (record['source'] as string) ?? 'card'
      const payload: ContinuePayload = {
        pageUrl: route,
        taskId: taskId,
        baseUrl: baseUrl,
        contractName: '',
        generatedAt: '',
        source: source
      }
      return payload
    } catch (error) {
      logError('Parse card route payload failed', JSON.stringify(error), 'ContinueService')
      return undefined
    }
  }

  mapRecordToPayload(record: Record<string, Object>): ContinuePayload | undefined {
    const pageUrl = (record['pageUrl'] as string) ?? RoutePath.HOME
    const payload: ContinuePayload = {
      pageUrl: pageUrl,
      taskId: (record['taskId'] as string) ?? '',
      baseUrl: (record['baseUrl'] as string) ?? '',
      contractName: (record['contractName'] as string) ?? '',
      generatedAt: (record['generatedAt'] as string) ?? '',
      source: (record['source'] as string) ?? ''
    }
    return payload
  }
}
