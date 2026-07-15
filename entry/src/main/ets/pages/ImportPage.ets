import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { picker } from '@kit.CoreFileKit'

import { back, goAnalyzing, RouteParams } from '../app/AppRouter'
import { API_BASE_URL } from '../common/constants'
import { AppError } from '../common/errors'
import { logError, logInfo } from '../common/logger'
import { UiColors, UiRadius, UiSpace } from '../common/ui/DesignTokens'
import { EmptyState, EmptyStateType } from '../components/EmptyState'
import { LoadingState } from '../components/LoadingState'
import { PageScaffold } from '../components/PageScaffold'
import { SectionHeader } from '../components/SectionHeader'
import { SurfaceCard } from '../components/SurfaceCard'
import { Contract } from '../model/domain/Contract'
import { DemoFaultMode, DemoSamplePreset } from '../model/enums/DemoMode'
import { ImportVM } from '../model/viewmodel/ImportVM'
import { ContractApi } from '../services/api/ContractApi'
import { MockContractService } from '../services/mock/MockContractService'
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
  @State selectedDemoPreset: DemoSamplePreset = DemoSamplePreset.NONE
  @State demoFaultMode: DemoFaultMode = DemoFaultMode.NONE
  @State demoModeNoticeText: string = '当前未启用异常演示模式。'
  @State demoModeNoticeColor: string = '#666666'

  fileImportService: FileImportService = new FileImportService()
  cacheService: CacheService = new CacheService()
  userSettingsService: UserSettingsService = new UserSettingsService()

  aboutToAppear(): void {
    this.initializePage()
  }

  build() {
    Column() {
      PageScaffold({
        title: '导入合同',
        description: '支持导入真实合同，也支持在文件区直接选择演示样例。服务地址请前往用户设置维护，当前已接入本地文件选择，拍照和相册导入将在后续补齐。',
        backText: '返回首页',
        onBack: () => {
          back(this.getUIContext())
        }
      }) {
        Column({ space: UiSpace.LG }) {
        SurfaceCard() {
          Column({ space: UiSpace.MD }) {
            SectionHeader({
              title: '导入方式',
              description: '先选择合同来源，再继续选择文件；服务地址由用户设置统一管理。'
            })
            Row({ space: UiSpace.SM }) {
              Button('拍照')
                .type(ButtonType.Capsule)
                .enabled(!this.isSubmitting)
                .backgroundColor(this.importVM.selectedSource === 'CAMERA' ? UiColors.BRAND : UiColors.SURFACE_SECONDARY)
                .fontColor(this.importVM.selectedSource === 'CAMERA' ? '#FFFFFF' : UiColors.TEXT_PRIMARY)
                .onClick(() => {
                  this.importVM.setSelectedSource('CAMERA')
                })
              Button('相册')
                .type(ButtonType.Capsule)
                .enabled(!this.isSubmitting)
                .backgroundColor(this.importVM.selectedSource === 'GALLERY' ? UiColors.BRAND : UiColors.SURFACE_SECONDARY)
                .fontColor(this.importVM.selectedSource === 'GALLERY' ? '#FFFFFF' : UiColors.TEXT_PRIMARY)
                .onClick(() => {
                  this.importVM.setSelectedSource('GALLERY')
                })
              Button('本地文件')
                .type(ButtonType.Capsule)
                .enabled(!this.isSubmitting)
                .backgroundColor(this.importVM.selectedSource === 'LOCAL_FILE' ? UiColors.BRAND : UiColors.SURFACE_SECONDARY)
                .fontColor(this.importVM.selectedSource === 'LOCAL_FILE' ? '#FFFFFF' : UiColors.TEXT_PRIMARY)
                .onClick(() => {
                  this.importVM.setSelectedSource('LOCAL_FILE')
                })
            }
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
        }

        SurfaceCard() {
          Column({ space: UiSpace.MD }) {
            SectionHeader({
              title: '文件信息',
              description: '支持 pdf、docx、txt、md、jpg、png 等常见合同文件；也可在这里直接选择高风险或低风险演示样例。'
            })
            Text(`当前服务地址：${this.baseUrl}`)
              .fontSize(12)
              .fontColor(UiColors.TEXT_SECONDARY)
            Text(this.baseUrlNoticeText)
              .fontSize(12)
              .fontColor(this.baseUrlNoticeColor)
            Text(this.apiKeyNoticeText)
              .fontSize(12)
              .fontColor(this.apiKeyNoticeColor)
            Row({ space: UiSpace.SM }) {
              Button('选择文件')
                .type(ButtonType.Capsule)
                .enabled(!this.isSubmitting)
                .backgroundColor(UiColors.BRAND)
                .fontColor('#FFFFFF')
                .onClick(() => {
                  this.selectLocalFile()
                })
              Button('高风险样例')
                .type(ButtonType.Capsule)
                .enabled(!this.isSubmitting)
                .backgroundColor(this.selectedDemoPreset === DemoSamplePreset.HIGH_RISK ? UiColors.BRAND : UiColors.SURFACE_SECONDARY)
                .fontColor(this.selectedDemoPreset === DemoSamplePreset.HIGH_RISK ? '#FFFFFF' : UiColors.TEXT_PRIMARY)
                .onClick(() => {
                  this.applyDemoSample(DemoSamplePreset.HIGH_RISK)
                })
              Button('低风险样例')
                .type(ButtonType.Capsule)
                .enabled(!this.isSubmitting)
                .backgroundColor(this.selectedDemoPreset === DemoSamplePreset.LOW_RISK ? UiColors.BRAND : UiColors.SURFACE_SECONDARY)
                .fontColor(this.selectedDemoPreset === DemoSamplePreset.LOW_RISK ? '#FFFFFF' : UiColors.TEXT_PRIMARY)
                .onClick(() => {
                  this.applyDemoSample(DemoSamplePreset.LOW_RISK)
                })
              Button('清空')
                .type(ButtonType.Capsule)
                .enabled(!this.isSubmitting)
                .backgroundColor(UiColors.SURFACE_SECONDARY)
                .fontColor(UiColors.TEXT_PRIMARY)
                .onClick(() => {
                  this.fileUri = ''
                  this.fileName = ''
                  this.selectedDemoPreset = DemoSamplePreset.NONE
                  this.importVM.reset()
                  this.errorText = ''
                })
            }

            TextInput({ text: this.fileUri, placeholder: '文件 URI / 路径（未选择时可手动输入）' })
              .width('100%')
              .enabled(!this.isSubmitting)
              .backgroundColor(UiColors.SURFACE_MUTED)
              .borderRadius(UiRadius.MEDIUM)
              .onChange((value: string) => {
                this.fileUri = value
                this.selectedDemoPreset = DemoSamplePreset.NONE
              })
            TextInput({ text: this.fileName, placeholder: '文件名（可选）' })
              .width('100%')
              .enabled(!this.isSubmitting)
              .backgroundColor(UiColors.SURFACE_MUTED)
              .borderRadius(UiRadius.MEDIUM)
              .onChange((value: string) => {
                this.fileName = value
                this.selectedDemoPreset = DemoSamplePreset.NONE
              })

            if (this.importVM.selectedFileName.length > 0) {
              Text(`已选择：${this.importVM.selectedFileName} (${this.importVM.selectedFileType})`)
                .fontSize(13)
                .fontColor(UiColors.TEXT_SECONDARY)
            }
            Text(this.demoSampleHint())
              .fontSize(12)
              .fontColor(UiColors.TEXT_SECONDARY)
            Text(this.demoModeNoticeText)
              .fontSize(12)
              .fontColor(this.demoModeNoticeColor)
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
        }

        if (this.isSubmitting) {
          LoadingState({
            title: '正在提交分析任务',
            description: '我们正在校验文件信息并向服务端创建分析任务。',
            detail: '提交成功后会自动进入“分析中”页面。'
          })
        }

        if (this.errorText.length > 0) {
          SurfaceCard({
            surfaceColor: '#FFF8F7',
            strokeColor: '#F2D6D2'
          }) {
            Column({ space: UiSpace.MD }) {
              EmptyState({
                title: '导入失败',
                description: this.errorText,
                hint: this.canContinueDemo ? '可修正服务地址后重试，或继续进入临时 Mock 演示任务。' : '请修正输入信息后重试。',
                stateType: EmptyStateType.ERROR
              })
              Row({ space: UiSpace.SM }) {
                Button('重试上传')
                  .type(ButtonType.Capsule)
                  .enabled(!this.isSubmitting)
                  .backgroundColor(UiColors.BRAND)
                  .fontColor('#FFFFFF')
                  .onClick(() => {
                    this.startAnalyze()
                  })
                if (this.canContinueDemo) {
                  Button('继续演示')
                    .type(ButtonType.Capsule)
                    .backgroundColor(UiColors.SURFACE_SECONDARY)
                    .fontColor(UiColors.TEXT_PRIMARY)
                    .onClick(() => {
                      this.continueDemo()
                    })
                }
              }
            }
            .width('100%')
          }
        }

        SurfaceCard({
          surfaceColor: UiColors.SURFACE_ACCENT,
          strokeColor: UiColors.BRAND_SOFT
        }) {
          Column({ space: UiSpace.MD }) {
            Button(this.isSubmitting ? '提交中...' : '开始分析')
              .width('100%')
              .enabled(!this.isSubmitting)
              .backgroundColor(UiColors.BRAND)
              .fontColor('#FFFFFF')
              .onClick(() => {
                this.startAnalyze()
              })

            if (this.selectedDemoPreset !== DemoSamplePreset.NONE) {
              Button('直接演示当前样例')
                .width('100%')
                .type(ButtonType.Capsule)
                .backgroundColor(UiColors.SURFACE_SECONDARY)
                .fontColor(UiColors.TEXT_PRIMARY)
                .enabled(!this.isSubmitting)
                .onClick(() => {
                  this.startDemoPreview()
                })
            }
          }
          .width('100%')
        }

        Text('文本文件会自动读取正文并转为可分析内容；如需快速调试，也可在文件 URI 中填入 `inline://合同正文`。')
          .fontSize(13)
          .fontColor(UiColors.TEXT_TERTIARY)
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
      }
    }
    .width('100%')
    .height('100%')
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
      logInfo(
        `Start analyze: file=${this.fileName}, source=${this.importVM.selectedSource}, preset=${this.selectedOrDefaultDemoPreset()}, faultMode=${this.demoFaultMode}, baseUrl=${this.baseUrl}`,
        'ImportPage'
      )
      const meta = this.fileImportService.parseFile(this.fileUri, this.fileName)
      const uploadRequest = this.fileImportService.buildUploadRequest(meta, this.selectedBusinessTag())
      uploadRequest.debugMode = this.demoFaultMode
      if (this.fileImportService.isTextFile(meta) && !this.fileImportService.isInlineTextUri(meta.fileUri)) {
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
      logInfo(`Analyze task created: taskId=${result.taskId}`, 'ImportPage')
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
      this.selectedDemoPreset = DemoSamplePreset.NONE
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
    logInfo(
      `Continue with fallback demo: preset=${this.selectedOrDefaultDemoPreset()}, faultMode=${this.fallbackPreviewFaultMode()}`,
      'ImportPage'
    )
    await this.goToAnalyzing(this.buildDemoTaskId(this.fallbackPreviewFaultMode()))
  }

  async startDemoPreview(): Promise<void> {
    this.errorText = ''
    logInfo(
      `Open direct demo preview: preset=${this.selectedOrDefaultDemoPreset()}, faultMode=${this.previewFaultMode()}`,
      'ImportPage'
    )
    await this.goToAnalyzing(this.buildDemoTaskId(this.previewFaultMode()))
  }

  async goToAnalyzing(taskId: string): Promise<void> {
    const params: RouteParams = new RouteParams()
    params.taskId = taskId
    params.baseUrl = this.baseUrl
    await goAnalyzing(this.getUIContext(), params)
  }

  buildDemoTaskId(faultMode: DemoFaultMode): string {
    return ContractApi.buildMockTaskId(this.selectedOrDefaultDemoPreset(), faultMode)
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
      this.demoFaultMode = await this.userSettingsService.loadDemoFaultMode(hostContext)
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
      this.demoFaultMode = DemoFaultMode.NONE
    }
    this.refreshDemoModeNotice()
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

  applyDemoSample(preset: DemoSamplePreset): void {
    const sample = MockContractService.getDemoSample(preset)
    this.selectedDemoPreset = sample.preset
    this.fileUri = sample.inlineText
    this.fileName = sample.fileName
    this.errorText = ''
    logInfo(`Apply demo sample: preset=${sample.preset}, fileName=${sample.fileName}`, 'ImportPage')
  }

  selectedBusinessTag(): string | undefined {
    if (this.selectedDemoPreset === DemoSamplePreset.NONE) {
      return undefined
    }
    return this.selectedDemoPreset
  }

  selectedOrDefaultDemoPreset(): DemoSamplePreset {
    return this.selectedDemoPreset === DemoSamplePreset.NONE ? DemoSamplePreset.HIGH_RISK : this.selectedDemoPreset
  }

  previewFaultMode(): DemoFaultMode {
    if (this.demoFaultMode === DemoFaultMode.SERVICE_ERROR) {
      return DemoFaultMode.NONE
    }
    return this.demoFaultMode
  }

  fallbackPreviewFaultMode(): DemoFaultMode {
    if (this.demoFaultMode === DemoFaultMode.SERVICE_ERROR) {
      return DemoFaultMode.DEGRADE_TO_DEMO
    }
    return this.previewFaultMode()
  }

  refreshDemoModeNotice(): void {
    if (this.demoFaultMode === DemoFaultMode.WEAK_NETWORK) {
      this.demoModeNoticeText = '当前已开启弱网演示模式：提交后会走本地慢速状态流转。'
      this.demoModeNoticeColor = '#A36B00'
      return
    }
    if (this.demoFaultMode === DemoFaultMode.TIMEOUT) {
      this.demoModeNoticeText = '当前已开启超时演示模式：提交后会在分析阶段模拟超时失败。'
      this.demoModeNoticeColor = '#C0392B'
      return
    }
    if (this.demoFaultMode === DemoFaultMode.SERVICE_ERROR) {
      this.demoModeNoticeText = '当前已开启服务失败演示模式：点击“开始分析”会直接出现失败提示。'
      this.demoModeNoticeColor = '#C0392B'
      return
    }
    if (this.demoFaultMode === DemoFaultMode.DEGRADE_TO_DEMO) {
      this.demoModeNoticeText = '当前已开启降级展示模式：提交后会直接进入本地演示结果。'
      this.demoModeNoticeColor = '#2E6BE6'
      return
    }
    this.demoModeNoticeText = '当前未启用异常演示模式。'
    this.demoModeNoticeColor = '#666666'
  }

  demoSampleHint(): string {
    if (this.selectedDemoPreset === DemoSamplePreset.LOW_RISK) {
      return '当前已选择低风险样例：适合演示“整体可签，但建议补充细节”的结果。'
    }
    if (this.selectedDemoPreset === DemoSamplePreset.HIGH_RISK) {
      return '当前已选择高风险样例：适合演示自动续约、押金退还不明等高风险问题。'
    }
    return '未选择样例时，仍可导入真实文件；选择样例后也可直接进入本地演示链路。'
  }
}
