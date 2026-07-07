import { common } from '@kit.AbilityKit'
import { back, goClauseCompare, RouteParams } from '../app/AppRouter'
import { API_BASE_URL } from '../common/constants'
import { AppError } from '../common/errors'
import { logError } from '../common/logger'
import { EmptyState } from '../components/EmptyState'
import { RiskBadge } from '../components/RiskBadge'
import { SummaryCard } from '../components/SummaryCard'
import { AnalysisResult } from '../model/domain/AnalysisResult'
import { ClauseRisk } from '../model/domain/ClauseRisk'
import { Contract } from '../model/domain/Contract'
import { AnalyzeStatus } from '../model/enums/AnalyzeStatus'
import { RiskLevel } from '../model/enums/RiskLevel'
import { ResultVM } from '../model/viewmodel/ResultVM'
import { DTOMapper } from '../services/api/DTOMapper'
import { ContractApi } from '../services/api/ContractApi'
import { CacheService } from '../services/storage/CacheService'

@Entry
@Component
struct ResultOverviewPage {
  @State isLoading: boolean = true
  @State errorText: string = ''
  @State renderTick: number = 0
  @State currentResult?: AnalysisResult = undefined

  resultVM: ResultVM = new ResultVM()
  cacheService: CacheService = new CacheService()

  aboutToAppear(): void {
    this.loadResult()
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Row({ space: 12 }) {
          Button('返回')
            .type(ButtonType.Capsule)
            .onClick(() => {
              back(this.getUIContext())
            })
          Text('结果总览')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
        }

        if (this.isLoading) {
          Text('正在加载分析结果...')
            .fontSize(14)
            .fontColor('#666666')
        }

        if (this.errorText.length > 0) {
          Column({ space: 12 }) {
            EmptyState({
              title: '结果加载异常',
              description: this.errorText,
              hint: this.currentResult !== undefined ? '当前已回退为临时 Mock 数据；可重试拉取真实结果，或继续查看演示内容。' : '请检查服务状态后重试加载结果。'
            })
            Row({ space: 8 }) {
              Button('重试加载')
                .type(ButtonType.Capsule)
                .onClick(() => {
                  this.retryLoadResult()
                })
            }
          }
          .width('100%')
        }

        if (this.currentResult !== undefined) {
          SummaryCard({
            contractName: this.currentResult.contractName,
            overallSummary: this.currentResult.overallSummary,
            generatedAt: this.currentResult.generatedAt,
            checklist: this.currentResult.signBeforeChecklist,
            redCount: this.currentResult.riskStats.red,
            yellowCount: this.currentResult.riskStats.yellow,
            greenCount: this.currentResult.riskStats.green
          })

          Column({ space: 8 }) {
            Text('风险统计')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
            Row({ space: 8 }) {
              RiskBadge({ riskLevel: RiskLevel.RED, count: this.currentResult.riskStats.red })
              RiskBadge({ riskLevel: RiskLevel.YELLOW, count: this.currentResult.riskStats.yellow })
              RiskBadge({ riskLevel: RiskLevel.GREEN, count: this.currentResult.riskStats.green })
            }
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')

          Column({ space: 12 }) {
            Text('风险条目')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
            ForEach(this.currentResult.clauses, (clause: ClauseRisk) => {
              Button() {
                Column({ space: 8 }) {
                  Row({ space: 8 }) {
                    Text(clause.title)
                      .fontSize(16)
                      .fontWeight(FontWeight.Medium)
                    RiskBadge({ riskLevel: clause.riskLevel })
                  }
                  .width('100%')
                  .justifyContent(FlexAlign.SpaceBetween)

                  Text(clause.riskReason)
                    .fontSize(13)
                    .fontColor('#666666')
                    .maxLines(2)

                  Text('点击查看原文与白话解释')
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
              .backgroundColor('#FFFFFF')
              .borderRadius(16)
              .onClick(() => {
                this.openClauseCompare(clause.clauseId)
              })
            })
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
        }
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .padding(24)
    }
    .width('100%')
    .height('100%')
  }

  async loadResult(): Promise<void> {
    const params = this.readParams()
    const taskId: string = params.taskId ?? ''
    const baseUrl: string = params.baseUrl ?? API_BASE_URL
    const mapper = new DTOMapper()
    this.resultVM.setRouteContext(taskId, baseUrl)
    this.resultVM.setLoading(true)
    this.resultVM.setError('')
    this.isLoading = true
    this.errorText = ''

    try {
      if (taskId.length === 0 || ContractApi.isMockTask(taskId)) {
        const mockDto = ContractApi.getMockAnalysisResult(taskId)
        const mockResult = mapper.mapAnalysisResult(mockDto)
        this.currentResult = mockResult
        this.resultVM.setResult(mockResult)
      } else {
        const api = new ContractApi(baseUrl)
        const dto = await api.getAnalysisResult(taskId)
        const mappedResult = mapper.mapAnalysisResult(dto)
        this.currentResult = mappedResult
        this.resultVM.setResult(mappedResult)
      }
    } catch (error) {
      const mockDto = ContractApi.getMockAnalysisResult(taskId)
      const mockResult = mapper.mapAnalysisResult(mockDto)
      this.currentResult = mockResult
      this.resultVM.setResult(mockResult)
      if (error instanceof AppError) {
        this.errorText = `结果获取失败，已回退到 Mock 数据：${error.message}`
        this.resultVM.setError(this.errorText)
        logError('Result overview load failed', error.details ?? '', 'ResultOverviewPage')
      } else {
        this.errorText = '结果获取失败，已回退到 Mock 数据'
        this.resultVM.setError(this.errorText)
        logError('Result overview load failed', JSON.stringify(error), 'ResultOverviewPage')
      }
    } finally {
      await this.saveRecentContract()
      this.isLoading = false
      this.resultVM.setLoading(false)
      this.renderTick = this.renderTick + 1
    }
  }

  retryLoadResult(): void {
    this.currentResult = undefined
    this.loadResult()
  }

  async openClauseCompare(clauseId: string): Promise<void> {
    const params: RouteParams = new RouteParams()
    params.taskId = this.resultVM.taskId
    params.baseUrl = this.resultVM.baseUrl
    params.clauseId = clauseId
    await goClauseCompare(this.getUIContext(), params)
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
  }

}
