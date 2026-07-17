import { UiColors, UiFont, UiRadius, UiShadow, UiSpace } from '../common/ui/DesignTokens'

@Component
export struct SummaryCard {
  contractName: string = ''
  overallSummary: string = ''
  generatedAt: string = ''
  checklist: string[] = []
  redCount: number = 0
  yellowCount: number = 0
  greenCount: number = 0

  build() {
    Column({ space: UiSpace.LG }) {
      Text('合同结论')
        .fontSize(UiFont.BADGE)
        .fontColor(UiColors.BRAND)
        .padding({ left: 10, right: 10, top: 4, bottom: 4 })
        .backgroundColor(UiColors.BRAND_SOFT)
        .borderRadius(UiRadius.PILL)

      Text(this.contractName)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(UiColors.TEXT_PRIMARY)

      Text(this.overallSummary)
        .fontSize(UiFont.BODY)
        .fontColor(UiColors.TEXT_SECONDARY)
        .lineHeight(24)

      Row({ space: UiSpace.SM }) {
        this.metricCell('高风险', `${this.redCount}`, UiColors.DANGER, UiColors.DANGER_SOFT)
        this.metricCell('中风险', `${this.yellowCount}`, UiColors.WARNING, UiColors.WARNING_SOFT)
        this.metricCell('低风险', `${this.greenCount}`, UiColors.SUCCESS, UiColors.SUCCESS_SOFT)
      }
      .width('100%')

      if (this.checklist.length > 0) {
        Column({ space: UiSpace.SM }) {
          Text('签署前建议确认')
            .fontSize(UiFont.BODY)
            .fontWeight(FontWeight.Medium)
            .fontColor(UiColors.TEXT_PRIMARY)
          ForEach(this.checklist, (item: string) => {
            Row({ space: UiSpace.SM }) {
              Text('•')
                .fontSize(UiFont.BODY)
                .fontColor(UiColors.BRAND)
              Text(item)
                .fontSize(UiFont.BODY_SMALL)
                .fontColor(UiColors.TEXT_SECONDARY)
                .layoutWeight(1)
                .lineHeight(20)
            }
            .alignItems(VerticalAlign.Top)
            .width('100%')
          })
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding(UiSpace.LG)
        .backgroundColor(UiColors.SURFACE_INSET)
        .borderRadius(UiRadius.MEDIUM)
      }

      Text(`生成时间：${this.generatedAt}`)
        .fontSize(UiFont.CAPTION)
        .fontColor(UiColors.TEXT_TERTIARY)
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(UiSpace.XXL)
    .borderRadius(UiRadius.XLARGE)
    .backgroundColor(UiColors.SURFACE_PRIMARY)
    .shadow({
      radius: UiShadow.CARD_RADIUS,
      color: UiShadow.CARD_COLOR,
      offsetX: 0,
      offsetY: UiShadow.CARD_OFFSET_Y
    })
  }

  @Builder
  metricCell(label: string, value: string, color: string, soft: string) {
    Column({ space: UiSpace.XS }) {
      Text(value)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
      Text(label)
        .fontSize(UiFont.CAPTION)
        .fontColor(UiColors.TEXT_SECONDARY)
    }
    .layoutWeight(1)
    .padding(UiSpace.MD)
    .backgroundColor(soft)
    .borderRadius(UiRadius.MEDIUM)
    .alignItems(HorizontalAlign.Center)
  }
}
