import { common } from '@kit.AbilityKit'
import { goImport, goResultOverview, goSettings, RouteParams } from '../app/AppRouter'
import { API_BASE_URL } from '../common/constants'
import { logError } from '../common/logger'
import {
  contentMaxWidth,
  heroFontSize,
  isCompactLayout,
  pageHorizontalPadding,
  pageVerticalPadding,
  sectionGap
} from '../common/ui/LayoutHelpers'
import { LayoutMetrics, UiColors, UiFont, UiRadius, UiSpace } from '../common/ui/DesignTokens'
import { GhostButton, PrimaryButton } from '../components/ActionButtons'
import { EmptyState, EmptyStateType } from '../components/EmptyState'
import { LoadingState } from '../components/LoadingState'
import { SectionHeader } from '../components/SectionHeader'
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
  @State heroOpacity: number = 0
  @State heroOffsetY: number = 16
  @State ctaOpacity: number = 0
  @State ctaOffsetY: number = 12

  homeVM: HomeVM = new HomeVM()
  cacheService: CacheService = new CacheService()

  aboutToAppear(): void {
    this.loadRecentContracts()
    this.playHeroEntrance()
  }

  onPageShow(): void {
    this.loadRecentContracts()
  }

  playHeroEntrance(): void {
    this.heroOpacity = 0
    this.heroOffsetY = 16
    this.ctaOpacity = 0
    this.ctaOffsetY = 12

    this.getUIContext().animateTo({ duration: 320, curve: Curve.EaseOut }, () => {
      this.heroOpacity = 1
      this.heroOffsetY = 0
    })

    setTimeout(() => {
      this.getUIContext().animateTo({ duration: 280, curve: Curve.EaseOut }, () => {
        this.ctaOpacity = 1
        this.ctaOffsetY = 0
      })
    }, 120)
  }

  build() {
    Scroll() {
      Column({ space: sectionGap() }) {
        Column({ space: UiSpace.XXL }) {
          Row() {
            Blank()
            Text('设置')
              .fontSize(UiFont.BODY_SMALL)
              .fontColor(UiColors.BRAND)
              .padding({ left: 4, right: 4, top: 6, bottom: 6 })
              .onClick(() => {
                goSettings(this.getUIContext())
              })
          }
          .width('100%')

          Column({ space: UiSpace.MD }) {
            Column({ space: UiSpace.SM }) {
              Text('法言白话')
                .fontSize(heroFontSize())
                .fontWeight(FontWeight.Bold)
                .fontColor(UiColors.TEXT_PRIMARY)
                .letterSpacing(6)
                .textAlign(TextAlign.Center)
                .width('100%')

              Row()
                .width(32)
                .height(3)
                .borderRadius(1)
                .backgroundColor(UiColors.BRAND)
                .margin({ top: 2 })
            }
            .alignItems(HorizontalAlign.Center)
            .width('100%')

            Text('把合同读成人话')
              .fontSize(isCompactLayout() ? UiFont.BODY : UiFont.SECTION_TITLE)
              .fontColor(UiColors.TEXT_SECONDARY)
              .letterSpacing(1)
              .textAlign(TextAlign.Center)
              .width('100%')
          }
          .alignItems(HorizontalAlign.Center)
          .width('100%')
          .padding({ top: UiSpace.LG, bottom: UiSpace.SM })
          .opacity(this.heroOpacity)
          .translate({ y: this.heroOffsetY })

          Column() {
            PrimaryButton({
              label: '导入合同',
              fillWidth: true,
              onTap: () => {
                goImport(this.getUIContext())
              }
            })
          }
          .width('100%')
          .opacity(this.ctaOpacity)
          .translate({ y: this.ctaOffsetY })
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')

        Column({ space: UiSpace.LG }) {
          SectionHeader({
            title: '最近记录',
            description: '本地保留最近 5 条结果，便于快速回看。',
            alignCenter: false
          })

          if (this.isLoadingRecentContracts) {
            LoadingState({
              title: '正在加载最近记录',
              description: '正在读取本地缓存中的历史分析结果。'
            })
          } else if (this.recentErrorText.length > 0) {
            Column({ space: UiSpace.MD }) {
              EmptyState({
                title: '最近记录读取失败',
                description: this.recentErrorText,
                hint: '可重试加载，或直接发起新的合同分析。',
                stateType: EmptyStateType.ERROR
              })
              Row({ space: UiSpace.SM }) {
                PrimaryButton({
                  label: '重试读取',
                  onTap: () => {
                    this.loadRecentContracts()
                  }
                })
                GhostButton({
                  label: '导入合同',
                  onTap: () => {
                    goImport(this.getUIContext())
                  }
                })
              }
            }
            .width('100%')
          } else if (this.recentContracts.length > 0) {
            Column({ space: UiSpace.SM }) {
              Column() {
                ForEach(this.visibleRecentContracts(), (contract: Contract, index: number) => {
                  Column() {
                    if (index > 0) {
                      Divider()
                        .color(UiColors.BORDER_HAIRLINE)
                        .strokeWidth(0.5)
                        .margin({ left: UiSpace.LG + LayoutMetrics.RISK_BAR_WIDTH + UiSpace.MD })
                    }
                    Row({ space: UiSpace.MD }) {
                      Column()
                        .width(LayoutMetrics.RISK_BAR_WIDTH)
                        .height(28)
                        .borderRadius(1)
                        .backgroundColor(this.statusBarColor(contract.status))

                      Column({ space: 4 }) {
                        Text(contract.contractName)
                          .fontSize(UiFont.BODY)
                          .fontWeight(FontWeight.Medium)
                          .fontColor(UiColors.TEXT_PRIMARY)
                          .maxLines(1)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                          .width('100%')
                        Text(`${this.formatCreatedAt(contract.createdAt)}  ·  ${this.statusLabel(contract.status)}`)
                          .fontSize(UiFont.CAPTION)
                          .fontColor(UiColors.TEXT_TERTIARY)
                          .maxLines(1)
                      }
                      .alignItems(HorizontalAlign.Start)
                      .layoutWeight(1)

                      Text('›')
                        .fontSize(18)
                        .fontColor(UiColors.TEXT_TERTIARY)
                    }
                    .width('100%')
                    .alignItems(VerticalAlign.Center)
                    .padding({
                      left: UiSpace.LG,
                      right: UiSpace.LG,
                      top: UiSpace.LG,
                      bottom: UiSpace.LG
                    })
                    .onClick(() => {
                      this.openRecentContract(contract)
                    })
                  }
                  .width('100%')
                }, (contract: Contract) => contract.taskId)
              }
              .width('100%')
              .backgroundColor(UiColors.SURFACE_MUTED)
              .borderRadius(UiRadius.LARGE)

              if (this.shouldShowRecentToggle()) {
                GhostButton({
                  label: this.recentToggleText(),
                  fillWidth: true,
                  onTap: () => {
                    this.isRecentExpanded = !this.isRecentExpanded
                  }
                })
              }
            }
            .width('100%')
          } else {
            Column({ space: UiSpace.MD }) {
              EmptyState({
                title: '暂无最近记录',
                description: '完成一次分析并进入结果页后，最近记录会显示在这里。',
                hint: '可先导入演示合同，跑通主链路。',
                stateType: EmptyStateType.EMPTY
              })
              PrimaryButton({
                label: '开始分析',
                fillWidth: true,
                onTap: () => {
                  goImport(this.getUIContext())
                }
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
        bottom: pageVerticalPadding() + (isCompactLayout() ? 24 : 12)
      })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .align(Alignment.Top)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
    .linearGradient({
      angle: 180,
      colors: [
        [UiColors.PAGE_GRADIENT_TOP, 0.0],
        [UiColors.PAGE_GRADIENT_BOTTOM, 0.4],
        [UiColors.PAGE_BACKGROUND, 1.0]
      ]
    })
  }

  formatCreatedAt(createdAt?: string): string {
    if (createdAt === undefined || createdAt.length === 0) {
      return '生成时间待更新'
    }
    if (isCompactLayout() && createdAt.indexOf('T') > 0) {
      return createdAt.replace('T', ' ').substring(0, 19)
    }
    return createdAt
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

  statusBarColor(status?: AnalyzeStatus): string {
    switch (status) {
      case AnalyzeStatus.FAILED:
        return UiColors.DANGER
      case AnalyzeStatus.SUCCESS:
        return UiColors.BRAND
      case AnalyzeStatus.LLM_RUNNING:
      case AnalyzeStatus.OCR_RUNNING:
        return UiColors.BRAND_STRONG
      default:
        return UiColors.BRAND_SOFT
    }
  }
}
