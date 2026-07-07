import { RiskLevel } from '../model/enums/RiskLevel'
import { RiskBadge } from './RiskBadge'

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
    Column({ space: 8 }) {
      Text(this.contractName)
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
      Text(this.overallSummary)
        .fontSize(14)
        .fontColor('#666666')
      Row({ space: 8 }) {
        RiskBadge({ riskLevel: RiskLevel.RED, count: this.redCount })
        RiskBadge({ riskLevel: RiskLevel.YELLOW, count: this.yellowCount })
        RiskBadge({ riskLevel: RiskLevel.GREEN, count: this.greenCount })
      }
      if (this.checklist.length > 0) {
        Column({ space: 6 }) {
          Text('签署前建议确认')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
          ForEach(this.checklist, (item: string) => {
            Text(`• ${item}`)
              .fontSize(13)
              .fontColor('#444444')
              .width('100%')
          })
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
      }
      Text(`生成时间：${this.generatedAt}`)
        .fontSize(12)
        .fontColor('#999999')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(16)
    .borderRadius(16)
    .backgroundColor('#F2F3F5')
  }
}
