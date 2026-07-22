/** 扫描/识文结果的进程内暂存，避免超长正文写入 Preferences */
export interface PendingScanResult {
  fileName: string
  textContent: string
}

class PendingScanStoreImpl {
  private pending?: PendingScanResult = undefined

  setPending(result: PendingScanResult): void {
    this.pending = result
  }

  consumePending(): PendingScanResult | undefined {
    const result = this.pending
    this.pending = undefined
    return result
  }

  clear(): void {
    this.pending = undefined
  }
}

export const PendingScanStore: PendingScanStoreImpl = new PendingScanStoreImpl()
