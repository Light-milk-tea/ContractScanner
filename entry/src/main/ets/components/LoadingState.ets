import { UiColors, UiFont, UiRadius, UiSpace } from '../common/ui/DesignTokens'

@Component
export struct LoadingState {
  @Prop title: string = '处理中'
  @Prop description: string = '请稍候，内容正在准备中。'
  @Prop detail: string = ''

  build() {
    Column({ space: UiSpace.MD }) {
      Row() {
        LoadingProgress()
          .width(26)
          .height(26)
      }
      .padding(10)
      .backgroundColor(UiColors.BRAND_SOFT)
      .borderRadius(UiRadius.PILL)

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
    .padding(UiSpace.XL)
    .borderRadius(UiRadius.LARGE)
    .backgroundColor(UiColors.SURFACE_PRIMARY)
    .border({
      width: 1,
      color: UiColors.BORDER_SOFT
    })
  }
}
