import { router } from '@kit.ArkUI'

@Component
export struct HeadComponent {
  @Prop headName: string
  @Prop isHaveBtn: boolean
  @Prop btnScr: Resource
  @Prop backUrl: string
  @Prop tabs: number
  receive: Function = () => {
  }
  backRouter: Function = () => {
  }

  build() {
    Row() {
      Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
        Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
          Image($r('app.media.user_rightIcon'))
            .rotate({
              x: 0,
              y: 1,
              z: 0,
              angle: 180
            })
            .width('20lpx')
            .height('20lpx')
            .margin({ right: '16lpx' })
            .onClick(() => {
              console.info('headComponentBack')
              if (this.tabs) {
                router.pushUrl({
                  url: this.backUrl,
                  params: {
                    tabs: this.tabs
                  }
                })
              } else if (this.headName === '充电中') {
                this.backRouter()
              } else {
                if (this.backUrl) {
                  router.pushUrl({
                    url: this.backUrl
                  })
                } else {
                  router.back()
                }
              }
            })
          Text(this.headName)
            .fontSize('20lpx')
        }

        if (this.isHaveBtn) {
          if (this.headName === '我的卡券') {
            Column() {
              Text('领取')
                .fontSize('14lpx')
            }
            .width('40.00lpx')
            .onClick(() => {
              this.receive()
            })
          } else if (this.headName === '充电中') {
            Image(this.btnScr)
              .width('36lpx')
              .height('33lpx')
              .onClick(() => {
                this.receive()
              })
          } else if (this.headName === '站点详情') {
            Image(this.btnScr)
              .width('20lpx')
              .height('20lpx')
              .onClick(() => {
                this.receive()
              })
          } else {
            Image(this.btnScr)
              .width('32lpx')
              .height('32lpx')
          }
        }
      }

    }
    .width('100%')
    .padding({
      left: '16lpx',
      right: '16lpx',
      bottom: '14lpx',
      top: '14lpx'
    })
    .backgroundColor($r('app.color.background_color_over'))
  }
}