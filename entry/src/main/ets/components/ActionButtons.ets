import { LayoutMetrics, UiColors, UiFont, UiRadius } from '../common/ui/DesignTokens'

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
        .type(ButtonType.Normal)
        .height(LayoutMetrics.BUTTON_HEIGHT)
        .width('100%')
        .borderRadius(LayoutMetrics.BUTTON_RADIUS)
        .fontSize(UiFont.BUTTON)
        .fontWeight(FontWeight.Medium)
        .backgroundColor(this.isEnabled ? UiColors.BRAND : UiColors.SURFACE_SECONDARY)
        .fontColor(this.isEnabled ? UiColors.TEXT_ON_BRAND : UiColors.TEXT_TERTIARY)
        .enabled(this.isEnabled)
        .onClick(() => {
          if (this.isEnabled) {
            this.onTap()
          }
        })
    } else {
      Button(this.label)
        .type(ButtonType.Normal)
        .height(LayoutMetrics.BUTTON_HEIGHT)
        .borderRadius(LayoutMetrics.BUTTON_RADIUS)
        .fontSize(UiFont.BUTTON)
        .fontWeight(FontWeight.Medium)
        .backgroundColor(this.isEnabled ? UiColors.BRAND : UiColors.SURFACE_SECONDARY)
        .fontColor(this.isEnabled ? UiColors.TEXT_ON_BRAND : UiColors.TEXT_TERTIARY)
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
export struct GhostButton {
  @Prop label: string = ''
  @Prop isEnabled: boolean = true
  @Prop fillWidth: boolean = false
  onTap: () => void = () => {
  }

  build() {
    if (this.fillWidth) {
      Button(this.label)
        .type(ButtonType.Normal)
        .height(LayoutMetrics.BUTTON_HEIGHT)
        .width('100%')
        .borderRadius(LayoutMetrics.BUTTON_RADIUS)
        .fontSize(UiFont.BUTTON)
        .fontWeight(FontWeight.Medium)
        .backgroundColor(UiColors.SURFACE_MUTED)
        .fontColor(UiColors.TEXT_PRIMARY)
        .border({
          width: 1,
          color: UiColors.BORDER_SOFT
        })
        .enabled(this.isEnabled)
        .onClick(() => {
          if (this.isEnabled) {
            this.onTap()
          }
        })
    } else {
      Button(this.label)
        .type(ButtonType.Normal)
        .height(LayoutMetrics.BUTTON_HEIGHT)
        .borderRadius(LayoutMetrics.BUTTON_RADIUS)
        .fontSize(UiFont.BUTTON)
        .fontWeight(FontWeight.Medium)
        .backgroundColor(UiColors.SURFACE_MUTED)
        .fontColor(UiColors.TEXT_PRIMARY)
        .border({
          width: 1,
          color: UiColors.BORDER_SOFT
        })
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
      .type(ButtonType.Normal)
      .height(40)
      .borderRadius(UiRadius.MEDIUM)
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
