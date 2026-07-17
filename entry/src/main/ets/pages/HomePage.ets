import { common } from '@kit.AbilityKit'
import { goImport, goResultOverview, goSettings, RouteParams } from '../app/AppRouter'
import { API_BASE_URL } from '../common/constants'
import { logError } from '../common/logger'
import { contentMaxWidth, pageHorizontalPadding, pageVerticalPadding } from '../common/ui/LayoutHelpers'
import { LayoutMetrics, UiColors, UiFont, UiRadius, UiShadow, UiSpace } from '../common/ui/DesignTokens'
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
      Column({ space: UiSpace.XXL }) {
        Column({ space: UiSpace.XL }) {
          Row() {
            Blank()
            Text('设置')
              .fontSize(UiFont.BODY_SMALL)
              .fontColor(UiColors.BRAND)
              .padding({ left: 14, right: 14, top: 8, bottom: 8 })
              .backgroundColor(UiColors.SURFACE_PRIMARY)
              .borderRadius(UiRadius.PILL)
              .shadow({
                radius: UiShadow.SOFT_RADIUS,
                color: UiShadow.SOFT_COLOR,
                offsetX: 0,
                offsetY: 4
              })
              .onClick(() => {
                goSettings(this.getUIContext())
              })
          }
          .width('100%')

          Column({ space: UiSpace.MD }) {
            Text('法言白话')
              .fontSize(UiFont.HERO)
              .fontWeight(FontWeight.Bold)
              .fontColor(UiColors.TEXT_PRIMARY)
              .letterSpacing(0.5)

            Text('把晦涩合同变成可快速理解的白话摘要，并提前标出值得注意的风险条款。')
              .fontSize(UiFont.BODY)
              .fontColor(UiColors.TEXT_SECONDARY)
              .lineHeight(24)
              .width('100%')
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')

          Row({ space: UiSpace.SM }) {
            this.stepChip('1', '导入')
            Text('→')
              .fontSize(UiFont.CAPTION)
              .fontColor(UiColors.TEXT_TERTIARY)
            this.stepChip('2', '分析')
            Text('→')
              .fontSize(UiFont.CAPTION)
              .fontColor(UiColors.TEXT_TERTIARY)
            this.stepChip('3', '解读')
          }
          .width('100%')
          .justifyContent(FlexAlign.Start)

          PrimaryButton({
            label: '导入合同',
            fillWidth: true,
            onTap: () => {
              goImport(this.getUIContext())
            }
          })
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding({
          left: UiSpace.XXL,
          right: UiSpace.XXL,
          top: UiSpace.XXL,
          bottom: UiSpace.XXL
        })
        .borderRadius(UiRadius.XLARGE)
        .linearGradient({
          angle: 145,
          colors: [
            [UiColors.SURFACE_PRIMARY, 0.0],
            [UiColors.SURFACE_ACCENT, 1.0]
          ]
        })
        .shadow({
          radius: UiShadow.CARD_RADIUS,
          color: UiShadow.CARD_COLOR,
          offsetX: 0,
          offsetY: UiShadow.CARD_OFFSET_Y
        })

        Column({ space: UiSpace.MD }) {
          SectionHeader({
            title: '最近记录',
            description: '本地保留最近 5 条结果，便于快速回看。'
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
              ForEach(this.visibleRecentContracts(), (contract: Contract) => {
                Row({ space: UiSpace.MD }) {
                  Column()
                    .width(LayoutMetrics.RISK_BAR_WIDTH)
                    .height(36)
                    .borderRadius(UiRadius.PILL)
                    .backgroundColor(this.statusBarColor(contract.status))

                  Column({ space: UiSpace.XS }) {
                    Text(contract.contractName)
                      .fontSize(UiFont.BODY)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(UiColors.TEXT_PRIMARY)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(contract.createdAt ?? '生成时间待更新')
                      .fontSize(UiFont.CAPTION)
                      .fontColor(UiColors.TEXT_TERTIARY)
                      .maxLines(1)
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)

                  Text(this.statusLabel(contract.status))
                    .fontSize(UiFont.BADGE)
                    .fontColor(UiColors.BRAND)
                    .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                    .backgroundColor(UiColors.BRAND_SOFT)
                    .borderRadius(UiRadius.PILL)

                  Text('›')
                    .fontSize(22)
                    .fontColor(UiColors.TEXT_TERTIARY)
                }
                .width('100%')
                .height(64)
                .alignItems(VerticalAlign.Center)
                .padding({
                  left: UiSpace.MD,
                  right: UiSpace.LG
                })
                .backgroundColor(UiColors.SURFACE_PRIMARY)
                .borderRadius(UiRadius.MEDIUM)
                .shadow({
                  radius: UiShadow.SOFT_RADIUS,
                  color: UiShadow.SOFT_COLOR,
                  offsetX: 0,
                  offsetY: 4
                })
                .onClick(() => {
                  this.openRecentContract(contract)
                })
              }, (contract: Contract) => contract.taskId)

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
        bottom: pageVerticalPadding() + 12
      })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .linearGradient({
      angle: 180,
      colors: [
        [UiColors.PAGE_GRADIENT_TOP, 0.0],
        [UiColors.PAGE_GRADIENT_BOTTOM, 0.4],
        [UiColors.PAGE_BACKGROUND, 1.0]
      ]
    })
  }

  @Builder
  stepChip(index: string, label: string) {
    Row({ space: UiSpace.XS }) {
      Text(index)
        .fontSize(UiFont.BADGE)
        .fontWeight(FontWeight.Bold)
        .fontColor(UiColors.BRAND)
        .width(20)
        .height(20)
        .textAlign(TextAlign.Center)
        .borderRadius(UiRadius.PILL)
        .backgroundColor(UiColors.SURFACE_PRIMARY)
      Text(label)
        .fontSize(UiFont.BODY_SMALL)
        .fontColor(UiColors.TEXT_SECONDARY)
    }
    .padding({ left: 8, right: 12, top: 6, bottom: 6 })
    .backgroundColor(UiColors.BRAND_SOFT)
    .borderRadius(UiRadius.PILL)
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
        return UiColors.SUCCESS
      case AnalyzeStatus.LLM_RUNNING:
      case AnalyzeStatus.OCR_RUNNING:
        return UiColors.BRAND
      default:
        return UiColors.TEXT_TERTIARY
    }
  }
}
