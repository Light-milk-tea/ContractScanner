import { common } from '@kit.AbilityKit'
import { back, RouteParams } from '../app/AppRouter'
import { API_BASE_URL } from '../common/constants'
import { AppError } from '../common/errors'
import { logError, logInfo } from '../common/logger'
import { readingMaxWidth } from '../common/ui/LayoutHelpers'
import { UiColors, UiFont, UiRadius, UiSpace } from '../common/ui/DesignTokens'
import { GhostButton, PrimaryButton } from '../components/ActionButtons'
import { ClauseBlock } from '../components/ClauseBlock'
import { EmptyState, EmptyStateType } from '../components/EmptyState'
import { LoadingState } from '../components/LoadingState'
import { PageScaffold } from '../components/PageScaffold'
import { AnalysisResult } from '../model/domain/AnalysisResult'
import { ClauseRisk } from '../model/domain/ClauseRisk'
import { ResultVM } from '../model/viewmodel/ResultVM'
import { DTOMapper } from '../services/api/DTOMapper'
import { ContractApi } from '../services/api/ContractApi'
import { PrivacyGuardService } from '../services/ability/PrivacyGuardService'

@Entry
@Component
struct ClauseComparePage {
  @State isLoading: boolean = true
  @State errorText: string = ''
  @State renderTick: number = 0
  @State isUsingDemoResult: boolean = false
  @State currentResult?: AnalysisResult = undefined
  @State currentClause?: ClauseRisk = undefined
  @State privacyGuardEnabled: boolean = false

  resultVM: ResultVM = new ResultVM()
  privacyGuardService: PrivacyGuardService = new PrivacyGuardService()

  aboutToAppear(): void {
    this.loadClauseDetail()
  }

  onPageShow(): void {
    this.applySensitiveProtection()
  }

  onPageHide(): void {
    this.releaseSensitiveProtection()
  }

  build() {
    Column() {
      PageScaffold({
        title: '条款对照阅读',
        description: '',
        backText: '返回结果页',
        onBack: () => {
          back(this.getUIContext())
        }
      }) {
        Column({ space: UiSpace.LG }) {
        if (this.isLoading) {
          LoadingState({
            title: '正在加载条款详情',
            description: '正在整理原文与解释内容。'
          })
        }

        if (this.errorText.length > 0) {
          Column({ space: UiSpace.MD }) {
            EmptyState({
              title: '条款详情加载异常',
              description: this.errorText,
              hint: this.isUsingDemoResult ? '当前为演示条款，可继续查看。' : '可重试或切换演示条款。',
              stateType: EmptyStateType.ERROR
            })
            Row({ space: UiSpace.SM }) {
              PrimaryButton({
                label: '重试加载',
                onTap: () => {
                  this.loadClauseDetail()
                }
              })
              if (!this.isUsingDemoResult) {
                GhostButton({
                  label: '查看演示条款',
                  onTap: () => {
                    this.openDemoClause()
                  }
                })
              }
            }
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
        }

        if (this.currentClause !== undefined) {
          if (this.privacyGuardEnabled) {
            Text('已开启隐私防窥，当前条款详情页会限制截屏和录屏。')
              .fontSize(UiFont.CAPTION)
              .fontColor(UiColors.BRAND)
              .width('100%')
          }

          Column() {
            ClauseBlock({
              title: this.currentClause.title,
              originalText: this.currentClause.originalText,
              plainText: this.currentClause.plainText,
              riskReason: this.currentClause.riskReason,
              suggestion: this.currentClause.suggestion ?? '',
              legalBasis: this.currentClause.legalBasis ?? '',
              anchorText: this.buildAnchorText(this.currentClause),
              riskLevel: this.currentClause.riskLevel
            })
          }
          .width('100%')
          .constraintSize({ maxWidth: readingMaxWidth() })
          .padding({
            left: UiSpace.LG,
            right: UiSpace.LG,
            top: UiSpace.LG,
            bottom: UiSpace.LG
          })
          .backgroundColor(UiColors.SURFACE_MUTED)
          .borderRadius(UiRadius.LARGE)
        }
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
      }
    }
    .width('100%')
    .height('100%')
  }

  async loadClauseDetail(): Promise<void> {
    const params = this.readParams()
    const taskId: string = params.taskId ?? ''
    const baseUrl: string = params.baseUrl ?? API_BASE_URL
    const clauseId: string = params.clauseId ?? ''
    const mapper = new DTOMapper()
    logInfo(`Load clause detail: taskId=${taskId}, clauseId=${clauseId}, baseUrl=${baseUrl}`, 'ClauseComparePage')
    this.resultVM.setRouteContext(taskId, baseUrl)
    this.resultVM.setSelectedClauseId(clauseId)
    this.isLoading = true
    this.errorText = ''
    this.isUsingDemoResult = false
    this.currentResult = undefined
    this.currentClause = undefined

    try {
      if (taskId.length === 0 || ContractApi.isMockTask(taskId)) {
        const mockDto = ContractApi.getMockAnalysisResult(taskId)
        this.currentResult = mapper.mapAnalysisResult(mockDto)
        this.resultVM.setResult(this.currentResult)
        this.isUsingDemoResult = true
      } else {
        const api = new ContractApi(baseUrl)
        const dto = await api.getAnalysisResult(taskId)
        this.currentResult = mapper.mapAnalysisResult(dto)
        this.resultVM.setResult(this.currentResult)
      }

      if (clauseId.length > 0 && this.currentResult !== undefined) {
        this.currentClause = this.findClause(this.currentResult, clauseId)
      } else if (this.currentResult !== undefined && this.currentResult.clauses.length > 0) {
        this.currentClause = this.currentResult.clauses[0]
      }

      if (this.currentClause === undefined) {
        this.errorText = '未找到对应条款，已停留在对照页。'
      } else {
        logInfo(`Clause detail ready: clauseId=${this.currentClause.clauseId}, title=${this.currentClause.title}`, 'ClauseComparePage')
      }
    } catch (error) {
      this.currentResult = undefined
      this.currentClause = undefined
      this.resultVM.clear()
      this.resultVM.setRouteContext(taskId, baseUrl)
      this.resultVM.setSelectedClauseId(clauseId)
      if (error instanceof AppError) {
        this.errorText = `条款详情加载失败：${error.message}`
        logError('Clause compare load failed', error.details ?? '', 'ClauseComparePage')
      } else {
        this.errorText = '条款详情加载失败，请稍后重试'
        logError('Clause compare load failed', JSON.stringify(error), 'ClauseComparePage')
      }
    } finally {
      this.isLoading = false
      this.renderTick = this.renderTick + 1
    }
  }

  findClause(result: AnalysisResult, clauseId: string): ClauseRisk | undefined {
    for (let i: number = 0; i < result.clauses.length; i++) {
      const clause = result.clauses[i]
      if (clause.clauseId === clauseId) {
        return clause
      }
    }
    return undefined
  }

  buildAnchorText(clause: ClauseRisk): string {
    const hasPage: boolean = clause.anchors.page !== undefined
    const hasParagraph: boolean = clause.anchors.paragraph !== undefined
    if (!hasPage && !hasParagraph) {
      return ''
    }

    let anchorText: string = '定位：'
    if (hasPage) {
      anchorText = `${anchorText} 第 ${clause.anchors.page} 页`
    }
    if (hasParagraph) {
      anchorText = `${anchorText} 第 ${clause.anchors.paragraph} 段`
    }
    return anchorText
  }

  readParams(): RouteParams {
    return this.getUIContext().getRouter().getParams() as RouteParams
  }

  getHostContext(): common.UIAbilityContext | undefined {
    const hostContext = this.getUIContext().getHostContext()
    if (hostContext === undefined) {
      return undefined
    }
    return hostContext as common.UIAbilityContext
  }

  openDemoClause(): void {
    const demoResult = this.resultVM.loadDemoResult(this.resultVM.taskId)
    this.currentResult = demoResult
    this.isUsingDemoResult = true
    const selectedClause = this.findClause(demoResult, this.resultVM.selectedClauseId)
    if (selectedClause !== undefined) {
      this.currentClause = selectedClause
    } else if (demoResult.clauses.length > 0) {
      this.currentClause = demoResult.clauses[0]
    }
    this.errorText = '当前展示的是临时演示条款，真实结果仍可稍后重试拉取。'
    logInfo(`Fallback to demo clause: taskId=${demoResult.taskId}`, 'ClauseComparePage')
  }

  async applySensitiveProtection(): Promise<void> {
    const hostContext = this.getHostContext()
    if (hostContext === undefined) {
      return
    }

    this.privacyGuardEnabled = await this.privacyGuardService.loadEnabled(hostContext)
    await this.privacyGuardService.applyWindowPrivacyMode(hostContext, this.privacyGuardEnabled)
  }

  async releaseSensitiveProtection(): Promise<void> {
    const hostContext = this.getHostContext()
    if (hostContext === undefined || !this.privacyGuardEnabled) {
      return
    }
    await this.privacyGuardService.applyWindowPrivacyMode(hostContext, false)
  }
}
