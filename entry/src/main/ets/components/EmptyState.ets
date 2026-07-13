export enum EmptyStateType {
  EMPTY = 'empty',
  ERROR = 'error',
  INFO = 'info'
}

@Component
export struct EmptyState {
  @Prop title: string = '暂无内容'
  @Prop description: string = ''
  @Prop hint: string = ''
  @Prop stateType: EmptyStateType = EmptyStateType.EMPTY

  build() {
    Column({ space: 10 }) {
      Text(this.badgeText())
        .fontSize(11)
        .fontColor(this.badgeFontColor())
        .padding({ left: 10, right: 10, top: 4, bottom: 4 })
        .backgroundColor(this.badgeBackgroundColor())
        .borderRadius(999)

      Text(this.title)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#182431')

      if (this.description.length > 0) {
        Text(this.description)
          .fontSize(14)
          .fontColor('#445266')
          .width('100%')
          .lineHeight(22)
      }

      if (this.hint.length > 0) {
        Text(this.hint)
          .fontSize(13)
          .fontColor('#6B7280')
          .width('100%')
          .lineHeight(20)
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(16)
    .borderRadius(20)
    .backgroundColor(this.cardBackgroundColor())
  }

  badgeText(): string {
    switch (this.stateType) {
      case EmptyStateType.ERROR:
        return '异常提醒'
      case EmptyStateType.INFO:
        return '状态说明'
      default:
        return '暂无数据'
    }
  }

  cardBackgroundColor(): string {
    switch (this.stateType) {
      case EmptyStateType.ERROR:
        return '#FDF2F2'
      case EmptyStateType.INFO:
        return '#F2F7FF'
      default:
        return '#F7F8FA'
    }
  }

  badgeBackgroundColor(): string {
    switch (this.stateType) {
      case EmptyStateType.ERROR:
        return '#FDE2E2'
      case EmptyStateType.INFO:
        return '#DCEBFF'
      default:
        return '#E8ECF2'
    }
  }

  badgeFontColor(): string {
    switch (this.stateType) {
      case EmptyStateType.ERROR:
        return '#C0392B'
      case EmptyStateType.INFO:
        return '#2E6BE6'
      default:
        return '#56657A'
    }
  }
}
