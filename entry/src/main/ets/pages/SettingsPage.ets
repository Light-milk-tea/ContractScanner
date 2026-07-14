import { common } from '@kit.AbilityKit'
import { back } from '../app/AppRouter'
import { DemoFaultMode } from '../model/enums/DemoMode'
import { PrivacyGuardService } from '../services/ability/PrivacyGuardService'
import { UserSettingsService } from '../services/storage/UserSettingsService'

const API_KEY_MIN_LENGTH: number = 16
const API_KEY_MAX_LENGTH: number = 128
const API_KEY_PATTERN: RegExp = /^[A-Za-z0-9._-]+$/

@Entry
@Component
struct SettingsPage {
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
    this.loadApiKey()
    this.loadPrivacyGuardSetting()
    this.loadDemoFaultMode()
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Row({ space: 12 }) {
          Button('返回')
            .type(ButtonType.Capsule)
            .onClick(() => {
              back(this.getUIContext())
            })
          Text('用户设置')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
        }

        Text('配置 B17 阶段真实大模型联调所需的 API Key。密钥仅保存在当前设备本地，用于后续服务接入。')
          .fontSize(14)
          .fontColor('#666666')

        Column({ space: 12 }) {
          Text('模型 API Key')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
          Text('支持密码隐藏/显示切换，输入后会做格式校验；建议使用提供方发放的正式密钥。')
            .fontSize(13)
            .fontColor('#666666')

          Row({ space: 8 }) {
            TextInput({
              text: this.apiKeyInput,
              placeholder: '请输入 API Key，例如 sk-xxxxxxxxxxxxxxxx'
            })
              .type(this.isApiKeyVisible ? InputType.Normal : InputType.Password)
              .maxLength(API_KEY_MAX_LENGTH)
              .width('78%')
              .onChange((value: string) => {
                this.apiKeyInput = value
                this.statusText = ''
              })

            Button(this.isApiKeyVisible ? '隐藏' : '显示')
              .type(ButtonType.Capsule)
              .width('22%')
              .onClick(() => {
                this.isApiKeyVisible = !this.isApiKeyVisible
              })
          }
          .width('100%')

          Text(this.validationMessage())
            .fontSize(12)
            .fontColor(this.isApiKeyFormatValid() ? '#2A8F5B' : '#C0392B')

          Row({ space: 8 }) {
            Button('保存到本地')
              .type(ButtonType.Capsule)
              .enabled(this.canSaveApiKey())
              .onClick(() => {
                this.saveApiKey()
              })
            Button('清空')
              .type(ButtonType.Capsule)
              .backgroundColor('#DDE3EE')
              .fontColor('#333333')
              .enabled(this.hasStoredApiKey || this.apiKeyInput.length > 0)
              .onClick(() => {
                this.clearApiKey()
              })
          }

          if (this.hasStoredApiKey) {
            Text(this.savedApiKeySummary())
              .fontSize(13)
              .fontColor('#666666')
          }

          if (this.statusText.length > 0) {
            Text(this.statusText)
              .fontSize(13)
              .fontColor(this.statusColor)
          }
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding(16)
        .backgroundColor('#F8F9FB')
        .borderRadius(16)

        Column({ space: 12 }) {
          Text('系统控制项')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)

          Row() {
            Column({ space: 4 }) {
              Text('隐私防窥')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
              Text('在结果页与条款对照页启用系统隐私窗口，限制截屏与录屏。')
                .fontSize(13)
                .fontColor('#666666')
              Text(this.privacyGuardEnabled ? '当前状态：已开启，敏感页面会自动套用隐私窗口。' : '当前状态：已关闭，敏感页面按普通窗口显示。')
                .fontSize(12)
                .fontColor(this.privacyGuardEnabled ? '#2A8F5B' : '#999999')
              if (this.privacyGuardHint.length > 0) {
                Text(this.privacyGuardHint)
                  .fontSize(12)
                  .fontColor('#2E6BE6')
              }
            }
            .alignItems(HorizontalAlign.Start)

            Button(this.privacyGuardEnabled ? '关闭' : '开启')
              .type(ButtonType.Capsule)
              .onClick(() => {
                this.togglePrivacyGuard()
              })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
          .alignItems(VerticalAlign.Center)
          .padding({ top: 8, bottom: 8 })

          this.buildSettingHint('日志调试', '后续将在此补齐日志开关与调试信息展示能力。')

          Column({ space: 8 }) {
            Text('答辩演示模式')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
            Text('用于主动触发弱网、超时、服务失败或降级展示，不依赖现场网络偶发问题。')
              .fontSize(13)
              .fontColor('#666666')

            Row({ space: 8 }) {
              this.buildDemoModeButton(DemoFaultMode.NONE, '正常')
              this.buildDemoModeButton(DemoFaultMode.WEAK_NETWORK, '弱网')
              this.buildDemoModeButton(DemoFaultMode.TIMEOUT, '超时')
            }

            Row({ space: 8 }) {
              this.buildDemoModeButton(DemoFaultMode.SERVICE_ERROR, '服务失败')
              this.buildDemoModeButton(DemoFaultMode.DEGRADE_TO_DEMO, '降级展示')
            }

            Text(`当前模式：${this.demoFaultModeLabel(this.demoFaultMode)}`)
              .fontSize(12)
              .fontColor(this.demoFaultMode === DemoFaultMode.NONE ? '#999999' : '#2A8F5B')

            if (this.demoFaultHint.length > 0) {
              Text(this.demoFaultHint)
                .fontSize(12)
                .fontColor('#2E6BE6')
            }
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
          .padding({ top: 8, bottom: 8 })
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding(16)
        .backgroundColor('#F8F9FB')
        .borderRadius(16)

        Text('当前实现基于 ArkData Preferences 本地存储，适用于手机、平板等设备场景；后续服务接入时将优先复用该配置。')
          .fontSize(12)
          .fontColor('#999999')
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .padding(24)
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
          .fontColor('#666666')
      }
      .alignItems(HorizontalAlign.Start)

      Text('规划中')
        .fontSize(12)
        .fontColor('#2E6BE6')
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
    .padding({ top: 8, bottom: 8 })
  }

  @Builder
  buildDemoModeButton(mode: DemoFaultMode, label: string) {
    Button(label)
      .type(ButtonType.Capsule)
      .backgroundColor(this.demoFaultMode === mode ? '#2E6BE6' : '#DDE3EE')
      .fontColor(this.demoFaultMode === mode ? '#FFFFFF' : '#333333')
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
