import assert from 'assert'

import { buildRiskEngineOutput, sanitizeLegalBasis } from '../src/core/risk-engine'
import { RagHit } from '../src/core/rag/client'

function sampleHits(): RagHit[] {
  return [
    {
      id: 'rule_auto_renew_long',
      title: '超长自动续约',
      content: '自动续约两年风险高',
      doc_type: 'risk_rule',
      risk_level: 'RED',
      scenario: '租房',
      category: 'renewal',
      score: 0.9,
      source: '风险规则库',
      related_law_ids: ['law_cc_497']
    },
    {
      id: 'law_cc_497',
      title: '格式条款无效情形',
      content: '不合理免除责任的格式条款无效',
      doc_type: 'law_snippet',
      risk_level: 'INFO',
      scenario: '通用',
      category: 'format_clause',
      score: 0.85,
      source: '民法典第497条',
      citation: {
        law_name: '中华人民共和国民法典',
        article_no: '第497条',
        text: '不合理免除或减轻己方责任、加重对方责任、限制或排除对方主要权利的格式条款无效。'
      },
      related_law_ids: []
    }
  ]
}

function main(): void {
  const engine = buildRiskEngineOutput(sampleHits(), 8)
  assert.ok(engine.allowedCitations.length >= 1, 'should expose allowed citations')

  const grounded = sanitizeLegalBasis(
    '参考《中华人民共和国民法典》第497条相关规定',
    engine.allowedCitations
  )
  assert.ok(grounded !== undefined && grounded.indexOf('第497条') >= 0, 'grounded citation kept')

  const fabricated = sanitizeLegalBasis(
    '《不存在的法》第999条：编造条文',
    engine.allowedCitations
  )
  assert.strictEqual(fabricated, undefined, 'fabricated citation stripped')

  const empty = sanitizeLegalBasis('《民法典》第497条', [])
  assert.strictEqual(empty, undefined, 'no allowed list means no legalBasis')

  console.log('risk-engine citation guard checks passed')
}

main()
