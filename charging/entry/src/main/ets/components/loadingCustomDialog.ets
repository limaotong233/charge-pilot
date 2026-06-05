import { LoadingDialog } from '@kit.ArkUI'

@Component
export struct LoadingCustomDialog {
  @Prop dialogTitle: string
  @Prop autoCancel: boolean
  @Link @Watch('onChangeCloseDialog') closeDialog: boolean
  // 弹窗 结束充电
  dialogControllerProgress: CustomDialogController = new CustomDialogController({
    builder: LoadingDialog({
      content: `${this.dialogTitle}…`
    }),
    autoCancel: false,
    backgroundBlurStyle: BlurStyle.COMPONENT_ULTRA_THICK
  })

  aboutToAppear(): void {
    this.dialogControllerProgress.open()
    setTimeout(() => {
      this.dialogControllerProgress.close()
    },2500)
  }

  onChangeCloseDialog() {
    if (!this.closeDialog) {
      // this.dialogControllerProgress.close()
    }
  }

  build() {
    Stack() {
    }
    .width('100%')
    .height('100%')
  }
}