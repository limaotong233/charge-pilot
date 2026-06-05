@Component
export struct BottomDialog {
  @Builder
  DefaultBtn() {
  }

  @Builder
  DefaultMain() {
  }

  @Builder
  DefaultToast() {
  }

  @BuilderParam MainContent: () => void = this.DefaultMain
  @BuilderParam longBtn: () => void = this.DefaultBtn
  @BuilderParam CustomShowToast: () => void = this.DefaultToast
  @Prop bdBackgroundColor: Resource
  @Prop bdName: string
  @Prop isHaveLongBtn: boolean
  cancelOnclick: Function = () => {
  }

  build() {
    Column() {
      Stack({ alignContent: Alignment.BottomStart }) {
        Column() {
          this.CustomShowToast()
          Column() {
            Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
              Text(this.bdName)
                .fontSize('20lpx')
              Image($r('app.media.bottomDialogCloseIcon'))
                .width('40lpx')
                .height('40lpx')
                .onClick(() => {
                  this.cancelOnclick()
                })
            }
            .margin({ bottom: '16lpx', left: '16lpx', right: '16lpx' })

            this.MainContent()
            if (this.isHaveLongBtn) {
              this.longBtn()
            }
          }
          .padding({ top: '16lpx', bottom: '16lpx' })
          .borderRadius({ topLeft: '16lpx', topRight: '16lpx' })
          .backgroundColor(this.bdBackgroundColor)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('rgba(25, 25, 25, 0.3)')
    }
    .zIndex(1)
  }
}