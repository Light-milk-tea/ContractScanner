import {
  bodyLineHeight,
  cardInnerGap,
  cardPadding,
  contractTitleFontSize,
  isCompactLayout,
  metricValueFontSize
} from '../common/ui/LayoutHelpers'
import { UiColors, UiFont, UiRadius, UiSpace } from '../common/ui/DesignTokens'

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
    Column({ space: cardInnerGap() }) {
      Text('合同结论')
        .fontSize(UiFont.CAPTION)
        .fontColor(UiColors.BRAND)
        .fontWeight(FontWeight.Medium)
        .width('100%')

      Text(this.contractName)
        .fontSize(contractTitleFontSize())
        .fontWeight(FontWeight.Bold)
        .fontColor(UiColors.TEXT_PRIMARY)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .textAlign(TextAlign.Start)
        .width('100%')

      Text(this.overallSummary)
        .fontSize(UiFont.BODY)
        .fontColor(UiColors.TEXT_SECONDARY)
        .lineHeight(bodyLineHeight())
        .width('100%')

      Row({ space: UiSpace.SM }) {
        this.metricBlock('高风险', `${this.redCount}`, UiColors.DANGER, UiColors.DANGER_SOFT)
        this.metricBlock('中风险', `${this.yellowCount}`, UiColors.WARNING, UiColors.WARNING_SOFT)
        this.metricBlock('低风险', `${this.greenCount}`, UiColors.SUCCESS, UiColors.SUCCESS_SOFT)
      }
      .width('100%')

      if (this.checklist.length > 0) {
        Column({ space: UiSpace.MD }) {
          Text('签署前建议确认')
            .fontSize(UiFont.BODY)
            .fontWeight(FontWeight.Medium)
            .fontColor(UiColors.TEXT_PRIMARY)
            .width('100%')
          ForEach(this.checklist, (item: string) => {
            Row({ space: UiSpace.SM }) {
              Column()
                .width(4)
                .height(4)
                .borderRadius(1)
                .backgroundColor(UiColors.BRAND)
                .margin({ top: 8 })
              Text(item)
                .fontSize(UiFont.BODY_SMALL)
                .fontColor(UiColors.TEXT_SECONDARY)
                .layoutWeight(1)
                .lineHeight(isCompactLayout() ? 22 : 24)
            }
            .alignItems(VerticalAlign.Top)
            .width('100%')
          }, (item: string) => item)
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
      }

      if (this.formatGeneratedAt().length > 0) {
        Text(this.formatGeneratedAt())
          .fontSize(UiFont.CAPTION)
          .fontColor(UiColors.TEXT_TERTIARY)
          .maxLines(1)
          .width('100%')
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(cardPadding())
    .borderRadius(UiRadius.LARGE)
    .backgroundColor(UiColors.SURFACE_MUTED)
  }

  formatGeneratedAt(): string {
    if (this.generatedAt.length === 0) {
      return ''
    }
    if (this.generatedAt.indexOf('T') > 0) {
      return `生成时间 ${this.generatedAt.replace('T', ' ').substring(0, 19)}`
    }
    return `生成时间 ${this.generatedAt}`
  }

  @Builder
  metricBlock(label: string, value: string, color: string, softColor: string) {
    Column({ space: 4 }) {
      Text(value)
        .fontSize(metricValueFontSize())
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
      Text(label)
        .fontSize(UiFont.CAPTION)
        .fontColor(UiColors.TEXT_TERTIARY)
    }
    .alignItems(HorizontalAlign.Start)
    .layoutWeight(1)
    .padding({
      left: UiSpace.MD,
      right: UiSpace.MD,
      top: UiSpace.MD,
      bottom: UiSpace.MD
    })
    .backgroundColor(softColor)
    .borderRadius(UiRadius.MEDIUM)
  }
}
