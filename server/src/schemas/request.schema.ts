export interface AnalyzeContractRequest {
  fileName: string
  fileType: string
  fileUri: string
  businessTag?: string
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
