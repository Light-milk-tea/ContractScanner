import { cardPadding, isCompactLayout } from '../common/ui/LayoutHelpers'
import { UiColors, UiRadius, UiSpace } from '../common/ui/DesignTokens'

/**
 * tone:
 * - plain（默认）：无底、无边、无阴影，只保留区块间距
 * - soft：极淡底色，仍无边框阴影
 * - inset / flat：兼容旧调用，按 plain/soft 处理
 */
@Component
export struct SurfaceCard {
  @Prop surfaceColor: string = UiColors.SURFACE_PRIMARY
  @Prop strokeColor: string = UiColors.BORDER_HAIRLINE
  @Prop radius: number = -1
  @Prop paddingValue: number = -1
  @Prop tone: string = 'plain'
  @Builder emptyBuilder() {}
  @BuilderParam content: () => void = this.emptyBuilder

  build() {
    Column() {
      Column() {
        this.content()
      }
      .width('100%')
      .padding(this.resolvedPadding())
      .backgroundColor(this.resolvedBackground())
      .borderRadius(this.resolvedRadius())
    }
    .width('100%')
    .margin({ bottom: isCompactLayout() ? UiSpace.SM : UiSpace.MD })
  }

  resolvedRadius(): number {
    if (this.radius >= 0) {
      return this.radius
    }
    return isCompactLayout() ? UiRadius.MEDIUM : UiRadius.LARGE
  }

  resolvedPadding(): number {
    if (this.paddingValue >= 0) {
      return this.paddingValue
    }
    // plain 模式减少左右内边距，避免“框里再缩一圈”
    if (this.tone === 'plain' || this.tone === 'elevated') {
      return isCompactLayout() ? UiSpace.XS : UiSpace.SM
    }
    return cardPadding()
  }

  resolvedBackground(): string {
    if (this.tone === 'soft' || this.tone === 'inset' || this.tone === 'flat') {
      return this.surfaceColor === UiColors.SURFACE_PRIMARY
        ? UiColors.SURFACE_MUTED
        : this.surfaceColor
    }
    // plain / elevated：透明，不再做白卡片
    return '#00000000'
  }
}
