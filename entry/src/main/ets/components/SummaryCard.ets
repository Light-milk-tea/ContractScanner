@Component
export struct SummaryCard {
  build() {
    Column({ space: 8 }) {
      Text('SummaryCard')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
      Text('组件骨架已创建，等待后续实现。')
        .fontSize(14)
        .fontColor('#666666')
    }
    .width('100%')
    .padding(16)
    .borderRadius(16)
    .backgroundColor('#F2F3F5')
  }
}
