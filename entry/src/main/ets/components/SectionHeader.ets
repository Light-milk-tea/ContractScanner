import { isCompactLayout, sectionTitleFontSize } from '../common/ui/LayoutHelpers'
import { UiColors, UiFont, UiSpace } from '../common/ui/DesignTokens'

@Component
export struct SectionHeader {
  @Prop title: string = ''
  @Prop description: string = ''
  @Prop badgeText: string = ''
  /** 默认左对齐，贴合墨纸文书编辑排版 */
  @Prop alignCenter: boolean = false

  build() {
    Column({ space: UiSpace.XS }) {
      if (this.badgeText.length > 0) {
        Text(this.badgeText)
          .fontSize(UiFont.BADGE)
          .fontColor(UiColors.BRAND)
          .fontWeight(FontWeight.Medium)
      }

      Text(this.title)
        .fontSize(sectionTitleFontSize())
        .fontWeight(FontWeight.Bold)
        .fontColor(UiColors.TEXT_PRIMARY)
        .textAlign(this.alignCenter ? TextAlign.Center : TextAlign.Start)
        .width('100%')

      if (this.description.length > 0) {
        Text(this.description)
          .fontSize(UiFont.CAPTION)
          .fontColor(UiColors.TEXT_SECONDARY)
          .lineHeight(isCompactLayout() ? 18 : 20)
          .textAlign(this.alignCenter ? TextAlign.Center : TextAlign.Start)
          .width('100%')
      }
    }
    .alignItems(this.alignCenter ? HorizontalAlign.Center : HorizontalAlign.Start)
    .width('100%')
  }
}
