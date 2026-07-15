import { common } from '@kit.AbilityKit'
import { goImport, goResultOverview, goSettings, RouteParams } from '../app/AppRouter'
import { API_BASE_URL } from '../common/constants'
import { logError } from '../common/logger'
import { contentMaxWidth, pageHorizontalPadding, pageVerticalPadding } from '../common/ui/LayoutHelpers'
import { UiColors, UiFont, UiRadius, UiSpace } from '../common/ui/DesignTokens'
import { EmptyState, EmptyStateType } from '../components/EmptyState'
import { LoadingState } from '../components/LoadingState'
import { SectionHeader } from '../components/SectionHeader'
import { SurfaceCard } from '../components/SurfaceCard'
import { Contract } from '../model/domain/Contract'
import { AnalyzeStatus } from '../model/enums/AnalyzeStatus'
import { HomeVM } from '../model/viewmodel/HomeVM'
import { CacheService } from '../services/storage/CacheService'

@Entry
@Component
struct HomePage {
  static readonly RECENT_VISIBLE_COUNT: number = 3

  @State recentContracts: Contract[] = []
  @State recentErrorText: string = ''
  @State isLoadingRecentContracts: boolean = false
  @State isRecentExpanded: boolean = false

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
      Column({ space: UiSpace.XL }) {
        SurfaceCard({
          surfaceColor: UiColors.SURFACE_PRIMARY,
          strokeColor: UiColors.BRAND_SOFT,
          paddingValue: UiSpace.XXL,
          radius: UiRadius.LARGE
        }) {
          Column({ space: UiSpace.LG }) {
            Row() {
              Column({ space: UiSpace.SM }) {
                Text('法言白话')
                  .fontSize(UiFont.HERO)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(UiColors.TEXT_PRIMARY)
                Text('把晦涩合同变成可快速理解的白话摘要，并提前标出值得注意的风险条款。')
                  .fontSize(UiFont.BODY)
                  .fontColor(UiColors.TEXT_SECONDARY)
                  .lineHeight(22)
              }
              .alignItems(HorizontalAlign.Start)

              Button('设置')
                .type(ButtonType.Capsule)
                .backgroundColor(UiColors.BRAND_SOFT)
                .fontColor(UiColors.BRAND)
                .onClick(() => {
                  goSettings(this.getUIContext())
                })
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)

            SurfaceCard({
              surfaceColor: UiColors.SURFACE_ACCENT,
              strokeColor: UiColors.BRAND_SOFT,
              paddingValue: UiSpace.LG,
              radius: UiRadius.MEDIUM
            }) {
              Column({ space: UiSpace.SM }) {
                Text('三步完成合同速览')
                  .fontSize(UiFont.BODY)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(UiColors.TEXT_PRIMARY)
                Text('导入合同 -> 等待分析 -> 查看摘要、风险和条款解释。')
                  .fontSize(UiFont.BODY_SMALL)
                  .fontColor(UiColors.TEXT_SECONDARY)
              }
              .alignItems(HorizontalAlign.Start)
              .width('100%')
            }

            Row({ space: UiSpace.MD }) {
              Button('开始导入合同')
                .type(ButtonType.Capsule)
                .backgroundColor(UiColors.BRAND)
                .fontColor('#FFFFFF')
                .onClick(() => {
                  goImport(this.getUIContext())
                })

              Button('查看用户设置')
                .type(ButtonType.Capsule)
                .backgroundColor(UiColors.SURFACE_SECONDARY)
                .fontColor(UiColors.TEXT_PRIMARY)
                .onClick(() => {
                  goSettings(this.getUIContext())
                })
            }
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
        }

        Column({ space: UiSpace.MD }) {
          SectionHeader({
            title: '最近记录',
            description: '保留最近 5 条已查看结果，方便你快速回看上次分析。'
          })

          if (this.isLoadingRecentContracts) {
            LoadingState({
              title: '正在加载最近记录',
              description: '我们正在读取本地缓存中的历史分析结果。',
              detail: '若刚从结果页返回，列表会自动刷新。'
            })
          } else if (this.recentErrorText.length > 0) {
            Column({ space: UiSpace.MD }) {
              EmptyState({
                title: '最近记录读取失败',
                description: this.recentErrorText,
                hint: '可点击重试重新加载本地缓存，也可以直接发起新的合同分析。',
                stateType: EmptyStateType.ERROR
              })
              Row({ space: UiSpace.SM }) {
                Button('重试读取')
                  .type(ButtonType.Capsule)
                  .backgroundColor(UiColors.BRAND)
                  .fontColor('#FFFFFF')
                  .onClick(() => {
                    this.loadRecentContracts()
                  })
                Button('导入合同')
                  .type(ButtonType.Capsule)
                  .backgroundColor(UiColors.SURFACE_SECONDARY)
                  .fontColor(UiColors.TEXT_PRIMARY)
                  .onClick(() => {
                    goImport(this.getUIContext())
                  })
              }
            }
            .width('100%')
          } else if (this.recentContracts.length > 0) {
            Column({ space: UiSpace.MD }) {
              ForEach(this.visibleRecentContracts(), (contract: Contract) => {
                Button() {
                  Column({ space: UiSpace.MD }) {
                    Row() {
                      Column({ space: UiSpace.XS }) {
                        Text(contract.contractName)
                          .fontSize(18)
                          .fontWeight(FontWeight.Bold)
                          .fontColor(UiColors.TEXT_PRIMARY)
                          .maxLines(2)
                        Text(contract.taskId)
                          .fontSize(UiFont.CAPTION)
                          .fontColor(UiColors.TEXT_TERTIARY)
                          .maxLines(1)
                      }
                      .alignItems(HorizontalAlign.Start)

                      Text(this.statusLabel(contract.status))
                        .fontSize(UiFont.CAPTION)
                        .fontColor(UiColors.BRAND)
                        .padding({ left: 10, right: 10, top: 5, bottom: 5 })
                        .backgroundColor(UiColors.BRAND_SOFT)
                        .borderRadius(UiRadius.PILL)
                    }
                    .width('100%')
                    .justifyContent(FlexAlign.SpaceBetween)

                    Row() {
                      Text(contract.createdAt ?? '生成时间待更新')
                        .fontSize(UiFont.CAPTION)
                        .fontColor(UiColors.TEXT_SECONDARY)
                      Text('进入结果总览')
                        .fontSize(UiFont.CAPTION)
                        .fontColor(UiColors.BRAND)
                    }
                    .width('100%')
                    .justifyContent(FlexAlign.SpaceBetween)
                  }
                  .alignItems(HorizontalAlign.Start)
                  .width('100%')
                  .padding(UiSpace.LG)
                  .backgroundColor(UiColors.SURFACE_PRIMARY)
                  .borderRadius(UiRadius.MEDIUM)
                  .border({
                    width: 1,
                    color: UiColors.BORDER_SOFT
                  })
                }
                .type(ButtonType.Normal)
                .width('100%')
                .backgroundColor(UiColors.PAGE_BACKGROUND)
                .borderRadius(UiRadius.MEDIUM)
                .onClick(() => {
                  this.openRecentContract(contract)
                })
              }, (contract: Contract) => contract.taskId)

              if (this.shouldShowRecentToggle()) {
                Button(this.recentToggleText())
                  .type(ButtonType.Capsule)
                  .backgroundColor(UiColors.SURFACE_SECONDARY)
                  .fontColor(UiColors.TEXT_PRIMARY)
                  .onClick(() => {
                    this.isRecentExpanded = !this.isRecentExpanded
                  })
              }
            }
            .width('100%')
          } else {
            Column({ space: UiSpace.MD }) {
              EmptyState({
                title: '暂无最近记录',
                description: '完成一次分析并进入结果页后，最近 5 条记录会显示在这里。',
                hint: '建议先导入一份演示合同，跑通上传、分析和结果查看主链路。',
                stateType: EmptyStateType.EMPTY
              })
              Button('开始分析')
                .type(ButtonType.Capsule)
                .backgroundColor(UiColors.BRAND)
                .fontColor('#FFFFFF')
                .onClick(() => {
                  goImport(this.getUIContext())
                })
            }
            .width('100%')
          }
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
      }
      .width('100%')
      .constraintSize({ maxWidth: contentMaxWidth() })
      .padding({
        left: pageHorizontalPadding(),
        right: pageHorizontalPadding(),
        top: pageVerticalPadding(),
        bottom: pageVerticalPadding()
      })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(UiColors.PAGE_BACKGROUND)
  }

  async loadRecentContracts(): Promise<void> {
    this.recentErrorText = ''
    this.isLoadingRecentContracts = true

    const hostContext = this.getHostContext()
    if (hostContext === undefined) {
      this.homeVM.clearRecentContracts()
      this.recentContracts = []
      this.recentErrorText = '当前页面上下文不可用，暂时无法读取最近记录'
      this.isLoadingRecentContracts = false
      return
    }

    try {
      const recentContracts = await this.cacheService.loadRecentContracts(hostContext)
      this.homeVM.setRecentContracts(recentContracts)
      this.recentContracts = this.homeVM.recentContracts
      if (this.recentContracts.length <= HomePage.RECENT_VISIBLE_COUNT) {
        this.isRecentExpanded = false
      }
    } catch (error) {
      this.homeVM.clearRecentContracts()
      this.recentContracts = []
      this.recentErrorText = '读取最近记录失败，请稍后重试。'
      this.isRecentExpanded = false
      logError('Load recent contracts failed', JSON.stringify(error), 'HomePage')
    } finally {
      this.isLoadingRecentContracts = false
    }
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

  visibleRecentContracts(): Contract[] {
    if (this.isRecentExpanded || this.recentContracts.length <= HomePage.RECENT_VISIBLE_COUNT) {
      return this.recentContracts
    }
    return this.recentContracts.slice(0, HomePage.RECENT_VISIBLE_COUNT)
  }

  shouldShowRecentToggle(): boolean {
    return this.recentContracts.length > HomePage.RECENT_VISIBLE_COUNT
  }

  recentToggleText(): string {
    if (this.isRecentExpanded) {
      return '收起最近记录'
    }
    return `展开其余 ${this.recentContracts.length - HomePage.RECENT_VISIBLE_COUNT} 条`
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
