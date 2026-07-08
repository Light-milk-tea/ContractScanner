import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { picker } from '@kit.CoreFileKit'

import { back, goAnalyzing, RouteParams } from '../app/AppRouter'
import { API_BASE_URL } from '../common/constants'
import { AppError } from '../common/errors'
import { logError } from '../common/logger'
import { EmptyState } from '../components/EmptyState'
import { Contract } from '../model/domain/Contract'
import { ImportVM } from '../model/viewmodel/ImportVM'
import { ContractApi } from '../services/api/ContractApi'
import { FileImportService } from '../services/parser/FileImportService'
import { CacheService } from '../services/storage/CacheService'
import { UserSettingsService } from '../services/storage/UserSettingsService'

@Entry
@Component
struct ImportPage {
  @State importVM: ImportVM = new ImportVM()
  @State baseUrl: string = API_BASE_URL
  @State fileUri: string = ''
  @State fileName: string = ''
  @State errorText: string = ''
  @State isSubmitting: boolean = false
  @State canContinueDemo: boolean = false
  @State apiKeyNoticeText: string = '正在检查本地 API Key 配置...'
  @State apiKeyNoticeColor: string = '#666666'
  @State baseUrlNoticeText: string = '当前使用默认服务地址。'
  @State baseUrlNoticeColor: string = '#666666'

  fileImportService: FileImportService = new FileImportService()
  cacheService: CacheService = new CacheService()
  userSettingsService: UserSettingsService = new UserSettingsService()

  aboutToAppear(): void {
    this.initializePage()
  }

  build() {
    Column({ space: 16 }) {
      Row({ space: 12 }) {
        Button('返回首页')
          .type(ButtonType.Capsule)
          .onClick(() => {
            back(this.getUIContext())
          })
        Text('导入合同')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
      }
      Text('当前已接入本地文件选择，拍照和相册导入将在后续继续补齐。')
        .fontSize(14)
        .fontColor('#666666')

      Column({ space: 8 }) {
        Text('导入方式')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
        Row({ space: 8 }) {
          Button('拍照')
            .type(ButtonType.Capsule)
            .backgroundColor(this.importVM.selectedSource === 'CAMERA' ? '#2E6BE6' : '#DDE3EE')
            .fontColor(this.importVM.selectedSource === 'CAMERA' ? '#FFFFFF' : '#333333')
            .onClick(() => {
              this.importVM.setSelectedSource('CAMERA')
            })
          Button('相册')
            .type(ButtonType.Capsule)
            .backgroundColor(this.importVM.selectedSource === 'GALLERY' ? '#2E6BE6' : '#DDE3EE')
            .fontColor(this.importVM.selectedSource === 'GALLERY' ? '#FFFFFF' : '#333333')
            .onClick(() => {
              this.importVM.setSelectedSource('GALLERY')
            })
          Button('本地文件')
            .type(ButtonType.Capsule)
            .backgroundColor(this.importVM.selectedSource === 'LOCAL_FILE' ? '#2E6BE6' : '#DDE3EE')
            .fontColor(this.importVM.selectedSource === 'LOCAL_FILE' ? '#FFFFFF' : '#333333')
            .onClick(() => {
              this.importVM.setSelectedSource('LOCAL_FILE')
            })
        }
      }

      Column({ space: 8 }) {
        Text('服务地址')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
        TextInput({ text: this.baseUrl, placeholder: '例如：http://192.168.x.x:3000' })
          .width('100%')
          .onChange((value: string) => {
            this.baseUrl = value
          })
        if (this.isLoopbackBaseUrl()) {
          Text('当前是本机回环地址；在真机或模拟器上请改成电脑局域网 IP，例如 http://192.168.x.x:3000。')
            .fontSize(12)
            .fontColor('#C0392B')
        }
        Text(this.baseUrlNoticeText)
          .fontSize(12)
          .fontColor(this.baseUrlNoticeColor)
        Text(this.apiKeyNoticeText)
          .fontSize(12)
          .fontColor(this.apiKeyNoticeColor)
      }

      Column({ space: 8 }) {
        Text('文件信息')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
        Row({ space: 8 }) {
          Button('选择文件')
            .type(ButtonType.Capsule)
            .enabled(!this.isSubmitting)
            .onClick(() => {
              this.selectLocalFile()
            })
          Text('支持 pdf、docx、txt、md、jpg、png 等常见合同文件')
            .fontSize(12)
            .fontColor('#666666')
        }
        TextInput({ text: this.fileUri, placeholder: '文件 URI / 路径（未选择时可手动输入）' })
          .width('100%')
          .onChange((value: string) => {
            this.fileUri = value
          })
        TextInput({ text: this.fileName, placeholder: '文件名（可选）' })
          .width('100%')
          .onChange((value: string) => {
            this.fileName = value
          })
        Row({ space: 8 }) {
          Button('填充示例')
            .onClick(() => {
              this.fileUri = 'inline://甲方应于每月5日前支付租金，逾期每日按应付金额0.5%支付违约金。乙方提前解约需承担剩余租期30%的违约责任。出租方可在验收后30个工作日内单方决定是否退还押金。争议提交合同签订地人民法院处理。'
              this.fileName = 'demo.pdf'
            })
          Button('清空')
            .onClick(() => {
              this.fileUri = ''
              this.fileName = ''
              this.importVM.reset()
              this.errorText = ''
            })
        }
        if (this.importVM.selectedFileName.length > 0) {
          Text(`已选择：${this.importVM.selectedFileName} (${this.importVM.selectedFileType})`)
            .fontSize(13)
            .fontColor('#666666')
        }
      }

      if (this.errorText.length > 0) {
        Column({ space: 12 }) {
          EmptyState({
            title: '导入失败',
            description: this.errorText,
            hint: this.canContinueDemo ? '可修正服务地址后重试，或继续进入临时 Mock 演示任务。' : '请修正输入信息后重试。'
          })
          Row({ space: 8 }) {
            Button('重试上传')
              .type(ButtonType.Capsule)
              .enabled(!this.isSubmitting)
              .onClick(() => {
                this.startAnalyze()
              })
            if (this.canContinueDemo) {
              Button('继续演示')
                .type(ButtonType.Capsule)
                .onClick(() => {
                  this.continueDemo()
                })
            }
          }
        }
        .width('100%')
      }

      Button(this.isSubmitting ? '提交中...' : '开始分析')
        .width('100%')
        .enabled(!this.isSubmitting)
        .onClick(() => {
          this.startAnalyze()
        })

      Text('当前页已支持直接选择本地文件；文本文件会自动读取正文并转为可分析内容，也可在文件 URI 中填入 `inline://合同正文` 形式的文本样例。')
        .fontSize(13)
        .fontColor('#999999')
    }
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .height('100%')
    .padding(24)
  }

  async startAnalyze(): Promise<void> {
    this.errorText = ''
    this.canContinueDemo = false
    if (this.fileUri.length === 0 && this.fileName.length === 0) {
      this.errorText = '请先填写文件 URI/路径或文件名'
      return
    }

    this.isSubmitting = true
    try {
      const meta = this.fileImportService.parseFile(this.fileUri, this.fileName)
      const uploadRequest = this.fileImportService.buildUploadRequest(meta)
      if (this.fileImportService.isTextFile(meta)) {
        const textContent = this.fileImportService.readTextFile(meta.fileUri)
        uploadRequest.fileUri = this.fileImportService.buildInlineTextUri(textContent)
      }
      this.importVM.setSelectedFile(meta.fileName, uploadRequest.fileType, meta.fileUri)

      const hostContext = this.getHostContext()
      if (hostContext !== undefined) {
        const savedApiKey = await this.userSettingsService.loadApiKey(hostContext)
        if (savedApiKey.length > 0) {
          uploadRequest.apiKey = savedApiKey
          this.apiKeyNoticeText = '已透传本地 API Key，本次将优先走真实模型分析。'
          this.apiKeyNoticeColor = '#2A8F5B'
        } else {
          this.apiKeyNoticeText = '未检测到本地 API Key，若服务端未配置环境变量，真实分析会失败。'
          this.apiKeyNoticeColor = '#C0392B'
        }
      }

      const api = new ContractApi(this.baseUrl)
      const result = await api.uploadContract(uploadRequest)
      await this.goToAnalyzing(result.taskId)
    } catch (error) {
      if (error instanceof AppError) {
        this.errorText = `${error.message} (${error.code})`
        logError('Import analyze failed', error.details ?? '', 'ImportPage')
        this.canContinueDemo = true
        return
      }
      this.errorText = '导入失败，请检查网络与服务地址'
      logError('Import analyze failed', JSON.stringify(error), 'ImportPage')
      this.canContinueDemo = true
    } finally {
      this.isSubmitting = false
    }
  }

  async selectLocalFile(): Promise<void> {
    this.errorText = ''
    this.importVM.setSelectedSource('LOCAL_FILE')

    const hostContext = this.getHostContext()
    if (hostContext === undefined) {
      this.errorText = '当前页面上下文不可用，暂时无法拉起文件选择器'
      return
    }

    try {
      const documentPicker = new picker.DocumentViewPicker(hostContext)
      const selectOptions = new picker.DocumentSelectOptions()
      selectOptions.maxSelectNumber = 1
      selectOptions.fileSuffixFilters = [
        '合同文档(.pdf,.docx,.txt,.md,.markdown)|.pdf,.docx,.txt,.md,.markdown',
        '合同图片(.jpg,.jpeg,.png,.webp,.heic)|.jpg,.jpeg,.png,.webp,.heic'
      ]

      const selectedUris = await documentPicker.select(selectOptions)
      if (selectedUris.length === 0) {
        return
      }

      const meta = this.fileImportService.parseFile(selectedUris[0])
      const selectedFileType = meta.extension.length > 0 ? meta.extension : `${meta.fileType}`.toLowerCase()
      this.fileUri = meta.fileUri
      this.fileName = meta.fileName
      this.importVM.setSelectedFile(meta.fileName, selectedFileType, meta.fileUri)
    } catch (error) {
      if (error instanceof AppError) {
        this.errorText = `${error.message} (${error.code})`
        return
      }

      const businessError = error as BusinessError
      logError(
        'Open document picker failed',
        `code=${businessError.code}, message=${businessError.message}`,
        'ImportPage'
      )
      this.errorText = '拉起文件选择器失败，请稍后重试或手动填写文件 URI'
    }
  }

  async continueDemo(): Promise<void> {
    this.errorText = ''
    await this.goToAnalyzing(this.buildDemoTaskId())
  }

  async goToAnalyzing(taskId: string): Promise<void> {
    const params: RouteParams = new RouteParams()
    params.taskId = taskId
    params.baseUrl = this.baseUrl
    await goAnalyzing(this.getUIContext(), params)
  }

  buildDemoTaskId(): string {
    return ContractApi.buildMockTaskId()
  }

  getHostContext(): common.UIAbilityContext | undefined {
    const hostContext = this.getUIContext().getHostContext()
    if (hostContext === undefined) {
      return undefined
    }
    return hostContext as common.UIAbilityContext
  }

  async refreshApiKeyNotice(): Promise<void> {
    const hostContext = this.getHostContext()
    if (hostContext === undefined) {
      this.apiKeyNoticeText = '当前页面上下文不可用，暂时无法读取本地 API Key 配置。'
      this.apiKeyNoticeColor = '#C0392B'
      return
    }

    const savedApiKey = await this.userSettingsService.loadApiKey(hostContext)
    if (savedApiKey.length > 0) {
      this.apiKeyNoticeText = '已检测到本地 API Key，提交分析时会自动透传到服务端。'
      this.apiKeyNoticeColor = '#2A8F5B'
      return
    }

    this.apiKeyNoticeText = '尚未检测到本地 API Key，可先前往设置页配置后再做真实模型联调。'
    this.apiKeyNoticeColor = '#A36B00'
  }

  async initializePage(): Promise<void> {
    const hostContext = this.getHostContext()
    if (hostContext !== undefined) {
      const savedBaseUrl = await this.userSettingsService.loadServiceBaseUrl(hostContext, API_BASE_URL)
      const recentContracts = await this.cacheService.loadRecentContracts(hostContext)
      const recentBaseUrl = this.findLatestRealBaseUrl(recentContracts)
      const effectiveBaseUrl = recentBaseUrl.length > 0 ? recentBaseUrl : savedBaseUrl
      if (effectiveBaseUrl !== savedBaseUrl) {
        await this.userSettingsService.saveServiceBaseUrl(hostContext, effectiveBaseUrl)
      }
      this.baseUrl = effectiveBaseUrl
      if (effectiveBaseUrl === API_BASE_URL) {
        this.baseUrlNoticeText = '当前使用默认服务地址。'
        this.baseUrlNoticeColor = '#666666'
      } else {
        this.baseUrlNoticeText = '已自动回填最近一次真实分析成功的服务地址，可直接开始分析。'
        this.baseUrlNoticeColor = '#2A8F5B'
      }
    } else {
      this.baseUrl = API_BASE_URL
      this.baseUrlNoticeText = '当前页面上下文不可用，暂时无法读取已保存的服务地址。'
      this.baseUrlNoticeColor = '#C0392B'
    }
    await this.refreshApiKeyNotice()
  }

  findLatestRealBaseUrl(recentContracts: Contract[]): string {
    for (let i: number = 0; i < recentContracts.length; i++) {
      const contract = recentContracts[i]
      const contractBaseUrl = contract.baseUrl ?? ''
      if (contractBaseUrl.length === 0) {
        continue
      }
      if (ContractApi.isMockTask(contract.taskId)) {
        continue
      }
      return contractBaseUrl
    }
    return ''
  }

  isLoopbackBaseUrl(): boolean {
    return this.baseUrl.indexOf('127.0.0.1') >= 0 || this.baseUrl.indexOf('localhost') >= 0
  }
}
