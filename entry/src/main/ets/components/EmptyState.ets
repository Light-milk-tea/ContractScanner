import { UiColors, UiFont, UiRadius, UiShadow, UiSpace } from '../common/ui/DesignTokens'

export enum EmptyStateType {
  EMPTY = 'empty',
  ERROR = 'error',
  INFO = 'info'
}

@Component
export struct EmptyState {
  @Prop title: string = '暂无内容'
  @Prop description: string = ''
  @Prop hint: string = ''
  @Prop stateType: EmptyStateType = EmptyStateType.EMPTY

  build() {
    Column({ space: UiSpace.MD }) {
      Text(this.iconGlyph())
        .fontSize(28)
        .fontColor(this.badgeFontColor())
        .width(48)
        .height(48)
        .textAlign(TextAlign.Center)
        .borderRadius(UiRadius.PILL)
        .backgroundColor(this.badgeBackgroundColor())

      Text(this.title)
        .fontSize(UiFont.SECTION_TITLE)
        .fontWeight(FontWeight.Bold)
        .fontColor(UiColors.TEXT_PRIMARY)

      if (this.description.length > 0) {
        Text(this.description)
          .fontSize(UiFont.BODY)
          .fontColor(UiColors.TEXT_SECONDARY)
          .width('100%')
          .lineHeight(22)
      }

      if (this.hint.length > 0) {
        Text(this.hint)
          .fontSize(UiFont.BODY_SMALL)
          .fontColor(UiColors.TEXT_TERTIARY)
          .width('100%')
          .lineHeight(20)
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(UiSpace.XL)
    .borderRadius(UiRadius.LARGE)
    .backgroundColor(this.cardBackgroundColor())
    .shadow({
      radius: UiShadow.SOFT_RADIUS,
      color: UiShadow.SOFT_COLOR,
      offsetX: 0,
      offsetY: 4
    })
  }

  iconGlyph(): string {
    switch (this.stateType) {
      case EmptyStateType.ERROR:
        return '!'
      case EmptyStateType.INFO:
        return 'i'
      default:
        return '◦'
    }
  }

  cardBackgroundColor(): string {
    switch (this.stateType) {
      case EmptyStateType.ERROR:
        return '#FFF8F7'
      case EmptyStateType.INFO:
        return UiColors.SURFACE_ACCENT
      default:
        return UiColors.SURFACE_PRIMARY
    }
  }

  badgeBackgroundColor(): string {
    switch (this.stateType) {
      case EmptyStateType.ERROR:
        return UiColors.DANGER_SOFT
      case EmptyStateType.INFO:
        return UiColors.BRAND_SOFT
      default:
        return UiColors.SURFACE_SECONDARY
    }
  }

  badgeFontColor(): string {
    switch (this.stateType) {
      case EmptyStateType.ERROR:
        return UiColors.DANGER
      case EmptyStateType.INFO:
        return UiColors.BRAND
      default:
        return UiColors.TEXT_SECONDARY
    }
  }
}
