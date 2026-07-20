import { RiskLevel } from '../model/enums/RiskLevel'
import { UiColors, UiFont } from '../common/ui/DesignTokens'

@Component
export struct RiskBadge {
  riskLevel: RiskLevel = RiskLevel.GREEN
  count: number = -1

  build() {
    Text(this.buildLabel())
      .fontSize(UiFont.CAPTION)
      .fontWeight(FontWeight.Medium)
      .fontColor(this.badgeTextColor())
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

  badgeTextColor(): string {
    if (this.riskLevel === RiskLevel.RED) {
      return UiColors.DANGER
    }
    if (this.riskLevel === RiskLevel.YELLOW) {
      return UiColors.WARNING
    }
    return UiColors.SUCCESS
  }
}
