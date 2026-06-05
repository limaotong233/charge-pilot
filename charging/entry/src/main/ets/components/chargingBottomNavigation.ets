@Component
export struct ChargingBottomNav {
  @Prop activeName: string;
  onEvent: Function = (data: string, index: number) => {
  };

  build() {
    Flex({ justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
      Column() {
        Image(this.activeName === '我的有序桩' ? $r('app.media.home_homeActive') : $r('app.media.home_home'))
          .width('20lpx')
          .height('20lpx')
          .margin({ top: '5lpx', bottom: '8lpx' })
        Text('我的有序桩')
          .fontSize('10lpx')
          .fontColor(this.activeName === '我的有序桩' ? $r('app.color.bottom_nav_fontcolor_active') :
          $r('app.color.bottom_nav_fontcolor'))
      }
      .width('50%')
      .height('100%')
      .onClick(() => {
        this.activeName = '我的有序桩'
        this.onEvent('我的有序桩', 0)
      })

      Column() {
        Image(this.activeName === '预约充电' ? $r('app.media.chargingTab2_active') : $r('app.media.chargingTab2'))
          .width('20lpx')
          .height('20lpx')
          .margin({ top: '5lpx', bottom: '8lpx' })
        Text('预约充电')
          .fontSize('10lpx')
          .fontColor(this.activeName === '预约充电' ? $r('app.color.bottom_nav_fontcolor_active') :
          $r('app.color.bottom_nav_fontcolor'))
      }
      .width('50%')
      .height('100%')
      .onClick(() => {
        this.activeName = '预约充电'
        this.onEvent('预约充电', 1)
      })
    }
    .width('100%')
    .height('70lpx')
    // .height('52lpx')
    .padding({ left: '16lpx', right: '16lpx' })
    .backgroundColor('#ffffff')
    .backgroundImageSize({ width: '100%', height: '100%' })

  }
}