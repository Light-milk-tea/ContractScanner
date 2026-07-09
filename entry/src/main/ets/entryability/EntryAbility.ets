import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit'
import { window } from '@kit.ArkUI'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { RoutePath } from '../common/constants'
import { ContinuePayload, ContinueService } from '../services/ability/ContinueService'

const DOMAIN = 0x0000
const TAG = 'EntryAbility'

export default class EntryAbility extends UIAbility {
  currentWindowStage?: window.WindowStage = undefined
  pendingPageUrl: string = RoutePath.HOME
  continueService: ContinueService = new ContinueService()

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET)
      this.context.setRestoreEnabled(true)
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to initialize ability. Cause: %{public}s', JSON.stringify(err))
    }
    this.resolveLaunchTarget(want, launchParam)
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onCreate')
  }

  async onContinue(wantParam: Record<string, Object>): Promise<AbilityConstant.OnContinueResult> {
    const payload = await this.continueService.loadLastViewedResult(this.context)
    if (payload !== undefined) {
      this.continueService.fillWantParams(wantParam, payload)
    }
    return AbilityConstant.OnContinueResult.AGREE
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.resolveLaunchTarget(want, launchParam)
    if (this.currentWindowStage !== undefined) {
      this.loadLaunchPage(this.currentWindowStage)
    }
  }

  onDestroy(): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onDestroy')
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onWindowStageCreate')
    this.currentWindowStage = windowStage
    this.loadLaunchPage(windowStage)
  }

  onWindowStageDestroy(): void {
    this.currentWindowStage = undefined
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onWindowStageDestroy')
  }

  onForeground(): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onForeground')
  }

  onBackground(): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onBackground')
  }

  resolveLaunchTarget(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    const payload = this.continueService.parseWantPayload(want)
    if (payload === undefined) {
      this.pendingPageUrl = RoutePath.HOME
      return
    }

    const normalizedPayload = this.normalizePayload(payload, launchParam)
    this.pendingPageUrl = normalizedPayload.pageUrl
    this.continueService.savePendingRoute(this.context, normalizedPayload).catch((error: Object) => {
      hilog.error(DOMAIN, TAG, 'Failed to save pending route. Cause: %{public}s', JSON.stringify(error))
    })
  }

  normalizePayload(payload: ContinuePayload, launchParam: AbilityConstant.LaunchParam): ContinuePayload {
    const normalizedPayload: ContinuePayload = {
      pageUrl: payload.pageUrl.length > 0 ? payload.pageUrl : RoutePath.HOME,
      taskId: payload.taskId,
      baseUrl: payload.baseUrl,
      contractName: payload.contractName,
      generatedAt: payload.generatedAt,
      source: payload.source.length > 0 ? payload.source : this.launchSource(launchParam)
    }
    return normalizedPayload
  }

  launchSource(launchParam: AbilityConstant.LaunchParam): string {
    if (launchParam.launchReason === AbilityConstant.LaunchReason.CONTINUATION) {
      return 'continuation'
    }
    return 'ability'
  }

  loadLaunchPage(windowStage: window.WindowStage): void {
    windowStage.loadContent(this.pendingPageUrl, (err) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, 'Failed to load the content. Cause: %{public}s', JSON.stringify(err))
        return
      }
      hilog.info(DOMAIN, TAG, 'Succeeded in loading content: %{public}s', this.pendingPageUrl)
    })
  }
}
