import { RiskLevel } from '../model/enums/RiskLevel'
import { UiRadius } from '../common/ui/DesignTokens'

@Component
export struct RiskBadge {
  riskLevel: RiskLevel = RiskLevel.GREEN
  count: number = -1

  build() {
    Row() {
      Text(this.buildLabel())
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.badgeTextColor())
    }
    .padding({ left: 12, right: 12, top: 7, bottom: 7 })
    .borderRadius(UiRadius.PILL)
    .backgroundColor(this.badgeBackgroundColor())
  }

  buildLabel(): string {
    const levelText = this.riskLevelText()
    if (this.count >= 0) {
      return `${levelText} ${this.count}`
    }
    return levelText
  }

  riskLevelText(): string {
    if (this.riskLevel === RiskLevel.RED) {
      return '高风险'
    }
    if (this.riskLevel === RiskLevel.YELLOW) {
      return '中风险'
    }
    return '低风险'
  }

  badgeBackgroundColor(): string {
    if (this.riskLevel === RiskLevel.RED) {
      return '#FCE7E5'
    }
    if (this.riskLevel === RiskLevel.YELLOW) {
      return '#FFF1D8'
    }
    return '#E8F6EE'
  }

  badgeTextColor(): string {
    if (this.riskLevel === RiskLevel.RED) {
      return '#B9352F'
    }
    if (this.riskLevel === RiskLevel.YELLOW) {
      return '#9A6711'
    }
    return '#247249'
  }
}
