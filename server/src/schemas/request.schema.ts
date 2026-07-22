export interface AnalyzeContractRequest {
  fileName: string
  fileType: string
  fileUri: string
  businessTag?: string
  apiKey?: string
}

export interface AnalyzeContractRequestValidationResult {
  isValid: boolean
  message?: string
}

export function validateAnalyzeContractRequest(payload: Partial<AnalyzeContractRequest>): AnalyzeContractRequestValidationResult {
  if ((payload.fileName ?? '').trim().length === 0) {
    return { isValid: false, message: 'fileName is required' }
  }
  if ((payload.fileType ?? '').trim().length === 0) {
    return { isValid: false, message: 'fileType is required' }
  }
  if ((payload.fileUri ?? '').trim().length === 0) {
    return { isValid: false, message: 'fileUri is required' }
  }
  return { isValid: true }
}

export type ChatMessageRole = 'user' | 'assistant'

export interface ChatHistoryMessage {
  role: ChatMessageRole
  content: string
}

export interface ChatQuestionRequest {
  question: string
  history?: ChatHistoryMessage[]
  apiKey?: string
}

export interface ChatQuestionRequestValidationResult {
  isValid: boolean
  message?: string
}

export function validateChatQuestionRequest(payload: Partial<ChatQuestionRequest>): ChatQuestionRequestValidationResult {
  if ((payload.question ?? '').trim().length === 0) {
    return { isValid: false, message: 'question is required' }
  }
  if (payload.history !== undefined && !Array.isArray(payload.history)) {
    return { isValid: false, message: 'history must be an array' }
  }
  if (Array.isArray(payload.history)) {
    for (let i: number = 0; i < payload.history.length; i++) {
      const item = payload.history[i]
      if (item === undefined || item === null || typeof item !== 'object') {
        return { isValid: false, message: `history[${i}] is invalid` }
      }
      const role = (item as ChatHistoryMessage).role
      const content = (item as ChatHistoryMessage).content
      if (role !== 'user' && role !== 'assistant') {
        return { isValid: false, message: `history[${i}].role must be user or assistant` }
      }
      if (typeof content !== 'string' || content.trim().length === 0) {
        return { isValid: false, message: `history[${i}].content is required` }
      }
    }
  }
  return { isValid: true }
}
