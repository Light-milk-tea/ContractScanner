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
  @LocalStorageProp('pageUrl') pageUrl: string = 'pages/MainShellPage'
  @LocalStorageProp('entrySource') entrySource: string = 'card'
  @LocalStorageProp('actionText') actionText: string = '打开应用'
  @LocalStorageProp('redCount') redCount: number = 0
  @LocalStorageProp('yellowCount') yellowCount: number = 0
  @LocalStorageProp('greenCount') greenCount: number = 0

  build() {
    FormLink({
      action: 'router',
      bundleName: 'com.example.contractscanner',
      moduleName: 'entry',
      abilityName: 'EntryAbility',
      params: this.buildLinkParams()
    }) {
      Column({ space: 8 }) {
        Text(this.cardTitle)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#12151A')

        Text(this.contractName)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .fontColor('#12151A')

        if (this.hasRiskMetrics()) {
          Row({ space: 8 }) {
            this.metricChip('红', `${this.redCount}`, '#D1433A', this.redCount > 0)
            this.metricChip('黄', `${this.yellowCount}`, '#9A6B12', false)
            this.metricChip('绿', `${this.greenCount}`, '#2A7A52', false)
          }
          .width('100%')
        }

        Text(this.statusText)
          .fontSize(11)
          .maxLines(2)
          .fontColor('#5C6670')

        Row() {
          Text(this.actionText)
            .fontSize(11)
            .fontColor('#B91C1C')
          Text('›')
            .fontSize(11)
            .fontColor('#B91C1C')
        }
        .width('100%')
        .justifyContent(FlexAlign.End)
      }
      .alignItems(HorizontalAlign.Start)
      .height('100%')
      .width('100%')
      .padding(14)
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

  @Builder
  metricChip(label: string, value: string, color: string, emphasize: boolean) {
    Column({ space: 2 }) {
      Text(label)
        .fontSize(10)
        .fontColor(color)
      Text(value)
        .fontSize(emphasize ? 18 : 16)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
    }
    .layoutWeight(1)
    .padding({ top: 4, bottom: 4 })
    .backgroundColor(emphasize ? '#FBEDEC' : '#FFFFFF')
    .border({
      width: emphasize ? 1.5 : 0,
      color: emphasize ? '#D1433A' : '#00000000'
    })
    .borderRadius(8)
    .alignItems(HorizontalAlign.Center)
  }

  hasRiskMetrics(): boolean {
    return this.taskId.length > 0 && this.contractName !== '暂无最近分析结果'
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
