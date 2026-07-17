import { AnalyzeStatus } from '../model/enums/AnalyzeStatus'
import { UiColors, UiFont, UiRadius, UiShadow, UiSpace } from '../common/ui/DesignTokens'

@Component
export struct AnalyzeProgress {
  @Prop status: AnalyzeStatus = AnalyzeStatus.PENDING
  @Prop progressText: string = ''
  @Prop progressValue: number = 0

  build() {
    Column({ space: UiSpace.LG }) {
      Column({ space: UiSpace.SM }) {
        Text(this.humanizedStatus())
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(UiColors.TEXT_PRIMARY)
          .textAlign(TextAlign.Center)

        Text(this.progressText)
          .fontSize(UiFont.BODY)
          .fontColor(UiColors.TEXT_SECONDARY)
          .lineHeight(22)
          .textAlign(TextAlign.Center)
      }
      .alignItems(HorizontalAlign.Center)
      .width('100%')

      Stack({ alignContent: Alignment.Center }) {
        Progress({ value: this.progressValue, total: 100, type: ProgressType.Ring })
          .width(128)
          .height(128)
          .color(this.progressColor())

        Text(`${Math.floor(this.progressValue)}%`)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(UiColors.TEXT_PRIMARY)
      }
      .width(128)
      .height(128)

      Progress({ value: this.progressValue, total: 100, type: ProgressType.Linear })
        .width('100%')
        .height(8)
        .color(this.progressColor())
        .borderRadius(UiRadius.PILL)
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .width('100%')
    .padding({
      left: UiSpace.XXL,
      right: UiSpace.XXL,
      top: UiSpace.XXXL,
      bottom: UiSpace.XXXL
    })
    .borderRadius(UiRadius.XLARGE)
    .backgroundColor(UiColors.SURFACE_PRIMARY)
    .shadow({
      radius: UiShadow.CARD_RADIUS,
      color: UiShadow.CARD_COLOR,
      offsetX: 0,
      offsetY: UiShadow.CARD_OFFSET_Y
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

  progressColor(): string {
    if (this.status === AnalyzeStatus.FAILED) {
      return UiColors.DANGER
    }
    if (this.status === AnalyzeStatus.SUCCESS) {
      return UiColors.SUCCESS
    }
    return UiColors.BRAND
  }
}
