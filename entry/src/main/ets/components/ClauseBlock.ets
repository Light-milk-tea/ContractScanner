import { RiskLevel } from '../model/enums/RiskLevel'
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
    Column({ space: 8 }) {
      Row({ space: 8 }) {
        Text(this.title)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
        RiskBadge({ riskLevel: this.riskLevel })
      }
      if (this.anchorText.length > 0) {
        Text(this.anchorText)
          .fontSize(12)
          .fontColor('#999999')
      }
      Text('原文')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
      Text(this.originalText)
        .fontSize(14)
        .fontColor('#444444')
      Text('白话解释')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
      Text(this.plainText)
        .fontSize(14)
        .fontColor('#666666')
      Text('风险原因')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
      Text(this.riskReason)
        .fontSize(14)
        .fontColor('#444444')
      if (this.suggestion.length > 0) {
        Text('建议')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
        Text(this.suggestion)
          .fontSize(14)
          .fontColor('#2E6BE6')
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(16)
    .borderRadius(16)
    .backgroundColor('#F2F3F5')
  }
}
