import { UiColors, UiFont, UiRadius, UiSpace } from '../common/ui/DesignTokens'

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
      Text(this.badgeText())
        .fontSize(UiFont.BADGE)
        .fontColor(this.badgeFontColor())
        .padding({ left: 10, right: 10, top: 4, bottom: 4 })
        .backgroundColor(this.badgeBackgroundColor())
        .borderRadius(UiRadius.PILL)

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
    .border({
      width: 1,
      color: this.badgeBackgroundColor()
    })
    .backgroundColor(this.cardBackgroundColor())
  }

  badgeText(): string {
    switch (this.stateType) {
      case EmptyStateType.ERROR:
        return '异常提醒'
      case EmptyStateType.INFO:
        return '状态说明'
      default:
        return '暂无数据'
    }
  }

  cardBackgroundColor(): string {
    switch (this.stateType) {
      case EmptyStateType.ERROR:
        return '#FFF7F6'
      case EmptyStateType.INFO:
        return UiColors.SURFACE_ACCENT
      default:
        return UiColors.SURFACE_MUTED
    }
  }

  badgeBackgroundColor(): string {
    switch (this.stateType) {
      case EmptyStateType.ERROR:
        return '#FCE4E0'
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
