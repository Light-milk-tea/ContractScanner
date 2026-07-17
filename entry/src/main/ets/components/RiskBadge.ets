import { RiskLevel } from '../model/enums/RiskLevel'
import { UiColors, UiFont, UiRadius } from '../common/ui/DesignTokens'

@Component
export struct RiskBadge {
  riskLevel: RiskLevel = RiskLevel.GREEN
  count: number = -1

  build() {
    Row() {
      Text(this.buildLabel())
        .fontSize(UiFont.BADGE)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.badgeTextColor())
    }
    .padding({ left: 10, right: 10, top: 6, bottom: 6 })
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
      return UiColors.DANGER_SOFT
    }
    if (this.riskLevel === RiskLevel.YELLOW) {
      return UiColors.WARNING_SOFT
    }
    return UiColors.SUCCESS_SOFT
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
