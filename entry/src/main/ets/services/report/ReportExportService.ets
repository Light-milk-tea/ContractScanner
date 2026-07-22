import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { fileIo, picker } from '@kit.CoreFileKit'
import { AppError, ErrorCode } from '../../common/errors'
import { logError, logInfo, logWarn } from '../../common/logger'

export class ReportExportService {
  /**
   * Opens the system document saver and writes a Word-compatible .doc file.
   * Returns the saved URI, or empty string when the user cancels.
   */
  async saveDoc(
    hostContext: common.UIAbilityContext,
    fileName: string,
    content: string
  ): Promise<string> {
    if (content.length === 0) {
      throw new AppError(ErrorCode.RESULT_001, '报告内容为空，无法导出')
    }

    const resolvedName = fileName.trim().length > 0 ? fileName.trim() : '合同-分析报告.doc'
    try {
      const documentPicker = new picker.DocumentViewPicker(hostContext)
      const saveOptions = new picker.DocumentSaveOptions()
      saveOptions.newFileNames = [resolvedName]
      saveOptions.fileSuffixChoices = ['Word 文档|.doc']

      const savedUris = await documentPicker.save(saveOptions)
      if (savedUris.length === 0) {
        logInfo('User cancelled doc report export', 'ReportExportService')
        return ''
      }

      const targetUri = savedUris[0]
      this.writeTextFile(targetUri, content)
      logInfo(`Doc report saved: uri=${targetUri}`, 'ReportExportService')
      return targetUri
    } catch (error) {
      if (error instanceof AppError) {
        throw error
      }
      const businessError = error as BusinessError
      logError(
        'Save doc report failed',
        `code=${businessError.code}, message=${businessError.message}`,
        'ReportExportService'
      )
      throw new AppError(
        ErrorCode.RESULT_001,
        '导出报告失败，请稍后重试',
        `code=${businessError.code}, message=${businessError.message}`
      )
    }
  }

  private writeTextFile(fileUri: string, content: string): void {
    let file: fileIo.File | null = null
    try {
      file = fileIo.openSync(fileUri, fileIo.OpenMode.READ_WRITE)
      fileIo.writeSync(file.fd, content)
    } catch (error) {
      const message = error instanceof Error ? error.message : JSON.stringify(error)
      throw new AppError(ErrorCode.RESULT_001, '写入报告文件失败', `${fileUri} | ${message}`)
    } finally {
      if (file !== null) {
        try {
          fileIo.closeSync(file)
        } catch (closeError) {
          const message = closeError instanceof Error ? closeError.message : JSON.stringify(closeError)
          logWarn(`Close report file failed: ${fileUri} | ${message}`, 'ReportExportService')
        }
      }
    }
  }
}
