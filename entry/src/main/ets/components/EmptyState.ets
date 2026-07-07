@Component
export struct EmptyState {
  @Prop title: string = '暂无内容'
  @Prop description: string = ''
  @Prop hint: string = ''

  build() {
    Column({ space: 8 }) {
      Text(this.title)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
      if (this.description.length > 0) {
        Text(this.description)
          .fontSize(14)
          .fontColor('#444444')
          .width('100%')
      }
      if (this.hint.length > 0) {
        Text(this.hint)
          .fontSize(13)
          .fontColor('#666666')
          .width('100%')
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(16)
    .borderRadius(16)
    .backgroundColor('#F2F3F5')
  }
}
