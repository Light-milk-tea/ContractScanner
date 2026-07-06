export enum ErrorCode {
  IMPORT_001 = 'IMPORT_001',
  OCR_001 = 'OCR_001',
  LLM_001 = 'LLM_001',
  RESULT_001 = 'RESULT_001',
  SYS_500 = 'SYS_500'
}

export class AppError extends Error {
  code: string
  details?: string

  constructor(code: string, message: string, details?: string) {
    super(message)
    this.code = code
    this.details = details
  }
}
