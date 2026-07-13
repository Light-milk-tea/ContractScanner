import { goBackToHome, replace } from '../app/AppRouter'
import { RouteParams } from '../app/AppRouter'
import { API_BASE_URL, RoutePath } from '../common/constants'
import { AppError, ErrorCode } from '../common/errors'
import { logError } from '../common/logger'
import { AnalyzeProgress } from '../components/AnalyzeProgress'
import { EmptyState, EmptyStateType } from '../components/EmptyState'
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

    this.syncFromViewModel()
    this.startPolling()
  }

  aboutToDisappear(): void {
    this.stopPolling()
    this.clearTransientUiState()
  }

  build() {
    Column({ space: 16 }) {
      Text('分析中')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)

      AnalyzeProgress({
        status: this.status,
        progressText: this.progressText,
        progressValue: this.progressValue
      })

      if (this.taskId.length > 0) {
        Text(`任务：${this.taskId}`)
          .fontSize(12)
          .fontColor('#999999')
      }

      if (this.noticeText.length > 0) {
        Text(this.noticeText)
          .fontSize(13)
          .fontColor('#A36B00')
      }

      if (this.errorText.length > 0 || this.status === AnalyzeStatus.FAILED) {
        EmptyState({
          title: '分析未完成',
          description: this.errorText.length > 0 ? this.errorText : '分析任务执行失败，请重试或返回重新发起分析。',
          hint: '修正服务地址或服务状态后，可点击“重试”重新发起轮询。',
          stateType: EmptyStateType.ERROR
        })
      }

      Row({ space: 12 }) {
        Button('返回首页')
          .type(ButtonType.Capsule)
          .onClick(() => {
            this.leaveToHome()
          })

        if (this.status === AnalyzeStatus.FAILED || this.errorText.length > 0) {
          Button('重试')
            .type(ButtonType.Capsule)
            .onClick(() => {
              this.retry()
            })
        }

        if (this.canGoResult && !this.isNavigatingToResult) {
          Button('查看结果')
            .type(ButtonType.Capsule)
            .onClick(() => {
              this.goResult()
            })
        }

        Button(this.isPolling ? '轮询中...' : '开始轮询')
          .type(ButtonType.Capsule)
          .enabled(!this.isPolling)
          .onClick(() => {
            this.startPolling()
          })
      }
    }
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .height('100%')
    .padding(24)
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
    this.progressValue = this.analyzeVM.progressValue
    this.canGoResult = this.analyzeVM.canGoResult()
  }

  scheduleNextDemoStep(): void {
    this.stopPolling()
    this.isPolling = true
    this.timerId = setTimeout(() => {
      this.advanceDemoStatus()
    }, 1000)
  }

  advanceDemoStatus(): void {
    const mockResponse = ContractApi.getMockTaskStatus(this.demoStep, this.taskId)
    this.updateStatus(mockResponse.status)
    if (this.demoStep === 0) {
      this.noticeText = ContractApi.mockNoticeText()
      this.demoStep = 1
      this.scheduleNextDemoStep()
      return
    }
    if (this.demoStep === 1) {
      this.demoStep = 2
      this.scheduleNextDemoStep()
      return
    }
    if (this.demoStep === 2) {
      this.demoStep = 3
      this.scheduleNextDemoStep()
      return
    }
  }

  async goResult(): Promise<void> {
    this.isNavigatingToResult = true
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
