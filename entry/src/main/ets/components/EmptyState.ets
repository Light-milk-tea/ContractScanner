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
      Row() {
        Column()
          .width(this.glyphWidth())
          .height(14)
          .borderRadius(UiRadius.SMALL)
          .backgroundColor(this.badgeFontColor())
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)

      Text(this.title)
        .fontSize(UiFont.SECTION_TITLE)
        .fontWeight(FontWeight.Bold)
        .fontColor(UiColors.TEXT_PRIMARY)

      if (this.description.length > 0) {
        Text(this.description)
          .fontSize(UiFont.BODY)
          .fontColor(UiColors.TEXT_SECONDARY)
          .width('100%')
          .lineHeight(24)
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
    .padding({ top: UiSpace.LG, bottom: UiSpace.LG })
  }

  glyphWidth(): number {
    switch (this.stateType) {
      case EmptyStateType.ERROR:
        return 18
      case EmptyStateType.INFO:
        return 28
      default:
        return 10
    }
  }

  badgeFontColor(): string {
    switch (this.stateType) {
      case EmptyStateType.ERROR:
        return UiColors.DANGER
      case EmptyStateType.INFO:
        return UiColors.BRAND
      default:
        return UiColors.TEXT_TERTIARY
    }
  }
}
