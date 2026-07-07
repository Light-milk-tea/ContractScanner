import { RiskLevel } from '../model/enums/RiskLevel'

@Component
export struct RiskBadge {
  riskLevel: RiskLevel = RiskLevel.GREEN
  count: number = -1

  build() {
    Row() {
      Text(this.buildLabel())
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.badgeTextColor())
    }
    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
    .borderRadius(999)
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
      return '#FDECEC'
    }
    if (this.riskLevel === RiskLevel.YELLOW) {
      return '#FFF7E6'
    }
    return '#EAF7EF'
  }

  badgeTextColor(): string {
    if (this.riskLevel === RiskLevel.RED) {
      return '#C23B3B'
    }
    if (this.riskLevel === RiskLevel.YELLOW) {
      return '#B7791F'
    }
    return '#2F855A'
  }
}
