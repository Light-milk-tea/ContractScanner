import { BusinessError } from '@kit.BasicServicesKit'
import { http } from '@kit.NetworkKit'

import { AppError, ErrorCode } from '../../common/errors'
import { logError, logInfo } from '../../common/logger'

export interface RequestHeader {
  Accept?: string
  'Content-Type'?: string
}

export interface HttpRequestOptions {
  path: string
  method: http.RequestMethod
  query?: string
  body?: string
  accept?: string
  contentType?: string
  readTimeout?: number
  connectTimeout?: number
}

export interface HttpResponse {
  statusCode: number
  body: string
}

interface JsonErrorResponse {
  code?: string
  message?: string
}

export class HttpClient {
  private static readonly DEFAULT_READ_TIMEOUT: number = 15000
  private static readonly DEFAULT_CONNECT_TIMEOUT: number = 15000
  private static readonly LOG_TAG: string = 'HttpClient'

  private readonly baseUrl: string
  private readonly defaultAccept: string
  private readonly defaultContentType: string

  constructor(baseUrl: string, defaultAccept: string = 'application/json', defaultContentType: string = 'application/json') {
    this.baseUrl = this.normalizeBaseUrl(baseUrl)
    this.defaultAccept = defaultAccept
    this.defaultContentType = defaultContentType
  }

  async get(path: string): Promise<HttpResponse> {
    return this.request({
      path,
      method: http.RequestMethod.GET
    })
  }

  async post(path: string, body: string): Promise<HttpResponse> {
    return this.request({
      path,
      method: http.RequestMethod.POST,
      body
    })
  }

  async request(options: HttpRequestOptions): Promise<HttpResponse> {
    const requestUrl = this.buildRequestUrl(options.path, options.query)
    const requestHeaders = this.buildHeaders(options.accept, options.contentType)
    const requestTask = http.createHttp()

    try {
      logInfo(`HTTP ${this.requestMethodLabel(options.method)} ${requestUrl}`, HttpClient.LOG_TAG)
      const response = await requestTask.request(requestUrl, {
        method: options.method,
        header: requestHeaders,
        extraData: options.body ?? '',
        expectDataType: http.HttpDataType.STRING,
        readTimeout: options.readTimeout ?? HttpClient.DEFAULT_READ_TIMEOUT,
        connectTimeout: options.connectTimeout ?? HttpClient.DEFAULT_CONNECT_TIMEOUT
      })
      const responseBody = this.readResponseBody(response.result)

      if (response.responseCode < 200 || response.responseCode >= 300) {
        throw this.buildHttpStatusError(response.responseCode, responseBody)
      }

      return {
        statusCode: response.responseCode,
        body: responseBody
      }
    } catch (error) {
      throw this.normalizeError(error, requestUrl)
    } finally {
      requestTask.destroy()
    }
  }

  private normalizeBaseUrl(baseUrl: string): string {
    if (baseUrl.length === 0) {
      return ''
    }

    if (baseUrl.endsWith('/')) {
      return baseUrl.substring(0, baseUrl.length - 1)
    }

    return baseUrl
  }

  private buildRequestUrl(path: string, query?: string): string {
    const normalizedPath = path.startsWith('/') ? path : `/${path}`
    const baseUrl = this.baseUrl.length > 0 ? this.baseUrl : ''

    if (query === undefined || query.length === 0) {
      return `${baseUrl}${normalizedPath}`
    }

    const normalizedQuery = query.startsWith('?') ? query : `?${query}`
    return `${baseUrl}${normalizedPath}${normalizedQuery}`
  }

  private buildHeaders(accept?: string, contentType?: string): RequestHeader {
    const resolvedAccept = accept ?? this.defaultAccept
    const resolvedContentType = contentType ?? this.defaultContentType
    const header: RequestHeader = {
      Accept: resolvedAccept,
      'Content-Type': resolvedContentType
    }
    return header
  }

  private requestMethodLabel(method: http.RequestMethod): string {
    return `${method}`
  }

  private readResponseBody(result: string | Object): string {
    if (typeof result === 'string') {
      return result
    }

    return JSON.stringify(result)
  }

  private buildHttpStatusError(statusCode: number, responseBody: string): AppError {
    const parsedError = this.tryParseErrorResponse(responseBody)
    if (parsedError !== undefined) {
      const code = parsedError.code ?? ErrorCode.SYS_500
      const message = parsedError.message ?? '网络请求失败'
      const detailsFromPayload = `status=${statusCode}, body=${responseBody}`
      return new AppError(code, message, detailsFromPayload)
    }

    const details = `status=${statusCode}, body=${responseBody}`
    return new AppError(ErrorCode.SYS_500, '网络请求失败', details)
  }

  private tryParseErrorResponse(responseBody: string): JsonErrorResponse | undefined {
    try {
      const parsed = JSON.parse(responseBody) as JsonErrorResponse
      if (parsed.code === undefined && parsed.message === undefined) {
        return undefined
      }
      return parsed
    } catch (_error) {
      return undefined
    }
  }

  private normalizeError(error: Object, requestUrl: string): AppError {
    if (error instanceof AppError) {
      logError(`HTTP request failed: ${requestUrl}`, error.details ?? error.message, HttpClient.LOG_TAG)
      return error
    }

    const businessError = error as BusinessError
    const details = `code=${businessError.code}, message=${businessError.message}, url=${requestUrl}`
    logError('HTTP request exception', details, HttpClient.LOG_TAG)
    return new AppError(ErrorCode.SYS_500, '网络请求异常', details)
  }
}
