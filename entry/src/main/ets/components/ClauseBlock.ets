import { RiskLevel } from '../model/enums/RiskLevel'
import { LayoutMetrics, UiColors, UiFont, UiRadius, UiShadow, UiSpace } from '../common/ui/DesignTokens'
import { RiskBadge } from './RiskBadge'

@Component
export struct ClauseBlock {
  title: string = ''
  originalText: string = ''
  plainText: string = ''
  riskReason: string = ''
  suggestion: string = ''
  anchorText: string = ''
  riskLevel: RiskLevel = RiskLevel.GREEN

  build() {
    Column({ space: UiSpace.LG }) {
      Row({ space: UiSpace.MD }) {
        Column()
          .width(LayoutMetrics.RISK_BAR_WIDTH)
          .height(42)
          .borderRadius(UiRadius.PILL)
          .backgroundColor(this.riskBarColor())

        Column({ space: UiSpace.XS }) {
          Text(this.title)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(UiColors.TEXT_PRIMARY)
          if (this.anchorText.length > 0) {
            Text(this.anchorText)
              .fontSize(UiFont.CAPTION)
              .fontColor(UiColors.TEXT_TERTIARY)
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        RiskBadge({ riskLevel: this.riskLevel })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      this.buildSection('原文条款', this.originalText, UiColors.TEXT_PRIMARY, UiColors.SURFACE_INSET)
      this.buildSection('白话解释', this.plainText, UiColors.TEXT_SECONDARY, UiColors.SURFACE_ACCENT)
      this.buildSection('风险原因', this.riskReason, UiColors.TEXT_PRIMARY, UiColors.WARNING_SOFT)

      if (this.suggestion.length > 0) {
        this.buildSection('修改建议', this.suggestion, UiColors.BRAND_STRONG, UiColors.BRAND_SOFT)
      }
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

  riskBarColor(): string {
    if (this.riskLevel === RiskLevel.RED) {
      return UiColors.DANGER
    }
    if (this.riskLevel === RiskLevel.YELLOW) {
      return UiColors.WARNING
    }
    return UiColors.SUCCESS
  }

  @Builder
  buildSection(title: string, content: string, textColor: string, backgroundColor: string) {
    Column({ space: UiSpace.SM }) {
      Text(title)
        .fontSize(UiFont.CAPTION)
        .fontWeight(FontWeight.Medium)
        .fontColor(UiColors.TEXT_TERTIARY)
      Text(content)
        .fontSize(UiFont.BODY)
        .fontColor(textColor)
        .lineHeight(24)
        .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(UiSpace.LG)
    .backgroundColor(backgroundColor)
    .borderRadius(UiRadius.MEDIUM)
  }
}
