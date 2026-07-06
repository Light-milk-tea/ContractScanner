import { router, UIContext } from '@kit.ArkUI'
import { BusinessError } from '@kit.BasicServicesKit'
import { logError } from '../common/logger'
import { RoutePath } from '../common/constants'

export class RouteParams {
}

function formatBusinessError(error: BusinessError): string {
  return `code=${error.code}, message=${error.message}`
}

function buildRouteOptions(url: string, params?: RouteParams): router.RouterOptions {
  if (params !== undefined) {
    const optionsWithParams: router.RouterOptions = {
      url: url,
      params: params
    }
    return optionsWithParams
  }

  const options: router.RouterOptions = {
    url: url
  }
  return options
}

export async function push(uiContext: UIContext, url: string, params?: RouteParams): Promise<void> {
  try {
    await uiContext.getRouter().pushUrl(buildRouteOptions(url, params))
  } catch (error) {
    const businessError: BusinessError = error as BusinessError
    logError(`Router push failed: ${url}`, formatBusinessError(businessError))
  }
}

export async function replace(uiContext: UIContext, url: string, params?: RouteParams): Promise<void> {
  try {
    await uiContext.getRouter().replaceUrl(buildRouteOptions(url, params))
  } catch (error) {
    const businessError: BusinessError = error as BusinessError
    logError(`Router replace failed: ${url}`, formatBusinessError(businessError))
  }
}

export function back(uiContext: UIContext): void {
  try {
    uiContext.getRouter().back()
  } catch (error) {
    const businessError: BusinessError = error as BusinessError
    logError('Router back failed', formatBusinessError(businessError))
  }
}

export async function goHome(uiContext: UIContext): Promise<void> {
  await replace(uiContext, RoutePath.HOME)
}

export async function goImport(uiContext: UIContext): Promise<void> {
  await push(uiContext, RoutePath.IMPORT)
}

export async function goAnalyzing(uiContext: UIContext, params?: RouteParams): Promise<void> {
  await push(uiContext, RoutePath.ANALYZING, params)
}

export async function goResultOverview(uiContext: UIContext, params?: RouteParams): Promise<void> {
  await push(uiContext, RoutePath.RESULT_OVERVIEW, params)
}

export async function goClauseCompare(uiContext: UIContext, params?: RouteParams): Promise<void> {
  await push(uiContext, RoutePath.CLAUSE_COMPARE, params)
}

export async function goSettings(uiContext: UIContext): Promise<void> {
  await push(uiContext, RoutePath.SETTINGS)
}
