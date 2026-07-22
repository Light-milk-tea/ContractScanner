import { DocType, DocumentScanner, DocumentScannerConfig, FilterId, SaveOption, ShootingMode } from '@kit.VisionKit'

import { back } from '../app/AppRouter'
import { AppError } from '../common/errors'
import { logError, logInfo } from '../common/logger'
import { UiColors, UiFont, UiSpace } from '../common/ui/DesignTokens'
import { GhostButton } from '../components/ActionButtons'
import { LoadingState } from '../components/LoadingState'
import { ContractOcrService } from '../services/ocr/ContractOcrService'
import { PendingScanStore } from '../services/ocr/PendingScanStore'

@Entry
@Component
struct DocumentScanPage {
  @State isRecognizing: boolean = false
  @State statusText: string = '请将纸质合同放入取景框，完成拍摄后自动识别文字。'
  @State errorText: string = ''

  private scannerConfig: DocumentScannerConfig = new DocumentScannerConfig()
  private ocrService: ContractOcrService = new ContractOcrService()
  private handled: boolean = false

  aboutToAppear(): void {
    this.scannerConfig.supportType = [DocType.DOC, DocType.SHEET]
    this.scannerConfig.isGallerySupported = true
    this.scannerConfig.maxShotCount = 3
    this.scannerConfig.defaultFilterId = FilterId.ORIGINAL
    this.scannerConfig.defaultShootingMode = ShootingMode.MANUAL
    this.scannerConfig.isShareable = false
    this.scannerConfig.originalUris = []
  }

  aboutToDisappear(): void {
    void this.ocrService.release()
  }

  build() {
    Column() {
      if (this.isRecognizing) {
        Column({ space: UiSpace.LG }) {
          LoadingState({
            title: '正在识别文字',
            description: '已完成文档扫描，正在提取合同正文…'
          })
          Text(this.statusText)
            .fontSize(UiFont.BODY_SMALL)
            .fontColor(UiColors.TEXT_SECONDARY)
            .width('100%')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .padding(UiSpace.XXL)
      } else {
        Column() {
          Row() {
            Text('文档扫描')
              .fontSize(UiFont.SECTION_TITLE)
              .fontWeight(FontWeight.Bold)
              .fontColor(UiColors.TEXT_PRIMARY)
              .layoutWeight(1)
            GhostButton({
              label: '取消',
              onTap: () => {
                back(this.getUIContext())
              }
            })
          }
          .width('100%')
          .padding({
            left: UiSpace.LG,
            right: UiSpace.LG,
            top: UiSpace.MD,
            bottom: UiSpace.SM
          })

          if (this.errorText.length > 0) {
            Text(this.errorText)
              .fontSize(UiFont.CAPTION)
              .fontColor(UiColors.DANGER)
              .width('100%')
              .padding({
                left: UiSpace.LG,
                right: UiSpace.LG,
                bottom: UiSpace.SM
              })
          }

          DocumentScanner({
            scannerConfig: this.scannerConfig,
            onResult: (code: number, saveType: SaveOption, uris: string[]) => {
              void this.handleScanResult(code, saveType, uris)
            }
          })
            .width('100%')
            .layoutWeight(1)
        }
        .width('100%')
        .height('100%')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(UiColors.PAGE_BACKGROUND)
  }

  async handleScanResult(code: number, saveType: SaveOption, uris: string[]): Promise<void> {
    if (this.handled) {
      return
    }
    this.handled = true
    logInfo(`Document scan result: code=${code}, saveType=${saveType}, uris=${uris.length}`, 'DocumentScanPage')

    if (uris.length === 0) {
      this.handled = false
      this.errorText = '未获得扫描图片，请重试或取消返回。'
      return
    }

    this.isRecognizing = true
    this.errorText = ''
    this.statusText = `正在识别 ${uris.length} 页扫描结果…`

    try {
      const textContent = await this.ocrService.recognizeTextFromUris(uris)
      PendingScanStore.setPending({
        fileName: `扫描合同_${uris.length}页.jpg`,
        textContent: textContent
      })
      logInfo(`Document scan OCR ready, length=${textContent.length}`, 'DocumentScanPage')
      back(this.getUIContext())
    } catch (error) {
      this.isRecognizing = false
      this.handled = false
      if (error instanceof AppError) {
        this.errorText = `${error.message} (${error.code})`
        logError('Document scan OCR failed', error.details ?? '', 'DocumentScanPage')
        return
      }
      this.errorText = '识别失败，请重拍或换清晰图片'
      logError('Document scan OCR failed', JSON.stringify(error), 'DocumentScanPage')
    }
  }
}
