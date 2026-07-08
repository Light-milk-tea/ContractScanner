import { back, RouteParams } from '../app/AppRouter'
import { API_BASE_URL } from '../common/constants'
import { AppError } from '../common/errors'
import { logError } from '../common/logger'
import { ClauseBlock } from '../components/ClauseBlock'
import { AnalysisResult } from '../model/domain/AnalysisResult'
import { ClauseRisk } from '../model/domain/ClauseRisk'
import { ResultVM } from '../model/viewmodel/ResultVM'
import { DTOMapper } from '../services/api/DTOMapper'
import { ContractApi } from '../services/api/ContractApi'

@Entry
@Component
struct ClauseComparePage {
  @State isLoading: boolean = true
  @State errorText: string = ''
  @State renderTick: number = 0
  @State isUsingDemoResult: boolean = false
  @State currentResult?: AnalysisResult = undefined
  @State currentClause?: ClauseRisk = undefined

  resultVM: ResultVM = new ResultVM()

  aboutToAppear(): void {
    this.loadClauseDetail()
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Row({ space: 12 }) {
          Button('返回结果页')
            .type(ButtonType.Capsule)
            .onClick(() => {
              back(this.getUIContext())
            })
          Text('条款对照阅读')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
        }

        if (this.isLoading) {
          Text('正在加载条款详情...')
            .fontSize(14)
            .fontColor('#666666')
        }

        if (this.errorText.length > 0) {
          Column({ space: 8 }) {
            Text(this.errorText)
              .fontSize(13)
              .fontColor('#D64B4B')
            if (!this.isUsingDemoResult) {
              Button('查看演示条款')
                .type(ButtonType.Capsule)
                .backgroundColor('#DDE3EE')
                .fontColor('#333333')
                .onClick(() => {
                  this.openDemoClause()
                })
            }
          }
          .alignItems(HorizontalAlign.Start)
        }

        if (this.currentClause !== undefined) {
          ClauseBlock({
            title: this.currentClause.title,
            originalText: this.currentClause.originalText,
            plainText: this.currentClause.plainText,
            riskReason: this.currentClause.riskReason,
            suggestion: this.currentClause.suggestion ?? '',
            anchorText: this.buildAnchorText(this.currentClause),
            riskLevel: this.currentClause.riskLevel
          })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .padding(24)
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
  }
}
