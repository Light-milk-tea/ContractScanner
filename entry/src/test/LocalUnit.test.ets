import { describe, it, expect } from '@ohos/hypium'

import { AppError, ErrorCode } from '../main/ets/common/errors'
import {
  buildServiceBaseUrlCandidatesFor,
  DEV_HOST_LAN_IP,
  resolveEffectiveApiBaseUrlFor,
  rewriteLoopbackToHost
} from '../main/ets/common/ServiceBaseUrl'
import { AnalyzeStatus } from '../main/ets/model/enums/AnalyzeStatus'
import { DemoFaultMode, DemoSamplePreset } from '../main/ets/model/enums/DemoMode'
import { RiskLevel } from '../main/ets/model/enums/RiskLevel'
import { AnalyzeVM } from '../main/ets/model/viewmodel/AnalyzeVM'
import { DTOMapper } from '../main/ets/services/api/DTOMapper'
import { CacheService } from '../main/ets/services/storage/CacheService'
import { MockContractService } from '../main/ets/services/mock/MockContractService'

export default function localUnitTest() {
  describe('AnalyzeVMTest', () => {
    it('should_update_progress_when_status_changes', 0, () => {
      const vm = new AnalyzeVM()

      vm.updateStatus(AnalyzeStatus.OCR_RUNNING)
      expect(vm.status).assertEqual(AnalyzeStatus.OCR_RUNNING)
      expect(vm.progressText).assertEqual('正在识别文字')
      expect(vm.stageIndex()).assertEqual(1)
      // 状态切换不应瞬间抬高进度
      expect(vm.progressValue).assertEqual(0)

      vm.updateStatus(AnalyzeStatus.LLM_RUNNING)
      expect(vm.stageIndex()).assertEqual(2)
      expect(vm.progressValue).assertEqual(0)

      vm.updateStatus(AnalyzeStatus.SUCCESS)
      expect(vm.canGoResult()).assertTrue()
      expect(vm.shouldStopPolling()).assertTrue()
      expect(vm.progressValue).assertEqual(100)
    })

    it('should_ease_progress_during_llm_without_reaching_100', 0, () => {
      const vm = new AnalyzeVM()

      vm.updateStatus(AnalyzeStatus.LLM_RUNNING)
      expect(vm.progressValue).assertEqual(0)
      expect(vm.tickProgress()).assertTrue()
      expect(vm.progressValue).assertEqual(3)

      const beforeTick: number = vm.progressValue
      expect(vm.tickProgress()).assertTrue()
      expect(vm.progressValue > beforeTick).assertTrue()
      expect(vm.progressValue - beforeTick < 1.5).assertTrue()

      // 同一状态再次 update 不应改写已缓动进度
      vm.progressValue = 70
      vm.updateStatus(AnalyzeStatus.LLM_RUNNING)
      expect(vm.progressValue).assertEqual(70)

      for (let i = 0; i < 500; i++) {
        vm.tickProgress()
      }
      expect(vm.progressValue <= 97).assertTrue()
      expect(vm.progressValue >= 94).assertTrue()

      // 末段仍保持可见步进，不应趋近于 0
      vm.progressValue = 95
      const lateBefore: number = vm.progressValue
      expect(vm.tickProgress()).assertTrue()
      expect(vm.progressValue - lateBefore >= 0.03).assertTrue()

      vm.updateStatus(AnalyzeStatus.SUCCESS)
      expect(vm.progressValue).assertEqual(100)
    })

    it('should_identify_demo_task_and_retry_state', 0, () => {
      const vm = new AnalyzeVM()
      vm.setTaskId('demo-task-HIGH_RISK__NONE__123456')
      expect(vm.isDemoTask()).assertTrue()

      vm.resetForRetry()
      expect(vm.status).assertEqual(AnalyzeStatus.PENDING)
      expect(vm.progressText).assertEqual('重试中')
    })
  })

  describe('DTOMapperTest', () => {
    it('should_map_analysis_result_with_defaults', 0, () => {
      const mapper = new DTOMapper()
      const mapped = mapper.mapAnalysisResult({
        taskId: 'task-001',
        contractName: '示例合同',
        overallSummary: '摘要',
        signBeforeChecklist: undefined,
        riskStats: undefined,
        clauses: undefined,
        generatedAt: '2026-07-14 12:00'
      })

      expect(mapped.taskId).assertEqual('task-001')
      expect(mapped.signBeforeChecklist.length).assertEqual(0)
      expect(mapped.riskStats.red).assertEqual(0)
      expect(mapped.clauses.length).assertEqual(0)
    })

    it('should_throw_when_risk_level_is_invalid', 0, () => {
      const mapper = new DTOMapper()
      let caught: boolean = false

      try {
        mapper.mapRiskLevel('BLUE')
      } catch (error) {
        caught = true
        const appError = error as AppError
        expect(appError.code).assertEqual(ErrorCode.RESULT_001)
        expect(appError.message).assertEqual('风险等级值不合法')
      }

      expect(caught).assertTrue()
    })

    it('should_map_clause_risk_correctly', 0, () => {
      const mapper = new DTOMapper()
      const clause = mapper.mapClauseRisk({
        clauseId: 'clause-1',
        title: '自动续约条款',
        originalText: '原文',
        plainText: '白话',
        riskLevel: RiskLevel.RED,
        riskReason: '风险原因',
        suggestion: '修改建议',
        anchors: {
          page: 2,
          paragraph: 3
        }
      })

      expect(clause.riskLevel).assertEqual(RiskLevel.RED)
      expect(clause.anchors.page).assertEqual(2)
      expect(clause.anchors.paragraph).assertEqual(3)
    })
  })

  describe('ServiceBaseUrlTest', () => {
    it('should_map_loopback_and_build_probe_candidates', 0, () => {
      expect(rewriteLoopbackToHost('http://127.0.0.1:3000', DEV_HOST_LAN_IP))
        .assertEqual(`http://${DEV_HOST_LAN_IP}:3000`)
      expect(resolveEffectiveApiBaseUrlFor('http://127.0.0.1:3000', true))
        .assertEqual(`http://${DEV_HOST_LAN_IP}:3000`)
      expect(resolveEffectiveApiBaseUrlFor('http://10.0.2.2:3000', true))
        .assertEqual(`http://${DEV_HOST_LAN_IP}:3000`)
      expect(resolveEffectiveApiBaseUrlFor('http://127.0.0.1:3000', false))
        .assertEqual('http://127.0.0.1:3000')

      const candidates = buildServiceBaseUrlCandidatesFor('http://10.0.2.2:3000', true)
      expect(candidates.length >= 2).assertTrue()
      expect(candidates[0]).assertEqual('http://10.0.2.2:3000')
      expect(candidates.indexOf(`http://${DEV_HOST_LAN_IP}:3000`) >= 0).assertTrue()
    })
  })

  describe('CacheServiceTest', () => {
    it('should_parse_records_and_skip_invalid_items', 0, () => {
      const cacheService = new CacheService()
      const records = cacheService.parseRecords(JSON.stringify([
        {
          taskId: 'task-001',
          contractName: '合同 A',
          status: AnalyzeStatus.SUCCESS,
          createdAt: '2026-07-14',
          baseUrl: 'http://192.168.0.2:3000'
        },
        {
          taskId: '',
          contractName: '无效合同',
          status: AnalyzeStatus.FAILED,
          createdAt: '2026-07-14',
          baseUrl: ''
        }
      ]))

      expect(records.length).assertEqual(1)
      expect(records[0].taskId).assertEqual('task-001')
    })

    it('should_merge_records_with_latest_first_and_limit', 0, () => {
      const cacheService = new CacheService()
      const merged = cacheService.mergeRecords(
        {
          taskId: 'task-new',
          contractName: '最新合同',
          status: AnalyzeStatus.SUCCESS,
          createdAt: '2026-07-14',
          baseUrl: 'http://192.168.0.3:3000'
        },
        [
          { taskId: 'task-1', contractName: '合同1', status: AnalyzeStatus.SUCCESS, createdAt: '1', baseUrl: '' },
          { taskId: 'task-2', contractName: '合同2', status: AnalyzeStatus.SUCCESS, createdAt: '2', baseUrl: '' },
          { taskId: 'task-3', contractName: '合同3', status: AnalyzeStatus.SUCCESS, createdAt: '3', baseUrl: '' },
          { taskId: 'task-4', contractName: '合同4', status: AnalyzeStatus.SUCCESS, createdAt: '4', baseUrl: '' },
          { taskId: 'task-5', contractName: '合同5', status: AnalyzeStatus.SUCCESS, createdAt: '5', baseUrl: '' },
          { taskId: 'task-6', contractName: '合同6', status: AnalyzeStatus.SUCCESS, createdAt: '6', baseUrl: '' }
        ]
      )

      expect(merged.length).assertEqual(5)
      expect(merged[0].taskId).assertEqual('task-new')
      expect(merged[4].taskId).assertEqual('task-4')
    })
  })

  describe('MockContractServiceTest', () => {
    it('should_return_high_and_low_risk_samples', 0, () => {
      const highRiskSample = MockContractService.getDemoSample(DemoSamplePreset.HIGH_RISK)
      const lowRiskSample = MockContractService.getDemoSample(DemoSamplePreset.LOW_RISK)

      expect(highRiskSample.preset).assertEqual(DemoSamplePreset.HIGH_RISK)
      expect(highRiskSample.inlineText).assertContain('自动续约')
      expect(lowRiskSample.preset).assertEqual(DemoSamplePreset.LOW_RISK)
      expect(lowRiskSample.inlineText).assertContain('自然终止')
    })

    it('should_generate_task_status_for_timeout_and_weak_network_modes', 0, () => {
      const timeoutTaskId = MockContractService.buildMockTaskId(DemoSamplePreset.HIGH_RISK, DemoFaultMode.TIMEOUT)
      const weakNetworkTaskId = MockContractService.buildMockTaskId(DemoSamplePreset.LOW_RISK, DemoFaultMode.WEAK_NETWORK)

      const timeoutStatus = MockContractService.getTaskStatus(3, timeoutTaskId)
      const weakNetworkStatus = MockContractService.getTaskStatus(4, weakNetworkTaskId)

      expect(timeoutStatus.status).assertEqual(AnalyzeStatus.FAILED)
      expect(timeoutStatus.errorMessage).assertContain('超时')
      expect(weakNetworkStatus.status).assertEqual(AnalyzeStatus.LLM_RUNNING)
      expect(MockContractService.getDemoStepDelayMillis(weakNetworkTaskId)).assertEqual(2200)
    })

    it('should_build_analysis_result_by_sample_preset', 0, () => {
      const highRiskTaskId = MockContractService.buildMockTaskId(DemoSamplePreset.HIGH_RISK, DemoFaultMode.NONE)
      const lowRiskTaskId = MockContractService.buildMockTaskId(DemoSamplePreset.LOW_RISK, DemoFaultMode.DEGRADE_TO_DEMO)

      const highRiskResult = MockContractService.getAnalysisResult(highRiskTaskId)
      const lowRiskResult = MockContractService.getAnalysisResult(lowRiskTaskId)

      expect(highRiskResult.riskStats.red).assertEqual(2)
      expect(lowRiskResult.riskStats.green).assertEqual(2)
      expect(lowRiskResult.contractName).assertContain('降级演示')
    })
  })
}
