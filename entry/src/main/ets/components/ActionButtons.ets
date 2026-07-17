import { LayoutMetrics, UiColors, UiShadow } from '../common/ui/DesignTokens'

@Component
export struct PrimaryButton {
  @Prop label: string = ''
  @Prop isEnabled: boolean = true
  @Prop fillWidth: boolean = false
  onTap: () => void = () => {
  }

  build() {
    if (this.fillWidth) {
      Button(this.label)
        .type(ButtonType.Capsule)
        .height(LayoutMetrics.BUTTON_HEIGHT)
        .width('100%')
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .backgroundColor(this.isEnabled ? UiColors.BRAND : UiColors.SURFACE_SECONDARY)
        .fontColor(this.isEnabled ? UiColors.TEXT_ON_BRAND : UiColors.TEXT_TERTIARY)
        .enabled(this.isEnabled)
        .shadow(this.isEnabled ? {
          radius: UiShadow.SOFT_RADIUS,
          color: '#332E6BE6',
          offsetX: 0,
          offsetY: 4
        } : {
          radius: 0,
          color: '#00000000',
          offsetX: 0,
          offsetY: 0
        })
        .onClick(() => {
          if (this.isEnabled) {
            this.onTap()
          }
        })
    } else {
      Button(this.label)
        .type(ButtonType.Capsule)
        .height(LayoutMetrics.BUTTON_HEIGHT)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .backgroundColor(this.isEnabled ? UiColors.BRAND : UiColors.SURFACE_SECONDARY)
        .fontColor(this.isEnabled ? UiColors.TEXT_ON_BRAND : UiColors.TEXT_TERTIARY)
        .enabled(this.isEnabled)
        .shadow(this.isEnabled ? {
          radius: UiShadow.SOFT_RADIUS,
          color: '#332E6BE6',
          offsetX: 0,
          offsetY: 4
        } : {
          radius: 0,
          color: '#00000000',
          offsetX: 0,
          offsetY: 0
        })
        .onClick(() => {
          if (this.isEnabled) {
            this.onTap()
          }
        })
    }
  }
}

@Component
export struct GhostButton {
  @Prop label: string = ''
  @Prop isEnabled: boolean = true
  @Prop fillWidth: boolean = false
  onTap: () => void = () => {
  }

  build() {
    if (this.fillWidth) {
      Button(this.label)
        .type(ButtonType.Capsule)
        .height(LayoutMetrics.BUTTON_HEIGHT)
        .width('100%')
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .backgroundColor(UiColors.SURFACE_SECONDARY)
        .fontColor(UiColors.TEXT_PRIMARY)
        .enabled(this.isEnabled)
        .onClick(() => {
          if (this.isEnabled) {
            this.onTap()
          }
        })
    } else {
      Button(this.label)
        .type(ButtonType.Capsule)
        .height(LayoutMetrics.BUTTON_HEIGHT)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .backgroundColor(UiColors.SURFACE_SECONDARY)
        .fontColor(UiColors.TEXT_PRIMARY)
        .enabled(this.isEnabled)
        .onClick(() => {
          if (this.isEnabled) {
            this.onTap()
          }
        })
    }
  }
}

@Component
export struct SegmentChip {
  @Prop label: string = ''
  @Prop selected: boolean = false
  @Prop isEnabled: boolean = true
  onTap: () => void = () => {
  }

  build() {
    Button(this.label)
      .type(ButtonType.Capsule)
      .height(40)
      .fontSize(14)
      .fontWeight(this.selected ? FontWeight.Medium : FontWeight.Regular)
      .backgroundColor(this.selected ? UiColors.BRAND_SOFT : UiColors.SURFACE_MUTED)
      .fontColor(this.selected ? UiColors.BRAND_STRONG : UiColors.TEXT_SECONDARY)
      .border({
        width: this.selected ? 1.5 : 1,
        color: this.selected ? UiColors.BRAND : UiColors.BORDER_SOFT
      })
      .enabled(this.isEnabled)
      .onClick(() => {
        if (this.isEnabled) {
          this.onTap()
        }
      })
  }
}
