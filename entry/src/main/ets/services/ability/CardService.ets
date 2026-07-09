import { formBindingData, formProvider } from '@kit.FormKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { common } from '@kit.AbilityKit'
import { RoutePath, StorageKey } from '../../common/constants'
import { logError } from '../../common/logger'
import { Contract } from '../../model/domain/Contract'
import { AnalyzeStatus } from '../../model/enums/AnalyzeStatus'
import { CacheService } from '../storage/CacheService'
import { SessionStore } from '../storage/SessionStore'

export interface CardSnapshot {
  pageUrl: string
  contractName: string
  statusText: string
  generatedAt: string
  taskId: string
  baseUrl: string
  actionText: string
  source: string
}

class CardFormData {
  cardTitle: string = ''
  contractName: string = ''
  statusText: string = ''
  generatedAt: string = ''
  taskId: string = ''
  baseUrl: string = ''
  pageUrl: string = ''
  entrySource: string = ''
  actionText: string = ''
}

export class CardService {
  cacheService: CacheService = new CacheService()
  sessionStore: SessionStore = new SessionStore()

  buildDefaultSnapshot(): CardSnapshot {
    const snapshot: CardSnapshot = {
      pageUrl: RoutePath.HOME,
      contractName: '暂无最近分析结果',
      statusText: '完成一次分析并进入结果页后，这里会展示最近合同摘要。',
      generatedAt: '',
      taskId: '',
      baseUrl: '',
      actionText: '打开应用',
      source: 'card'
    }
    return snapshot
  }

  async loadLatestSnapshot(context: common.Context): Promise<CardSnapshot> {
    const recentContracts = await this.cacheService.loadRecentContracts(context)
    if (recentContracts.length === 0) {
      return this.buildDefaultSnapshot()
    }

    return this.mapContractToSnapshot(recentContracts[0])
  }

  buildFormData(snapshot: CardSnapshot): CardFormData {
    const formData: CardFormData = new CardFormData()
    formData.cardTitle = '最近合同摘要'
    formData.contractName = snapshot.contractName
    formData.statusText = snapshot.statusText
    formData.generatedAt = snapshot.generatedAt
    formData.taskId = snapshot.taskId
    formData.baseUrl = snapshot.baseUrl
    formData.pageUrl = snapshot.pageUrl
    formData.entrySource = snapshot.source
    formData.actionText = snapshot.actionText
    return formData
  }

  async registerForm(context: common.Context, formId: string): Promise<void> {
    if (formId.length === 0) {
      return
    }

    const formIds = await this.loadFormIds(context)
    for (let i: number = 0; i < formIds.length; i++) {
      if (formIds[i] === formId) {
        return
      }
    }
    formIds.push(formId)
    await this.sessionStore.putString(context, StorageKey.CARD_FORM_IDS, JSON.stringify(formIds))
  }

  async unregisterForm(context: common.Context, formId: string): Promise<void> {
    const formIds = await this.loadFormIds(context)
    const filteredIds: string[] = []
    for (let i: number = 0; i < formIds.length; i++) {
      if (formIds[i] !== formId) {
        filteredIds.push(formIds[i])
      }
    }
    await this.sessionStore.putString(context, StorageKey.CARD_FORM_IDS, JSON.stringify(filteredIds))
  }

  async refreshRegisteredForms(context: common.Context): Promise<void> {
    const formIds = await this.loadFormIds(context)
    if (formIds.length === 0) {
      return
    }

    const snapshot = await this.loadLatestSnapshot(context)
    const bindingData = formBindingData.createFormBindingData(this.buildFormData(snapshot))
    for (let i: number = 0; i < formIds.length; i++) {
      try {
        await formProvider.updateForm(formIds[i], bindingData)
      } catch (error) {
        const businessError: BusinessError = error as BusinessError
        logError(
          'Update widget card failed',
          `formId=${formIds[i]}, code=${businessError.code}, message=${businessError.message}`,
          'CardService'
        )
      }
    }
  }

  async loadFormIds(context: common.Context): Promise<string[]> {
    const serialized = await this.sessionStore.getString(context, StorageKey.CARD_FORM_IDS, '')
    if (serialized.length === 0) {
      return []
    }

    try {
      const parsed = JSON.parse(serialized) as string[]
      if (!Array.isArray(parsed)) {
        return []
      }

      const formIds: string[] = []
      for (let i: number = 0; i < parsed.length; i++) {
        if (typeof parsed[i] === 'string' && parsed[i].length > 0) {
          formIds.push(parsed[i])
        }
      }
      return formIds
    } catch (error) {
      logError('Parse card form ids failed', JSON.stringify(error), 'CardService')
      return []
    }
  }

  mapContractToSnapshot(contract: Contract): CardSnapshot {
    const snapshot: CardSnapshot = {
      pageUrl: RoutePath.RESULT_OVERVIEW,
      contractName: contract.contractName,
      statusText: this.statusText(contract.status),
      generatedAt: contract.createdAt ?? '生成时间待更新',
      taskId: contract.taskId,
      baseUrl: contract.baseUrl ?? '',
      actionText: '查看结果总览',
      source: 'card'
    }
    return snapshot
  }

  statusText(status?: AnalyzeStatus): string {
    switch (status) {
      case AnalyzeStatus.PENDING:
        return '状态：等待开始'
      case AnalyzeStatus.OCR_RUNNING:
        return '状态：OCR 处理中'
      case AnalyzeStatus.LLM_RUNNING:
        return '状态：模型分析中'
      case AnalyzeStatus.SUCCESS:
        return '状态：分析完成，可点击继续阅读'
      case AnalyzeStatus.FAILED:
        return '状态：分析失败，请回到应用重试'
      default:
        return '状态：最近结果已缓存，可从卡片继续查看'
    }
  }
}
