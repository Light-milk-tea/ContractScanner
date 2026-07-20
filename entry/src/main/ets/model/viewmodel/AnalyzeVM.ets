import { AnalyzeStatus } from '../enums/AnalyzeStatus'

export class AnalyzeVM {
  private static readonly DEMO_TASK_PREFIX: string = 'demo-task-'

  taskId: string = ''
  status: AnalyzeStatus = AnalyzeStatus.PENDING
  progressText: string = '等待开始'
  progressValue: number = 0

  setTaskId(taskId: string): void {
    this.taskId = taskId
  }

  updateStatus(status: AnalyzeStatus): void {
    this.status = status
    this.progressText = this.progressTextFor(status)

    if (status === AnalyzeStatus.SUCCESS) {
      this.progressValue = 100
      return
    }
    // 状态切换只改文案与上限，不瞬间抬进度，避免 5%→42% 这种大跳
  }

  /**
   * 高频小步爬升到当前状态上限；SUCCESS 前不超过 cap。
   * 中段稍快，末段改为近似匀速，避免卡在 90%+ 再忽然跳到 100%。
   * @returns 本次是否有进度变化
   */
  tickProgress(): boolean {
    if (this.status === AnalyzeStatus.SUCCESS || this.status === AnalyzeStatus.FAILED) {
      return false
    }

    // 尚未开始时给一个很小的起点，避免从 0 空白
    if (this.progressValue < 3) {
      this.progressValue = 3
      return true
    }

    const cap: number = this.progressCapFor(this.status)
    if (this.progressValue >= cap - 0.01) {
      this.progressValue = cap
      return false
    }

    const remaining: number = cap - this.progressValue
    // 按 ~32ms tick 设计的小步长，配合 UI 插值更连贯
    let step: number
    if (remaining > 10) {
      step = Math.max(0.055, remaining * 0.01)
    } else {
      step = this.status === AnalyzeStatus.LLM_RUNNING ? 0.045 : 0.035
    }
    this.progressValue = Math.min(cap, this.progressValue + step)
    return true
  }

  resetForRetry(): void {
    this.status = AnalyzeStatus.PENDING
    this.progressValue = 3
    this.progressText = '重试中'
  }

  isDemoTask(): boolean {
    return this.taskId.indexOf(AnalyzeVM.DEMO_TASK_PREFIX) === 0
  }

  canGoResult(): boolean {
    return this.status === AnalyzeStatus.SUCCESS
  }

  shouldStopPolling(): boolean {
    return this.status === AnalyzeStatus.SUCCESS || this.status === AnalyzeStatus.FAILED
  }

  nextDemoStatus(currentStep: number): AnalyzeStatus {
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

  /** 供阶段指示条使用：0 排队 / 1 识别 / 2 分析 */
  stageIndex(): number {
    if (this.status === AnalyzeStatus.OCR_RUNNING) {
      return 1
    }
    if (this.status === AnalyzeStatus.LLM_RUNNING ||
      this.status === AnalyzeStatus.SUCCESS ||
      this.status === AnalyzeStatus.FAILED) {
      return 2
    }
    return 0
  }

  private progressTextFor(status: AnalyzeStatus): string {
    if (status === AnalyzeStatus.PENDING) {
      return '任务排队中'
    }
    if (status === AnalyzeStatus.OCR_RUNNING) {
      return '正在识别文字'
    }
    if (status === AnalyzeStatus.LLM_RUNNING) {
      return '正在分析条款'
    }
    if (status === AnalyzeStatus.SUCCESS) {
      return '分析完成'
    }
    return '分析失败'
  }

  /** 该状态内缓动可到达的上限；完成前尽量贴近 100，收尾动画跨度更小 */
  progressCapFor(status: AnalyzeStatus): number {
    if (status === AnalyzeStatus.PENDING) {
      return 14
    }
    if (status === AnalyzeStatus.OCR_RUNNING) {
      return 36
    }
    if (status === AnalyzeStatus.LLM_RUNNING) {
      return 97
    }
    if (status === AnalyzeStatus.SUCCESS) {
      return 100
    }
    return 0
  }
}
