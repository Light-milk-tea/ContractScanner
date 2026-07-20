import { goBackToHome, replace } from '../app/AppRouter'
import { RouteParams } from '../app/AppRouter'
import { API_BASE_URL, RoutePath } from '../common/constants'
import { AppError, ErrorCode } from '../common/errors'
import { logError, logInfo } from '../common/logger'
import { isCompactLayout } from '../common/ui/LayoutHelpers'
import { UiColors, UiFont, UiSpace } from '../common/ui/DesignTokens'
import { GhostButton, PrimaryButton } from '../components/ActionButtons'
import { AnalyzeProgress } from '../components/AnalyzeProgress'
import { EmptyState, EmptyStateType } from '../components/EmptyState'
import { PageScaffold } from '../components/PageScaffold'
import { AnalyzeStatus } from '../model/enums/AnalyzeStatus'
import { AnalyzeVM } from '../model/viewmodel/AnalyzeVM'
import { ContractApi } from '../services/api/ContractApi'

@Entry
@Component
struct AnalyzingPage {
  analyzeVM: AnalyzeVM = new AnalyzeVM()

  @State taskId: string = ''
  @State status: AnalyzeStatus = AnalyzeStatus.PENDING
  @State stageIndex: number = 0
  @State progressText: string = '等待开始'
  @State errorText: string = ''
  @State noticeText: string = ''
  @State progressValue: number = 0
  @State canGoResult: boolean = false
  @State isPolling: boolean = false
  @State demoStep: number = 0
  @State isNavigatingToResult: boolean = false

  timerId: number = -1
  progressTimerId: number = -1
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
    this.analyzeVM.updateStatus(AnalyzeStatus.PENDING)
    this.syncFromViewModel()
    this.startPolling()
  }

  aboutToDisappear(): void {
    this.stopPolling()
    this.stopProgressTicker()
    this.clearTransientUiState()
  }

  build() {
    Column() {
      PageScaffold({
        title: '分析中',
        description: '请稍候，完成后会自动打开结果页。',
        backText: '返回首页',
        onBack: () => {
          this.leaveToHome()
        }
      }) {
        Column({ space: isCompactLayout() ? UiSpace.MD : UiSpace.LG }) {
          AnalyzeProgress({
            status: this.status,
            stageIndex: this.stageIndex,
            progressText: this.progressText,
            progressValue: this.progressValue
          })

          if (this.noticeText.length > 0) {
            Text(this.noticeText)
              .fontSize(UiFont.BODY_SMALL)
              .fontColor(UiColors.WARNING)
              .lineHeight(22)
              .width('100%')
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

            if (this.status === AnalyzeStatus.FAILED || this.errorText.length > 0 ||
              (!this.isPolling && !this.canGoResult)) {
              Row({ space: UiSpace.SM }) {
                GhostButton({
                  label: '返回首页',
                  fillWidth: true,
                  onTap: () => {
                    this.leaveToHome()
                  }
                })
                if (!this.canGoResult && this.status !== AnalyzeStatus.FAILED && !this.isPolling) {
                  GhostButton({
                    label: '继续分析',
                    fillWidth: true,
                    onTap: () => {
                      this.startPolling()
                    }
                  })
                }
              }
              .width('100%')
            } else if (!this.canGoResult) {
              GhostButton({
                label: '返回首页',
                fillWidth: true,
                onTap: () => {
                  this.leaveToHome()
                }
              })
            }
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
    this.startProgressTicker()

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

  startProgressTicker(): void {
    if (this.progressTimerId >= 0) {
      return
    }
    this.progressTimerId = setInterval(() => {
      this.tickDisplayedProgress()
    }, 32)
  }

  stopProgressTicker(): void {
    if (this.progressTimerId < 0) {
      return
    }
    clearInterval(this.progressTimerId)
    this.progressTimerId = -1
  }

  tickDisplayedProgress(): void {
    if (!this.analyzeVM.tickProgress()) {
      return
    }
    // 短线性插值衔接相邻 tick，叠加上 Progress.enableSmoothEffect
    this.getUIContext().animateTo({ duration: 36, curve: Curve.Linear }, () => {
      this.progressValue = this.analyzeVM.progressValue
    })
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
        this.stopProgressTicker()
        return
      }
      this.errorText = `轮询失败，请检查网络与服务地址 (${ErrorCode.TASK_002})`
      logError('Analyze poll failed', JSON.stringify(error), 'AnalyzingPage')
      this.stopPolling()
      this.stopProgressTicker()
    }
  }

  updateStatus(status: AnalyzeStatus): void {
    if (status === this.status && this.canGoResult) {
      return
    }

    const statusChanged: boolean = status !== this.status
    if (statusChanged) {
      logInfo(`Task status changed: taskId=${this.taskId}, from=${this.status}, to=${status}`, 'AnalyzingPage')
    }
    this.analyzeVM.updateStatus(status)
    if (statusChanged || status === AnalyzeStatus.SUCCESS) {
      this.syncFromViewModel()
    } else {
      // 状态未变时保留缓动进度，只同步文案 / 阶段 / 可跳转态
      this.progressText = this.analyzeVM.progressText
      this.stageIndex = this.analyzeVM.stageIndex()
      this.canGoResult = this.analyzeVM.canGoResult()
    }
    if (this.analyzeVM.shouldStopPolling()) {
      this.stopPolling()
      this.stopProgressTicker()
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
    this.stageIndex = this.analyzeVM.stageIndex()
    this.progressText = this.analyzeVM.progressText
    this.canGoResult = this.analyzeVM.canGoResult()
    // 完成态从当前进度缓到 100%，拉长过渡，减少「卡住再跳满」的割裂感
    if (this.analyzeVM.status === AnalyzeStatus.SUCCESS) {
      this.getUIContext().animateTo({ duration: 720, curve: Curve.EaseOut }, () => {
        this.progressValue = 100
      })
      return
    }
    this.progressValue = this.analyzeVM.progressValue
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
    // 略长于收尾到 100% 的动画，让进度走完再跳转
    setTimeout(() => {
      this.goResult()
    }, 850)
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
    this.stopPolling()
    this.stopProgressTicker()
    this.clearTransientUiState()
    await goBackToHome(this.getUIContext())
  }

  clearTransientUiState(): void {
    this.noticeText = ''
    this.isNavigatingToResult = false
  }
}
