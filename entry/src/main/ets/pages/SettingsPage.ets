@Entry
@Component
struct SettingsPage {
  build() {
    Column({ space: 12 }) {
      Text('SettingsPage')
        .fontSize(24)
        .fontWeight(FontWeight.Medium)
      Text('页面骨架已创建，等待后续实现。')
        .fontSize(14)
        .fontColor('#666666')
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .width('100%')
    .height('100%')
    .padding(24)
  }
}
