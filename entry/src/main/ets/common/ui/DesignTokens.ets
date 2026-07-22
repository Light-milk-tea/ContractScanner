export class UiColors {
  static readonly PAGE_BACKGROUND: string = '#F7F4F3'
  static readonly PAGE_GRADIENT_TOP: string = '#F0E8E6'
  static readonly PAGE_GRADIENT_BOTTOM: string = '#F4EFED'
  static readonly SURFACE_PRIMARY: string = '#FFFFFF'
  static readonly SURFACE_SECONDARY: string = '#EEE8E6'
  static readonly SURFACE_MUTED: string = '#F5F1F0'
  static readonly SURFACE_ACCENT: string = '#F3E9E7'
  static readonly SURFACE_INSET: string = '#F0EAE8'
  static readonly BORDER_SOFT: string = '#E0D6D3'
  static readonly BORDER_HAIRLINE: string = '#EBE4E2'
  static readonly TEXT_PRIMARY: string = '#12151A'
  static readonly TEXT_SECONDARY: string = '#5C6670'
  static readonly TEXT_TERTIARY: string = '#8A949C'
  static readonly TEXT_ON_BRAND: string = '#FFFFFF'
  /** 合同印章红 */
  static readonly BRAND: string = '#B91C1C'
  static readonly BRAND_SOFT: string = '#F5E4E2'
  static readonly BRAND_STRONG: string = '#8F1515'
  static readonly SUCCESS: string = '#2A7A52'
  static readonly SUCCESS_SOFT: string = '#E6F3EB'
  static readonly WARNING: string = '#9A6B12'
  static readonly WARNING_SOFT: string = '#F7F0E0'
  /** 风险高亮，略浅于印章主色，避免与品牌完全撞色 */
  static readonly DANGER: string = '#D1433A'
  static readonly DANGER_SOFT: string = '#FBEDEC'
  static readonly SHADOW: string = '#12151A'
}

export class UiRadius {
  static readonly SMALL: number = 10
  static readonly MEDIUM: number = 12
  static readonly LARGE: number = 16
  static readonly XLARGE: number = 18
  /** 仅用于进度点等极小圆元素，按钮勿用 */
  static readonly PILL: number = 999
}

export class UiSpace {
  static readonly XS: number = 6
  static readonly SM: number = 8
  static readonly MD: number = 12
  static readonly LG: number = 16
  static readonly XL: number = 20
  static readonly XXL: number = 24
  static readonly XXXL: number = 32
  static readonly PAGE_HORIZONTAL: number = 20
  static readonly PAGE_VERTICAL: number = 18
}

export class UiFont {
  static readonly HERO: number = 40
  static readonly PAGE_TITLE: number = 26
  static readonly SECTION_TITLE: number = 18
  static readonly BODY: number = 15
  static readonly BODY_SMALL: number = 13
  static readonly CAPTION: number = 12
  static readonly BADGE: number = 11
  static readonly BUTTON: number = 15
}

export class UiShadow {
  static readonly SOFT_RADIUS: number = 12
  static readonly SOFT_OFFSET_Y: number = 3
  static readonly SOFT_COLOR: string = '#0F12151A'
  static readonly CARD_RADIUS: number = 14
  static readonly CARD_OFFSET_Y: number = 4
  static readonly CARD_COLOR: string = '#1412151A'
}

export class LayoutMetrics {
  static readonly CONTENT_MAX_WIDTH: number = 940
  static readonly READING_MAX_WIDTH: number = 820
  /** 宽屏条款对照分栏可用宽度 */
  static readonly WIDE_READING_MAX_WIDTH: number = 1280
  static readonly BUTTON_HEIGHT: number = 48
  static readonly NAV_ICON_SIZE: number = 36
  static readonly RISK_BAR_WIDTH: number = 3
  static readonly BUTTON_RADIUS: number = 14
}
