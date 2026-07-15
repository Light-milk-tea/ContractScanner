import { UiColors, UiRadius } from '../common/ui/DesignTokens'

@Component
export struct SurfaceCard {
  @Prop surfaceColor: string = UiColors.SURFACE_PRIMARY
  @Prop strokeColor: string = UiColors.BORDER_SOFT
  @Prop radius: number = UiRadius.MEDIUM
  @Prop paddingValue: number = 18
  @Builder emptyBuilder() {}
  @BuilderParam content: () => void = this.emptyBuilder

  build() {
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
