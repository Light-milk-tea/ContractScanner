import { AnalyzeStatus } from '../../model/enums/AnalyzeStatus'
import { RiskLevel } from '../../model/enums/RiskLevel'

const MOCK_TASK_PREFIX: string = 'demo-task-'
const DEFAULT_MOCK_TASK_ID: string = 'demo-task-001'

export interface MockTaskStatusData {
  taskId: string
  status: AnalyzeStatus
}

export interface MockClauseAnchorData {
  page?: number
  paragraph?: number
}

export interface MockClauseRiskData {
  clauseId: string
  title: string
  originalText: string
  plainText: string
  riskLevel: string
  riskReason: string
  suggestion?: string
  anchors: MockClauseAnchorData
}

export interface MockAnalysisResultData {
  taskId: string
  contractName: string
  overallSummary: string
  signBeforeChecklist: string[]
  riskStats: MockRiskStatsData
  clauses: MockClauseRiskData[]
  generatedAt: string
}

export interface MockRiskStatsData {
  red: number
  yellow: number
  green: number
}

export class MockContractService {
  static buildMockTaskId(): string {
    return DEFAULT_MOCK_TASK_ID
  }

  static isMockTask(taskId: string): boolean {
    return taskId.indexOf(MOCK_TASK_PREFIX) === 0
  }

  static mockNoticeText(): string {
    return '当前使用 Mock 数据闭环，本页展示临时模拟状态流转。'
  }

  static getTaskStatus(currentStep: number, taskId: string): MockTaskStatusData {
    const result: MockTaskStatusData = {
      taskId: taskId.length > 0 ? taskId : DEFAULT_MOCK_TASK_ID,
      status: MockContractService.statusAtStep(currentStep)
    }
    return result
  }

  static getAnalysisResult(taskId: string): MockAnalysisResultData {
    const highRiskAnchor: MockClauseAnchorData = { page: 2, paragraph: 3 }
    const mediumRiskAnchor: MockClauseAnchorData = { page: 4, paragraph: 1 }
    const lowRiskAnchor: MockClauseAnchorData = { page: 5, paragraph: 2 }

    const clauses: MockClauseRiskData[] = [
      {
        clauseId: 'clause-001',
        title: '自动续约条款',
        originalText: '若任一方未在到期前 30 日提出书面异议，本合同自动续约一年。',
        plainText: '如果你没有提前 30 天明确提出不续约，合同会自动再续一年。',
        riskLevel: RiskLevel.RED,
        riskReason: '自动续约时间较长，且未明确提醒机制，可能导致用户被动续签。',
        suggestion: '建议改为到期前由双方再次确认，并缩短异议期。',
        anchors: highRiskAnchor
      },
      {
        clauseId: 'clause-002',
        title: '违约责任条款',
        originalText: '乙方违约时，应向甲方支付合同总额 30% 的违约金。',
        plainText: '只要你违约，就要按合同总价的 30% 赔偿，对你约束较重。',
        riskLevel: RiskLevel.YELLOW,
        riskReason: '违约金比例偏高，但仍可进一步结合交易性质判断是否合理。',
        suggestion: '建议增加违约金上限或按实际损失比例计算。',
        anchors: mediumRiskAnchor
      },
      {
        clauseId: 'clause-003',
        title: '通知送达条款',
        originalText: '双方确认电子邮件可作为有效通知方式。',
        plainText: '邮件通知同样算正式送达，这条款本身风险较低。',
        riskLevel: RiskLevel.GREEN,
        riskReason: '属于常见约定，且有助于固定通知方式。',
        suggestion: '建议补充邮箱变更后的通知义务。',
        anchors: lowRiskAnchor
      }
    ]

    const riskStats: MockRiskStatsData = {
      red: 1,
      yellow: 1,
      green: 1
    }

    const result: MockAnalysisResultData = {
      taskId: taskId.length > 0 ? taskId : DEFAULT_MOCK_TASK_ID,
      contractName: '办公场地租赁合同（Mock 演示）',
      overallSummary: '该结果来自客户端临时 Mock 数据闭环，用于在真实服务端未接入或不可用时继续演示主链路。',
      signBeforeChecklist: [
        '确认是否接受自动续约机制',
        '核对违约金比例是否可协商',
        '补充关键通知方式和送达地址'
      ],
      riskStats: riskStats,
      clauses: clauses,
      generatedAt: '2026-07-07 11:00'
    }
    return result
  }

  static statusAtStep(currentStep: number): AnalyzeStatus {
    if (currentStep <= 0) {
      return AnalyzeStatus.PENDING
    }
    if (currentStep === 1) {
      return AnalyzeStatus.OCR_RUNNING
    }
    if (currentStep === 2) {
      return AnalyzeStatus.LLM_RUNNING
    }
    return AnalyzeStatus.SUCCESS
  }
}
