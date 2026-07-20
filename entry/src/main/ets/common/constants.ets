import {
  buildServiceBaseUrlCandidates,
  DEV_HOST_LAN_IP,
  isEmulatorRuntime,
  isLoopbackBaseUrl,
  networkFailureHint,
  resolveDefaultApiBaseUrl,
  resolveEffectiveApiBaseUrl
} from './ServiceBaseUrl'

export enum RoutePath {
  HOME = 'pages/HomePage',
  IMPORT = 'pages/ImportPage',
  ANALYZING = 'pages/AnalyzingPage',
  RESULT_OVERVIEW = 'pages/ResultOverviewPage',
  CLAUSE_COMPARE = 'pages/ClauseComparePage',
  SETTINGS = 'pages/SettingsPage'
}

export enum StorageKey {
  RECENT_TASK_IDS = 'recent_task_ids',
  RECENT_CONTRACTS = 'recent_contracts',
  CARD_FORM_IDS = 'card_form_ids',
  PRIVACY_GUARD_ENABLED = 'privacy_guard_enabled',
  LOG_ENABLED = 'log_enabled',
  MODEL_API_KEY = 'model_api_key',
  SERVICE_BASE_URL = 'service_base_url',
  DEMO_FAULT_MODE = 'demo_fault_mode',
  LAST_VIEWED_RESULT = 'last_viewed_result',
  PENDING_ROUTE_PARAMS = 'pending_route_params'
}

/** 按运行环境解析：模拟器优先电脑局域网 IP，其他为 http://127.0.0.1:3000 */
export const API_BASE_URL: string = resolveDefaultApiBaseUrl()

export {
  buildServiceBaseUrlCandidates,
  DEV_HOST_LAN_IP,
  isEmulatorRuntime,
  isLoopbackBaseUrl,
  networkFailureHint,
  resolveDefaultApiBaseUrl,
  resolveEffectiveApiBaseUrl
}
