import { call } from '@kit.TelephonyKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { CustomShowToast } from '../../components/customShowToast'

const TAG = 'HuaweiTelephonyKit'

@CustomDialog
export struct CustomCustomerDialog {
  controller?: CustomDialogController;
  cancel: () => void = () => {
  }
  confirm: () => void = () => {
  }
  @State showTip: boolean = false

  build() {
    Column() {
      Image($r('app.media.customer'))
        .width('190lpx')
        .height('190lpx')
        .margin({
          top: '-10lpx',
        })
      Button('拨打客服电话')
        .width('280lpx')
        .height('40lpx')
        .onClick(() => {
          if (this.controller != undefined) {
            this.call();
          }
        })
        .margin({
          left: '20lpx',
          right: '20lpx',
          top: '-30lpx',
          bottom: '5lpx'
        })
      if (this.showTip) {
        CustomShowToast({
          cusSTBorderRadius: '8lpx',
          cusSTBackgroundColor: 'rgba(252, 227, 223, 1)',
          cusSTText: '本设备不支持拨打电话功能',
          cusSTImage: $r('app.media.customShowToast_error'),
          cusSTFontColor: $r('app.color.longBtn_red')
        })
      }
    }

  }

  call() {
    // 调用查询能力接口
    let isSupport = call.hasVoiceCapability();
    console.log(TAG, 'isSupport', isSupport);
    if (isSupport) {
      // 如果设备支持呼叫能力，则继续跳转到拨号界面，并显示拨号的号码
      call.makeCall('12345678', (err: BusinessError) => {
        if (!err) {
          console.log(TAG, 'make call success.');
        } else {
          console.log(TAG, 'make call fail, err is:' + JSON.stringify(err));
        }
      });
    } else {
      this.showTip = true
      setTimeout(() => {
        this.showTip = false
      }, 2000)
    }
  }
}