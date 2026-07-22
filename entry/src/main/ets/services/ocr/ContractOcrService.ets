import { image } from '@kit.ImageKit'
import { fileIo } from '@kit.CoreFileKit'
import { textRecognition } from '@kit.CoreVisionKit'
import { BusinessError } from '@kit.BasicServicesKit'

import { AppError, ErrorCode } from '../../common/errors'
import { logError, logInfo } from '../../common/logger'

export class ContractOcrService {
  static readonly MAX_TEXT_LENGTH: number = 20000

  private initialized: boolean = false

  async ensureInitialized(): Promise<void> {
    if (this.initialized) {
      return
    }
    try {
      const initResult = await textRecognition.init()
      this.initialized = initResult === true
      logInfo(`OCR init result=${initResult}`, 'ContractOcrService')
    } catch (error) {
      const message = error instanceof Error ? error.message : JSON.stringify(error)
      throw new AppError(ErrorCode.OCR_001, '文字识别服务初始化失败', message)
    }
  }

  async release(): Promise<void> {
    if (!this.initialized) {
      return
    }
    try {
      await textRecognition.release()
    } catch (error) {
      logError('OCR release failed', JSON.stringify(error), 'ContractOcrService')
    } finally {
      this.initialized = false
    }
  }

  async recognizeTextFromUri(fileUri: string): Promise<string> {
    await this.ensureInitialized()
    const pixelMap = await this.uriToPixelMap(fileUri)
    try {
      const visionInfo: textRecognition.VisionInfo = {
        pixelMap: pixelMap
      }
      const textConfiguration: textRecognition.TextRecognitionConfiguration = {
        isDirectionDetectionSupported: true
      }
      const result = await textRecognition.recognizeText(visionInfo, textConfiguration)
      const recognized = (result.value ?? '').trim()
      if (recognized.length === 0) {
        throw new AppError(ErrorCode.OCR_001, '识别失败，请重拍或换清晰图片', fileUri)
      }
      return this.truncateText(recognized)
    } catch (error) {
      if (error instanceof AppError) {
        throw error
      }
      const businessError = error as BusinessError
      const message = businessError.message ?? (error instanceof Error ? error.message : JSON.stringify(error))
      throw new AppError(ErrorCode.OCR_001, '识别失败，请重拍或换清晰图片', message)
    } finally {
      try {
        await pixelMap.release()
      } catch (_error) {
        // ignore pixelMap release errors
      }
    }
  }

  async recognizeTextFromUris(fileUris: string[]): Promise<string> {
    if (fileUris.length === 0) {
      throw new AppError(ErrorCode.OCR_001, '识别失败，请重拍或换清晰图片', 'empty uris')
    }

    const chunks: string[] = []
    for (let i: number = 0; i < fileUris.length; i++) {
      const text = await this.recognizeTextFromUri(fileUris[i])
      if (text.length > 0) {
        chunks.push(text)
      }
    }
    const joined = chunks.join('\n\n').trim()
    if (joined.length === 0) {
      throw new AppError(ErrorCode.OCR_001, '识别失败，请重拍或换清晰图片', 'all pages empty')
    }
    return this.truncateText(joined)
  }

  truncateText(text: string): string {
    if (text.length <= ContractOcrService.MAX_TEXT_LENGTH) {
      return text
    }
    logInfo(`OCR text truncated from ${text.length} to ${ContractOcrService.MAX_TEXT_LENGTH}`, 'ContractOcrService')
    return `${text.substring(0, ContractOcrService.MAX_TEXT_LENGTH)}\n\n（正文过长，已截断至前 ${ContractOcrService.MAX_TEXT_LENGTH} 字）`
  }

  private async uriToPixelMap(fileUri: string): Promise<image.PixelMap> {
    let file: fileIo.File | null = null
    try {
      file = await fileIo.open(fileUri, fileIo.OpenMode.READ_ONLY)
      const imageSource = image.createImageSource(file.fd)
      const pixelMap = await imageSource.createPixelMap()
      return pixelMap
    } catch (error) {
      const message = error instanceof Error ? error.message : JSON.stringify(error)
      throw new AppError(ErrorCode.OCR_001, '无法读取合同图片', `${fileUri} | ${message}`)
    } finally {
      if (file !== null) {
        try {
          await fileIo.close(file)
        } catch (_error) {
          // ignore close errors
        }
      }
    }
  }
}
