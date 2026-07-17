import { goBackToHome, replace } from '../app/AppRouter'
import { RouteParams } from '../app/AppRouter'
import { API_BASE_URL, RoutePath } from '../common/constants'
import { AppError, ErrorCode } from '../common/errors'
import { logError, logInfo } from '../common/logger'
import { UiColors, UiSpace } from '../common/ui/DesignTokens'
import { GhostButton, PrimaryButton } from '../components/ActionButtons'
import { AnalyzeProgress } from '../components/AnalyzeProgress'
import { EmptyState, EmptyStateType } from '../components/EmptyState'
import { PageScaffold } from '../components/PageScaffold'
import { SurfaceCard } from '../components/SurfaceCard'
import { AnalyzeStatus } from '../model/enums/AnalyzeStatus'
import { AnalyzeVM } from '../model/viewmodel/AnalyzeVM'
import { ContractApi } from '../services/api/ContractApi'

@Entry
@Component
struct AnalyzingPage {
  analyzeVM: AnalyzeVM = new AnalyzeVM()

  @State taskId: string = ''
  @State status: AnalyzeStatus = AnalyzeStatus.PENDING
  @State progressText: string = '等待开始'
  @State errorText: string = ''
  @State noticeText: string = ''
  @State progressValue: number = 0
  @State canGoResult: boolean = false
  @State isPolling: boolean = false
  @State demoStep: number = 0
  @State isNavigatingToResult: boolean = false

  timerId: number = -1
  api: ContractApi = new ContractApi(API_BASE_URL)

  aboutToAppear(): void {
    const rawParams = this.getUIContext().getRouter().getParams()
    const params = rawParams as RouteParams
    const taskId = params.taskId ?? ''
    const baseUrl = params.baseUrl ?? ''
    if (baseUrl.length > 0) {
      this.api = new ContractApi(baseUrl)
    }
    if (taskId.length > 0) {
      this.analyzeVM.setTaskId(taskId)
      this.taskId = taskId
    }

    logInfo(`Open analyzing page: taskId=${taskId}, baseUrl=${this.apiBaseUrl()}`, 'AnalyzingPage')
    this.syncFromViewModel()
    this.startPolling()
  }

  aboutToDisappear(): void {
    this.stopPolling()
    this.clearTransientUiState()
  }

  build() {
    Column() {
      PageScaffold({
        title: '分析中',
        description: '完成后会自动打开结果页。',
        backText: '返回首页',
        onBack: () => {
          this.leaveToHome()
        }
      }) {
        Column({ space: UiSpace.XL }) {
        AnalyzeProgress({
          status: this.status,
          progressText: this.progressText,
          progressValue: this.progressValue
        })

        if (this.noticeText.length > 0) {
          SurfaceCard({
            tone: 'inset',
            paddingValue: UiSpace.LG
          }) {
            Text(this.noticeText)
              .fontSize(13)
              .fontColor(UiColors.WARNING)
              .lineHeight(20)
          }
        }

        if (this.errorText.length > 0 || this.status === AnalyzeStatus.FAILED) {
          EmptyState({
            title: '分析未完成',
            description: this.errorText.length > 0 ? this.errorText : '分析任务执行失败，请重试或返回重新发起分析。',
            hint: '可点击“重试”重新发起轮询。',
            stateType: EmptyStateType.ERROR
          })
        }

        Column({ space: UiSpace.MD }) {
          if (this.canGoResult && !this.isNavigatingToResult) {
            PrimaryButton({
              label: '查看结果',
              fillWidth: true,
              isEnabled: !this.isNavigatingToResult,
              onTap: () => {
                this.goResult()
              }
            })
          }

          if (this.status === AnalyzeStatus.FAILED || this.errorText.length > 0) {
            PrimaryButton({
              label: '重试',
              fillWidth: true,
              isEnabled: !this.isPolling,
              onTap: () => {
                this.retry()
              }
            })
          }

          Row({ space: UiSpace.SM }) {
            GhostButton({
              label: '返回首页',
              fillWidth: true,
              onTap: () => {
                this.leaveToHome()
              }
            })
            if (!this.canGoResult && this.status !== AnalyzeStatus.FAILED) {
              GhostButton({
                label: this.isPolling ? '刷新中' : '开始轮询',
                fillWidth: true,
                isEnabled: !this.isPolling,
                onTap: () => {
                  this.startPolling()
                }
              })
            }
          }
          .width('100%')
        }
        .width('100%')
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
      }
    }
    .width('100%')
    .height('100%')
  }

  startPolling(): void {
    if (this.taskId.length === 0) {
      this.errorText = `缺少 taskId，无法开始轮询 (${ErrorCode.TASK_001})`
      return
    }

    if (this.timerId >= 0) {
      return
    }

    this.errorText = ''
    this.noticeText = ''
    this.canGoResult = false
    this.isPolling = true
    logInfo(`Start polling: taskId=${this.taskId}, isDemo=${this.analyzeVM.isDemoTask()}`, 'AnalyzingPage')

    if (this.analyzeVM.isDemoTask()) {
      this.demoStep = 0
      this.scheduleNextDemoStep()
      return
    }

    this.timerId = setInterval(() => {
      this.pollOnce()
    }, 1500)

    this.pollOnce()
  }

  stopPolling(): void {
    if (this.timerId < 0) {
      this.isPolling = false
      return
    }
    clearInterval(this.timerId)
    this.timerId = -1
    this.isPolling = false
  }

  async pollOnce(): Promise<void> {
    try {
      const response = await this.api.getTaskStatus(this.taskId)
      if (response.status === AnalyzeStatus.FAILED) {
        this.errorText = response.errorMessage ?? '真实分析失败，请检查 API Key、服务地址或模型额度'
      }
      this.updateStatus(response.status)
    } catch (error) {
      if (error instanceof AppError) {
        this.errorText = `${error.message} (${error.code})`
        logError('Analyze poll failed', error.details ?? '', 'AnalyzingPage')
        this.stopPolling()
        return
      }
      this.errorText = `轮询失败，请检查网络与服务地址 (${ErrorCode.TASK_002})`
      logError('Analyze poll failed', JSON.stringify(error), 'AnalyzingPage')
      this.stopPolling()
    }
  }

  updateStatus(status: AnalyzeStatus): void {
    if (status === this.status && this.canGoResult) {
      return
    }

    logInfo(`Task status changed: taskId=${this.taskId}, from=${this.status}, to=${status}`, 'AnalyzingPage')
    this.analyzeVM.updateStatus(status)
    this.syncFromViewModel()
    if (this.analyzeVM.shouldStopPolling()) {
      this.stopPolling()
    }
    if (status === AnalyzeStatus.FAILED && this.errorText.length === 0) {
      this.errorText = '分析任务失败，请修正配置后重试。'
    }
    if (status === AnalyzeStatus.SUCCESS) {
      this.autoOpenResult()
    }
  }

  retry(): void {
    logInfo(`Retry polling: taskId=${this.taskId}`, 'AnalyzingPage')
    this.errorText = ''
    this.noticeText = ''
    this.canGoResult = false
    this.isNavigatingToResult = false
    this.analyzeVM.resetForRetry()
    this.syncFromViewModel()
    this.startPolling()
  }

  syncFromViewModel(): void {
    this.taskId = this.analyzeVM.taskId
    this.status = this.analyzeVM.status
    this.progressText = this.analyzeVM.progressText
    this.canGoResult = this.analyzeVM.canGoResult()
    this.getUIContext().animateTo({ duration: 320, curve: Curve.EaseOut }, () => {
      this.progressValue = this.analyzeVM.progressValue
    })
  }

  scheduleNextDemoStep(): void {
    this.stopPolling()
    this.isPolling = true
    this.timerId = setTimeout(() => {
      this.advanceDemoStatus()
    }, ContractApi.getMockStepDelayMillis(this.taskId))
  }

  advanceDemoStatus(): void {
    const mockResponse = ContractApi.getMockTaskStatus(this.demoStep, this.taskId)
    if (mockResponse.errorMessage !== undefined && mockResponse.errorMessage.length > 0) {
      this.errorText = mockResponse.errorMessage
    }
    this.updateStatus(mockResponse.status)
    if (this.demoStep === 0) {
      this.noticeText = ContractApi.mockNoticeText(this.taskId)
    }
    if (this.demoStep < ContractApi.getMockTotalSteps(this.taskId)) {
      this.demoStep = this.demoStep + 1
      this.scheduleNextDemoStep()
    }
  }

  async goResult(): Promise<void> {
    this.isNavigatingToResult = true
    logInfo(`Go result overview: taskId=${this.taskId}`, 'AnalyzingPage')
    const params: RouteParams = new RouteParams()
    params.taskId = this.taskId
    params.baseUrl = this.apiBaseUrl()
    await replace(this.getUIContext(), RoutePath.RESULT_OVERVIEW, params)
    this.noticeText = ''
    this.isNavigatingToResult = false
  }

  autoOpenResult(): void {
    if (this.isNavigatingToResult) {
      return
    }
    this.noticeText = this.analyzeVM.isDemoTask() ? '分析完成，正在打开演示结果页。' : '分析完成，正在打开结果页。'
    this.isNavigatingToResult = true
    setTimeout(() => {
      this.goResult()
    }, 400)
  }

  shouldShowPollingState(): boolean {
    return this.isPolling && this.errorText.length === 0 && this.status !== AnalyzeStatus.SUCCESS
  }

  pollingTitle(): string {
    if (this.status === AnalyzeStatus.OCR_RUNNING) {
      return '正在识别合同文字'
    }
    if (this.status === AnalyzeStatus.LLM_RUNNING) {
      return '正在分析风险条款'
    }
    return '正在等待任务推进'
  }

  pollingDescription(): string {
    if (this.analyzeVM.isDemoTask()) {
      return '当前为演示任务，页面会按预设节奏自动推进状态。'
    }
    if (this.status === AnalyzeStatus.OCR_RUNNING) {
      return '系统正在提取正文内容，完成后会自动进入条款分析阶段。'
    }
    if (this.status === AnalyzeStatus.LLM_RUNNING) {
      return '系统正在生成白话解释、风险原因与修改建议。'
    }
    return '任务已创建成功，系统会持续轮询服务端并自动刷新状态。'
  }

  pollingDetail(): string {
    return this.noticeText.length > 0 ? this.noticeText : '无需手动刷新，完成后会自动跳转到结果页。'
  }

  apiBaseUrl(): string {
    const rawParams = this.getUIContext().getRouter().getParams() as RouteParams
    return rawParams.baseUrl ?? API_BASE_URL
  }

  async leaveToHome(): Promise<void> {
    this.clearTransientUiState()
    await goBackToHome(this.getUIContext())
  }

  clearTransientUiState(): void {
    this.noticeText = ''
    this.isNavigatingToResult = false
  }
}
