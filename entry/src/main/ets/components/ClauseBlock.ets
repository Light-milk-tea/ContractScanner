import { RiskLevel } from '../model/enums/RiskLevel'
import { UiColors, UiFont, UiRadius, UiSpace } from '../common/ui/DesignTokens'
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
      Column({ space: UiSpace.SM }) {
        Text('条款精读')
          .fontSize(UiFont.BADGE)
          .fontColor(UiColors.BRAND)
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .backgroundColor(UiColors.BRAND_SOFT)
          .borderRadius(UiRadius.PILL)

        Row({ space: UiSpace.SM }) {
          Text(this.title)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(UiColors.TEXT_PRIMARY)
          RiskBadge({ riskLevel: this.riskLevel })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
      }

      if (this.anchorText.length > 0) {
        Text(this.anchorText)
          .fontSize(UiFont.CAPTION)
          .fontColor(UiColors.TEXT_TERTIARY)
      }

      this.buildSection('原文条款', this.originalText, UiColors.TEXT_PRIMARY, UiColors.SURFACE_MUTED)
      this.buildSection('白话解释', this.plainText, UiColors.TEXT_SECONDARY, UiColors.SURFACE_ACCENT)
      this.buildSection('风险原因', this.riskReason, UiColors.TEXT_PRIMARY, '#FFF8EE')

      if (this.suggestion.length > 0) {
        this.buildSection('修改建议', this.suggestion, UiColors.BRAND_STRONG, UiColors.BRAND_SOFT)
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(UiSpace.XL)
    .borderRadius(UiRadius.LARGE)
    .backgroundColor(UiColors.SURFACE_PRIMARY)
    .border({
      width: 1,
      color: UiColors.BORDER_SOFT
    })
  }

  @Builder
  buildSection(title: string, content: string, textColor: string, backgroundColor: string) {
    Column({ space: UiSpace.SM }) {
      Text(title)
        .fontSize(UiFont.BODY)
        .fontWeight(FontWeight.Bold)
        .fontColor(UiColors.TEXT_PRIMARY)
      Text(content)
        .fontSize(UiFont.BODY)
        .fontColor(textColor)
        .lineHeight(22)
        .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(UiSpace.LG)
    .backgroundColor(backgroundColor)
    .borderRadius(UiRadius.MEDIUM)
  }
}
