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
  LAST_VIEWED_RESULT = 'last_viewed_result',
  PENDING_ROUTE_PARAMS = 'pending_route_params'
}

export const API_BASE_URL: string = 'http://127.0.0.1:3000'
