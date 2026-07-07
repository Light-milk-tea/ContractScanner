import { AnalyzeStatus } from '../enums/AnalyzeStatus'

export interface Contract {
  taskId: string
  contractName: string
  status?: AnalyzeStatus
  createdAt?: string
  baseUrl?: string
}
