import { UiColors, UiRadius, UiShadow } from '../common/ui/DesignTokens'

@Component
export struct SurfaceCard {
  @Prop surfaceColor: string = UiColors.SURFACE_PRIMARY
  @Prop strokeColor: string = UiColors.BORDER_HAIRLINE
  @Prop radius: number = UiRadius.LARGE
  @Prop paddingValue: number = 20
  @Prop tone: string = 'elevated'
  @Builder emptyBuilder() {}
  @BuilderParam content: () => void = this.emptyBuilder

  build() {
    if (this.tone === 'elevated') {
      Column() {
        this.content()
      }
      .width('100%')
      .padding(this.paddingValue)
      .backgroundColor(this.surfaceColor)
      .borderRadius(this.radius)
      .border({
        width: 0.5,
        color: this.strokeColor
      })
      .shadow({
        radius: UiShadow.CARD_RADIUS,
        color: UiShadow.CARD_COLOR,
        offsetX: 0,
        offsetY: UiShadow.CARD_OFFSET_Y
      })
    } else if (this.tone === 'inset') {
      Column() {
        this.content()
      }
      .width('100%')
      .padding(this.paddingValue)
      .backgroundColor(UiColors.SURFACE_INSET)
      .borderRadius(this.radius)
    } else {
      Column() {
        this.content()
      }
      .width('100%')
      .padding(this.paddingValue)
      .backgroundColor(this.surfaceColor)
      .borderRadius(this.radius)
      .border({
        width: 1,
        color: this.strokeColor
      })
    }
  }
}
