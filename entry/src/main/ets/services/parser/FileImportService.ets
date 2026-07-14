import { buffer } from '@kit.ArkTS'
import { fileIo, ReadOptions } from '@kit.CoreFileKit'
import { AppError, ErrorCode } from '../../common/errors'
import { logWarn } from '../../common/logger'
import { UploadContractRequest } from '../api/ContractApi'

export enum ImportFileType {
  IMAGE = 'IMAGE',
  PDF = 'PDF',
  DOCX = 'DOCX',
  TEXT = 'TEXT',
  UNKNOWN = 'UNKNOWN'
}

export interface ImportedFileMeta {
  fileUri: string
  fileName: string
  extension: string
  fileType: ImportFileType
}

export class FileImportService {
  private static readonly TEXT_CHUNK_SIZE: number = 4096

  parseFile(fileUri: string, fileName?: string): ImportedFileMeta {
    const resolvedName = this.resolveFileName(fileUri, fileName)
    const extension = this.extractExtension(resolvedName)
    const fileType = this.inferFileType(extension)

    const meta: ImportedFileMeta = {
      fileUri,
      fileName: resolvedName,
      extension,
      fileType
    }

    this.assertSupported(meta)
    return meta
  }

  buildUploadRequest(meta: ImportedFileMeta, businessTag?: string): UploadContractRequest {
    this.assertSupported(meta)
    const fileType = meta.extension.length > 0 ? meta.extension : `${meta.fileType}`.toLowerCase()

    return {
      fileName: meta.fileName,
      fileType,
      fileUri: meta.fileUri,
      businessTag
    }
  }

  isTextFile(meta: ImportedFileMeta): boolean {
    return meta.fileType === ImportFileType.TEXT
  }

  isInlineTextUri(fileUri: string): boolean {
    return fileUri.indexOf('inline://') === 0
  }

  buildInlineTextUri(textContent: string): string {
    return `inline://${textContent}`
  }

  readTextFile(fileUri: string): string {
    let file: fileIo.File | null = null
    try {
      file = fileIo.openSync(fileUri, fileIo.OpenMode.READ_ONLY)
      let offset: number = 0
      const chunks: string[] = []
      while (true) {
        const arrayBuffer = new ArrayBuffer(FileImportService.TEXT_CHUNK_SIZE)
        const readOptions: ReadOptions = {
          offset: offset,
          length: arrayBuffer.byteLength
        }
        const readLength = fileIo.readSync(file.fd, arrayBuffer, readOptions)
        if (readLength <= 0) {
          break
        }
        chunks.push(buffer.from(arrayBuffer, 0, readLength).toString())
        offset += readLength
      }
      const textContent = chunks.join('').trim()
      if (textContent.length === 0) {
        throw new AppError(ErrorCode.IMPORT_001, '文本文件内容为空', fileUri)
      }
      return textContent
    } catch (error) {
      if (error instanceof AppError) {
        throw error
      }
      const message = error instanceof Error ? error.message : JSON.stringify(error)
      throw new AppError(ErrorCode.IMPORT_001, '读取文本文件失败', `${fileUri} | ${message}`)
    } finally {
      if (file !== null) {
        try {
          fileIo.closeSync(file)
        } catch (error) {
          const message = error instanceof Error ? error.message : JSON.stringify(error)
          logWarn(`Close text file failed: ${fileUri} | ${message}`, 'FileImportService')
        }
      }
    }
  }

  private assertSupported(meta: ImportedFileMeta): void {
    if (meta.fileType !== ImportFileType.UNKNOWN) {
      return
    }
    throw new AppError(ErrorCode.IMPORT_001, '文件格式不支持', `${meta.fileName} (${meta.fileUri})`)
  }

  private resolveFileName(fileUri: string, fileName?: string): string {
    if (fileName !== undefined && fileName.length > 0) {
      return this.decodeFileName(fileName)
    }

    const cleanedUri = this.stripQuery(fileUri)
    const slashIndex = cleanedUri.lastIndexOf('/')
    if (slashIndex >= 0 && slashIndex < cleanedUri.length - 1) {
      return this.decodeFileName(cleanedUri.substring(slashIndex + 1))
    }

    return cleanedUri.length > 0 ? this.decodeFileName(cleanedUri) : 'unknown'
  }

  private extractExtension(fileName: string): string {
    const dotIndex = fileName.lastIndexOf('.')
    if (dotIndex < 0 || dotIndex === fileName.length - 1) {
      return ''
    }

    return fileName.substring(dotIndex + 1).toLowerCase()
  }

  private inferFileType(extension: string): ImportFileType {
    if (extension === 'pdf') {
      return ImportFileType.PDF
    }

    if (extension === 'docx') {
      return ImportFileType.DOCX
    }

    if (extension === 'jpg' || extension === 'jpeg' || extension === 'png' || extension === 'webp' || extension === 'heic') {
      return ImportFileType.IMAGE
    }

    if (extension === 'txt' || extension === 'md' || extension === 'markdown') {
      return ImportFileType.TEXT
    }

    return ImportFileType.UNKNOWN
  }

  private stripQuery(uri: string): string {
    const qIndex = uri.indexOf('?')
    if (qIndex < 0) {
      return uri
    }
    return uri.substring(0, qIndex)
  }

  private decodeFileName(rawFileName: string): string {
    if (rawFileName.length === 0) {
      return rawFileName
    }

    try {
      return decodeURIComponent(rawFileName)
    } catch (_error) {
      return rawFileName
    }
  }
}
