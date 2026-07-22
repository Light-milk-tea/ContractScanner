import { back } from '../app/AppRouter'
import { UiColors, UiFont, UiSpace } from '../common/ui/DesignTokens'
import { SettingsPanel } from '../components/SettingsPanel'

@Entry
@Component
struct SettingsPage {
  build() {
    Column() {
      Row({ space: UiSpace.XS }) {
        Text('‹')
          .fontSize(24)
          .fontWeight(FontWeight.Medium)
          .fontColor(UiColors.BRAND)
          .onClick(() => {
            back(this.getUIContext())
          })
        Text('返回')
          .fontSize(UiFont.BODY_SMALL)
          .fontColor(UiColors.BRAND)
          .onClick(() => {
            back(this.getUIContext())
          })
      }
      .width('100%')
      .padding({
        left: UiSpace.PAGE_HORIZONTAL,
        right: UiSpace.PAGE_HORIZONTAL,
        top: UiSpace.PAGE_VERTICAL,
        bottom: UiSpace.SM
      })
      .justifyContent(FlexAlign.Start)

      SettingsPanel({
        bottomInset: 0,
        showHeader: true
      })
        .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(UiColors.PAGE_BACKGROUND)
  }
}
