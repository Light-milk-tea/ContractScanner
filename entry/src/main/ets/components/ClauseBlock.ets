import { RiskLevel } from '../model/enums/RiskLevel'
import {
  bodyLineHeight,
  cardInnerGap,
  contractTitleFontSize,
  isCompactLayout
} from '../common/ui/LayoutHelpers'
import { LayoutMetrics, UiColors, UiFont, UiSpace } from '../common/ui/DesignTokens'
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
    Column({ space: cardInnerGap() }) {
      Row({ space: UiSpace.MD }) {
        Column()
          .width(LayoutMetrics.RISK_BAR_WIDTH)
          .height(isCompactLayout() ? 36 : 42)
          .borderRadius(999)
          .backgroundColor(this.riskBarColor())

        Column({ space: UiSpace.XS }) {
          Text(this.title)
            .fontSize(contractTitleFontSize())
            .fontWeight(FontWeight.Bold)
            .fontColor(UiColors.TEXT_PRIMARY)
            .maxLines(3)
            .width('100%')
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
      .alignItems(VerticalAlign.Top)

      this.buildSection('原文条款', this.originalText, UiColors.TEXT_PRIMARY)
      this.buildSection('白话解释', this.plainText, UiColors.TEXT_SECONDARY)
      this.buildSection('风险原因', this.riskReason, UiColors.TEXT_PRIMARY)

      if (this.suggestion.length > 0) {
        this.buildSection('修改建议', this.suggestion, UiColors.BRAND_STRONG)
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
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
  buildSection(title: string, content: string, textColor: string) {
    Column({ space: UiSpace.SM }) {
      Divider()
        .color(UiColors.BORDER_HAIRLINE)
        .strokeWidth(0.5)
      Text(title)
        .fontSize(UiFont.CAPTION)
        .fontWeight(FontWeight.Medium)
        .fontColor(UiColors.TEXT_TERTIARY)
        .margin({ top: UiSpace.SM })
      Text(this.indentParagraph(content))
        .fontSize(UiFont.BODY)
        .fontColor(textColor)
        .lineHeight(bodyLineHeight())
        .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  /** 正文首行空两格（全角空格），阅读更舒适 */
  indentParagraph(content: string): string {
    const trimmed = content.trim()
    if (trimmed.length === 0) {
      return ''
    }
    return `　　${trimmed}`
  }
}
