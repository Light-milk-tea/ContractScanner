export function splitClauses(contractText: string): string[] {
  const clauses = contractText
    .split(/\n+/)
    .map((item: string) => item.trim())
    .filter((item: string) => item.length > 0)

  const selectedClauses: string[] = []
  for (let i: number = 0; i < clauses.length; i++) {
    if (selectedClauses.length >= 8) {
      break
    }
    selectedClauses.push(clauses[i])
  }

  return selectedClauses
}

export function describeClauseSplitterStage(): string {
  return 'Clause splitter prepares prompt-ready contract chunks for B17'
}
