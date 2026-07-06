import { Contract } from '../domain/Contract'

export class HomeVM {
  recentContracts: Contract[] = []

  setRecentContracts(contracts: Contract[]): void {
    this.recentContracts = contracts
  }
}
