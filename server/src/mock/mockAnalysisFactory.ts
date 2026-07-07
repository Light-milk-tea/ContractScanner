import { AnalyzeContractRequest } from '../schemas/request.schema'
import { AnalysisResultResponse } from '../schemas/response.schema'

function contractNameFrom(request: AnalyzeContractRequest): string {
  return request.fileName.trim().length > 0 ? request.fileName : '未命名合同.pdf'
}

export function buildMockAnalysisResult(taskId: string, request: AnalyzeContractRequest): AnalysisResultResponse {
  const contractName = contractNameFrom(request)
  return {
    taskId,
    contractName,
    overallSummary: '该合同已由服务端骨架完成模拟解析，当前结果用于验证客户端与服务端接口联调，后续将在 B17 接入真实 OCR 与大模型分析。',
    signBeforeChecklist: [
      '确认租赁期限、付款周期与违约责任是否一致',
      '确认押金退还条件与修缮责任是否明确',
      '确认是否存在自动续约、单方解释权等条款'
    ],
    riskStats: {
      red: 1,
      yellow: 1,
      green: 1
    },
    clauses: [
      {
        clauseId: 'server-clause-001',
        title: '押金退还条件',
        originalText: '承租人退租后，出租人有权在九十个工作日后视房屋情况决定是否退还押金。',
        plainText: '押金退还时间过长，且是否退还由出租方单方判断，对你不利。',
        riskLevel: 'RED',
        riskReason: '退还条件与时间不明确，出租方自由裁量空间过大。',
        suggestion: '建议补充明确验房标准，并将押金退还期限缩短为 7-15 个工作日。',
        anchors: {
          page: 2,
          paragraph: 3
        }
      },
      {
        clauseId: 'server-clause-002',
        title: '违约责任',
        originalText: '任何一方违约，守约方有权要求赔偿全部损失。',
        plainText: '条款有基础保护作用，但损失范围没有细化，执行时可能产生争议。',
        riskLevel: 'YELLOW',
        riskReason: '违约赔偿范围没有约定上限或认定标准。',
        suggestion: '建议补充直接损失、间接损失及举证责任的边界。',
        anchors: {
          page: 4,
          paragraph: 2
        }
      },
      {
        clauseId: 'server-clause-003',
        title: '争议解决',
        originalText: '双方因履行本合同发生争议，可向合同签订地人民法院提起诉讼。',
        plainText: '争议解决路径比较清晰，属于较为常规的保护性条款。',
        riskLevel: 'GREEN',
        riskReason: '争议处理方式明确，便于后续维权。',
        suggestion: '可结合实际业务补充仲裁或调解优先机制。',
        anchors: {
          page: 6,
          paragraph: 1
        }
      }
    ],
    generatedAt: new Date().toISOString()
  }
}
