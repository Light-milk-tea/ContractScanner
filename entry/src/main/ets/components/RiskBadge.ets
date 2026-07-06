@Component
export struct RiskBadge {
  build() {
    Row() {
      Text('RiskBadge')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
    }
    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
    .borderRadius(999)
    .backgroundColor('#F2F3F5')
  }
}
