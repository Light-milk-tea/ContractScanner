import { AnalyzeStatus } from '../model/enums/AnalyzeStatus'
import {
  cardInnerGap,
  isCompactLayout,
  progressHaloSize,
  progressPercentFontSize,
  progressRingSize,
  progressStatusFontSize,
  showLinearProgressBar
} from '../common/ui/LayoutHelpers'
import { UiColors, UiFont, UiRadius, UiSpace } from '../common/ui/DesignTokens'

@Component
export struct AnalyzeProgress {
  @Prop status: AnalyzeStatus = AnalyzeStatus.PENDING
  @Prop stageIndex: number = 0
  @Prop progressText: string = ''
  @Prop progressValue: number = 0

  @State private haloOpacity: number = 0.36
  @State private barSheenX: number = -56
  @State private barWidth: number = 0

  private static readonly SHEEN_WIDTH: number = 56
  private motionTimerId: number = -1
  private haloRising: boolean = true

  aboutToAppear(): void {
    this.startMotion()
  }

  aboutToDisappear(): void {
    this.stopMotion()
  }

  build() {
    Column({ space: cardInnerGap() }) {
      this.StageRow()

      Column({ space: UiSpace.SM }) {
        Text(this.humanizedStatus())
          .fontSize(progressStatusFontSize())
          .fontWeight(FontWeight.Bold)
          .fontColor(UiColors.TEXT_PRIMARY)
          .textAlign(TextAlign.Center)
          .width('100%')

        Text(this.progressText)
          .fontSize(UiFont.BODY)
          .fontColor(UiColors.TEXT_SECONDARY)
          .lineHeight(22)
          .textAlign(TextAlign.Center)
          .width('100%')
      }
      .alignItems(HorizontalAlign.Center)
      .width('100%')

      Stack({ alignContent: Alignment.Center }) {
        Column()
          .width(progressHaloSize())
          .height(progressHaloSize())
          .borderRadius(UiRadius.PILL)
          .linearGradient({
            angle: 145,
            colors: [
              ['#E8A8A4', 0.0],
              ['#66B91C1C', 0.45],
              ['#00FFFFFF', 1.0]
            ]
          })
          .opacity(this.isActive() ? this.haloOpacity : 0.16)

        Progress({ value: this.progressValue, total: 100, type: ProgressType.Ring })
          .width(progressRingSize())
          .height(progressRingSize())
          .color(this.progressColor())
          .backgroundColor(UiColors.BRAND_SOFT)
          .style({
            strokeWidth: isCompactLayout() ? 9 : 11,
            enableSmoothEffect: true,
            shadow: false
          })

        Row({ space: 1 }) {
          Text(`${Math.floor(this.progressValue)}`)
            .fontSize(progressPercentFontSize())
            .fontWeight(FontWeight.Bold)
            .fontColor(UiColors.TEXT_PRIMARY)
          Text('%')
            .fontSize(isCompactLayout() ? 14 : 17)
            .fontWeight(FontWeight.Medium)
            .fontColor(UiColors.TEXT_TERTIARY)
            .margin({ bottom: 3 })
        }
        .alignItems(VerticalAlign.Bottom)
      }
      .width(progressHaloSize())
      .height(progressHaloSize())

      if (showLinearProgressBar()) {
        Stack({ alignContent: Alignment.Start }) {
          Progress({ value: this.progressValue, total: 100, type: ProgressType.Linear })
            .width('100%')
            .height(6)
            .color(this.progressColor())
            .backgroundColor(UiColors.SURFACE_SECONDARY)
            .borderRadius(UiRadius.PILL)
            .style({
              strokeWidth: 6,
              enableSmoothEffect: true
            })

          Row()
            .width(AnalyzeProgress.SHEEN_WIDTH)
            .height(6)
            .borderRadius(UiRadius.PILL)
            .linearGradient({
              angle: 90,
              colors: [
                ['#00FFFFFF', 0.0],
                ['#B3FFFFFF', 0.5],
                ['#00FFFFFF', 1.0]
              ]
            })
            .opacity(this.isActive() ? 1 : 0)
            .translate({ x: this.barSheenX })
        }
        .width('100%')
        .height(6)
        .borderRadius(UiRadius.PILL)
        .clip(true)
        .onAreaChange((_oldValue: Area, newValue: Area) => {
          const width: number = Number(newValue.width)
          if (width > 0) {
            this.barWidth = width
          }
        })
      }

      Text(this.stageHint())
        .fontSize(UiFont.BODY_SMALL)
        .fontColor(UiColors.TEXT_TERTIARY)
        .lineHeight(20)
        .textAlign(TextAlign.Center)
        .width('100%')
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .width('100%')
    .padding({
      top: UiSpace.LG,
      bottom: UiSpace.LG
    })
  }

  @Builder
  StageRow() {
    Row() {
      Column({ space: 6 }) {
        Stack({ alignContent: Alignment.Center }) {
          if (this.stageIndex === 0 && this.isActive()) {
            Column()
              .width(16)
              .height(16)
              .borderRadius(UiRadius.PILL)
              .backgroundColor(UiColors.BRAND_SOFT)
          }
          Column()
            .width(this.stageIndex === 0 ? 8 : 5)
            .height(this.stageIndex === 0 ? 8 : 5)
            .borderRadius(UiRadius.PILL)
            .backgroundColor(this.stageIndex >= 0 ? UiColors.BRAND : UiColors.BORDER_SOFT)
        }
        .width(16)
        .height(16)
        Text('排队')
          .fontSize(UiFont.CAPTION)
          .fontWeight(this.stageIndex === 0 ? FontWeight.Medium : FontWeight.Regular)
          .fontColor(this.stageIndex >= 0 ? UiColors.BRAND_STRONG : UiColors.TEXT_TERTIARY)
      }
      .alignItems(HorizontalAlign.Center)
      .layoutWeight(1)

      Row()
        .height(1)
        .layoutWeight(1)
        .margin({ top: 7 })
        .backgroundColor(this.stageIndex >= 1 ? UiColors.BRAND : UiColors.BORDER_SOFT)

      Column({ space: 6 }) {
        Stack({ alignContent: Alignment.Center }) {
          if (this.stageIndex === 1 && this.isActive()) {
            Column()
              .width(16)
              .height(16)
              .borderRadius(UiRadius.PILL)
              .backgroundColor(UiColors.BRAND_SOFT)
          }
          Column()
            .width(this.stageIndex === 1 ? 8 : 5)
            .height(this.stageIndex === 1 ? 8 : 5)
            .borderRadius(UiRadius.PILL)
            .backgroundColor(this.stageIndex >= 1 ? UiColors.BRAND : UiColors.BORDER_SOFT)
        }
        .width(16)
        .height(16)
        Text('识别')
          .fontSize(UiFont.CAPTION)
          .fontWeight(this.stageIndex === 1 ? FontWeight.Medium : FontWeight.Regular)
          .fontColor(this.stageIndex >= 1 ? UiColors.BRAND_STRONG : UiColors.TEXT_TERTIARY)
      }
      .alignItems(HorizontalAlign.Center)
      .layoutWeight(1)

      Row()
        .height(1)
        .layoutWeight(1)
        .margin({ top: 7 })
        .backgroundColor(this.stageIndex >= 2 ? UiColors.BRAND : UiColors.BORDER_SOFT)

      Column({ space: 6 }) {
        Stack({ alignContent: Alignment.Center }) {
          if (this.stageIndex === 2 && this.isActive()) {
            Column()
              .width(16)
              .height(16)
              .borderRadius(UiRadius.PILL)
              .backgroundColor(UiColors.BRAND_SOFT)
          }
          Column()
            .width(this.stageIndex === 2 ? 8 : 5)
            .height(this.stageIndex === 2 ? 8 : 5)
            .borderRadius(UiRadius.PILL)
            .backgroundColor(this.stageIndex >= 2 ? UiColors.BRAND : UiColors.BORDER_SOFT)
        }
        .width(16)
        .height(16)
        Text('分析')
          .fontSize(UiFont.CAPTION)
          .fontWeight(this.stageIndex === 2 ? FontWeight.Medium : FontWeight.Regular)
          .fontColor(this.stageIndex >= 2 ? UiColors.BRAND_STRONG : UiColors.TEXT_TERTIARY)
      }
      .alignItems(HorizontalAlign.Center)
      .layoutWeight(1)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
  }

  startMotion(): void {
    if (this.motionTimerId >= 0) {
      return
    }
    this.motionTimerId = setInterval(() => {
      if (!this.isActive()) {
        return
      }

      if (showLinearProgressBar()) {
        this.barSheenX = this.barSheenX + 6
        const endX: number = this.barWidth > 0 ? this.barWidth : 400
        if (this.barSheenX > endX) {
          this.barSheenX = -AnalyzeProgress.SHEEN_WIDTH
        }
      }

      if (this.haloRising) {
        this.haloOpacity = this.haloOpacity + 0.008
        if (this.haloOpacity >= 0.52) {
          this.haloOpacity = 0.52
          this.haloRising = false
        }
      } else {
        this.haloOpacity = this.haloOpacity - 0.008
        if (this.haloOpacity <= 0.24) {
          this.haloOpacity = 0.24
          this.haloRising = true
        }
      }
    }, 32)
  }

  stopMotion(): void {
    if (this.motionTimerId < 0) {
      return
    }
    clearInterval(this.motionTimerId)
    this.motionTimerId = -1
  }

  isActive(): boolean {
    return this.status !== AnalyzeStatus.SUCCESS && this.status !== AnalyzeStatus.FAILED
  }

  humanizedStatus(): string {
    switch (this.status) {
      case AnalyzeStatus.OCR_RUNNING:
        return '正在识别合同内容'
      case AnalyzeStatus.LLM_RUNNING:
        return '正在分析条款风险'
      case AnalyzeStatus.SUCCESS:
        return '分析已完成'
      case AnalyzeStatus.FAILED:
        return '分析失败'
      default:
        return '任务已创建'
    }
  }

  stageHint(): string {
    switch (this.status) {
      case AnalyzeStatus.OCR_RUNNING:
        return '正在提取正文，随后会进入条款解读'
      case AnalyzeStatus.LLM_RUNNING:
        return '正在生成白话解释、风险原因与修改建议'
      case AnalyzeStatus.SUCCESS:
        return '结果已就绪，即将打开结果页'
      case AnalyzeStatus.FAILED:
        return '可以重试，或返回后重新发起分析'
      default:
        return '任务已排队，系统会自动推进'
    }
  }

  progressColor(): string {
    if (this.status === AnalyzeStatus.FAILED) {
      return UiColors.DANGER
    }
    return UiColors.BRAND
  }
}
