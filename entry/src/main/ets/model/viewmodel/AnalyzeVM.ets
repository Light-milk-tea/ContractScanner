import { AnalyzeStatus } from '../enums/AnalyzeStatus'

export class AnalyzeVM {
  taskId: string = ''
  status: AnalyzeStatus = AnalyzeStatus.PENDING
  progressText: string = '等待开始'

  updateStatus(status: AnalyzeStatus, progressText: string): void {
    this.status = status
    this.progressText = progressText
  }
}
