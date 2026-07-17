import { contentMaxWidth, pageHorizontalPadding, pageVerticalPadding } from '../common/ui/LayoutHelpers'
import { LayoutMetrics, UiColors, UiFont, UiRadius, UiSpace } from '../common/ui/DesignTokens'

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
        if (this.backText.length > 0 || this.title.length > 0) {
          Column({ space: UiSpace.MD }) {
            if (this.backText.length > 0) {
              Row({ space: UiSpace.SM }) {
                Text('‹')
                  .fontSize(28)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(UiColors.BRAND)
                  .width(LayoutMetrics.NAV_ICON_SIZE)
                  .height(LayoutMetrics.NAV_ICON_SIZE)
                  .textAlign(TextAlign.Center)
                  .borderRadius(UiRadius.PILL)
                  .backgroundColor(UiColors.SURFACE_PRIMARY)
                  .onClick(() => {
                    if (this.onBack !== undefined) {
                      this.onBack()
                    }
                  })

                Text(this.backText)
                  .fontSize(UiFont.BODY_SMALL)
                  .fontColor(UiColors.BRAND)
                  .onClick(() => {
                    if (this.onBack !== undefined) {
                      this.onBack()
                    }
                  })
              }
              .width('100%')
              .alignItems(VerticalAlign.Center)
            }

            if (this.title.length > 0) {
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
            }
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
        }

        this.content()
      }
      .width('100%')
      .constraintSize({ maxWidth: contentMaxWidth() })
      .padding({
        left: pageHorizontalPadding(),
        right: pageHorizontalPadding(),
        top: pageVerticalPadding(),
        bottom: pageVerticalPadding() + 12
      })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .linearGradient({
      angle: 180,
      colors: [
        [UiColors.PAGE_GRADIENT_TOP, 0.0],
        [UiColors.PAGE_GRADIENT_BOTTOM, 0.35],
        [UiColors.PAGE_BACKGROUND, 1.0]
      ]
    })
  }
}
