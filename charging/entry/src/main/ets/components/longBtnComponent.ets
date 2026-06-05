@Component
export struct LongBtnComponent {
  @Prop btnColor: Resource
  @Prop btnFontColor: Resource
  @Prop btnBorderColor: Resource
  @Prop btnName: string
  onEvent: Function = (data: string) => {
  }

  build() {
    Flex({ justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
      if (this.btnName === '清空搜索历史') {
        Image($r('app.media.homeSearch_dustbin'))
          .margin({right: '8lpx'})
          .width('16lpx')
          .height('16lpx')
      }
      Text(this.btnName)
        .fontSize('16lpx')
        .fontColor(this.btnFontColor)
    }
    .padding({ top: '8lpx', bottom: '8lpx' })
    .borderRadius('20lpx')
    .borderWidth('1lpx')
    .borderColor(this.btnBorderColor)
    .margin({ left: '16lpx', right: '16lpx' })
    .backgroundColor(this.btnColor)
    .onClick(() => {
      this.onEvent(this.btnName)
    })
  }
}