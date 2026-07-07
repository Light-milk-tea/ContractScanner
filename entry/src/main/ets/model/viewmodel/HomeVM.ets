import { Contract } from '../domain/Contract'

export class HomeVM {
  recentContracts: Contract[] = []

  setRecentContracts(contracts: Contract[]): void {
    this.recentContracts = contracts
  }

  clearRecentContracts(): void {
    this.recentContracts = []
  }

  hasRecentContracts(): boolean {
    return this.recentContracts.length > 0
  }
}
