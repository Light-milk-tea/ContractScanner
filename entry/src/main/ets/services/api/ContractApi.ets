import { AnalyzeStatus } from '../../model/enums/AnalyzeStatus'
import { AppError, ErrorCode } from '../../common/errors'
import { MockContractService } from '../mock/MockContractService'

import { HttpClient } from './HttpClient'

export interface UploadContractRequest {
  fileName: string
  fileType: string
  fileUri: string
  businessTag?: string
}

export interface UploadContractResponse {
  taskId: string
}

export interface TaskStatusResponse {
  taskId: string
  status: AnalyzeStatus
}

export interface ClauseAnchorDTO {
  page?: number
  paragraph?: number
}

export interface ClauseRiskDTO {
  clauseId: string
  title: string
  originalText: string
  plainText: string
  riskLevel: string
  riskReason: string
  suggestion?: string
  anchors: ClauseAnchorDTO
}

export interface RiskStatsDTO {
  red: number
  yellow: number
  green: number
}

export interface AnalysisResultDTO {
  taskId: string
  contractName: string
  overallSummary: string
  signBeforeChecklist: string[]
  riskStats: RiskStatsDTO
  clauses: ClauseRiskDTO[]
  generatedAt: string
}

interface JsonTaskIdResponse {
  taskId?: string
}

interface JsonTaskStatusResponse extends JsonTaskIdResponse {
  status?: string
}

export class ContractApi {
  private static readonly ANALYZE_PATH: string = '/v1/contracts/analyze'
  private static readonly STATUS_PATH_PREFIX: string = '/v1/tasks'

  private readonly httpClient: HttpClient

  constructor(baseUrl: string, httpClient?: HttpClient) {
    this.httpClient = httpClient ?? new HttpClient(baseUrl)
  }

  static buildMockTaskId(): string {
    return MockContractService.buildMockTaskId()
  }

  static isMockTask(taskId: string): boolean {
    return MockContractService.isMockTask(taskId)
  }

  static mockNoticeText(): string {
    return MockContractService.mockNoticeText()
  }

  static getMockTaskStatus(currentStep: number, taskId: string): TaskStatusResponse {
    const mockStatus = MockContractService.getTaskStatus(currentStep, taskId)
    return {
      taskId: mockStatus.taskId,
      status: mockStatus.status
    }
  }

  static getMockAnalysisResult(taskId: string): AnalysisResultDTO {
    const mockResult = MockContractService.getAnalysisResult(taskId)
    const riskStats: RiskStatsDTO = {
      red: mockResult.riskStats.red,
      yellow: mockResult.riskStats.yellow,
      green: mockResult.riskStats.green
    }
    const clauses: ClauseRiskDTO[] = []
    for (let i: number = 0; i < mockResult.clauses.length; i++) {
      const mockClause = mockResult.clauses[i]
      const anchors: ClauseAnchorDTO = {
        page: mockClause.anchors.page,
        paragraph: mockClause.anchors.paragraph
      }
      const clause: ClauseRiskDTO = {
        clauseId: mockClause.clauseId,
        title: mockClause.title,
        originalText: mockClause.originalText,
        plainText: mockClause.plainText,
        riskLevel: mockClause.riskLevel,
        riskReason: mockClause.riskReason,
        suggestion: mockClause.suggestion,
        anchors: anchors
      }
      clauses.push(clause)
    }
    const result: AnalysisResultDTO = {
      taskId: mockResult.taskId,
      contractName: mockResult.contractName,
      overallSummary: mockResult.overallSummary,
      signBeforeChecklist: mockResult.signBeforeChecklist,
      riskStats: riskStats,
      clauses: clauses,
      generatedAt: mockResult.generatedAt
    }
    return result
  }

  async uploadContract(request: UploadContractRequest): Promise<UploadContractResponse> {
    const response = await this.httpClient.post(
      ContractApi.ANALYZE_PATH,
      JSON.stringify({
        fileName: request.fileName,
        fileType: request.fileType,
        fileUri: request.fileUri,
        businessTag: request.businessTag
      })
    )

    const parsed = this.parseJsonObject<JsonTaskIdResponse>(response.body, '创建分析任务')
    const taskId = parsed.taskId ?? ''
    if (taskId.length === 0) {
      throw new AppError(ErrorCode.RESULT_001, '创建分析任务返回缺少 taskId', response.body)
    }

    return { taskId }
  }

  async getTaskStatus(taskId: string): Promise<TaskStatusResponse> {
    const response = await this.httpClient.get(`${ContractApi.STATUS_PATH_PREFIX}/${taskId}/status`)
    const parsed = this.parseJsonObject<JsonTaskStatusResponse>(response.body, '查询任务状态')
    const status = parsed.status ?? ''

    if (!this.isAnalyzeStatus(status)) {
      throw new AppError(ErrorCode.RESULT_001, '任务状态值不合法', response.body)
    }

    const typedStatus: AnalyzeStatus = status as AnalyzeStatus
    return { taskId: parsed.taskId ?? taskId, status: typedStatus }
  }

  async getAnalysisResult(taskId: string): Promise<AnalysisResultDTO> {
    const response = await this.httpClient.get(`${ContractApi.STATUS_PATH_PREFIX}/${taskId}/result`)
    return this.parseJsonObject<AnalysisResultDTO>(response.body, '获取分析结果')
  }

  private parseJsonObject<T>(jsonText: string, actionName: string): T {
    try {
      return JSON.parse(jsonText) as T
    } catch (error) {
      throw new AppError(
        ErrorCode.RESULT_001,
        `${actionName}返回的 JSON 无法解析`,
        `${jsonText} | ${this.readErrorMessage(error)}`
      )
    }
  }

  private isAnalyzeStatus(status: string): boolean {
    if (status === AnalyzeStatus.PENDING) {
      return true
    }
    if (status === AnalyzeStatus.OCR_RUNNING) {
      return true
    }
    if (status === AnalyzeStatus.LLM_RUNNING) {
      return true
    }
    if (status === AnalyzeStatus.SUCCESS) {
      return true
    }
    return status === AnalyzeStatus.FAILED
  }

  private readErrorMessage(error: Object): string {
    if (error instanceof Error) {
      return error.message
    }

    return JSON.stringify(error)
  }
}
