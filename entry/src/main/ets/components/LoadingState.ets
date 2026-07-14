@Component
export struct LoadingState {
  @Prop title: string = '处理中'
  @Prop description: string = '请稍候，内容正在准备中。'
  @Prop detail: string = ''

  build() {
    Column({ space: 12 }) {
      LoadingProgress()
        .width(28)
        .height(28)

      Text(this.title)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#182431')

      Text(this.description)
        .fontSize(14)
        .fontColor('#445266')
        .lineHeight(22)
        .textAlign(TextAlign.Center)

      if (this.detail.length > 0) {
        Text(this.detail)
          .fontSize(12)
          .fontColor('#6B7280')
          .lineHeight(18)
          .textAlign(TextAlign.Center)
      }
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .width('100%')
    .padding(20)
    .borderRadius(20)
    .backgroundColor('#F2F7FF')
  }
}
