import { back, goAnalyzing, RouteParams } from '../app/AppRouter'
import { API_BASE_URL } from '../common/constants'
import { AppError } from '../common/errors'
import { logError } from '../common/logger'
import { ImportVM } from '../model/viewmodel/ImportVM'
import { ContractApi } from '../services/api/ContractApi'
import { FileImportService } from '../services/parser/FileImportService'

@Entry
@Component
struct ImportPage {
  @State importVM: ImportVM = new ImportVM()
  @State baseUrl: string = API_BASE_URL
  @State fileUri: string = ''
  @State fileName: string = ''
  @State errorText: string = ''
  @State isSubmitting: boolean = false

  fileImportService: FileImportService = new FileImportService()

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
      Text('后续将在这里接入拍照、图片和文档导入能力。')
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
      }

      Column({ space: 8 }) {
        Text('文件信息')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
        TextInput({ text: this.fileUri, placeholder: '文件 URI / 路径（临时可手动输入）' })
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
              this.fileUri = 'demo.pdf'
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
        Text(this.errorText)
          .fontSize(13)
          .fontColor('#D64B4B')
      }

      Button(this.isSubmitting ? '提交中...' : '开始分析')
        .width('100%')
        .enabled(!this.isSubmitting)
        .onClick(() => {
          this.startAnalyze()
        })

      Text('当前页已实现“选择文件 -> 点击分析”的基础交互；实际文件选择器将在后续继续接入。')
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
    if (this.fileUri.length === 0 && this.fileName.length === 0) {
      this.errorText = '请先填写文件 URI/路径或文件名'
      return
    }

    this.isSubmitting = true
    try {
      const meta = this.fileImportService.parseFile(this.fileUri, this.fileName)
      const uploadRequest = this.fileImportService.buildUploadRequest(meta)
      this.importVM.setSelectedFile(meta.fileName, uploadRequest.fileType, meta.fileUri)

      const api = new ContractApi(this.baseUrl)
      const result = await api.uploadContract(uploadRequest)

      const params: RouteParams = new RouteParams()
      params.taskId = result.taskId
      params.baseUrl = this.baseUrl
      await goAnalyzing(this.getUIContext(), params)
    } catch (error) {
      if (error instanceof AppError) {
        this.errorText = `${error.message} (${error.code})`
        logError('Import analyze failed', error.details ?? '', 'ImportPage')
        return
      }
      this.errorText = '导入失败，请检查网络与服务地址'
      logError('Import analyze failed', JSON.stringify(error), 'ImportPage')
    } finally {
      this.isSubmitting = false
    }
  }
}
