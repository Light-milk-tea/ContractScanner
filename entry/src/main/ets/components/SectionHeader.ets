import { UiColors, UiFont, UiRadius, UiSpace } from '../common/ui/DesignTokens'

@Component
export struct SectionHeader {
  @Prop title: string = ''
  @Prop description: string = ''
  @Prop badgeText: string = ''
  @Prop alignCenter: boolean = false

  build() {
    Column({ space: UiSpace.XS }) {
      if (this.badgeText.length > 0) {
        Text(this.badgeText)
          .fontSize(UiFont.BADGE)
          .fontColor(UiColors.BRAND)
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .backgroundColor(UiColors.BRAND_SOFT)
          .borderRadius(UiRadius.PILL)
      }

      Text(this.title)
        .fontSize(UiFont.SECTION_TITLE)
        .fontWeight(FontWeight.Bold)
        .fontColor(UiColors.TEXT_PRIMARY)

      if (this.description.length > 0) {
        Text(this.description)
          .fontSize(UiFont.BODY_SMALL)
          .fontColor(UiColors.TEXT_SECONDARY)
          .lineHeight(20)
          .width('100%')
      }
    }
    .alignItems(this.alignCenter ? HorizontalAlign.Center : HorizontalAlign.Start)
    .width('100%')
  }
}
