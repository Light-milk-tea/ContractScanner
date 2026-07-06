import { AppError, ErrorCode } from '../../common/errors'
import { AnalysisResult, RiskStats } from '../../model/domain/AnalysisResult'
import { ClauseAnchor, ClauseRisk } from '../../model/domain/ClauseRisk'
import { RiskLevel } from '../../model/enums/RiskLevel'

import { AnalysisResultDTO, ClauseAnchorDTO, ClauseRiskDTO, RiskStatsDTO } from './ContractApi'

export class DTOMapper {
  mapAnalysisResult(dto: AnalysisResultDTO): AnalysisResult {
    return {
      taskId: dto.taskId,
      contractName: dto.contractName,
      overallSummary: dto.overallSummary,
      signBeforeChecklist: dto.signBeforeChecklist ?? [],
      riskStats: this.mapRiskStats(dto.riskStats),
      clauses: this.mapClauses(dto.clauses),
      generatedAt: dto.generatedAt
    }
  }

  mapClauseRisk(dto: ClauseRiskDTO): ClauseRisk {
    return {
      clauseId: dto.clauseId,
      title: dto.title,
      originalText: dto.originalText,
      plainText: dto.plainText,
      riskLevel: this.mapRiskLevel(dto.riskLevel),
      riskReason: dto.riskReason,
      suggestion: dto.suggestion,
      anchors: this.mapClauseAnchor(dto.anchors)
    }
  }

  mapRiskLevel(raw: string): RiskLevel {
    if (raw === RiskLevel.RED) {
      return RiskLevel.RED
    }
    if (raw === RiskLevel.YELLOW) {
      return RiskLevel.YELLOW
    }
    if (raw === RiskLevel.GREEN) {
      return RiskLevel.GREEN
    }
    throw new AppError(ErrorCode.RESULT_001, '风险等级值不合法', raw)
  }

  private mapRiskStats(dto?: RiskStatsDTO): RiskStats {
    if (dto === undefined) {
      return { red: 0, yellow: 0, green: 0 }
    }

    return {
      red: dto.red,
      yellow: dto.yellow,
      green: dto.green
    }
  }

  private mapClauses(clauses?: ClauseRiskDTO[]): ClauseRisk[] {
    const input: ClauseRiskDTO[] = clauses ?? []
    const output: ClauseRisk[] = []
    for (let i: number = 0; i < input.length; i++) {
      output.push(this.mapClauseRisk(input[i]))
    }
    return output
  }

  private mapClauseAnchor(dto?: ClauseAnchorDTO): ClauseAnchor {
    if (dto === undefined) {
      return {}
    }

    return {
      page: dto.page,
      paragraph: dto.paragraph
    }
  }
}

