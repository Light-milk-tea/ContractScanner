import {
  contentMaxWidth,
  isCompactLayout,
  pageHorizontalPadding,
  pageTitleFontSize,
  pageVerticalPadding,
  sectionGap
} from '../common/ui/LayoutHelpers'
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
      Column({ space: sectionGap() }) {
        if (this.backText.length > 0 || this.title.length > 0) {
          Column({ space: UiSpace.MD }) {
            if (this.backText.length > 0) {
              Row({ space: UiSpace.XS }) {
                Text('‹')
                  .fontSize(26)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(UiColors.BRAND)
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
              .justifyContent(FlexAlign.Start)
              .alignItems(VerticalAlign.Center)
            }

            if (this.title.length > 0) {
              Column({ space: UiSpace.SM }) {
                Text(this.title)
                  .fontSize(pageTitleFontSize())
                  .fontWeight(FontWeight.Bold)
                  .fontColor(UiColors.TEXT_PRIMARY)
                  .textAlign(TextAlign.Center)
                  .width('100%')

                if (this.description.length > 0) {
                  Text(this.description)
                    .fontSize(isCompactLayout() ? UiFont.BODY_SMALL : UiFont.BODY)
                    .fontColor(UiColors.TEXT_SECONDARY)
                    .lineHeight(isCompactLayout() ? 20 : 22)
                    .textAlign(TextAlign.Center)
                    .width('100%')
                }
              }
              .alignItems(HorizontalAlign.Center)
              .width('100%')
            }
          }
          .alignItems(HorizontalAlign.Center)
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
        bottom: pageVerticalPadding() + (isCompactLayout() ? 20 : 12)
      })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .align(Alignment.Top)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
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
