import { UiColors, UiFont, UiSpace } from '../common/ui/DesignTokens'

@Component
export struct LoadingState {
  @Prop title: string = '处理中'
  @Prop description: string = '请稍候，内容正在准备中。'
  @Prop detail: string = ''

  build() {
    Column({ space: UiSpace.MD }) {
      LoadingProgress()
        .width(32)
        .height(32)
        .color(UiColors.BRAND)

      Text(this.title)
        .fontSize(UiFont.SECTION_TITLE)
        .fontWeight(FontWeight.Bold)
        .fontColor(UiColors.TEXT_PRIMARY)

      Text(this.description)
        .fontSize(UiFont.BODY)
        .fontColor(UiColors.TEXT_SECONDARY)
        .lineHeight(22)
        .textAlign(TextAlign.Center)

      if (this.detail.length > 0) {
        Text(this.detail)
          .fontSize(UiFont.CAPTION)
          .fontColor(UiColors.TEXT_TERTIARY)
          .lineHeight(18)
          .textAlign(TextAlign.Center)
      }
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .width('100%')
    .padding({ top: UiSpace.XXL, bottom: UiSpace.XXL })
  }
}
