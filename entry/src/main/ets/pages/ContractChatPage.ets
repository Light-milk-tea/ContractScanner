import { common } from '@kit.AbilityKit'
import { back, RouteParams } from '../app/AppRouter'
import { API_BASE_URL } from '../common/constants'
import { logInfo } from '../common/logger'
import { pageHorizontalPadding, pageVerticalPadding } from '../common/ui/LayoutHelpers'
import { UiColors, UiFont, UiRadius, UiSpace } from '../common/ui/DesignTokens'
import { PrimaryButton } from '../components/ActionButtons'
import { ChatMessage, ChatVM } from '../model/viewmodel/ChatVM'
import { UserSettingsService } from '../services/storage/UserSettingsService'

@Entry
@Component
struct ContractChatPage {
  @State renderTick: number = 0
  @State draftText: string = ''
  @State isSending: boolean = false
  @State messages: ChatMessage[] = []
  @State contractTitle: string = '合同助手'

  chatVM: ChatVM = new ChatVM()
  listScroller: Scroller = new Scroller()

  aboutToAppear(): void {
    this.bootstrapChat()
  }

  build() {
    Column() {
      Column({ space: UiSpace.SM }) {
        Row({ space: UiSpace.XS }) {
          Text('‹')
            .fontSize(24)
            .fontWeight(FontWeight.Medium)
            .fontColor(UiColors.BRAND)
            .onClick(() => {
              back(this.getUIContext())
            })
          Text('返回结果')
            .fontSize(UiFont.BODY_SMALL)
            .fontColor(UiColors.BRAND)
            .onClick(() => {
              back(this.getUIContext())
            })
        }
        .width('100%')

        Text(this.contractTitle)
          .fontSize(UiFont.PAGE_TITLE)
          .fontWeight(FontWeight.Medium)
          .fontColor(UiColors.TEXT_PRIMARY)
          .width('100%')

        Text('基于本次分析结果回答，非正式法律意见。')
          .fontSize(UiFont.CAPTION)
          .fontColor(UiColors.TEXT_SECONDARY)
          .width('100%')
      }
      .width('100%')
      .padding({
        left: pageHorizontalPadding(),
        right: pageHorizontalPadding(),
        top: pageVerticalPadding(),
        bottom: UiSpace.MD
      })

      List({ scroller: this.listScroller }) {
        ForEach(this.messages, (message: ChatMessage) => {
          ListItem() {
            this.MessageBubble(message)
          }
        }, (message: ChatMessage) => message.id)
      }
      .width('100%')
      .layoutWeight(1)
      .padding({
        left: pageHorizontalPadding(),
        right: pageHorizontalPadding()
      })

      Column({ space: UiSpace.SM }) {
        if (this.isSending) {
          Text('正在思考…')
            .fontSize(UiFont.CAPTION)
            .fontColor(UiColors.TEXT_TERTIARY)
            .width('100%')
        }

        Row({ space: UiSpace.SM }) {
          TextInput({
            placeholder: '例如：押金怎么退？自动续约风险大吗？',
            text: this.draftText
          })
            .layoutWeight(1)
            .height(44)
            .fontSize(UiFont.BODY)
            .fontColor(UiColors.TEXT_PRIMARY)
            .placeholderColor(UiColors.TEXT_TERTIARY)
            .backgroundColor(UiColors.SURFACE_PRIMARY)
            .borderRadius(UiRadius.MEDIUM)
            .padding({
              left: UiSpace.MD,
              right: UiSpace.MD
            })
            .enabled(!this.isSending)
            .onChange((value: string) => {
              this.draftText = value
              this.chatVM.setDraftText(value)
            })
            .onSubmit(() => {
              this.handleSend()
            })

          PrimaryButton({
            label: '发送',
            isEnabled: !this.isSending && this.draftText.trim().length > 0,
            onTap: () => {
              this.handleSend()
            }
          })
        }
        .width('100%')
      }
      .width('100%')
      .padding({
        left: pageHorizontalPadding(),
        right: pageHorizontalPadding(),
        top: UiSpace.MD,
        bottom: pageVerticalPadding()
      })
      .backgroundColor(UiColors.PAGE_BACKGROUND)
      .border({
        width: { top: 0.5 },
        color: UiColors.BORDER_HAIRLINE
      })
    }
    .width('100%')
    .height('100%')
    .linearGradient({
      angle: 180,
      colors: [
        [UiColors.PAGE_GRADIENT_TOP, 0],
        [UiColors.PAGE_GRADIENT_BOTTOM, 1]
      ]
    })
  }

  @Builder
  MessageBubble(message: ChatMessage) {
    Row() {
      if (message.role === 'user') {
        Blank()
      }

      Text(message.content)
        .fontSize(UiFont.BODY)
        .fontColor(message.role === 'user' ? UiColors.TEXT_ON_BRAND :
          (message.isError === true ? UiColors.DANGER : UiColors.TEXT_PRIMARY))
        .lineHeight(22)
        .padding({
          left: UiSpace.MD,
          right: UiSpace.MD,
          top: UiSpace.MD,
          bottom: UiSpace.MD
        })
        .backgroundColor(message.role === 'user' ? UiColors.BRAND :
          (message.isError === true ? UiColors.DANGER_SOFT : UiColors.SURFACE_PRIMARY))
        .borderRadius(UiRadius.LARGE)
        .constraintSize({ maxWidth: '78%' })

      if (message.role !== 'user') {
        Blank()
      }
    }
    .width('100%')
    .padding({
      top: UiSpace.SM,
      bottom: UiSpace.SM
    })
    .justifyContent(message.role === 'user' ? FlexAlign.End : FlexAlign.Start)
  }

  async bootstrapChat(): Promise<void> {
    const params = this.readParams()
    const taskId = params.taskId ?? ''
    let baseUrl = params.baseUrl ?? API_BASE_URL
    const seedQuestion = params.seedQuestion ?? ''

    const hostContext = this.getHostContext()
    let apiKey = ''
    if (hostContext !== undefined) {
      const settings = new UserSettingsService()
      apiKey = await settings.loadApiKey(hostContext)
      if ((params.baseUrl ?? '').length === 0) {
        baseUrl = await settings.loadServiceBaseUrl(hostContext, API_BASE_URL)
      }
    }

    this.chatVM.setRouteContext(taskId, baseUrl)
    this.chatVM.setApiKey(apiKey)
    this.contractTitle = '合同助手'
    const welcome =
      '你好，我是合同解读助手。你可以围绕本次分析结果提问，例如风险点、押金退还、违约责任或签署前检查项。回答仅供理解参考，不构成正式法律意见。'
    this.chatVM.resetConversation(welcome)
    this.syncFromVm()

    if (seedQuestion.trim().length > 0) {
      this.draftText = seedQuestion
      this.chatVM.setDraftText(seedQuestion)
      this.syncFromVm()
      logInfo(`Contract chat seeded: taskId=${taskId}`, 'ContractChatPage')
    } else {
      logInfo(`Contract chat opened: taskId=${taskId}`, 'ContractChatPage')
    }
  }

  async handleSend(): Promise<void> {
    const question = this.draftText.trim()
    if (question.length === 0 || this.isSending) {
      return
    }

    if (!this.chatVM.beginSend(question)) {
      return
    }

    this.draftText = ''
    this.isSending = true
    this.syncFromVm()
    this.scrollToBottom()

    await this.chatVM.requestAnswer(question)
    this.isSending = this.chatVM.isSending
    this.syncFromVm()
    this.scrollToBottom()
  }

  syncFromVm(): void {
    this.messages = this.chatVM.messages.slice()
    this.isSending = this.chatVM.isSending
    this.renderTick = this.renderTick + 1
  }

  scrollToBottom(): void {
    if (this.messages.length === 0) {
      return
    }
    this.listScroller.scrollToIndex(this.messages.length - 1)
  }

  readParams(): RouteParams {
    return this.getUIContext().getRouter().getParams() as RouteParams
  }

  getHostContext(): common.UIAbilityContext | undefined {
    const hostContext = this.getUIContext().getHostContext()
    if (hostContext === undefined) {
      return undefined
    }
    return hostContext as common.UIAbilityContext
  }
}
