import { router } from '@kit.ArkUI'

@Component
export struct RouteSearchHeadComponent {
  @Link @Watch('onChangeKeyWord') keyWord: string;
  @Prop startOrEnd: string
  receive: Function = () => {
  }

  onChangeKeyWord() {
    console.info('this.keyWord-watch', this.keyWord)
    if (this.keyWord === '') {
      if (this.startOrEnd === 'start') {
        AppStorage.setOrCreate('startSpot', '我的位置')
      } else if (this.startOrEnd === 'end') {
        AppStorage.setOrCreate('endSpot', '输入目的地')
      }
    }
  }

  build() {
    Row() {
      Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
        Image($r('app.media.user_rightIcon'))
          .rotate({
            x: 0,
            y: 1,
            z: 0,
            angle: 180
          })
          .width('20lpx')
          .height('20lpx')
          .onClick(() => {
            router.pushUrl({
              url: 'pages/routePlanning/index',
              params: {
                keyWord: ''
              }
            })
          })
        Column() {
          // 搜索框输入
          Search({ value: this.keyWord, placeholder: '请输入目的地' })
            .height('40lpx')
            .onChange((value: string) => {
              this.keyWord = value

            })
            .onFocus(() => {
              console.info('searchFocus',)

            })
        }
        .margin({ left: '16lpx' })
        .width('100%')
      }

    }
    .width('100%')
    .padding({
      left: '16lpx',
      right: '16lpx',
      bottom: '0lpx',
      top: '0lpx'
    })
    .backgroundColor($r('app.color.background_color_over'))
  }
}