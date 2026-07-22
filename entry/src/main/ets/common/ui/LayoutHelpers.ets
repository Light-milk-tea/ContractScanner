import { display } from '@kit.ArkUI'

import { LayoutMetrics, UiFont, UiSpace } from './DesignTokens'

/** 低于该宽度（vp）按手机窄屏布局处理 */
const COMPACT_WIDTH_VP: number = 600
/** 达到该宽度（vp）启用平板/2in1 对照分栏 */
const WIDE_WIDTH_VP: number = 840

export function screenWidthVp(): number {
  try {
    const info = display.getDefaultDisplaySync()
    const density: number = info.densityPixels
    if (density > 0) {
      return info.width / density
    }
    return info.width
  } catch (_error) {
    return 390
  }
}

export function isCompactLayout(): boolean {
  return screenWidthVp() < COMPACT_WIDTH_VP
}

export function isWideLayout(): boolean {
  return screenWidthVp() >= WIDE_WIDTH_VP
}

export function pageHorizontalPadding(): number {
  return isCompactLayout() ? 20 : UiSpace.PAGE_HORIZONTAL
}

export function pageVerticalPadding(): number {
  return isCompactLayout() ? 18 : UiSpace.PAGE_VERTICAL
}

export function contentMaxWidth(): number {
  return LayoutMetrics.CONTENT_MAX_WIDTH
}

export function readingMaxWidth(): number {
  if (isWideLayout()) {
    return LayoutMetrics.WIDE_READING_MAX_WIDTH
  }
  return isCompactLayout() ? 720 : LayoutMetrics.READING_MAX_WIDTH
}

export function cardPadding(): number {
  return isCompactLayout() ? UiSpace.MD : UiSpace.LG
}

export function cardInnerGap(): number {
  return isCompactLayout() ? UiSpace.LG : UiSpace.XL
}

export function sectionGap(): number {
  return isCompactLayout() ? UiSpace.XXL : UiSpace.XXXL
}

export function heroFontSize(): number {
  return isCompactLayout() ? 36 : UiFont.HERO
}

export function pageTitleFontSize(): number {
  return isCompactLayout() ? 22 : UiFont.PAGE_TITLE
}

export function sectionTitleFontSize(): number {
  return isCompactLayout() ? 18 : UiFont.SECTION_TITLE
}

export function contractTitleFontSize(): number {
  return isCompactLayout() ? 20 : 24
}

export function metricValueFontSize(): number {
  return isCompactLayout() ? 20 : 24
}

export function progressRingSize(): number {
  return isCompactLayout() ? 108 : 136
}

export function progressHaloSize(): number {
  return isCompactLayout() ? 120 : 152
}

export function progressPercentFontSize(): number {
  return isCompactLayout() ? 30 : 36
}

export function progressStatusFontSize(): number {
  return isCompactLayout() ? 18 : 22
}

/** 手机端圆环已足够表达进度，隐藏底部线性条减轻拥挤 */
export function showLinearProgressBar(): boolean {
  return !isCompactLayout()
}

export function bodyLineHeight(): number {
  return isCompactLayout() ? 24 : 26
}
