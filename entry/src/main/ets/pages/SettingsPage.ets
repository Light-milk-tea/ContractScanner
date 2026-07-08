import { common } from '@kit.AbilityKit'
import { back } from '../app/AppRouter'
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

  userSettingsService: UserSettingsService = new UserSettingsService()

  aboutToAppear(): void {
    this.loadApiKey()
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

          this.buildSettingHint('隐私防窥', '后续将在此接入系统隐私防窥开关与状态同步。')
          this.buildSettingHint('日志调试', '后续将在此补齐日志开关与调试信息展示能力。')
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
}
