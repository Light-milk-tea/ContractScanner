import { HomePanel } from '../components/HomePanel'

@Entry
@Component
struct HomePage {
  build() {
    Column() {
      HomePanel({
        hideSettingsEntry: false,
        bottomInset: 0
      })
    }
    .width('100%')
    .height('100%')
  }
}
