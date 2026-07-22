import { hdsMaterial, HdsTabs, HdsTabsController } from '@kit.UIDesignKit'

import { HomePanel } from '../components/HomePanel'
import { SettingsPanel } from '../components/SettingsPanel'
import { UiColors, UiFont } from '../common/ui/DesignTokens'

@Entry
@Component
struct MainShellPage {
  private tabsController: HdsTabsController = new HdsTabsController()
  @State currentIndex: number = 0
  @State homeRefreshToken: number = 0

  build() {
    Column() {
      HdsTabs({ controller: this.tabsController }) {
        TabContent() {
          HomePanel({
            hideSettingsEntry: true,
            bottomInset: 96,
            refreshToken: this.homeRefreshToken
          })
        }
        .tabBar(this.homeTabBuilder)

        TabContent() {
          SettingsPanel({
            bottomInset: 96,
            showHeader: true
          })
        }
        .tabBar(this.settingsTabBuilder)
      }
      .barOverlap(true)
      .vertical(false)
      .barPosition(BarPosition.End)
      .animationDuration(200)
      .onChange((index: number) => {
        this.currentIndex = index
        if (index === 0) {
          this.homeRefreshToken = this.homeRefreshToken + 1
        }
      })
      .barFloatingStyle({
        barBottomMargin: 28,
        adaptToHandedness: true,
        gradientMask: {
          maskColor: '#66F7F4F3',
          maskHeight: 92
        },
        systemMaterialEffect: {
          materialType: hdsMaterial.MaterialType.ADAPTIVE,
          materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
        }
      })
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(UiColors.PAGE_BACKGROUND)
  }

  @Builder
  homeTabBuilder() {
    Column({ space: 2 }) {
      Text('首页')
        .fontSize(UiFont.CAPTION)
        .fontWeight(this.currentIndex === 0 ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(this.currentIndex === 0 ? UiColors.BRAND : UiColors.TEXT_SECONDARY)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  settingsTabBuilder() {
    Column({ space: 2 }) {
      Text('设置')
        .fontSize(UiFont.CAPTION)
        .fontWeight(this.currentIndex === 1 ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(this.currentIndex === 1 ? UiColors.BRAND : UiColors.TEXT_SECONDARY)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
