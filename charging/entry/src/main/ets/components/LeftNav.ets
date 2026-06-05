@Component
export struct LeftNav {
  @Prop activeName: string;
  onEvent: Function = (data: string, index: number) => {
  };

  build() {
    Flex({ justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
      Column() {
        Image(this.activeName === '首页' ? $r('app.media.home_homeActive') : $r('app.media.home_home'))
          .width('32lpx')
          .height('32lpx')
          .margin({ bottom: '4lpx' })
        Text('首页')
          .fontSize('12lpx')
          .fontColor(this.activeName === '首页' ? $r('app.color.bottom_nav_fontcolor_active') :
          $r('app.color.bottom_nav_fontcolor'))
      }
      .onClick(() => {
        this.activeName = '首页'
        this.onEvent('首页', 0)
      })
    }
    .width('108lpx')
    .height('100%')
    .padding({ top: '128lpx', bottom: '128lpx' })
    .backgroundColor('#ffffff')
  }
}