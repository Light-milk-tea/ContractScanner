import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { picker } from '@kit.CoreFileKit'
import { photoAccessHelper } from '@kit.MediaLibraryKit'

import { back, goAnalyzing, RouteParams } from '../app/AppRouter'
import {
  API_BASE_URL,
  isEmulatorRuntime,
  networkFailureHint,
  resolveDefaultApiBaseUrl,
  resolveEffectiveApiBaseUrl
} from '../common/constants'
import { AppError } from '../common/errors'
import { logError, logInfo } from '../common/logger'
import { isCompactLayout } from '../common/ui/LayoutHelpers'
import { UiColors, UiFont, UiRadius, UiSpace } from '../common/ui/DesignTokens'
import { GhostButton, PrimaryButton, SegmentChip } from '../components/ActionButtons'
import { EmptyState, EmptyStateType } from '../components/EmptyState'
import { LoadingState } from '../components/LoadingState'
import { PageScaffold } from '../components/PageScaffold'
import { SectionHeader } from '../components/SectionHeader'
import { SurfaceCard } from '../components/SurfaceCard'
import { Contract } from '../model/domain/Contract'
import { DemoFaultMode, DemoSamplePreset } from '../model/enums/DemoMode'
import { ImportVM } from '../model/viewmodel/ImportVM'
import { ContractApi } from '../services/api/ContractApi'
import { ServiceHealthProbe } from '../services/api/ServiceHealthProbe'
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
  @State apiKeyNoticeColor: string = UiColors.TEXT_SECONDARY
  @State baseUrlNoticeText: string = '当前使用默认服务地址。'
  @State baseUrlNoticeColor: string = UiColors.TEXT_SECONDARY
  @State selectedDemoPreset: DemoSamplePreset = DemoSamplePreset.NONE
  @State demoFaultMode: DemoFaultMode = DemoFaultMode.NONE
  @State demoModeNoticeText: string = '当前未启用异常演示模式。'
  @State demoModeNoticeColor: string = UiColors.TEXT_SECONDARY
  @State showMoreImportOptions: boolean = false

  fileImportService: FileImportService = new FileImportService()
  serviceHealthProbe: ServiceHealthProbe = new ServiceHealthProbe()
  cacheService: CacheService = new CacheService()
  userSettingsService: UserSettingsService = new UserSettingsService()

  aboutToAppear(): void {
    this.initializePage()
  }

  build() {
    Column() {
      PageScaffold({
        title: '导入合同',
        description: '选择来源或演示样例，即可开始分析。',
        backText: '返回首页',
        onBack: () => {
          back(this.getUIContext())
        }
      }) {
        Column({ space: isCompactLayout() ? UiSpace.MD : UiSpace.LG }) {
        SurfaceCard({ tone: 'soft' }) {
          Column({ space: UiSpace.MD }) {
            SectionHeader({
              title: '导入方式',
              description: '先选择合同来源，再通过下方按钮导入。',
              alignCenter: false
            })
            Flex({
              wrap: FlexWrap.Wrap,
              justifyContent: FlexAlign.Start,
              alignItems: ItemAlign.Center
            }) {
              Row() {
                SegmentChip({
                  label: '拍照',
                  selected: this.importVM.selectedSource === 'CAMERA',
                  isEnabled: !this.isSubmitting,
                  onTap: () => {
                    this.handleSourceSelection('CAMERA')
                  }
                })
              }
              .margin({ right: UiSpace.SM, bottom: UiSpace.SM })

              Row() {
                SegmentChip({
                  label: '相册',
                  selected: this.importVM.selectedSource === 'GALLERY',
                  isEnabled: !this.isSubmitting,
                  onTap: () => {
                    this.handleSourceSelection('GALLERY')
                  }
                })
              }
              .margin({ right: UiSpace.SM, bottom: UiSpace.SM })

              Row() {
                SegmentChip({
                  label: '本地文件',
                  selected: this.importVM.selectedSource === 'LOCAL_FILE',
                  isEnabled: !this.isSubmitting,
                  onTap: () => {
                    this.handleSourceSelection('LOCAL_FILE')
                  }
                })
              }
              .margin({ right: UiSpace.SM, bottom: UiSpace.SM })
            }
            .width('100%')
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
        }

        SurfaceCard({ tone: 'soft' }) {
          Column({ space: UiSpace.MD }) {
            SectionHeader({
              title: '选择文件',
              description: this.importActionDescription(),
              alignCenter: false
            })

            PrimaryButton({
              label: this.importActionLabel(),
              isEnabled: !this.isSubmitting,
              fillWidth: true,
              onTap: () => {
                void this.openSelectedSourcePicker()
              }
            })

            GhostButton({
              label: this.showMoreImportOptions ? '收起' : '更多导入选项',
              isEnabled: !this.isSubmitting,
              fillWidth: true,
              onTap: () => {
                this.showMoreImportOptions = !this.showMoreImportOptions
              }
            })

            if (this.showMoreImportOptions) {
              Column({ space: UiSpace.MD }) {
                Column({ space: UiSpace.SM }) {
                  Text('演示样例')
                    .fontSize(UiFont.CAPTION)
                    .fontColor(UiColors.TEXT_TERTIARY)
                  Flex({
                    wrap: FlexWrap.Wrap,
                    justifyContent: FlexAlign.Start,
                    alignItems: ItemAlign.Center
                  }) {
                    Row() {
                      SegmentChip({
                        label: '高风险样例',
                        selected: this.selectedDemoPreset === DemoSamplePreset.HIGH_RISK,
                        isEnabled: !this.isSubmitting,
                        onTap: () => {
                          this.applyDemoSample(DemoSamplePreset.HIGH_RISK)
                        }
                      })
                    }
                    .margin({ right: UiSpace.SM, bottom: UiSpace.SM })

                    Row() {
                      SegmentChip({
                        label: '低风险样例',
                        selected: this.selectedDemoPreset === DemoSamplePreset.LOW_RISK,
                        isEnabled: !this.isSubmitting,
                        onTap: () => {
                          this.applyDemoSample(DemoSamplePreset.LOW_RISK)
                        }
                      })
                    }
                    .margin({ right: UiSpace.SM, bottom: UiSpace.SM })

                    Row() {
                      GhostButton({
                        label: '清空',
                        isEnabled: !this.isSubmitting,
                        onTap: () => {
                          this.fileUri = ''
                          this.fileName = ''
                          this.selectedDemoPreset = DemoSamplePreset.NONE
                          this.importVM.reset()
                          this.errorText = ''
                        }
                      })
                    }
                    .margin({ right: UiSpace.SM, bottom: UiSpace.SM })
                  }
                  .width('100%')
                }
                .alignItems(HorizontalAlign.Start)
                .width('100%')

                TextInput({ text: this.fileUri, placeholder: '文件 URI / 路径（可选）' })
                  .width('100%')
                  .height(44)
                  .enabled(!this.isSubmitting)
                  .backgroundColor(UiColors.SURFACE_MUTED)
                  .borderRadius(UiRadius.MEDIUM)
                  .padding({ left: UiSpace.MD, right: UiSpace.MD })
                  .onChange((value: string) => {
                    this.fileUri = value
                    this.selectedDemoPreset = DemoSamplePreset.NONE
                  })
                TextInput({ text: this.fileName, placeholder: '文件名（可选）' })
                  .width('100%')
                  .height(44)
                  .enabled(!this.isSubmitting)
                  .backgroundColor(UiColors.SURFACE_MUTED)
                  .borderRadius(UiRadius.MEDIUM)
                  .padding({ left: UiSpace.MD, right: UiSpace.MD })
                  .onChange((value: string) => {
                    this.fileName = value
                    this.selectedDemoPreset = DemoSamplePreset.NONE
                  })
              }
              .alignItems(HorizontalAlign.Start)
              .width('100%')
            }

            if (this.importVM.selectedFileName.length > 0) {
              SurfaceCard({
                tone: 'inset',
                paddingValue: UiSpace.MD,
                radius: UiRadius.MEDIUM
              }) {
                Text(`已选择：${this.importVM.selectedFileName} (${this.importVM.selectedFileType})`)
                  .fontSize(UiFont.BODY_SMALL)
                  .fontColor(UiColors.TEXT_SECONDARY)
              }
            }

            if (this.demoSampleHint().length > 0) {
              Text(this.demoSampleHint())
                .fontSize(UiFont.CAPTION)
                .fontColor(UiColors.TEXT_SECONDARY)
            }
            if (this.demoFaultMode !== DemoFaultMode.NONE) {
              Text(this.demoModeNoticeText)
                .fontSize(UiFont.CAPTION)
                .fontColor(this.demoModeNoticeColor)
            }
            Text(`服务：${this.baseUrl}`)
              .fontSize(UiFont.CAPTION)
              .fontColor(UiColors.TEXT_TERTIARY)
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
        }

        if (this.isSubmitting) {
          LoadingState({
            title: '正在提交分析任务',
            description: '正在校验文件并向服务端创建任务。'
          })
        }

        if (this.errorText.length > 0) {
          Column({ space: UiSpace.MD }) {
            EmptyState({
              title: '导入失败',
              description: this.errorText,
              hint: this.canContinueDemo ? '可修正后重试，或继续进入演示任务。' : '请修正输入信息后重试。',
              stateType: EmptyStateType.ERROR
            })
            Row({ space: UiSpace.SM }) {
              PrimaryButton({
                label: '重试上传',
                isEnabled: !this.isSubmitting,
                onTap: () => {
                  this.startAnalyze()
                }
              })
              if (this.canContinueDemo) {
                GhostButton({
                  label: '继续演示',
                  onTap: () => {
                    this.continueDemo()
                  }
                })
              }
            }
          }
          .width('100%')
        }

        Column({ space: UiSpace.MD }) {
          PrimaryButton({
            label: this.isSubmitting ? '提交中...' : '开始分析',
            isEnabled: !this.isSubmitting,
            fillWidth: true,
            onTap: () => {
              this.startAnalyze()
            }
          })

          if (this.selectedDemoPreset !== DemoSamplePreset.NONE) {
            GhostButton({
              label: '直接演示当前样例',
              isEnabled: !this.isSubmitting,
              fillWidth: true,
              onTap: () => {
                this.startDemoPreview()
              }
            })
          }
        }
        .width('100%')
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
      const reachable = await this.ensureReachableServiceBaseUrl()
      if (!reachable) {
        this.canContinueDemo = true
        return
      }

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
        const hint = networkFailureHint(error.details)
        this.errorText = `${error.message} (${error.code})。${hint}`
        logError('Import analyze failed', error.details ?? '', 'ImportPage')
        this.canContinueDemo = true
        return
      }
      this.errorText = `导入失败，请检查网络与服务地址。${networkFailureHint()}`
      logError('Import analyze failed', JSON.stringify(error), 'ImportPage')
      this.canContinueDemo = true
    } finally {
      this.isSubmitting = false
    }
  }

  async ensureReachableServiceBaseUrl(): Promise<boolean> {
    this.baseUrlNoticeText = '正在自动检测可用服务地址...'
    this.baseUrlNoticeColor = UiColors.TEXT_SECONDARY
    const probeResult = await this.serviceHealthProbe.findReachableBaseUrl(this.baseUrl)
    if (!probeResult.ok) {
      this.errorText = probeResult.message
      this.baseUrlNoticeText = '未检测到可用服务地址，请检查后端与模拟器代理。'
      this.baseUrlNoticeColor = '#C0392B'
      return false
    }

    this.baseUrl = probeResult.baseUrl
    this.baseUrlNoticeText = probeResult.message
    this.baseUrlNoticeColor = '#2A8F5B'
    const hostContext = this.getHostContext()
    if (hostContext !== undefined) {
      await this.userSettingsService.saveServiceBaseUrl(hostContext, probeResult.baseUrl)
    }
    return true
  }

  handleSourceSelection(source: string): void {
    this.importVM.setSelectedSource(source)
    this.errorText = ''
  }

  async openSelectedSourcePicker(): Promise<void> {
    if (this.importVM.selectedSource === 'CAMERA') {
      await this.selectPhotoFromPicker(true, '拍照合同.jpg')
      return
    }
    if (this.importVM.selectedSource === 'GALLERY') {
      await this.selectPhotoFromPicker(false, '相册合同.jpg')
      return
    }
    await this.selectLocalFile()
  }

  importActionLabel(): string {
    if (this.importVM.selectedSource === 'CAMERA') {
      return '拍照'
    }
    if (this.importVM.selectedSource === 'GALLERY') {
      return '从相册选择'
    }
    return '选择本地文件'
  }

  importActionDescription(): string {
    if (this.importVM.selectedSource === 'CAMERA') {
      return '拍摄合同照片，支持常见图片格式。'
    }
    if (this.importVM.selectedSource === 'GALLERY') {
      return '从相册选择合同图片。'
    }
    return '支持 PDF、DOCX、文本及常见图片格式。'
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

  async selectPhotoFromPicker(isPhotoTakingSupported: boolean, fallbackFileName: string): Promise<void> {
    this.errorText = ''
    this.importVM.setSelectedSource(isPhotoTakingSupported ? 'CAMERA' : 'GALLERY')

    try {
      const photoSelectOptions = new photoAccessHelper.PhotoSelectOptions()
      photoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE
      photoSelectOptions.maxSelectNumber = 1
      photoSelectOptions.isPhotoTakingSupported = isPhotoTakingSupported

      const photoPicker = new photoAccessHelper.PhotoViewPicker()
      const photoSelectResult = await photoPicker.select(photoSelectOptions)
      if (photoSelectResult.photoUris.length === 0) {
        return
      }

      const selectedUri = photoSelectResult.photoUris[0]
      const selectedFileName = this.resolveMediaFileName(selectedUri, fallbackFileName)
      const meta = this.fileImportService.parseFile(selectedUri, selectedFileName)
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
        'Open photo picker failed',
        `code=${businessError.code}, message=${businessError.message}`,
        'ImportPage'
      )
      this.errorText = isPhotoTakingSupported
        ? '拉起拍照入口失败，请稍后重试或改用本地文件导入'
        : '拉起相册选择器失败，请稍后重试或改用本地文件导入'
    }
  }

  resolveMediaFileName(fileUri: string, fallbackFileName: string): string {
    const decodedUri = this.decodeUriSafely(fileUri)
    const cleanedUri = this.stripQueryString(decodedUri)
    const slashIndex = cleanedUri.lastIndexOf('/')
    const candidateName = slashIndex >= 0 ? cleanedUri.substring(slashIndex + 1) : cleanedUri
    if (candidateName.length === 0) {
      return fallbackFileName
    }

    const dotIndex = candidateName.lastIndexOf('.')
    if (dotIndex <= 0 || dotIndex === candidateName.length - 1) {
      return fallbackFileName
    }
    return candidateName
  }

  stripQueryString(uri: string): string {
    const queryIndex = uri.indexOf('?')
    if (queryIndex < 0) {
      return uri
    }
    return uri.substring(0, queryIndex)
  }

  decodeUriSafely(rawUri: string): string {
    if (rawUri.length === 0) {
      return rawUri
    }

    try {
      return decodeURIComponent(rawUri)
    } catch (_error) {
      return rawUri
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
      const defaultBaseUrl = resolveDefaultApiBaseUrl()
      const savedBaseUrl = await this.userSettingsService.loadServiceBaseUrl(hostContext, defaultBaseUrl)
      this.demoFaultMode = await this.userSettingsService.loadDemoFaultMode(hostContext)
      const recentContracts = await this.cacheService.loadRecentContracts(hostContext)
      const rawRecentBaseUrl = this.findLatestRealBaseUrl(recentContracts)
      const recentBaseUrl = rawRecentBaseUrl.length > 0
        ? resolveEffectiveApiBaseUrl(rawRecentBaseUrl)
        : ''
      const effectiveBaseUrl = recentBaseUrl.length > 0 ? recentBaseUrl : savedBaseUrl
      if (effectiveBaseUrl !== savedBaseUrl) {
        await this.userSettingsService.saveServiceBaseUrl(hostContext, effectiveBaseUrl)
      }
      this.baseUrl = effectiveBaseUrl
      if (effectiveBaseUrl === defaultBaseUrl) {
        this.baseUrlNoticeText = isEmulatorRuntime()
          ? '当前使用模拟器自动联网地址；提交时会探测局域网 IP / 10.0.2.2。'
          : '当前使用默认服务地址。'
        this.baseUrlNoticeColor = UiColors.TEXT_SECONDARY
      } else {
        this.baseUrlNoticeText = '已自动回填最近一次真实分析成功的服务地址，可直接开始分析。'
        this.baseUrlNoticeColor = '#2A8F5B'
      }
    } else {
      this.baseUrl = resolveDefaultApiBaseUrl()
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
      this.demoModeNoticeColor = UiColors.BRAND
      return
    }
    this.demoModeNoticeText = '当前未启用异常演示模式。'
    this.demoModeNoticeColor = UiColors.TEXT_SECONDARY
  }

  demoSampleHint(): string {
    if (this.selectedDemoPreset === DemoSamplePreset.LOW_RISK) {
      return '当前已选择低风险样例：适合演示“整体可签，但建议补充细节”的结果。'
    }
    if (this.selectedDemoPreset === DemoSamplePreset.HIGH_RISK) {
      return '当前已选择高风险样例：适合演示自动续约、押金退还不明等高风险问题。'
    }
    return ''
  }
}
