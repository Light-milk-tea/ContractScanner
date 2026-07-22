import { AppError } from '../../common/errors'
import { ChatAnswerDTO, ChatHistoryMessageDTO, ContractApi } from '../../services/api/ContractApi'

export type ChatMessageRole = 'user' | 'assistant' | 'system'

export interface ChatMessage {
  id: string
  role: ChatMessageRole
  content: string
  isError?: boolean
}

export class ChatVM {
  taskId: string = ''
  baseUrl: string = ''
  apiKey: string = ''
  messages: ChatMessage[] = []
  draftText: string = ''
  isSending: boolean = false
  errorText: string = ''
  private messageSeq: number = 0

  setRouteContext(taskId: string, baseUrl: string): void {
    this.taskId = taskId
    this.baseUrl = baseUrl
  }

  setApiKey(apiKey: string): void {
    this.apiKey = apiKey
  }

  setDraftText(text: string): void {
    this.draftText = text
  }

  resetConversation(welcomeText: string): void {
    this.messages = []
    this.messageSeq = 0
    this.errorText = ''
    this.isSending = false
    this.appendMessage('assistant', welcomeText)
  }

  appendMessage(role: ChatMessageRole, content: string, isError: boolean = false): ChatMessage {
    this.messageSeq += 1
    const message: ChatMessage = {
      id: `msg-${this.messageSeq}`,
      role: role,
      content: content,
      isError: isError
    }
    this.messages = this.messages.concat([message])
    return message
  }

  beginSend(question: string): boolean {
    const trimmed = question.trim()
    if (trimmed.length === 0 || this.isSending) {
      return false
    }
    this.isSending = true
    this.errorText = ''
    this.draftText = ''
    this.appendMessage('user', trimmed)
    return true
  }

  buildHistoryForRequest(excludeLatestUser: boolean = true): ChatHistoryMessageDTO[] {
    const history: ChatHistoryMessageDTO[] = []
    for (let i: number = 0; i < this.messages.length; i++) {
      const message = this.messages[i]
      if (message.role !== 'user' && message.role !== 'assistant') {
        continue
      }
      if (message.isError === true) {
        continue
      }
      if (message.role === 'assistant' && history.length === 0 && i === 0) {
        continue
      }
      history.push({
        role: message.role,
        content: message.content
      })
    }

    let trimmed = history
    if (excludeLatestUser && trimmed.length > 0 && trimmed[trimmed.length - 1].role === 'user') {
      trimmed = trimmed.slice(0, trimmed.length - 1)
    }

    if (trimmed.length <= 6) {
      return trimmed
    }
    return trimmed.slice(trimmed.length - 6)
  }

  async requestAnswer(question: string): Promise<void> {
    try {
      const api = new ContractApi(this.baseUrl)
      const history = this.buildHistoryForRequest(true)
      const answer: ChatAnswerDTO = await api.askQuestion(
        this.taskId,
        question.trim(),
        history,
        this.apiKey
      )
      this.appendMessage('assistant', answer.answer)
    } catch (error) {
      if (error instanceof AppError) {
        this.errorText = error.message
        this.appendMessage('assistant', `回答失败：${error.message}`, true)
      } else {
        this.errorText = '问答失败，请稍后重试'
        this.appendMessage('assistant', '回答失败，请稍后重试', true)
      }
    } finally {
      this.isSending = false
    }
  }
}
