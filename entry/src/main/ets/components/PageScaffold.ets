import { contentMaxWidth, pageHorizontalPadding, pageVerticalPadding } from '../common/ui/LayoutHelpers'
import { UiColors, UiFont, UiSpace } from '../common/ui/DesignTokens'

@Component
export struct PageScaffold {
  @Prop title: string = ''
  @Prop description: string = ''
  @Prop backText: string = ''
  onBack?: () => void
  @Builder emptyBuilder() {}
  @BuilderParam content: () => void = this.emptyBuilder

  build() {
    Scroll() {
      Column({ space: UiSpace.XL }) {
        if (this.backText.length > 0) {
          Button(this.backText)
            .type(ButtonType.Capsule)
            .backgroundColor(UiColors.BRAND_SOFT)
            .fontColor(UiColors.BRAND)
            .onClick(() => {
              if (this.onBack !== undefined) {
                this.onBack()
              }
            })
        }

        Column({ space: UiSpace.SM }) {
          Text(this.title)
            .fontSize(UiFont.PAGE_TITLE)
            .fontWeight(FontWeight.Bold)
            .fontColor(UiColors.TEXT_PRIMARY)

          if (this.description.length > 0) {
            Text(this.description)
              .fontSize(UiFont.BODY)
              .fontColor(UiColors.TEXT_SECONDARY)
              .lineHeight(22)
              .width('100%')
          }
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')

        this.content()
      }
      .width('100%')
      .constraintSize({ maxWidth: contentMaxWidth() })
      .padding({
        left: pageHorizontalPadding(),
        right: pageHorizontalPadding(),
        top: pageVerticalPadding(),
        bottom: pageVerticalPadding()
      })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(UiColors.PAGE_BACKGROUND)
  }
}
