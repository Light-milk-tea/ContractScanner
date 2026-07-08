export function cleanContractText(rawText: string): string {
  const compactText = rawText
    .replace(/\r/g, '\n')
    .replace(/\n{3,}/g, '\n\n')
    .replace(/[ \t]{2,}/g, ' ')
    .trim()

  return compactText
}

export function describeCleanerStage(): string {
  return 'Cleaner stage normalizes OCR text for B17'
}
