import { AnalysisResult } from '../../model/domain/AnalysisResult'
import { ClauseRisk } from '../../model/domain/ClauseRisk'
import { RiskLevel } from '../../model/enums/RiskLevel'

/**
 * Builds a Word-compatible .doc payload (HTML Word format).
 * Phones can open it with WPS / 文档类 App.
 */
export class DocReportBuilder {
  build(result: AnalysisResult): string {
    const bodyParts: string[] = []
    bodyParts.push(`<h1>${this.escapeHtml(result.contractName)} 分析报告</h1>`)
    bodyParts.push('<ul>')
    bodyParts.push(`<li>任务 ID：${this.escapeHtml(result.taskId)}</li>`)
    bodyParts.push(`<li>生成时间：${this.escapeHtml(result.generatedAt)}</li>`)
    bodyParts.push(
      `<li>风险统计：高风险 ${result.riskStats.red} / 中风险 ${result.riskStats.yellow} / 低风险 ${result.riskStats.green}</li>`
    )
    bodyParts.push('</ul>')

    bodyParts.push('<h2>整体结论</h2>')
    bodyParts.push(this.paragraphsHtml(result.overallSummary))

    bodyParts.push('<h2>签署前建议确认</h2>')
    if (result.signBeforeChecklist.length === 0) {
      bodyParts.push('<p>（暂无清单项）</p>')
    } else {
      bodyParts.push('<ol>')
      for (let i = 0; i < result.signBeforeChecklist.length; i++) {
        bodyParts.push(`<li>${this.escapeHtml(result.signBeforeChecklist[i])}</li>`)
      }
      bodyParts.push('</ol>')
    }

    bodyParts.push('<h2>风险条款明细</h2>')
    if (result.clauses.length === 0) {
      bodyParts.push('<p>（暂无条款明细）</p>')
    } else {
      for (let i = 0; i < result.clauses.length; i++) {
        bodyParts.push(this.clauseHtml(result.clauses[i], i + 1))
      }
    }

    bodyParts.push('<hr/>')
    bodyParts.push('<p><em>本报告由系统生成，不构成正式法律意见。</em></p>')

    return [
      '<html xmlns:o="urn:schemas-microsoft-com:office:office"',
      'xmlns:w="urn:schemas-microsoft-com:office:word"',
      'xmlns="http://www.w3.org/TR/REC-html40">',
      '<head>',
      '<meta charset="utf-8"/>',
      `<title>${this.escapeHtml(result.contractName)} 分析报告</title>`,
      '<!--[if gte mso 9]><xml><w:WordDocument><w:View>Print</w:View></w:WordDocument></xml><![endif]-->',
      '<style>',
      'body{font-family:"PingFang SC","Microsoft YaHei",sans-serif;font-size:12pt;line-height:1.6;color:#222;}',
      'h1{font-size:20pt;}h2{font-size:16pt;margin-top:18pt;}h3{font-size:14pt;margin-top:14pt;}',
      'blockquote{margin:8pt 0;padding:8pt 12pt;background:#f5f5f5;border-left:3pt solid #999;}',
      'section{margin-bottom:12pt;}',
      '</style>',
      '</head>',
      '<body>',
      bodyParts.join('\n'),
      '</body>',
      '</html>',
      ''
    ].join('\n')
  }

  buildFileName(contractName: string): string {
    const safeName = this.sanitizeFileName(contractName)
    return `${safeName}-分析报告.doc`
  }

  private clauseHtml(clause: ClauseRisk, index: number): string {
    const parts: string[] = []
    parts.push(
      `<h3>${index}. ${this.escapeHtml(clause.title)}（${this.riskLabel(clause.riskLevel)}）</h3>`
    )
    parts.push('<p><strong>原文条款</strong></p>')
    parts.push(`<blockquote>${this.paragraphsInner(clause.originalText)}</blockquote>`)
    parts.push('<p><strong>白话解释</strong></p>')
    parts.push(this.paragraphsHtml(clause.plainText))
    parts.push('<p><strong>风险原因</strong></p>')
    parts.push(this.paragraphsHtml(clause.riskReason))
    if (clause.legalBasis !== undefined && clause.legalBasis.length > 0) {
      parts.push('<p><strong>相关法条</strong></p>')
      parts.push(this.paragraphsHtml(clause.legalBasis))
    }
    if (clause.suggestion !== undefined && clause.suggestion.length > 0) {
      parts.push('<p><strong>修改建议</strong></p>')
      parts.push(this.paragraphsHtml(clause.suggestion))
    }
    const anchorParts: string[] = []
    if (clause.anchors.page !== undefined) {
      anchorParts.push(`页 ${clause.anchors.page}`)
    }
    if (clause.anchors.paragraph !== undefined) {
      anchorParts.push(`段 ${clause.anchors.paragraph}`)
    }
    if (anchorParts.length > 0) {
      parts.push(`<p><strong>位置锚点</strong>：${this.escapeHtml(anchorParts.join(' / '))}</p>`)
    }
    return parts.join('\n')
  }

  private riskLabel(level: RiskLevel): string {
    if (level === RiskLevel.RED) {
      return '高风险'
    }
    if (level === RiskLevel.YELLOW) {
      return '中风险'
    }
    return '低风险'
  }

  private paragraphsHtml(text: string): string {
    const normalized = this.normalizeBlock(text)
    if (normalized.length === 0) {
      return '<p>（空）</p>'
    }
    const lines = normalized.split('\n')
    const html: string[] = []
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i].trim()
      if (line.length === 0) {
        continue
      }
      html.push(`<p>${this.escapeHtml(line)}</p>`)
    }
    return html.length > 0 ? html.join('\n') : '<p>（空）</p>'
  }

  private paragraphsInner(text: string): string {
    const normalized = this.normalizeBlock(text)
    if (normalized.length === 0) {
      return '（空）'
    }
    return this.escapeHtml(normalized).replace(/\n/g, '<br/>')
  }

  private normalizeBlock(text: string): string {
    return text.replace(/\r\n/g, '\n').replace(/\r/g, '\n').trim()
  }

  private escapeHtml(text: string): string {
    let out = ''
    for (let i = 0; i < text.length; i++) {
      const ch = text.charAt(i)
      if (ch === '&') {
        out += '&amp;'
      } else if (ch === '<') {
        out += '&lt;'
      } else if (ch === '>') {
        out += '&gt;'
      } else if (ch === '"') {
        out += '&quot;'
      } else {
        out += ch
      }
    }
    return out
  }

  private sanitizeFileName(rawName: string): string {
    const trimmed = rawName.trim()
    if (trimmed.length === 0) {
      return '合同'
    }
    let safe = ''
    for (let i = 0; i < trimmed.length; i++) {
      const ch = trimmed.charAt(i)
      if (ch === '/' || ch === '\\' || ch === ':' || ch === '*' || ch === '?' || ch === '"' || ch === '<' ||
        ch === '>' || ch === '|') {
        safe += '_'
      } else {
        safe += ch
      }
    }
    const collapsed = safe.replace(/\s+/g, ' ').trim()
    return collapsed.length > 0 ? collapsed : '合同'
  }
}
