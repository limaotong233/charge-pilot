@Component
export struct CustomShowToast {
  @StorageProp('currentBreakpoint') curBp: string = 'sm'
  @Prop cusSTBorderRadius: string
  @Prop cusSTBackgroundColor: string
  @Prop cusSTText: string
  @Prop cusSTImage: Resource
  @Prop cusSTFontColor: Resource

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Row() {
        Image(this.cusSTImage)
          .width('24lpx')
          .height('24lpx')
          .margin({ right: '16lpx' })
        Text(this.cusSTText)
          .fontSize('16lpx')
          .fontColor(this.cusSTFontColor)
      }
      .width(this.curBp === 'sm' ? '100%' : '360lpx')
      .padding({
        left: '12lpx',
        right: '12lpx',
        top: '8lpx',
        bottom: '8lpx'
      })
      .backgroundColor(this.cusSTBackgroundColor)
      .borderRadius(this.cusSTBorderRadius)
      .alignSelf(ItemAlign.Center)
    }
    .padding({ left: '12lpx', right: '12lpx', bottom: '8lpx' })
    .width('100%')
    .zIndex(2)
  }
}