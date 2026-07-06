import { goResultOverview } from '../app/AppRouter'
import { RouteParams } from '../app/AppRouter'
import { API_BASE_URL } from '../common/constants'
import { AppError } from '../common/errors'
import { logError } from '../common/logger'
import { AnalyzeProgress } from '../components/AnalyzeProgress'
import { AnalyzeStatus } from '../model/enums/AnalyzeStatus'
import { AnalyzeVM } from '../model/viewmodel/AnalyzeVM'
import { ContractApi } from '../services/api/ContractApi'

@Entry
@Component
struct AnalyzingPage {
  @State analyzeVM: AnalyzeVM = new AnalyzeVM()
  @State errorText: string = ''
  @State progressValue: number = 0
  @State canGoResult: boolean = false
  @State isPolling: boolean = false

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
      this.analyzeVM.taskId = taskId
    }

    this.applyDerivedProgress()
    this.startPolling()
  }

  aboutToDisappear(): void {
    this.stopPolling()
  }

  build() {
    Column({ space: 16 }) {
      Text('分析中')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)

      AnalyzeProgress({
        status: this.analyzeVM.status,
        progressText: this.analyzeVM.progressText,
        progressValue: this.progressValue
      })

      if (this.analyzeVM.taskId.length > 0) {
        Text(`任务：${this.analyzeVM.taskId}`)
          .fontSize(12)
          .fontColor('#999999')
      }

      if (this.errorText.length > 0) {
        Text(this.errorText)
          .fontSize(13)
          .fontColor('#D64B4B')
      }

      Row({ space: 12 }) {
        if (this.analyzeVM.status === AnalyzeStatus.FAILED) {
          Button('重试')
            .type(ButtonType.Capsule)
            .onClick(() => {
              this.retry()
            })
        }

        if (this.canGoResult) {
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
    if (this.analyzeVM.taskId.length === 0) {
      this.errorText = '缺少 taskId，无法开始轮询'
      return
    }

    if (this.timerId >= 0) {
      return
    }

    this.errorText = ''
    this.canGoResult = false
    this.isPolling = true

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
      const response = await this.api.getTaskStatus(this.analyzeVM.taskId)
      this.updateStatus(response.status)
    } catch (error) {
      if (error instanceof AppError) {
        this.errorText = `${error.message} (${error.code})`
        logError('Analyze poll failed', error.details ?? '', 'AnalyzingPage')
        this.stopPolling()
        return
      }
      this.errorText = '轮询失败，请检查网络与服务地址'
      logError('Analyze poll failed', JSON.stringify(error), 'AnalyzingPage')
      this.stopPolling()
    }
  }

  updateStatus(status: AnalyzeStatus): void {
    if (status === this.analyzeVM.status && this.canGoResult) {
      return
    }

    this.analyzeVM.status = status
    if (status === AnalyzeStatus.PENDING) {
      this.analyzeVM.progressText = '任务排队中'
    } else if (status === AnalyzeStatus.OCR_RUNNING) {
      this.analyzeVM.progressText = '正在识别文字'
    } else if (status === AnalyzeStatus.LLM_RUNNING) {
      this.analyzeVM.progressText = '正在分析条款'
    } else if (status === AnalyzeStatus.SUCCESS) {
      this.analyzeVM.progressText = '分析完成'
      this.canGoResult = true
      this.stopPolling()
    } else if (status === AnalyzeStatus.FAILED) {
      this.analyzeVM.progressText = '分析失败'
      this.stopPolling()
    }
    this.applyDerivedProgress()
  }

  applyDerivedProgress(): void {
    if (this.analyzeVM.status === AnalyzeStatus.PENDING) {
      this.progressValue = 5
      return
    }
    if (this.analyzeVM.status === AnalyzeStatus.OCR_RUNNING) {
      this.progressValue = 35
      return
    }
    if (this.analyzeVM.status === AnalyzeStatus.LLM_RUNNING) {
      this.progressValue = 75
      return
    }
    if (this.analyzeVM.status === AnalyzeStatus.SUCCESS) {
      this.progressValue = 100
      return
    }
    if (this.analyzeVM.status === AnalyzeStatus.FAILED) {
      this.progressValue = 0
    }
  }

  retry(): void {
    this.errorText = ''
    this.canGoResult = false
    this.analyzeVM.status = AnalyzeStatus.PENDING
    this.analyzeVM.progressText = '重试中'
    this.applyDerivedProgress()
    this.startPolling()
  }

  async goResult(): Promise<void> {
    const params: RouteParams = new RouteParams()
    params.taskId = this.analyzeVM.taskId
    await goResultOverview(this.getUIContext(), params)
  }
}
