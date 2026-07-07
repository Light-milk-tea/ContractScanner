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
    this.progressValue = this.progressValueFor(status)
  }

  resetForRetry(): void {
    this.updateStatus(AnalyzeStatus.PENDING)
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

  private progressValueFor(status: AnalyzeStatus): number {
    if (status === AnalyzeStatus.PENDING) {
      return 5
    }
    if (status === AnalyzeStatus.OCR_RUNNING) {
      return 35
    }
    if (status === AnalyzeStatus.LLM_RUNNING) {
      return 75
    }
    if (status === AnalyzeStatus.SUCCESS) {
      return 100
    }
    return 0
  }
}
