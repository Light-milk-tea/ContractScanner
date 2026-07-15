import { AnalyzeStatus } from '../model/enums/AnalyzeStatus'
import { UiColors, UiFont, UiRadius, UiSpace } from '../common/ui/DesignTokens'

@Component
export struct AnalyzeProgress {
  @Prop status: AnalyzeStatus = AnalyzeStatus.PENDING
  @Prop progressText: string = ''
  @Prop progressValue: number = 0

  build() {
    Column({ space: UiSpace.MD }) {
      Text('任务进展')
        .fontSize(UiFont.BADGE)
        .fontColor(UiColors.BRAND)
        .padding({ left: 10, right: 10, top: 4, bottom: 4 })
        .backgroundColor(UiColors.BRAND_SOFT)
        .borderRadius(UiRadius.PILL)

      Text(this.humanizedStatus())
        .fontSize(UiFont.SECTION_TITLE)
        .fontWeight(FontWeight.Bold)
        .fontColor(UiColors.TEXT_PRIMARY)

      Text(this.progressText)
        .fontSize(UiFont.BODY)
        .fontColor(UiColors.TEXT_SECONDARY)
        .lineHeight(22)

      Progress({ value: this.progressValue, total: 100, type: ProgressType.Linear })
        .width('100%')
        .color(UiColors.BRAND)
    }
    .width('100%')
    .padding(UiSpace.XL)
    .borderRadius(UiRadius.LARGE)
    .backgroundColor(UiColors.SURFACE_PRIMARY)
    .border({
      width: 1,
      color: UiColors.BORDER_SOFT
    })
  }

  humanizedStatus(): string {
    switch (this.status) {
      case AnalyzeStatus.OCR_RUNNING:
        return '正在识别合同内容'
      case AnalyzeStatus.LLM_RUNNING:
        return '正在分析条款风险'
      case AnalyzeStatus.SUCCESS:
        return '分析已完成'
      case AnalyzeStatus.FAILED:
        return '分析失败'
      default:
        return '任务已创建'
    }
  }
}
