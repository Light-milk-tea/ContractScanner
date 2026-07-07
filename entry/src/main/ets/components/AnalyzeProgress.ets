import { AnalyzeStatus } from '../model/enums/AnalyzeStatus'

@Component
export struct AnalyzeProgress {
  @Prop status: AnalyzeStatus = AnalyzeStatus.PENDING
  @Prop progressText: string = ''
  @Prop progressValue: number = 0

  build() {
    Column({ space: 8 }) {
      Text('分析进度')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
      Text(`${this.status}  ${this.progressText}`)
        .fontSize(14)
        .fontColor('#666666')
      Progress({ value: this.progressValue, total: 100, type: ProgressType.Linear })
        .width('100%')
    }
    .width('100%')
    .padding(16)
    .borderRadius(16)
    .backgroundColor('#F2F3F5')
  }
}
