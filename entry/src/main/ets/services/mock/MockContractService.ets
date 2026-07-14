import { AnalyzeStatus } from '../../model/enums/AnalyzeStatus'
import { DemoFaultMode, DemoSamplePreset } from '../../model/enums/DemoMode'
import { RiskLevel } from '../../model/enums/RiskLevel'

const MOCK_TASK_PREFIX: string = 'demo-task-'
const LEGACY_MOCK_TASK_ID: string = 'demo-task-001'

export interface MockTaskStatusData {
  taskId: string
  status: AnalyzeStatus
  errorMessage?: string
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

export interface MockDemoSampleData {
  preset: DemoSamplePreset
  title: string
  fileName: string
  inlineText: string
  summary: string
}

interface MockTaskProfile {
  preset: DemoSamplePreset
  faultMode: DemoFaultMode
}

export class MockContractService {
  static buildMockTaskId(
    preset: DemoSamplePreset = DemoSamplePreset.HIGH_RISK,
    faultMode: DemoFaultMode = DemoFaultMode.NONE
  ): string {
    return `${MOCK_TASK_PREFIX}${preset}__${faultMode}__${Date.now()}`
  }

  static isMockTask(taskId: string): boolean {
    return taskId.indexOf(MOCK_TASK_PREFIX) === 0
  }

  static mockNoticeText(taskId: string): string {
    const profile = MockContractService.parseTaskProfile(taskId)
    if (profile.faultMode === DemoFaultMode.WEAK_NETWORK) {
      return '当前处于弱网演示模式，状态推进会刻意放慢以展示等待反馈。'
    }
    if (profile.faultMode === DemoFaultMode.TIMEOUT) {
      return '当前处于超时演示模式，任务会在模型分析阶段模拟超时失败。'
    }
    if (profile.faultMode === DemoFaultMode.SERVICE_ERROR) {
      return '当前处于服务异常演示模式，任务会快速进入失败态。'
    }
    if (profile.faultMode === DemoFaultMode.DEGRADE_TO_DEMO) {
      return '当前处于降级展示模式，页面将直接展示本地演示结果。'
    }
    return profile.preset === DemoSamplePreset.LOW_RISK
      ? '当前展示低风险演示样例，可用于快速讲解“可签但需补充”的合同情形。'
      : '当前展示高风险演示样例，可用于快速讲解“需重点复核”的合同情形。'
  }

  static getDemoStepDelayMillis(taskId: string): number {
    const profile = MockContractService.parseTaskProfile(taskId)
    return profile.faultMode === DemoFaultMode.WEAK_NETWORK ? 2200 : 1000
  }

  static getDemoTotalSteps(taskId: string): number {
    const profile = MockContractService.parseTaskProfile(taskId)
    if (profile.faultMode === DemoFaultMode.WEAK_NETWORK) {
      return 5
    }
    if (profile.faultMode === DemoFaultMode.SERVICE_ERROR) {
      return 1
    }
    return 3
  }

  static getDemoSample(preset: DemoSamplePreset): MockDemoSampleData {
    if (preset === DemoSamplePreset.LOW_RISK) {
      return {
        preset: DemoSamplePreset.LOW_RISK,
        title: '低风险样例',
        fileName: 'low_risk_contract_demo.txt',
        inlineText: 'inline://甲方应于每月10日前支付服务费，逾期超过5日按未付款项每日0.03%支付违约金。双方确认需求变更应以邮件书面确认。争议优先协商，协商不成提交乙方所在地仲裁委员会处理。合同到期前15日双方确认是否续签，未确认则自然终止。',
        summary: '适合展示“整体可签、仅有轻微补充建议”的低风险结果。'
      }
    }

    return {
      preset: DemoSamplePreset.HIGH_RISK,
      title: '高风险样例',
      fileName: 'high_risk_contract_demo.txt',
      inlineText: 'inline://甲方可单方解释本合同全部条款且无需承担通知义务。乙方提前解约需支付剩余全部租金作为违约金。甲方可在验收后60个工作日内自行决定是否退还押金。争议提交甲方所在地法院处理，乙方不得提出异议。若乙方未在到期前45日提出书面异议，本合同自动续约两年。',
      summary: '适合展示“自动续约、违约责任失衡、押金退还不明确”等高风险结果。'
    }
  }

  static getTaskStatus(currentStep: number, taskId: string): MockTaskStatusData {
    const profile = MockContractService.parseTaskProfile(taskId)
    const result: MockTaskStatusData = {
      taskId: taskId.length > 0 ? taskId : MockContractService.buildMockTaskId(),
      status: MockContractService.statusAtStep(currentStep, profile.faultMode)
    }
    if (result.status === AnalyzeStatus.FAILED) {
      result.errorMessage = MockContractService.mockFailureMessage(profile.faultMode)
    }
    return result
  }

  static getAnalysisResult(taskId: string): MockAnalysisResultData {
    const profile = MockContractService.parseTaskProfile(taskId)
    return profile.preset === DemoSamplePreset.LOW_RISK
      ? MockContractService.buildLowRiskResult(taskId, profile.faultMode)
      : MockContractService.buildHighRiskResult(taskId, profile.faultMode)
  }

  static statusAtStep(currentStep: number, faultMode: DemoFaultMode): AnalyzeStatus {
    if (faultMode === DemoFaultMode.SERVICE_ERROR) {
      return currentStep <= 0 ? AnalyzeStatus.PENDING : AnalyzeStatus.FAILED
    }
    if (faultMode === DemoFaultMode.WEAK_NETWORK) {
      if (currentStep <= 1) {
        return AnalyzeStatus.PENDING
      }
      if (currentStep <= 3) {
        return AnalyzeStatus.OCR_RUNNING
      }
      if (currentStep === 4) {
        return AnalyzeStatus.LLM_RUNNING
      }
      return AnalyzeStatus.SUCCESS
    }
    if (currentStep <= 0) {
      return AnalyzeStatus.PENDING
    }
    if (currentStep === 1) {
      return AnalyzeStatus.OCR_RUNNING
    }
    if (currentStep === 2) {
      return AnalyzeStatus.LLM_RUNNING
    }
    if (faultMode === DemoFaultMode.TIMEOUT) {
      return AnalyzeStatus.FAILED
    }
    return AnalyzeStatus.SUCCESS
  }

  private static parseTaskProfile(taskId: string): MockTaskProfile {
    const fallbackProfile: MockTaskProfile = {
      preset: DemoSamplePreset.HIGH_RISK,
      faultMode: DemoFaultMode.NONE
    }
    if (taskId.length === 0 || taskId === LEGACY_MOCK_TASK_ID) {
      return fallbackProfile
    }

    const normalized = taskId.indexOf(MOCK_TASK_PREFIX) === 0 ? taskId.substring(MOCK_TASK_PREFIX.length) : taskId
    const segments = normalized.split('__')
    const rawPreset = segments.length > 0 ? segments[0] : ''
    const rawFaultMode = segments.length > 1 ? segments[1] : ''

    const profile: MockTaskProfile = {
      preset: MockContractService.isDemoSamplePreset(rawPreset) ? rawPreset as DemoSamplePreset : DemoSamplePreset.HIGH_RISK,
      faultMode: MockContractService.isDemoFaultMode(rawFaultMode) ? rawFaultMode as DemoFaultMode : DemoFaultMode.NONE
    }
    return profile
  }

  private static isDemoSamplePreset(rawValue: string): boolean {
    return rawValue === DemoSamplePreset.HIGH_RISK || rawValue === DemoSamplePreset.LOW_RISK
  }

  private static isDemoFaultMode(rawValue: string): boolean {
    return rawValue === DemoFaultMode.NONE
      || rawValue === DemoFaultMode.WEAK_NETWORK
      || rawValue === DemoFaultMode.TIMEOUT
      || rawValue === DemoFaultMode.SERVICE_ERROR
      || rawValue === DemoFaultMode.DEGRADE_TO_DEMO
  }

  private static mockFailureMessage(faultMode: DemoFaultMode): string {
    if (faultMode === DemoFaultMode.SERVICE_ERROR) {
      return '演示模式已触发：服务端暂时不可用，请稍后重试。'
    }
    if (faultMode === DemoFaultMode.TIMEOUT) {
      return '演示模式已触发：模型响应超时，系统已停止当前任务。'
    }
    return '演示模式已触发：任务执行失败。'
  }

  private static buildHighRiskResult(taskId: string, faultMode: DemoFaultMode): MockAnalysisResultData {
    const clauses: MockClauseRiskData[] = [
      {
        clauseId: 'clause-001',
        title: '自动续约条款',
        originalText: '若乙方未在到期前45日提出书面异议，本合同自动续约两年。',
        plainText: '只要你没提前 45 天明确反对，合同就会自动再续两年，时间很长。',
        riskLevel: RiskLevel.RED,
        riskReason: '续约周期过长，且缺少到期提醒与二次确认机制，容易让承租方被动续签。',
        suggestion: '建议改为“到期前双方重新确认后续签”，并将提醒期缩短至 15 日左右。',
        anchors: { page: 2, paragraph: 2 }
      },
      {
        clauseId: 'clause-002',
        title: '押金退还条款',
        originalText: '甲方可在验收后60个工作日内自行决定是否退还押金。',
        plainText: '押金什么时候退、退多少都由对方单方决定，对你很不利。',
        riskLevel: RiskLevel.RED,
        riskReason: '退还条件、时间点和扣减依据均不明确，存在长期拖延或随意扣减风险。',
        suggestion: '建议明确“验收合格后 5-10 个工作日内全额退还”，并列出可扣减情形。',
        anchors: { page: 3, paragraph: 1 }
      },
      {
        clauseId: 'clause-003',
        title: '违约责任条款',
        originalText: '乙方提前解约需支付剩余全部租金作为违约金。',
        plainText: '哪怕你提前退租，也要把后面所有租金都赔掉，责任明显过重。',
        riskLevel: RiskLevel.YELLOW,
        riskReason: '违约责任明显失衡，超过常见商业租赁中的合理损失补偿范围。',
        suggestion: '建议改为“按实际损失或 1-2 个月租金封顶”计算违约责任。',
        anchors: { page: 4, paragraph: 3 }
      }
    ]

    return {
      taskId: taskId.length > 0 ? taskId : MockContractService.buildMockTaskId(DemoSamplePreset.HIGH_RISK, faultMode),
      contractName: faultMode === DemoFaultMode.DEGRADE_TO_DEMO ? '高风险样例合同（降级演示）' : '高风险样例合同',
      overallSummary: faultMode === DemoFaultMode.DEGRADE_TO_DEMO
        ? '当前结果来自本地降级展示数据，用于在真实服务不可用时继续稳定完成答辩讲解。该样例聚焦自动续约、押金退还不明与违约责任失衡三类高风险问题。'
        : '该样例用于展示高风险合同分析结果，重点覆盖自动续约、押金退还不明和违约责任失衡三类典型问题。',
      signBeforeChecklist: [
        '确认自动续约是否改为到期后二次签署',
        '要求明确押金退还时间、条件和扣减依据',
        '将违约责任调整为与实际损失相匹配'
      ],
      riskStats: {
        red: 2,
        yellow: 1,
        green: 0
      },
      clauses: clauses,
      generatedAt: '2026-07-14 10:30'
    }
  }

  private static buildLowRiskResult(taskId: string, faultMode: DemoFaultMode): MockAnalysisResultData {
    const clauses: MockClauseRiskData[] = [
      {
        clauseId: 'clause-101',
        title: '付款约定条款',
        originalText: '甲方应于每月10日前支付服务费，逾期超过5日按未付款项每日0.03%支付违约金。',
        plainText: '付款时间清楚，逾期责任也比较克制，整体风险较低。',
        riskLevel: RiskLevel.GREEN,
        riskReason: '付款节点、宽限期和违约责任均较明确，未见明显失衡约定。',
        suggestion: '建议补充发票交付与对账确认节点，进一步降低执行歧义。',
        anchors: { page: 1, paragraph: 2 }
      },
      {
        clauseId: 'clause-102',
        title: '通知与变更条款',
        originalText: '双方确认需求变更应以邮件书面确认，邮箱变更应提前2个工作日通知对方。',
        plainText: '需求变更和通知渠道都约定得比较清楚，执行时更容易留痕。',
        riskLevel: RiskLevel.GREEN,
        riskReason: '属于较规范的书面确认机制，能够降低后续争议。',
        suggestion: '可补充双方默认联系人信息，方便快速核验通知是否送达。',
        anchors: { page: 2, paragraph: 4 }
      },
      {
        clauseId: 'clause-103',
        title: '续签条款',
        originalText: '合同到期前15日双方确认是否续签，未确认则合同自然终止。',
        plainText: '续签需要双方重新确认，不会自动续约，整体更稳妥。',
        riskLevel: RiskLevel.YELLOW,
        riskReason: '虽然整体较合理，但建议明确“确认方式”和“逾期未回复”处理口径。',
        suggestion: '建议增加书面确认方式，并约定未续签时的交接节点。',
        anchors: { page: 3, paragraph: 1 }
      }
    ]

    return {
      taskId: taskId.length > 0 ? taskId : MockContractService.buildMockTaskId(DemoSamplePreset.LOW_RISK, faultMode),
      contractName: faultMode === DemoFaultMode.DEGRADE_TO_DEMO ? '低风险样例合同（降级演示）' : '低风险样例合同',
      overallSummary: faultMode === DemoFaultMode.DEGRADE_TO_DEMO
        ? '当前结果来自本地降级展示数据，用于在真实服务不可用时继续完成稳定讲解。该样例展示的是“整体可签，但仍建议补充细节”的低风险合同。'
        : '该样例用于展示低风险合同分析结果，整体条款较规范，仅有少量需要补充说明的细节项。',
      signBeforeChecklist: [
        '确认邮箱、联系人等通知信息是否完整',
        '补充发票、对账与交付的时间节点',
        '明确续签确认方式和交接安排'
      ],
      riskStats: {
        red: 0,
        yellow: 1,
        green: 2
      },
      clauses: clauses,
      generatedAt: '2026-07-14 10:35'
    }
  }
}
