import { common } from '@kit.AbilityKit'
import { back, goClauseCompare, goContractChat, RouteParams } from '../app/AppRouter'
import { API_BASE_URL } from '../common/constants'
import { AppError } from '../common/errors'
import { logError, logInfo } from '../common/logger'
import { isCompactLayout } from '../common/ui/LayoutHelpers'
import { UiColors, UiFont, UiRadius, UiSpace } from '../common/ui/DesignTokens'
import { GhostButton, PrimaryButton } from '../components/ActionButtons'
import { EmptyState, EmptyStateType } from '../components/EmptyState'
import { LoadingState } from '../components/LoadingState'
import { PageScaffold } from '../components/PageScaffold'
import { RiskBadge } from '../components/RiskBadge'
import { SectionHeader } from '../components/SectionHeader'
import { SummaryCard } from '../components/SummaryCard'
import { AnalysisResult } from '../model/domain/AnalysisResult'
import { ClauseRisk } from '../model/domain/ClauseRisk'
import { Contract } from '../model/domain/Contract'
import { AnalyzeStatus } from '../model/enums/AnalyzeStatus'
import { RiskLevel } from '../model/enums/RiskLevel'
import { ResultVM } from '../model/viewmodel/ResultVM'
import { DTOMapper } from '../services/api/DTOMapper'
import { ContractApi } from '../services/api/ContractApi'
import { CardService } from '../services/ability/CardService'
import { ContinuePayload, ContinueService } from '../services/ability/ContinueService'
import { PrivacyGuardService } from '../services/ability/PrivacyGuardService'
import { DocReportBuilder } from '../services/report/DocReportBuilder'
import { ReportExportService } from '../services/report/ReportExportService'
import { CacheService } from '../services/storage/CacheService'
import { UserSettingsService } from '../services/storage/UserSettingsService'

@Entry
@Component
struct ResultOverviewPage {
  @State isLoading: boolean = true
  @State errorText: string = ''
  @State renderTick: number = 0
  @State currentResult?: AnalysisResult = undefined
  @State isUsingDemoResult: boolean = false
  @State privacyGuardEnabled: boolean = false
  @State resultContentOpacity: number = 0
  @State isExportingReport: boolean = false
  @State exportHint: string = ''

  resultVM: ResultVM = new ResultVM()
  cacheService: CacheService = new CacheService()
  cardService: CardService = new CardService()
  continueService: ContinueService = new ContinueService()
  privacyGuardService: PrivacyGuardService = new PrivacyGuardService()
  reportBuilder: DocReportBuilder = new DocReportBuilder()
  reportExportService: ReportExportService = new ReportExportService()

  aboutToAppear(): void {
    this.loadResult()
  }

  playResultEntrance(): void {
    this.resultContentOpacity = 0
    this.getUIContext().animateTo({ duration: 280, curve: Curve.EaseOut }, () => {
      this.resultContentOpacity = 1
    })
  }

  onPageShow(): void {
    this.applySensitiveProtection()
  }

  onPageHide(): void {
    this.releaseSensitiveProtection()
    this.deactivateContinuation()
  }

  build() {
    Column() {
      PageScaffold({
        title: '结果总览',
        description: '先看结论，再逐条精读风险条款。',
        backText: '返回',
        onBack: () => {
          back(this.getUIContext())
        }
      }) {
        Column({ space: isCompactLayout() ? UiSpace.MD : UiSpace.LG }) {
        if (this.isLoading) {
          LoadingState({
            title: '正在加载分析结果',
            description: '正在整理合同摘要与风险条款。'
          })
        }

        if (this.errorText.length > 0) {
          Column({ space: UiSpace.MD }) {
            EmptyState({
              title: '结果加载异常',
              description: this.errorText,
              hint: this.isUsingDemoResult ? '当前为演示结果，可继续查看或重试真实结果。' : '请检查服务状态后重试。',
              stateType: EmptyStateType.ERROR
            })
            Row({ space: UiSpace.SM }) {
              PrimaryButton({
                label: '重试加载',
                isEnabled: !this.isLoading,
                onTap: () => {
                  this.retryLoadResult()
                }
              })
              if (!this.isUsingDemoResult) {
                GhostButton({
                  label: '查看演示结果',
                  isEnabled: !this.isLoading,
                  onTap: () => {
                    this.openDemoResult()
                  }
                })
              }
            }
          }
          .width('100%')
        }

        if (this.currentResult !== undefined) {
          if (this.privacyGuardEnabled) {
            Text('已开启隐私防窥，当前页面会限制截屏和录屏。')
              .fontSize(UiFont.CAPTION)
              .fontColor(UiColors.BRAND)
              .width('100%')
          }

          Column({ space: UiSpace.MD }) {
            SummaryCard({
              contractName: this.currentResult.contractName,
              overallSummary: this.currentResult.overallSummary,
              generatedAt: this.currentResult.generatedAt,
              checklist: this.currentResult.signBeforeChecklist,
              redCount: this.currentResult.riskStats.red,
              yellowCount: this.currentResult.riskStats.yellow,
              greenCount: this.currentResult.riskStats.green
            })

            GhostButton({
              label: this.isExportingReport ? '正在导出…' : '导出 Word 报告',
              isEnabled: !this.isExportingReport,
              fillWidth: true,
              onTap: () => {
                this.exportDocReport()
              }
            })

            PrimaryButton({
              label: '向合同助手提问',
              isEnabled: true,
              fillWidth: true,
              onTap: () => {
                this.openContractChat()
              }
            })

            if (this.exportHint.length > 0) {
              Text(this.exportHint)
                .fontSize(UiFont.CAPTION)
                .fontColor(UiColors.TEXT_SECONDARY)
                .width('100%')
            }
          }
          .width('100%')
          .opacity(this.resultContentOpacity)

          Column({ space: UiSpace.MD }) {
            SectionHeader({
              title: '风险条目',
              description: '点击条目查看原文、白话解释与修改建议。',
              alignCenter: false
            })

            Column() {
              ForEach(this.currentResult.clauses, (clause: ClauseRisk, index: number) => {
                Column() {
                  if (index > 0) {
                    Divider()
                      .color(UiColors.BORDER_HAIRLINE)
                      .strokeWidth(0.5)
                      .margin({ left: UiSpace.LG + 3 + UiSpace.MD })
                  }
                  Row({ space: UiSpace.MD }) {
                    Column()
                      .width(3)
                      .height(32)
                      .borderRadius(1)
                      .backgroundColor(this.riskBarColor(clause.riskLevel))

                    Column({ space: UiSpace.SM }) {
                      Row({ space: UiSpace.SM }) {
                        Text(clause.title)
                          .fontSize(UiFont.BODY)
                          .fontWeight(FontWeight.Medium)
                          .fontColor(UiColors.TEXT_PRIMARY)
                          .layoutWeight(1)
                          .maxLines(2)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                        RiskBadge({ riskLevel: clause.riskLevel })
                      }
                      .width('100%')

                      Text(clause.riskReason)
                        .fontSize(UiFont.BODY_SMALL)
                        .fontColor(UiColors.TEXT_SECONDARY)
                        .maxLines(3)
                        .lineHeight(22)

                      Text('查看对照阅读 ›')
                        .fontSize(UiFont.CAPTION)
                        .fontColor(UiColors.BRAND)
                    }
                    .alignItems(HorizontalAlign.Start)
                    .layoutWeight(1)
                  }
                  .width('100%')
                  .alignItems(VerticalAlign.Top)
                  .padding({
                    left: UiSpace.LG,
                    right: UiSpace.LG,
                    top: UiSpace.LG,
                    bottom: UiSpace.LG
                  })
                  .onClick(() => {
                    this.openClauseCompare(clause.clauseId)
                  })
                }
                .width('100%')
              })
            }
            .width('100%')
            .backgroundColor(UiColors.SURFACE_MUTED)
            .borderRadius(UiRadius.LARGE)
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
          .opacity(this.resultContentOpacity)
        }
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
      }
    }
    .width('100%')
    .height('100%')
  }

  async loadResult(): Promise<void> {
    const params = await this.readParams()
    const taskId: string = params.taskId ?? ''
    const baseUrl: string = params.baseUrl ?? API_BASE_URL
    const mapper = new DTOMapper()
    logInfo(`Load result overview: taskId=${taskId}, baseUrl=${baseUrl}`, 'ResultOverviewPage')
    this.resultVM.setRouteContext(taskId, baseUrl)
    this.resultVM.setLoading(true)
    this.resultVM.setError('')
    this.isLoading = true
    this.errorText = ''
    this.exportHint = ''
    this.isUsingDemoResult = false

    try {
      if (taskId.length === 0 || ContractApi.isMockTask(taskId)) {
        const mockDto = ContractApi.getMockAnalysisResult(taskId)
        const mockResult = mapper.mapAnalysisResult(mockDto)
        this.currentResult = mockResult
        this.resultVM.setResult(mockResult)
        this.isUsingDemoResult = true
        logInfo(`Use demo result: taskId=${mockResult.taskId}, contractName=${mockResult.contractName}`, 'ResultOverviewPage')
      } else {
        const api = new ContractApi(baseUrl)
        const dto = await api.getAnalysisResult(taskId)
        const mappedResult = mapper.mapAnalysisResult(dto)
        this.currentResult = mappedResult
        this.resultVM.setResult(mappedResult)
        logInfo(`Use real result: taskId=${mappedResult.taskId}, contractName=${mappedResult.contractName}`, 'ResultOverviewPage')
      }
    } catch (error) {
      this.currentResult = undefined
      this.resultVM.clear()
      this.resultVM.setRouteContext(taskId, baseUrl)
      if (error instanceof AppError) {
        this.errorText = `结果获取失败：${error.message}`
        this.resultVM.setError(this.errorText)
        logError('Result overview load failed', error.details ?? '', 'ResultOverviewPage')
      } else {
        this.errorText = '结果获取失败，请稍后重试'
        this.resultVM.setError(this.errorText)
        logError('Result overview load failed', JSON.stringify(error), 'ResultOverviewPage')
      }
    } finally {
      await this.saveRecentContract()
      await this.activateContinuation()
      await this.applySensitiveProtection()
      this.isLoading = false
      this.resultVM.setLoading(false)
      this.renderTick = this.renderTick + 1
      if (this.currentResult !== undefined) {
        this.playResultEntrance()
      }
    }
  }

  retryLoadResult(): void {
    this.currentResult = undefined
    this.loadResult()
  }

  openDemoResult(): void {
    const demoResult = this.resultVM.loadDemoResult(this.resultVM.taskId)
    this.currentResult = demoResult
    this.isUsingDemoResult = true
    this.errorText = '当前展示的是临时演示结果，真实结果仍可稍后重试拉取。'
    logInfo(`Fallback to demo result: taskId=${demoResult.taskId}`, 'ResultOverviewPage')
    this.playResultEntrance()
  }

  async openClauseCompare(clauseId: string): Promise<void> {
    logInfo(`Open clause compare: taskId=${this.resultVM.taskId}, clauseId=${clauseId}`, 'ResultOverviewPage')
    const params: RouteParams = new RouteParams()
    params.taskId = this.resultVM.taskId
    params.baseUrl = this.resultVM.baseUrl
    params.clauseId = clauseId
    await goClauseCompare(this.getUIContext(), params)
  }

  async openContractChat(): Promise<void> {
    logInfo(`Open contract chat: taskId=${this.resultVM.taskId}, demo=${this.isUsingDemoResult}`, 'ResultOverviewPage')
    const params: RouteParams = new RouteParams()
    if (this.isUsingDemoResult && !ContractApi.isMockTask(this.resultVM.taskId)) {
      params.taskId = ContractApi.buildMockTaskId()
    } else {
      params.taskId = this.resultVM.taskId
    }
    params.baseUrl = this.resultVM.baseUrl
    await goContractChat(this.getUIContext(), params)
  }

  async exportDocReport(): Promise<void> {
    if (this.currentResult === undefined || this.isExportingReport) {
      return
    }

    const hostContext = this.getHostContext()
    if (hostContext === undefined) {
      this.exportHint = '当前页面上下文不可用，暂时无法导出报告'
      return
    }

    this.isExportingReport = true
    this.exportHint = ''
    try {
      const docContent = this.reportBuilder.build(this.currentResult)
      const fileName = this.reportBuilder.buildFileName(this.currentResult.contractName)
      const savedUri = await this.reportExportService.saveDoc(hostContext, fileName, docContent)
      if (savedUri.length === 0) {
        this.exportHint = '已取消导出'
        return
      }
      this.exportHint = '报告已保存为 .doc，可用 WPS / 文档 App 打开'
      logInfo(`Export doc report ok: taskId=${this.currentResult.taskId}`, 'ResultOverviewPage')
    } catch (error) {
      if (error instanceof AppError) {
        this.exportHint = error.message
        logError('Export doc report failed', error.details ?? '', 'ResultOverviewPage')
      } else {
        this.exportHint = '导出报告失败，请稍后重试'
        logError('Export doc report failed', JSON.stringify(error), 'ResultOverviewPage')
      }
    } finally {
      this.isExportingReport = false
    }
  }

  async readParams(): Promise<RouteParams> {
    const routerParams = this.getUIContext().getRouter().getParams() as RouteParams
    const hasRouterTaskId = routerParams.taskId !== undefined && (routerParams.taskId ?? '').length > 0
    const hasRouterBaseUrl = routerParams.baseUrl !== undefined && (routerParams.baseUrl ?? '').length > 0
    if (hasRouterTaskId || hasRouterBaseUrl) {
      return routerParams
    }

    const hostContext = this.getHostContext()
    if (hostContext === undefined) {
      return routerParams
    }

    const pendingPayload = await this.continueService.consumePendingRoute(hostContext)
    if (pendingPayload === undefined) {
      return routerParams
    }
    return this.continueService.toRouteParams(pendingPayload)
  }

  getHostContext(): common.UIAbilityContext | undefined {
    const hostContext = this.getUIContext().getHostContext()
    if (hostContext === undefined) {
      return undefined
    }
    return hostContext as common.UIAbilityContext
  }

  async saveRecentContract(): Promise<void> {
    const hostContext = this.getHostContext()
    if (hostContext === undefined || this.currentResult === undefined) {
      return
    }

    const recentContract: Contract = {
      taskId: this.currentResult.taskId,
      contractName: this.currentResult.contractName,
      status: AnalyzeStatus.SUCCESS,
      createdAt: this.currentResult.generatedAt,
      baseUrl: this.resultVM.baseUrl
    }
    await this.cacheService.saveRecentContract(hostContext, recentContract)
    if (!this.isUsingDemoResult && this.resultVM.baseUrl.length > 0) {
      await new UserSettingsService().saveServiceBaseUrl(hostContext, this.resultVM.baseUrl)
    }
    await this.cardService.refreshRegisteredForms(hostContext)
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

  async activateContinuation(): Promise<void> {
    const hostContext = this.getHostContext()
    if (hostContext === undefined || this.currentResult === undefined) {
      return
    }

    const payload: ContinuePayload = this.continueService.buildResultPayload(
      this.currentResult.taskId,
      this.resultVM.baseUrl,
      this.currentResult.contractName,
      this.currentResult.generatedAt
    )
    await this.continueService.saveLastViewedResult(hostContext, payload)
    this.continueService.setMissionContinueActive(hostContext, true)
  }

  async deactivateContinuation(): Promise<void> {
    const hostContext = this.getHostContext()
    if (hostContext === undefined) {
      return
    }
    this.continueService.setMissionContinueActive(hostContext, false)
    await this.continueService.clearLastViewedResult(hostContext)
  }

  riskBarColor(level: RiskLevel): string {
    if (level === RiskLevel.RED) {
      return UiColors.DANGER
    }
    if (level === RiskLevel.YELLOW) {
      return UiColors.WARNING
    }
    return UiColors.SUCCESS
  }
}
