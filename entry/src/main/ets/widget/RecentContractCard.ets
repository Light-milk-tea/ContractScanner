let recentCardStorage: LocalStorage = new LocalStorage()

class CardLinkParams {
  route: string = ''
  taskId: string = ''
  baseUrl: string = ''
  source: string = ''
}

@Entry(recentCardStorage)
@Component
struct RecentContractCard {
  @LocalStorageProp('cardTitle') cardTitle: string = '最近合同摘要'
  @LocalStorageProp('contractName') contractName: string = '暂无最近分析结果'
  @LocalStorageProp('statusText') statusText: string = '完成一次分析后，这里会同步桌面卡片展示内容。'
  @LocalStorageProp('generatedAt') generatedAt: string = ''
  @LocalStorageProp('taskId') taskId: string = ''
  @LocalStorageProp('baseUrl') baseUrl: string = ''
  @LocalStorageProp('pageUrl') pageUrl: string = 'pages/HomePage'
  @LocalStorageProp('entrySource') entrySource: string = 'card'
  @LocalStorageProp('actionText') actionText: string = '打开应用'

  build() {
    FormLink({
      action: 'router',
      bundleName: 'com.example.contractscanner',
      moduleName: 'entry',
      abilityName: 'EntryAbility',
      params: this.buildLinkParams()
    }) {
      Column({ space: 10 }) {
        Text(this.cardTitle)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#12151A')

        Text(this.contractName)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .maxLines(2)
          .fontColor('#12151A')

        Text(this.statusText)
          .fontSize(12)
          .maxLines(2)
          .fontColor('#5C6670')

        if (this.generatedAt.length > 0) {
          Text(this.generatedAt)
            .fontSize(11)
            .fontColor('#8A949C')
        }

        Row() {
          Text(this.actionText)
            .fontSize(12)
            .fontColor('#B91C1C')
          Text('›')
            .fontSize(12)
            .fontColor('#B91C1C')
        }
        .width('100%')
        .justifyContent(FlexAlign.End)
      }
      .alignItems(HorizontalAlign.Start)
      .height('100%')
      .width('100%')
      .padding(16)
      .linearGradient({
        angle: 145,
        colors: [
          ['#FFFFFF', 0.0],
          ['#F3E9E7', 1.0]
        ]
      })
      .borderRadius(16)
    }
    .width('100%')
    .height('100%')
  }

  buildLinkParams(): CardLinkParams {
    const params: CardLinkParams = new CardLinkParams()
    params.route = this.pageUrl
    params.taskId = this.taskId
    params.baseUrl = this.baseUrl
    params.source = this.entrySource
    return params
  }
}
