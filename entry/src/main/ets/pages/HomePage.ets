import { goImport } from '../app/AppRouter'

@Entry
@Component
struct HomePage {
  build() {
    Column({ space: 16 }) {
      Column({ space: 6 }) {
        Text('法言白话')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
        Text('导入合同并获得白话解读与风险提示')
          .fontSize(14)
          .fontColor('#666666')
      }
      Button('导入合同')
        .width('100%')
        .onClick(() => {
          goImport(this.getUIContext())
        })
      Column({ space: 8 }) {
        Text('最近记录')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
        Text('（占位）后续展示最近 5 条分析记录')
          .fontSize(14)
          .fontColor('#666666')
      }
    }
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .height('100%')
    .padding(24)
  }
}
