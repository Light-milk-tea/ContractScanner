import { common } from '@kit.AbilityKit'
import { goImport, goResultOverview, goSettings, RouteParams } from '../app/AppRouter'
import { API_BASE_URL } from '../common/constants'
import { Contract } from '../model/domain/Contract'
import { AnalyzeStatus } from '../model/enums/AnalyzeStatus'
import { HomeVM } from '../model/viewmodel/HomeVM'
import { CacheService } from '../services/storage/CacheService'

@Entry
@Component
struct HomePage {
  @State recentContracts: Contract[] = []
  @State recentErrorText: string = ''

  homeVM: HomeVM = new HomeVM()
  cacheService: CacheService = new CacheService()

  aboutToAppear(): void {
    this.loadRecentContracts()
  }

  onPageShow(): void {
    this.loadRecentContracts()
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Row() {
          Column({ space: 6 }) {
            Text('法言白话')
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
            Text('导入合同并获得白话解读与风险提示')
              .fontSize(14)
              .fontColor('#666666')
          }
          .alignItems(HorizontalAlign.Start)

          Button('设置')
            .type(ButtonType.Capsule)
            .onClick(() => {
              goSettings(this.getUIContext())
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        Button('导入合同')
          .width('100%')
          .onClick(() => {
            goImport(this.getUIContext())
          })
        Column({ space: 12 }) {
          Text('最近记录')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
          Text('保留最近 5 条已查看结果，便于快速回看合同分析。')
            .fontSize(13)
            .fontColor('#666666')

          if (this.recentErrorText.length > 0) {
            Text(this.recentErrorText)
              .fontSize(13)
              .fontColor('#C0392B')
          }

          if (this.recentContracts.length > 0) {
            ForEach(this.recentContracts, (contract: Contract) => {
              Button() {
                Column({ space: 8 }) {
                  Row() {
                    Text(contract.contractName)
                      .fontSize(16)
                      .fontWeight(FontWeight.Medium)
                      .maxLines(2)
                    Text(this.statusLabel(contract.status))
                      .fontSize(12)
                      .fontColor('#2E6BE6')
                  }
                  .width('100%')
                  .justifyContent(FlexAlign.SpaceBetween)

                  Text(contract.taskId)
                    .fontSize(12)
                    .fontColor('#999999')
                    .maxLines(1)

                  Text(contract.createdAt ?? '生成时间待更新')
                    .fontSize(12)
                    .fontColor('#666666')

                  Text('点击进入结果总览')
                    .fontSize(12)
                    .fontColor('#2E6BE6')
                }
                .alignItems(HorizontalAlign.Start)
                .width('100%')
                .padding(16)
                .backgroundColor('#F8F9FB')
                .borderRadius(16)
              }
              .type(ButtonType.Normal)
              .width('100%')
              .backgroundColor('#FFFFFF')
              .borderRadius(16)
              .onClick(() => {
                this.openRecentContract(contract)
              })
            }, (contract: Contract) => contract.taskId)
          } else {
            Text('暂无最近记录，完成一次分析并进入结果页后会显示在这里。')
              .fontSize(14)
              .fontColor('#666666')
          }
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
      }
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .padding(24)
    }
    .width('100%')
    .height('100%')
  }

  async loadRecentContracts(): Promise<void> {
    this.recentErrorText = ''

    const hostContext = this.getHostContext()
    if (hostContext === undefined) {
      this.homeVM.clearRecentContracts()
      this.recentContracts = []
      this.recentErrorText = '当前页面上下文不可用，暂时无法读取最近记录'
      return
    }

    const recentContracts = await this.cacheService.loadRecentContracts(hostContext)
    this.homeVM.setRecentContracts(recentContracts)
    this.recentContracts = this.homeVM.recentContracts
  }

  getHostContext(): common.UIAbilityContext | undefined {
    const hostContext = this.getUIContext().getHostContext()
    if (hostContext === undefined) {
      return undefined
    }
    return hostContext as common.UIAbilityContext
  }

  async openRecentContract(contract: Contract): Promise<void> {
    const params: RouteParams = new RouteParams()
    params.taskId = contract.taskId
    params.baseUrl = contract.baseUrl ?? API_BASE_URL
    await goResultOverview(this.getUIContext(), params)
  }

  statusLabel(status?: AnalyzeStatus): string {
    switch (status) {
      case AnalyzeStatus.PENDING:
        return '等待开始'
      case AnalyzeStatus.OCR_RUNNING:
        return 'OCR处理中'
      case AnalyzeStatus.LLM_RUNNING:
        return '模型分析中'
      case AnalyzeStatus.SUCCESS:
        return '分析完成'
      case AnalyzeStatus.FAILED:
        return '分析失败'
      default:
        return '已缓存'
    }
  }
}
