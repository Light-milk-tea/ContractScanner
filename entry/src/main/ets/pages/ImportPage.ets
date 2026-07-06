@Entry
@Component
struct ImportPage {
  build() {
    Column({ space: 16 }) {
      Text('导入合同')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
      Text('后续将在这里接入拍照、图片和文档导入能力。')
        .fontSize(14)
        .fontColor('#666666')
      Column({ space: 8 }) {
        Text('导入方式')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
        Text('1. 拍照导入')
          .fontSize(14)
        Text('2. 相册图片导入')
          .fontSize(14)
        Text('3. 本地文档导入')
          .fontSize(14)
      }
      Text('当前为占位页，用于验证首页到导入页跳转链路。')
        .fontSize(13)
        .fontColor('#999999')
    }
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .height('100%')
    .padding(24)
  }
}
