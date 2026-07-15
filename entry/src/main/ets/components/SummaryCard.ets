import { RiskLevel } from '../model/enums/RiskLevel'
import { UiColors, UiFont, UiRadius, UiSpace } from '../common/ui/DesignTokens'
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
    Column({ space: UiSpace.MD }) {
      Text('合同概览')
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
        .lineHeight(22)

      Row({ space: UiSpace.SM }) {
        RiskBadge({ riskLevel: RiskLevel.RED, count: this.redCount })
        RiskBadge({ riskLevel: RiskLevel.YELLOW, count: this.yellowCount })
        RiskBadge({ riskLevel: RiskLevel.GREEN, count: this.greenCount })
      }
      .width('100%')

      if (this.checklist.length > 0) {
        Column({ space: UiSpace.SM }) {
          Text('签署前建议确认')
            .fontSize(UiFont.BODY)
            .fontWeight(FontWeight.Bold)
            .fontColor(UiColors.TEXT_PRIMARY)
          ForEach(this.checklist, (item: string) => {
            Row({ space: UiSpace.SM }) {
              Text('•')
                .fontSize(UiFont.BODY)
                .fontColor(UiColors.BRAND)
              Text(item)
                .fontSize(UiFont.BODY_SMALL)
                .fontColor(UiColors.TEXT_SECONDARY)
                .width('100%')
                .lineHeight(20)
            }
            .alignItems(VerticalAlign.Top)
            .width('100%')
          })
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding(UiSpace.LG)
        .backgroundColor(UiColors.SURFACE_MUTED)
        .borderRadius(UiRadius.MEDIUM)
      }

      Text(`生成时间：${this.generatedAt}`)
        .fontSize(UiFont.CAPTION)
        .fontColor(UiColors.TEXT_TERTIARY)
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
}
