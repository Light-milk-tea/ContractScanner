import { common } from '@kit.AbilityKit'
import { back } from '../app/AppRouter'
import { API_BASE_URL } from '../common/constants'
import { UiColors, UiRadius, UiSpace } from '../common/ui/DesignTokens'
import { PageScaffold } from '../components/PageScaffold'
import { SectionHeader } from '../components/SectionHeader'
import { SurfaceCard } from '../components/SurfaceCard'
import { DemoFaultMode } from '../model/enums/DemoMode'
import { PrivacyGuardService } from '../services/ability/PrivacyGuardService'
import { UserSettingsService } from '../services/storage/UserSettingsService'

const API_KEY_MIN_LENGTH: number = 16
const API_KEY_MAX_LENGTH: number = 128
const API_KEY_PATTERN: RegExp = /^[A-Za-z0-9._-]+$/

@Entry
@Component
struct SettingsPage {
  @State serviceBaseUrlInput: string = API_BASE_URL
  @State serviceBaseUrlStatusText: string = ''
  @State serviceBaseUrlStatusColor: string = '#2E6BE6'
  @State apiKeyInput: string = ''
  @State isApiKeyVisible: boolean = false
  @State statusText: string = ''
  @State statusColor: string = '#2E6BE6'
  @State hasStoredApiKey: boolean = false
  @State privacyGuardEnabled: boolean = false
  @State privacyGuardHint: string = ''
  @State demoFaultMode: DemoFaultMode = DemoFaultMode.NONE
  @State demoFaultHint: string = ''

  userSettingsService: UserSettingsService = new UserSettingsService()
  privacyGuardService: PrivacyGuardService = new PrivacyGuardService()

  aboutToAppear(): void {
    this.loadServiceBaseUrl()
    this.loadApiKey()
    this.loadPrivacyGuardSetting()
    this.loadDemoFaultMode()
  }

  build() {
    Column() {
      PageScaffold({
        title: '用户设置',
        description: '这里集中管理模型联调所需配置、隐私防窥和答辩演示模式。',
        backText: '返回',
        onBack: () => {
          back(this.getUIContext())
        }
      }) {
        Column({ space: UiSpace.LG }) {
          SurfaceCard() {
            Column({ space: UiSpace.MD }) {
              SectionHeader({
                title: '服务地址',
                description: '导入页会直接读取这里保存的服务地址；真机或模拟器联调时请填写电脑局域网 IP。'
              })

              TextInput({
                text: this.serviceBaseUrlInput,
                placeholder: '例如：http://192.168.x.x:3000'
              })
                .width('100%')
                .backgroundColor(UiColors.SURFACE_MUTED)
                .borderRadius(UiRadius.MEDIUM)
                .onChange((value: string) => {
                  this.serviceBaseUrlInput = value
                  this.serviceBaseUrlStatusText = ''
                })

              if (this.isLoopbackBaseUrl(this.serviceBaseUrlInput)) {
                Text('当前是本机回环地址；在真机或模拟器上请改成电脑局域网 IP，例如 http://192.168.x.x:3000。')
                  .fontSize(12)
                  .fontColor(UiColors.DANGER)
              }

              Row({ space: UiSpace.SM }) {
                Button('保存地址')
                  .type(ButtonType.Capsule)
                  .backgroundColor(UiColors.BRAND)
                  .fontColor('#FFFFFF')
                  .onClick(() => {
                    this.saveServiceBaseUrl()
                  })
                Button('恢复默认')
                  .type(ButtonType.Capsule)
                  .backgroundColor(UiColors.SURFACE_SECONDARY)
                  .fontColor(UiColors.TEXT_PRIMARY)
                  .onClick(() => {
                    this.clearServiceBaseUrl()
                  })
              }

              Text(this.serviceBaseUrlStatusText.length > 0 ? this.serviceBaseUrlStatusText : '默认地址仅适用于本机调试；答辩或模拟器演示建议改为宿主机局域网地址。')
                .fontSize(12)
                .fontColor(this.serviceBaseUrlStatusText.length > 0 ? this.serviceBaseUrlStatusColor : UiColors.TEXT_SECONDARY)
            }
            .alignItems(HorizontalAlign.Start)
            .width('100%')
          }

          SurfaceCard() {
            Column({ space: UiSpace.MD }) {
              SectionHeader({
                title: '模型 API Key',
                description: '密钥仅保存在当前设备本地，用于后续服务接入与真实模型联调。'
              })

              Row({ space: UiSpace.SM }) {
                TextInput({
                  text: this.apiKeyInput,
                  placeholder: '请输入 API Key，例如 sk-xxxxxxxxxxxxxxxx'
                })
                  .type(this.isApiKeyVisible ? InputType.Normal : InputType.Password)
                  .maxLength(API_KEY_MAX_LENGTH)
                  .width('78%')
                  .backgroundColor(UiColors.SURFACE_MUTED)
                  .borderRadius(UiRadius.MEDIUM)
                  .onChange((value: string) => {
                    this.apiKeyInput = value
                    this.statusText = ''
                  })

                Button(this.isApiKeyVisible ? '隐藏' : '显示')
                  .type(ButtonType.Capsule)
                  .width('22%')
                  .backgroundColor(UiColors.SURFACE_SECONDARY)
                  .fontColor(UiColors.TEXT_PRIMARY)
                  .onClick(() => {
                    this.isApiKeyVisible = !this.isApiKeyVisible
                  })
              }
              .width('100%')

              Text(this.validationMessage())
                .fontSize(12)
                .fontColor(this.isApiKeyFormatValid() ? UiColors.SUCCESS : UiColors.DANGER)

              Row({ space: UiSpace.SM }) {
                Button('保存到本地')
                  .type(ButtonType.Capsule)
                  .enabled(this.canSaveApiKey())
                  .backgroundColor(UiColors.BRAND)
                  .fontColor('#FFFFFF')
                  .onClick(() => {
                    this.saveApiKey()
                  })
                Button('清空')
                  .type(ButtonType.Capsule)
                  .backgroundColor(UiColors.SURFACE_SECONDARY)
                  .fontColor(UiColors.TEXT_PRIMARY)
                  .enabled(this.hasStoredApiKey || this.apiKeyInput.length > 0)
                  .onClick(() => {
                    this.clearApiKey()
                  })
              }

              if (this.hasStoredApiKey) {
                Text(this.savedApiKeySummary())
                  .fontSize(13)
                  .fontColor(UiColors.TEXT_SECONDARY)
              }

              if (this.statusText.length > 0) {
                Text(this.statusText)
                  .fontSize(13)
                  .fontColor(this.statusColor)
              }
            }
            .alignItems(HorizontalAlign.Start)
            .width('100%')
          }

          SurfaceCard() {
            Column({ space: UiSpace.MD }) {
              SectionHeader({
                title: '系统控制项',
                description: '集中管理敏感信息保护和答辩演示时的异常模拟。'
              })

              Row() {
                Column({ space: 4 }) {
                  Text('隐私防窥')
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                  Text('在结果页与条款对照页启用系统隐私窗口，限制截屏与录屏。')
                    .fontSize(13)
                    .fontColor(UiColors.TEXT_SECONDARY)
                  Text(this.privacyGuardEnabled ? '当前状态：已开启，敏感页面会自动套用隐私窗口。' : '当前状态：已关闭，敏感页面按普通窗口显示。')
                    .fontSize(12)
                    .fontColor(this.privacyGuardEnabled ? UiColors.SUCCESS : UiColors.TEXT_TERTIARY)
                  if (this.privacyGuardHint.length > 0) {
                    Text(this.privacyGuardHint)
                      .fontSize(12)
                      .fontColor(UiColors.BRAND)
                  }
                }
                .alignItems(HorizontalAlign.Start)

                Button(this.privacyGuardEnabled ? '关闭' : '开启')
                  .type(ButtonType.Capsule)
                  .backgroundColor(this.privacyGuardEnabled ? UiColors.SURFACE_SECONDARY : UiColors.BRAND)
                  .fontColor(this.privacyGuardEnabled ? UiColors.TEXT_PRIMARY : '#FFFFFF')
                  .onClick(() => {
                    this.togglePrivacyGuard()
                  })
              }
              .width('100%')
              .justifyContent(FlexAlign.SpaceBetween)
              .alignItems(VerticalAlign.Center)
              .padding({ top: 8, bottom: 8 })

              this.buildSettingHint('日志调试', '后续将在此补齐日志开关与调试信息展示能力。')

              Column({ space: UiSpace.SM }) {
                Text('答辩演示模式')
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                Text('用于主动触发弱网、超时、服务失败或降级展示，不依赖现场网络偶发问题。')
                  .fontSize(13)
                  .fontColor(UiColors.TEXT_SECONDARY)

                Row({ space: UiSpace.SM }) {
                  this.buildDemoModeButton(DemoFaultMode.NONE, '正常')
                  this.buildDemoModeButton(DemoFaultMode.WEAK_NETWORK, '弱网')
                  this.buildDemoModeButton(DemoFaultMode.TIMEOUT, '超时')
                }

                Row({ space: UiSpace.SM }) {
                  this.buildDemoModeButton(DemoFaultMode.SERVICE_ERROR, '服务失败')
                  this.buildDemoModeButton(DemoFaultMode.DEGRADE_TO_DEMO, '降级展示')
                }

                Text(`当前模式：${this.demoFaultModeLabel(this.demoFaultMode)}`)
                  .fontSize(12)
                  .fontColor(this.demoFaultMode === DemoFaultMode.NONE ? UiColors.TEXT_TERTIARY : UiColors.SUCCESS)

                if (this.demoFaultHint.length > 0) {
                  Text(this.demoFaultHint)
                    .fontSize(12)
                    .fontColor(UiColors.BRAND)
                }
              }
              .alignItems(HorizontalAlign.Start)
              .width('100%')
              .padding({ top: 8, bottom: 8 })
            }
            .alignItems(HorizontalAlign.Start)
            .width('100%')
          }

          Text('当前实现基于 ArkData Preferences 本地存储，适用于手机、平板等设备场景；后续服务接入时将优先复用该配置。')
            .fontSize(12)
            .fontColor(UiColors.TEXT_TERTIARY)
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
      }
    }
    .width('100%')
    .height('100%')
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
      .type(ButtonType.Capsule)
      .backgroundColor(this.demoFaultMode === mode ? UiColors.BRAND : UiColors.SURFACE_SECONDARY)
      .fontColor(this.demoFaultMode === mode ? '#FFFFFF' : UiColors.TEXT_PRIMARY)
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
      this.serviceBaseUrlStatusColor = '#C0392B'
      return
    }

    const savedBaseUrl = await this.userSettingsService.loadServiceBaseUrl(hostContext, API_BASE_URL)
    this.serviceBaseUrlInput = savedBaseUrl
    this.serviceBaseUrlStatusText = savedBaseUrl === API_BASE_URL ? '当前使用默认服务地址。' : '已读取本地保存的服务地址。'
    this.serviceBaseUrlStatusColor = savedBaseUrl === API_BASE_URL ? '#2E6BE6' : '#2A8F5B'
  }

  async loadApiKey(): Promise<void> {
    const hostContext = this.getHostContext()
    if (hostContext === undefined) {
      this.statusText = '当前页面上下文不可用，暂时无法读取本地配置'
      this.statusColor = '#C0392B'
      return
    }

    const savedApiKey = await this.userSettingsService.loadApiKey(hostContext)
    this.apiKeyInput = savedApiKey
    this.hasStoredApiKey = savedApiKey.length > 0
    this.statusText = savedApiKey.length > 0 ? '已读取本地保存的 API Key，可直接修改后重新保存。' : ''
    this.statusColor = '#2E6BE6'
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
      this.statusColor = '#C0392B'
      return
    }
    if (!this.isApiKeyFormatValid()) {
      this.statusText = this.validationMessage()
      this.statusColor = '#C0392B'
      return
    }

    await this.userSettingsService.saveApiKey(hostContext, this.apiKeyInput)
    this.apiKeyInput = this.apiKeyInput.trim()
    this.hasStoredApiKey = true
    this.statusText = 'API Key 已保存到本地设备。'
    this.statusColor = '#2A8F5B'
  }

  async clearApiKey(): Promise<void> {
    const hostContext = this.getHostContext()
    if (hostContext === undefined) {
      this.statusText = '当前页面上下文不可用，暂时无法清空 API Key'
      this.statusColor = '#C0392B'
      return
    }

    await this.userSettingsService.clearApiKey(hostContext)
    this.apiKeyInput = ''
    this.hasStoredApiKey = false
    this.statusText = '已清空本地 API Key。'
    this.statusColor = '#2E6BE6'
  }

  async saveServiceBaseUrl(): Promise<void> {
    const hostContext = this.getHostContext()
    if (hostContext === undefined) {
      this.serviceBaseUrlStatusText = '当前页面上下文不可用，暂时无法保存服务地址'
      this.serviceBaseUrlStatusColor = '#C0392B'
      return
    }

    const normalizedBaseUrl = this.serviceBaseUrlInput.trim()
    if (normalizedBaseUrl.length === 0) {
      this.serviceBaseUrlStatusText = '服务地址不能为空。'
      this.serviceBaseUrlStatusColor = '#C0392B'
      return
    }

    await this.userSettingsService.saveServiceBaseUrl(hostContext, normalizedBaseUrl)
    this.serviceBaseUrlInput = normalizedBaseUrl
    this.serviceBaseUrlStatusText = '服务地址已保存，导入页会自动使用该地址。'
    this.serviceBaseUrlStatusColor = '#2A8F5B'
  }

  async clearServiceBaseUrl(): Promise<void> {
    const hostContext = this.getHostContext()
    if (hostContext === undefined) {
      this.serviceBaseUrlStatusText = '当前页面上下文不可用，暂时无法恢复默认地址'
      this.serviceBaseUrlStatusColor = '#C0392B'
      return
    }

    await this.userSettingsService.clearServiceBaseUrl(hostContext)
    this.serviceBaseUrlInput = API_BASE_URL
    this.serviceBaseUrlStatusText = '已恢复默认服务地址。'
    this.serviceBaseUrlStatusColor = '#2E6BE6'
  }

  isLoopbackBaseUrl(baseUrl: string): boolean {
    return baseUrl.indexOf('127.0.0.1') >= 0 || baseUrl.indexOf('localhost') >= 0
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
