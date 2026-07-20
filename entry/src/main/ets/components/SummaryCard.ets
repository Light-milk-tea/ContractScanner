import {
  bodyLineHeight,
  cardInnerGap,
  cardPadding,
  contractTitleFontSize,
  isCompactLayout,
  metricValueFontSize
} from '../common/ui/LayoutHelpers'
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
    Column({ space: cardInnerGap() }) {
      Text('合同结论')
        .fontSize(UiFont.CAPTION)
        .fontColor(UiColors.BRAND)
        .fontWeight(FontWeight.Medium)
        .textAlign(TextAlign.Center)
        .width('100%')

      Text(this.contractName)
        .fontSize(contractTitleFontSize())
        .fontWeight(FontWeight.Bold)
        .fontColor(UiColors.TEXT_PRIMARY)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .textAlign(TextAlign.Center)
        .width('100%')

      Text(this.overallSummary)
        .fontSize(UiFont.BODY)
        .fontColor(UiColors.TEXT_SECONDARY)
        .lineHeight(bodyLineHeight())
        .width('100%')

      Row() {
        this.metricInline('高风险', `${this.redCount}`, UiColors.DANGER)
        this.metricInline('中风险', `${this.yellowCount}`, UiColors.WARNING)
        this.metricInline('低风险', `${this.greenCount}`, UiColors.SUCCESS)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceAround)

      if (this.checklist.length > 0) {
        Column({ space: UiSpace.MD }) {
          Text('签署前建议确认')
            .fontSize(UiFont.BODY)
            .fontWeight(FontWeight.Medium)
            .fontColor(UiColors.TEXT_PRIMARY)
            .width('100%')
          ForEach(this.checklist, (item: string) => {
            Row({ space: UiSpace.SM }) {
              Text('–')
                .fontSize(UiFont.BODY_SMALL)
                .fontColor(UiColors.TEXT_TERTIARY)
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

      Text(this.formatGeneratedAt())
        .fontSize(UiFont.CAPTION)
        .fontColor(UiColors.TEXT_TERTIARY)
        .maxLines(1)
        .textAlign(TextAlign.Center)
        .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(cardPadding() + 4)
    .borderRadius(isCompactLayout() ? UiRadius.LARGE : UiRadius.XLARGE)
    .backgroundColor(UiColors.SURFACE_PRIMARY)
    .shadow({
      radius: UiShadow.SOFT_RADIUS,
      color: UiShadow.SOFT_COLOR,
      offsetX: 0,
      offsetY: 4
    })
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
  metricInline(label: string, value: string, color: string) {
    Column({ space: 4 }) {
      Text(value)
        .fontSize(metricValueFontSize())
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
      Text(label)
        .fontSize(UiFont.CAPTION)
        .fontColor(UiColors.TEXT_TERTIARY)
    }
    .alignItems(HorizontalAlign.Center)
    .layoutWeight(1)
  }
}
