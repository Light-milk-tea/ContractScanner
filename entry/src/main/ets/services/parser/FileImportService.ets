import { AppError, ErrorCode } from '../../common/errors'

import { UploadContractRequest } from '../api/ContractApi'

export enum ImportFileType {
  IMAGE = 'IMAGE',
  PDF = 'PDF',
  DOCX = 'DOCX',
  UNKNOWN = 'UNKNOWN'
}

export interface ImportedFileMeta {
  fileUri: string
  fileName: string
  extension: string
  fileType: ImportFileType
}

export class FileImportService {
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

  private assertSupported(meta: ImportedFileMeta): void {
    if (meta.fileType !== ImportFileType.UNKNOWN) {
      return
    }
    throw new AppError(ErrorCode.IMPORT_001, '文件格式不支持', `${meta.fileName} (${meta.fileUri})`)
  }

  private resolveFileName(fileUri: string, fileName?: string): string {
    if (fileName !== undefined && fileName.length > 0) {
      return fileName
    }

    const cleanedUri = this.stripQuery(fileUri)
    const slashIndex = cleanedUri.lastIndexOf('/')
    if (slashIndex >= 0 && slashIndex < cleanedUri.length - 1) {
      return cleanedUri.substring(slashIndex + 1)
    }

    return cleanedUri.length > 0 ? cleanedUri : 'unknown'
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

    return ImportFileType.UNKNOWN
  }

  private stripQuery(uri: string): string {
    const qIndex = uri.indexOf('?')
    if (qIndex < 0) {
      return uri
    }
    return uri.substring(0, qIndex)
  }
}

