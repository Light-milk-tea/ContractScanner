import { AnalyzeContractRequest } from '../../schemas/request.schema'

export interface OcrExtractionResult {
  text: string
  source: string
}

function buildFallbackContractText(request: AnalyzeContractRequest): string {
  const businessContext = request.businessTag?.trim().length ? request.businessTag : '通用民商事合同'

  return [
    `合同名称：${request.fileName}`,
    `文件类型：${request.fileType}`,
    `业务场景：${businessContext}`,
    '合同节选：',
    '1. 乙方应在签署后 3 日内支付首期款项，逾期每日按未付款项的 0.5% 支付违约金。',
    '2. 若任一方提前解除合同，需提前 30 日书面通知；甲方可单方决定是否退还保证金。',
    '3. 因履行合同发生争议，双方应先协商，协商不成可向合同签订地人民法院起诉。',
    `原始文件位置：${request.fileUri}`
  ].join('\n')
}

export function extractContractText(request: AnalyzeContractRequest): OcrExtractionResult {
  const trimmedUri = request.fileUri.trim()

  if (trimmedUri.indexOf('\n') >= 0 && trimmedUri.length > 40) {
    return {
      text: trimmedUri,
      source: 'inline-uri'
    }
  }

  const inlinePrefix = 'inline://'
  if (trimmedUri.startsWith(inlinePrefix)) {
    return {
      text: trimmedUri.substring(inlinePrefix.length),
      source: 'inline-prefix'
    }
  }

  return {
    text: buildFallbackContractText(request),
    source: 'fallback-template'
  }
}

export function describeOcrStage(): string {
  return 'OCR stage extracts inline text or falls back to contract template for B17'
}
