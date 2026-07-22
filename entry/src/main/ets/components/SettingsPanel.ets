import { common } from '@kit.AbilityKit'
import {
  API_BASE_URL,
  DEV_HOST_LAN_IP,
  isEmulatorRuntime,
  isLoopbackBaseUrl,
  resolveDefaultApiBaseUrl
} from '../common/constants'
import { UiColors, UiFont, UiRadius, UiSpace } from '../common/ui/DesignTokens'
import { GhostButton, PrimaryButton, SegmentChip } from './ActionButtons'
import { SectionHeader } from './SectionHeader'
import { SurfaceCard } from './SurfaceCard'
import { DemoFaultMode } from '../model/enums/DemoMode'
import { PrivacyGuardService } from '../services/ability/PrivacyGuardService'
import { ServiceHealthProbe } from '../services/api/ServiceHealthProbe'
import { UserSettingsService } from '../services/storage/UserSettingsService'

const API_KEY_MIN_LENGTH: number = 16
const API_KEY_MAX_LENGTH: number = 128
const API_KEY_PATTERN: RegExp = /^[A-Za-z0-9._-]+$/

@Component
export struct SettingsPanel {
  @Prop bottomInset: number = 0
  @Prop showHeader: boolean = true

  @State serviceBaseUrlInput: string = API_BASE_URL
  @State serviceBaseUrlStatusText: string = ''
  @State serviceBaseUrlStatusColor: string = UiColors.BRAND
  @State apiKeyInput: string = ''
  @State isApiKeyVisible: boolean = false
  @State statusText: string = ''
  @State statusColor: string = UiColors.BRAND
  @State hasStoredApiKey: boolean = false
  @State privacyGuardEnabled: boolean = false
  @State privacyGuardHint: string = ''
  @State demoFaultMode: DemoFaultMode = DemoFaultMode.NONE
  @State demoFaultHint: string = ''
  @State isProbingService: boolean = false

  userSettingsService: UserSettingsService = new UserSettingsService()
  privacyGuardService: PrivacyGuardService = new PrivacyGuardService()
  serviceHealthProbe: ServiceHealthProbe = new ServiceHealthProbe()

  aboutToAppear(): void {
    this.loadServiceBaseUrl()
    this.loadApiKey()
    this.loadPrivacyGuardSetting()
    this.loadDemoFaultMode()
  }

  build() {
    Scroll() {
      Column({ space: UiSpace.LG }) {
          if (this.showHeader) {
            Text('用户设置')
              .fontSize(UiFont.PAGE_TITLE)
              .fontWeight(FontWeight.Bold)
              .fontColor(UiColors.TEXT_PRIMARY)
              .width('100%')
            Text('服务联调、隐私防窥与答辩演示模式。')
              .fontSize(UiFont.BODY_SMALL)
              .fontColor(UiColors.TEXT_SECONDARY)
              .width('100%')
          }

          SurfaceCard({ tone: 'soft' }) {
            Column({ space: UiSpace.MD }) {
              SectionHeader({
                title: '服务地址',
                description: isEmulatorRuntime()
                  ? `模拟器优先走电脑局域网 IP（当前 ${DEV_HOST_LAN_IP}）。`
                  : '真机联调请填写电脑局域网 IP。',
                alignCenter: false
              })

              TextInput({
                text: this.serviceBaseUrlInput,
                placeholder: `例如：http://${DEV_HOST_LAN_IP}:3000`
              })
                .width('100%')
                .height(44)
                .backgroundColor(UiColors.SURFACE_MUTED)
                .borderRadius(UiRadius.MEDIUM)
                .padding({ left: UiSpace.MD, right: UiSpace.MD })
                .onChange((value: string) => {
                  this.serviceBaseUrlInput = value
                  this.serviceBaseUrlStatusText = ''
                })

              if (!isEmulatorRuntime() && isLoopbackBaseUrl(this.serviceBaseUrlInput)) {
                Text('当前是本机回环地址；真机请改成局域网 IP。')
                  .fontSize(UiFont.CAPTION)
                  .fontColor(UiColors.DANGER)
              }

              if (isEmulatorRuntime()) {
                Text('若连不上：把模拟器代理设为「无代理」。代理下 HTTP 非 80 端口常会失败。')
                  .fontSize(UiFont.CAPTION)
                  .fontColor(UiColors.WARNING)
              }

              Flex({
                wrap: FlexWrap.Wrap,
                justifyContent: FlexAlign.Start,
                alignItems: ItemAlign.Center
              }) {
                Row() {
                  PrimaryButton({
                    label: '保存地址',
                    onTap: () => {
                      this.saveServiceBaseUrl()
                    }
                  })
                }
                .margin({ right: UiSpace.SM, bottom: UiSpace.SM })

                Row() {
                  GhostButton({
                    label: this.isProbingService ? '检测中...' : '检测连通',
                    isEnabled: !this.isProbingService,
                    onTap: () => {
                      this.probeServiceBaseUrl()
                    }
                  })
                }
                .margin({ right: UiSpace.SM, bottom: UiSpace.SM })

                Row() {
                  GhostButton({
                    label: '恢复默认',
                    onTap: () => {
                      this.clearServiceBaseUrl()
                    }
                  })
                }
                .margin({ right: UiSpace.SM, bottom: UiSpace.SM })
              }
              .width('100%')

              Text(this.serviceBaseUrlStatusText.length > 0
                ? this.serviceBaseUrlStatusText
                : (isEmulatorRuntime()
                  ? `默认优先 ${DEV_HOST_LAN_IP}:3000，并自动回退探测 10.0.2.2。`
                  : '默认地址仅适用于本机调试。'))
                .fontSize(UiFont.CAPTION)
                .fontColor(this.serviceBaseUrlStatusText.length > 0 ? this.serviceBaseUrlStatusColor : UiColors.TEXT_SECONDARY)
            }
            .alignItems(HorizontalAlign.Start)
            .width('100%')
          }

          SurfaceCard({ tone: 'soft' }) {
            Column({ space: UiSpace.MD }) {
              SectionHeader({
                title: '模型 API Key',
                description: '密钥仅保存在当前设备本地。',
                alignCenter: false
              })

              Row({ space: UiSpace.SM }) {
                TextInput({
                  text: this.apiKeyInput,
                  placeholder: '请输入 API Key'
                })
                  .type(this.isApiKeyVisible ? InputType.Normal : InputType.Password)
                  .maxLength(API_KEY_MAX_LENGTH)
                  .layoutWeight(1)
                  .height(44)
                  .backgroundColor(UiColors.SURFACE_MUTED)
                  .borderRadius(UiRadius.MEDIUM)
                  .padding({ left: UiSpace.MD, right: UiSpace.MD })
                  .onChange((value: string) => {
                    this.apiKeyInput = value
                    this.statusText = ''
                  })

                GhostButton({
                  label: this.isApiKeyVisible ? '隐藏' : '显示',
                  onTap: () => {
                    this.isApiKeyVisible = !this.isApiKeyVisible
                  }
                })
              }
              .width('100%')

              Text(this.validationMessage())
                .fontSize(UiFont.CAPTION)
                .fontColor(this.isApiKeyFormatValid() ? UiColors.SUCCESS : UiColors.DANGER)

              Row({ space: UiSpace.SM }) {
                PrimaryButton({
                  label: '保存到本地',
                  isEnabled: this.canSaveApiKey(),
                  onTap: () => {
                    this.saveApiKey()
                  }
                })
                GhostButton({
                  label: '清空',
                  isEnabled: this.hasStoredApiKey || this.apiKeyInput.length > 0,
                  onTap: () => {
                    this.clearApiKey()
                  }
                })
              }

              if (this.hasStoredApiKey) {
                Text(this.savedApiKeySummary())
                  .fontSize(UiFont.BODY_SMALL)
                  .fontColor(UiColors.TEXT_SECONDARY)
              }

              if (this.statusText.length > 0) {
                Text(this.statusText)
                  .fontSize(UiFont.BODY_SMALL)
                  .fontColor(this.statusColor)
              }
            }
            .alignItems(HorizontalAlign.Start)
            .width('100%')
          }

          SurfaceCard({ tone: 'soft' }) {
            Column({ space: UiSpace.MD }) {
              SectionHeader({
                title: '系统控制',
                description: '隐私保护与答辩异常演示。',
                alignCenter: false
              })

              Row() {
                Column({ space: UiSpace.XS }) {
                  Text('隐私防窥')
                    .fontSize(UiFont.BODY)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(UiColors.TEXT_PRIMARY)
                  Text('结果页与条款页启用系统隐私窗口。')
                    .fontSize(UiFont.BODY_SMALL)
                    .fontColor(UiColors.TEXT_SECONDARY)
                  Text(this.privacyGuardEnabled ? '当前：已开启' : '当前：已关闭')
                    .fontSize(UiFont.CAPTION)
                    .fontColor(this.privacyGuardEnabled ? UiColors.SUCCESS : UiColors.TEXT_TERTIARY)
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                if (this.privacyGuardEnabled) {
                  GhostButton({
                    label: '关闭',
                    onTap: () => {
                      this.togglePrivacyGuard()
                    }
                  })
                } else {
                  PrimaryButton({
                    label: '开启',
                    onTap: () => {
                      this.togglePrivacyGuard()
                    }
                  })
                }
              }
              .width('100%')
              .alignItems(VerticalAlign.Center)
              .padding({ top: UiSpace.SM, bottom: UiSpace.SM })

              this.buildSettingHint('日志调试', '后续将补齐日志开关与调试信息。')

              Column({ space: UiSpace.SM }) {
                Text('答辩演示模式')
                  .fontSize(UiFont.BODY)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(UiColors.TEXT_PRIMARY)
                Text('主动触发弱网、超时、服务失败或降级展示。')
                  .fontSize(UiFont.BODY_SMALL)
                  .fontColor(UiColors.TEXT_SECONDARY)

                Row({ space: UiSpace.SM }) {
                  SegmentChip({
                    label: '正常',
                    selected: this.demoFaultMode === DemoFaultMode.NONE,
                    onTap: () => {
                      this.saveDemoFaultMode(DemoFaultMode.NONE)
                    }
                  })
                  SegmentChip({
                    label: '弱网',
                    selected: this.demoFaultMode === DemoFaultMode.WEAK_NETWORK,
                    onTap: () => {
                      this.saveDemoFaultMode(DemoFaultMode.WEAK_NETWORK)
                    }
                  })
                  SegmentChip({
                    label: '超时',
                    selected: this.demoFaultMode === DemoFaultMode.TIMEOUT,
                    onTap: () => {
                      this.saveDemoFaultMode(DemoFaultMode.TIMEOUT)
                    }
                  })
                }

                Row({ space: UiSpace.SM }) {
                  SegmentChip({
                    label: '服务失败',
                    selected: this.demoFaultMode === DemoFaultMode.SERVICE_ERROR,
                    onTap: () => {
                      this.saveDemoFaultMode(DemoFaultMode.SERVICE_ERROR)
                    }
                  })
                  SegmentChip({
                    label: '降级展示',
                    selected: this.demoFaultMode === DemoFaultMode.DEGRADE_TO_DEMO,
                    onTap: () => {
                      this.saveDemoFaultMode(DemoFaultMode.DEGRADE_TO_DEMO)
                    }
                  })
                }

                Text(`当前模式：${this.demoFaultModeLabel(this.demoFaultMode)}`)
                  .fontSize(UiFont.CAPTION)
                  .fontColor(this.demoFaultMode === DemoFaultMode.NONE ? UiColors.TEXT_TERTIARY : UiColors.SUCCESS)

                if (this.demoFaultHint.length > 0) {
                  Text(this.demoFaultHint)
                    .fontSize(UiFont.CAPTION)
                    .fontColor(UiColors.BRAND)
                }
              }
              .alignItems(HorizontalAlign.Start)
              .width('100%')
              .padding({ top: UiSpace.SM, bottom: UiSpace.SM })
            }
            .alignItems(HorizontalAlign.Start)
            .width('100%')
          }
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding({
          left: UiSpace.PAGE_HORIZONTAL,
          right: UiSpace.PAGE_HORIZONTAL,
          top: UiSpace.PAGE_VERTICAL,
          bottom: UiSpace.PAGE_VERTICAL + this.bottomInset
        })
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
    .align(Alignment.Top)
    .backgroundColor(UiColors.PAGE_BACKGROUND)
  }

  @Builder
  buildSettingHint(title: string, description: string) {
    Row() {
      Column({ space: 4 }) {
        Text(title)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
        Text(description)
          .fontSize(13)
          .fontColor(UiColors.TEXT_SECONDARY)
      }
      .alignItems(HorizontalAlign.Start)

      Text('规划中')
        .fontSize(12)
        .fontColor(UiColors.BRAND)
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
    .padding({ top: 8, bottom: 8 })
  }

  @Builder
  buildDemoModeButton(mode: DemoFaultMode, label: string) {
    Button(label)
      .type(ButtonType.Normal)
      .height(40)
      .borderRadius(UiRadius.MEDIUM)
      .backgroundColor(this.demoFaultMode === mode ? UiColors.BRAND : UiColors.SURFACE_MUTED)
      .fontColor(this.demoFaultMode === mode ? UiColors.TEXT_ON_BRAND : UiColors.TEXT_PRIMARY)
      .border({
        width: 1,
        color: this.demoFaultMode === mode ? UiColors.BRAND : UiColors.BORDER_SOFT
      })
      .onClick(() => {
        this.saveDemoFaultMode(mode)
      })
  }

  getHostContext(): common.UIAbilityContext | undefined {
    const hostContext = this.getUIContext().getHostContext()
    if (hostContext === undefined) {
      return undefined
    }
    return hostContext as common.UIAbilityContext
  }

  async loadServiceBaseUrl(): Promise<void> {
    const hostContext = this.getHostContext()
    if (hostContext === undefined) {
      this.serviceBaseUrlStatusText = '当前页面上下文不可用，暂时无法读取服务地址配置'
      this.serviceBaseUrlStatusColor = UiColors.DANGER
      return
    }

    const defaultBaseUrl = resolveDefaultApiBaseUrl()
    const savedBaseUrl = await this.userSettingsService.loadServiceBaseUrl(hostContext, defaultBaseUrl)
    this.serviceBaseUrlInput = savedBaseUrl
    if (savedBaseUrl === defaultBaseUrl) {
      this.serviceBaseUrlStatusText = isEmulatorRuntime()
        ? `当前使用模拟器自动联网地址（${DEV_HOST_LAN_IP}:3000）。`
        : '当前使用默认服务地址。'
      this.serviceBaseUrlStatusColor = UiColors.BRAND
      return
    }
    this.serviceBaseUrlStatusText = '已读取本地保存的服务地址。'
    this.serviceBaseUrlStatusColor = UiColors.SUCCESS
  }

  async loadApiKey(): Promise<void> {
    const hostContext = this.getHostContext()
    if (hostContext === undefined) {
      this.statusText = '当前页面上下文不可用，暂时无法读取本地配置'
      this.statusColor = UiColors.DANGER
      return
    }

    const savedApiKey = await this.userSettingsService.loadApiKey(hostContext)
    this.apiKeyInput = savedApiKey
    this.hasStoredApiKey = savedApiKey.length > 0
    this.statusText = savedApiKey.length > 0 ? '已读取本地保存的 API Key，可直接修改后重新保存。' : ''
    this.statusColor = UiColors.BRAND
  }

  async loadPrivacyGuardSetting(): Promise<void> {
    const hostContext = this.getHostContext()
    if (hostContext === undefined) {
      this.privacyGuardHint = '当前页面上下文不可用，暂时无法读取隐私防窥配置'
      return
    }

    this.privacyGuardEnabled = await this.privacyGuardService.loadEnabled(hostContext)
    this.privacyGuardHint = this.privacyGuardEnabled ? '结果页和条款对照页会在进入时自动启用系统隐私窗口。' : ''
  }

  async loadDemoFaultMode(): Promise<void> {
    const hostContext = this.getHostContext()
    if (hostContext === undefined) {
      this.demoFaultHint = '当前页面上下文不可用，暂时无法读取演示模式配置'
      return
    }

    this.demoFaultMode = await this.userSettingsService.loadDemoFaultMode(hostContext)
    this.demoFaultHint = this.demoFaultModeHint(this.demoFaultMode)
  }

  validationMessage(): string {
    if (this.apiKeyInput.length === 0) {
      return `格式要求：${API_KEY_MIN_LENGTH}-${API_KEY_MAX_LENGTH} 位，仅支持字母、数字、点号、下划线、短横线。`
    }
    if (this.apiKeyInput.indexOf(' ') >= 0) {
      return 'API Key 不能包含空格，请检查复制内容。'
    }
    if (this.apiKeyInput.length < API_KEY_MIN_LENGTH || this.apiKeyInput.length > API_KEY_MAX_LENGTH) {
      return `API Key 长度需在 ${API_KEY_MIN_LENGTH}-${API_KEY_MAX_LENGTH} 位之间。`
    }
    if (!API_KEY_PATTERN.test(this.apiKeyInput)) {
      return 'API Key 格式不合法，仅允许字母、数字、点号、下划线和短横线。'
    }
    return '格式校验通过，可保存到本地。'
  }

  isApiKeyFormatValid(): boolean {
    if (this.apiKeyInput.length === 0) {
      return false
    }
    if (this.apiKeyInput.indexOf(' ') >= 0) {
      return false
    }
    if (this.apiKeyInput.length < API_KEY_MIN_LENGTH || this.apiKeyInput.length > API_KEY_MAX_LENGTH) {
      return false
    }
    return API_KEY_PATTERN.test(this.apiKeyInput)
  }

  canSaveApiKey(): boolean {
    return this.isApiKeyFormatValid()
  }

  savedApiKeySummary(): string {
    if (this.apiKeyInput.length <= 4) {
      return `本地已保存 API Key，当前长度 ${this.apiKeyInput.length} 位。`
    }
    const suffix = this.apiKeyInput.substring(this.apiKeyInput.length - 4)
    return `本地已保存 API Key，尾号 ${suffix}。`
  }

  async saveApiKey(): Promise<void> {
    const hostContext = this.getHostContext()
    if (hostContext === undefined) {
      this.statusText = '当前页面上下文不可用，暂时无法保存 API Key'
      this.statusColor = UiColors.DANGER
      return
    }
    if (!this.isApiKeyFormatValid()) {
      this.statusText = this.validationMessage()
      this.statusColor = UiColors.DANGER
      return
    }

    await this.userSettingsService.saveApiKey(hostContext, this.apiKeyInput)
    this.apiKeyInput = this.apiKeyInput.trim()
    this.hasStoredApiKey = true
    this.statusText = 'API Key 已保存到本地设备。'
    this.statusColor = UiColors.SUCCESS
  }

  async clearApiKey(): Promise<void> {
    const hostContext = this.getHostContext()
    if (hostContext === undefined) {
      this.statusText = '当前页面上下文不可用，暂时无法清空 API Key'
      this.statusColor = UiColors.DANGER
      return
    }

    await this.userSettingsService.clearApiKey(hostContext)
    this.apiKeyInput = ''
    this.hasStoredApiKey = false
    this.statusText = '已清空本地 API Key。'
    this.statusColor = UiColors.BRAND
  }

  async saveServiceBaseUrl(): Promise<void> {
    const hostContext = this.getHostContext()
    if (hostContext === undefined) {
      this.serviceBaseUrlStatusText = '当前页面上下文不可用，暂时无法保存服务地址'
      this.serviceBaseUrlStatusColor = UiColors.DANGER
      return
    }

    const normalizedBaseUrl = this.serviceBaseUrlInput.trim()
    if (normalizedBaseUrl.length === 0) {
      this.serviceBaseUrlStatusText = '服务地址不能为空。'
      this.serviceBaseUrlStatusColor = UiColors.DANGER
      return
    }

    await this.userSettingsService.saveServiceBaseUrl(hostContext, normalizedBaseUrl)
    this.serviceBaseUrlInput = normalizedBaseUrl
    this.serviceBaseUrlStatusText = '服务地址已保存，导入页会自动使用该地址。'
    this.serviceBaseUrlStatusColor = UiColors.SUCCESS
  }

  async clearServiceBaseUrl(): Promise<void> {
    const hostContext = this.getHostContext()
    if (hostContext === undefined) {
      this.serviceBaseUrlStatusText = '当前页面上下文不可用，暂时无法恢复默认地址'
      this.serviceBaseUrlStatusColor = UiColors.DANGER
      return
    }

    await this.userSettingsService.clearServiceBaseUrl(hostContext)
    const defaultBaseUrl = resolveDefaultApiBaseUrl()
    this.serviceBaseUrlInput = defaultBaseUrl
    this.serviceBaseUrlStatusText = isEmulatorRuntime()
      ? `已恢复模拟器自动联网地址（http://${DEV_HOST_LAN_IP}:3000）。`
      : '已恢复默认服务地址。'
    this.serviceBaseUrlStatusColor = UiColors.BRAND
  }

  async probeServiceBaseUrl(): Promise<void> {
    if (this.isProbingService) {
      return
    }
    this.isProbingService = true
    this.serviceBaseUrlStatusText = '正在检测服务连通性...'
    this.serviceBaseUrlStatusColor = UiColors.BRAND
    try {
      const probeResult = await this.serviceHealthProbe.findReachableBaseUrl(this.serviceBaseUrlInput)
      if (!probeResult.ok) {
        this.serviceBaseUrlStatusText = probeResult.message
        this.serviceBaseUrlStatusColor = UiColors.DANGER
        return
      }
      this.serviceBaseUrlInput = probeResult.baseUrl
      this.serviceBaseUrlStatusText = probeResult.message
      this.serviceBaseUrlStatusColor = UiColors.SUCCESS
      const hostContext = this.getHostContext()
      if (hostContext !== undefined) {
        await this.userSettingsService.saveServiceBaseUrl(hostContext, probeResult.baseUrl)
      }
    } finally {
      this.isProbingService = false
    }
  }

  async togglePrivacyGuard(): Promise<void> {
    const hostContext = this.getHostContext()
    if (hostContext === undefined) {
      this.privacyGuardHint = '当前页面上下文不可用，暂时无法切换隐私防窥'
      return
    }

    const nextValue = !this.privacyGuardEnabled
    await this.privacyGuardService.saveEnabled(hostContext, nextValue)
    this.privacyGuardEnabled = nextValue
    this.privacyGuardHint = nextValue
      ? '隐私防窥已开启，进入敏感页面时系统将阻止截屏和录屏。'
      : '隐私防窥已关闭，后续进入敏感页面时将恢复普通窗口。'
  }

  async saveDemoFaultMode(mode: DemoFaultMode): Promise<void> {
    const hostContext = this.getHostContext()
    if (hostContext === undefined) {
      this.demoFaultHint = '当前页面上下文不可用，暂时无法切换演示模式'
      return
    }

    await this.userSettingsService.saveDemoFaultMode(hostContext, mode)
    this.demoFaultMode = mode
    this.demoFaultHint = this.demoFaultModeHint(mode)
  }

  demoFaultModeLabel(mode: DemoFaultMode): string {
    if (mode === DemoFaultMode.WEAK_NETWORK) {
      return '弱网演示'
    }
    if (mode === DemoFaultMode.TIMEOUT) {
      return '超时演示'
    }
    if (mode === DemoFaultMode.SERVICE_ERROR) {
      return '服务失败演示'
    }
    if (mode === DemoFaultMode.DEGRADE_TO_DEMO) {
      return '降级展示'
    }
    return '正常'
  }

  demoFaultModeHint(mode: DemoFaultMode): string {
    if (mode === DemoFaultMode.WEAK_NETWORK) {
      return '导入后会走本地慢速演示链路，分析页状态推进会刻意放慢。'
    }
    if (mode === DemoFaultMode.TIMEOUT) {
      return '导入后会在模型分析阶段模拟超时失败，可直接演示重试与异常反馈。'
    }
    if (mode === DemoFaultMode.SERVICE_ERROR) {
      return '点击“开始分析”会直接触发服务失败提示，用于演示导入失败和继续演示入口。'
    }
    if (mode === DemoFaultMode.DEGRADE_TO_DEMO) {
      return '导入后会直接进入本地降级展示结果，用于演示服务不可用时的兜底讲解。'
    }
    return '关闭后将优先走真实服务分析链路。'
  }
}
