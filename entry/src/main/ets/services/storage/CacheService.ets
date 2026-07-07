import { common } from '@kit.AbilityKit'
import { StorageKey } from '../../common/constants'
import { logError, logWarn } from '../../common/logger'
import { Contract } from '../../model/domain/Contract'
import { AnalyzeStatus } from '../../model/enums/AnalyzeStatus'
import { SessionStore } from './SessionStore'

const RECENT_CONTRACT_LIMIT: number = 5

interface CachedContractRecord {
  taskId: string
  contractName: string
  status: string
  createdAt: string
  baseUrl: string
}

export class CacheService {
  sessionStore: SessionStore = new SessionStore()

  async loadRecentContracts(context: common.UIAbilityContext): Promise<Contract[]> {
    const cachedRecords = await this.loadCachedRecords(context)
    const contracts: Contract[] = []
    for (let i: number = 0; i < cachedRecords.length; i++) {
      contracts.push(this.mapRecordToContract(cachedRecords[i]))
    }
    return contracts
  }

  async saveRecentContract(context: common.UIAbilityContext, contract: Contract): Promise<void> {
    if (contract.taskId.length === 0 || contract.contractName.length === 0) {
      logWarn('Skip saving empty recent contract', 'CacheService')
      return
    }

    const cachedRecords = await this.loadCachedRecords(context)
    const mergedRecords = this.mergeRecords(this.mapContractToRecord(contract), cachedRecords)
    await this.sessionStore.putString(context, StorageKey.RECENT_CONTRACTS, JSON.stringify(mergedRecords))
  }

  async clearRecentContracts(context: common.UIAbilityContext): Promise<void> {
    await this.sessionStore.delete(context, StorageKey.RECENT_CONTRACTS)
  }

  async loadCachedRecords(context: common.UIAbilityContext): Promise<CachedContractRecord[]> {
    const serialized = await this.sessionStore.getString(context, StorageKey.RECENT_CONTRACTS, '')
    return this.parseRecords(serialized)
  }

  parseRecords(serialized: string): CachedContractRecord[] {
    if (serialized.length === 0) {
      return []
    }

    try {
      const parsed = JSON.parse(serialized) as CachedContractRecord[]
      if (!Array.isArray(parsed)) {
        return []
      }

      const records: CachedContractRecord[] = []
      for (let i: number = 0; i < parsed.length; i++) {
        const item = parsed[i]
        if (item.taskId.length === 0 || item.contractName.length === 0) {
          continue
        }

        const record: CachedContractRecord = {
          taskId: item.taskId,
          contractName: item.contractName,
          status: item.status,
          createdAt: item.createdAt,
          baseUrl: item.baseUrl
        }
        records.push(record)
      }
      return records
    } catch (error) {
      logError('Parse recent contracts failed', JSON.stringify(error), 'CacheService')
      return []
    }
  }

  mapContractToRecord(contract: Contract): CachedContractRecord {
    const record: CachedContractRecord = {
      taskId: contract.taskId,
      contractName: contract.contractName,
      status: this.statusToString(contract.status),
      createdAt: contract.createdAt ?? '',
      baseUrl: contract.baseUrl ?? ''
    }
    return record
  }

  mapRecordToContract(record: CachedContractRecord): Contract {
    const contract: Contract = {
      taskId: record.taskId,
      contractName: record.contractName,
      status: this.statusFromString(record.status),
      createdAt: record.createdAt,
      baseUrl: record.baseUrl
    }
    return contract
  }

  mergeRecords(targetRecord: CachedContractRecord, existingRecords: CachedContractRecord[]): CachedContractRecord[] {
    const mergedRecords: CachedContractRecord[] = [targetRecord]
    for (let i: number = 0; i < existingRecords.length; i++) {
      const currentRecord = existingRecords[i]
      if (currentRecord.taskId === targetRecord.taskId) {
        continue
      }
      if (mergedRecords.length >= RECENT_CONTRACT_LIMIT) {
        break
      }
      mergedRecords.push(currentRecord)
    }
    return mergedRecords
  }

  statusToString(status?: AnalyzeStatus): string {
    if (status === undefined) {
      return ''
    }
    return status
  }

  statusFromString(status: string): AnalyzeStatus | undefined {
    switch (status) {
      case AnalyzeStatus.PENDING:
        return AnalyzeStatus.PENDING
      case AnalyzeStatus.OCR_RUNNING:
        return AnalyzeStatus.OCR_RUNNING
      case AnalyzeStatus.LLM_RUNNING:
        return AnalyzeStatus.LLM_RUNNING
      case AnalyzeStatus.SUCCESS:
        return AnalyzeStatus.SUCCESS
      case AnalyzeStatus.FAILED:
        return AnalyzeStatus.FAILED
      default:
        return undefined
    }
  }
}
