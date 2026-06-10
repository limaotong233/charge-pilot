import { LongBtnComponent } from '../../components/longBtnComponent'
import { errorsItem, formItem } from '../../model/interface/loginInterface'
import { userInfoReturning } from '../../model/interface/api/LoginApiInterface'
import { router } from '@kit.ArkUI'
import { useToastHook } from '../../service'
import { login, getUserInfo } from '../../api/LoginApi'
import { LocalPreferences } from '../../service/LocalPreferences'
import { ResultVO } from '../../utils/Http'
import { resStr } from '../../utils/i18n'

@Entry
@Component
export struct Login {
  @State form: formItem = {
    account: LocalPreferences.get('account') as string || '',
    password: LocalPreferences.get('accountPassword') as string || ''
  }
  @State errors: errorsItem = { account: '', password: '' }

  private validateForm(): boolean {
    this.validateUsername(this.form.account)
    this.validatePassword(this.form.password)

    return !Object.values(this.errors).some(Boolean)
  }

  private validateUsername(value: string) {
    if (!value) {
      this.errors.account = resStr(getContext(this), 'login_error_account_empty')
    } else {
      this.errors.account = undefined
    }
  }

  private validatePassword(value: string) {
    if (!value) {
      this.errors.password = resStr(getContext(this), 'login_error_password_empty')
    } else {
      this.errors.password = undefined
    }
  }

  // 登录接口
  async loginApp() {
    let loginSuccess = false
    await login<string>(this.form)
      .then(() => {
        loginSuccess = true
      })
      .catch((err: ResultVO<string>) => {
        useToastHook(err.msg, '40lpx')
        console.log('==>MyLog-login', JSON.stringify(err))
      })

    if (!loginSuccess) return

    // JWT Token 已在 Http.ets 的登录响应处理中自动存储
    LocalPreferences.put('account', this.form.account)
    LocalPreferences.put('accountPassword', this.form.password)
    LocalPreferences.flush()

    getUserInfo<userInfoReturning>({ v: '' }).then((resUserInfo) => {
      if (resUserInfo) {
        LocalPreferences.put('account', resUserInfo.userName ? resUserInfo.userName : resUserInfo.account)
        LocalPreferences.put('accountNumber', resUserInfo.account)
        LocalPreferences.put('accountImage', resUserInfo.avatar ? resUserInfo.avatar.fileAccessUrl : '')
        LocalPreferences.flush()

        router.pushUrl({
          url: 'pages/Index'
        })
      }
    }).catch((err: ResultVO<string>) => {
      useToastHook(err.msg, '40lpx')
    })
  }

  onPageShow(): void {
    router.clear()
    // JWT 自动登录：检查 accessToken 是否存在
    if (LocalPreferences.get('accessToken')) {
      router.replaceUrl({
        url: 'pages/Index'
      })
    }
  }

  build() {
    Stack({ alignContent: Alignment.BottomStart }) {
      Column() {
        Column() {
          Image($r('app.media.loginLog'))
            .width('68lpx')
            .height('68lpx')
            .margin({ top: '44lpx', bottom: '56lpx' })
          Column() {
            Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
              Text($r('app.string.login_label_account'))
                .width('48lpx')

              TextInput({
                text: this.form.account,
                placeholder: this.errors.account ? this.errors.account : $r('app.string.login_placeholder_account')
              })
                .height('40lpx')
                .placeholderFont({
                  size: '16lpx'
                })
                .placeholderColor(this.errors.account ? 'rgb(246, 75, 75)' : $r('app.color.999999'))
                .backgroundColor($r('app.color.background_color_over'))
                .margin({ top: '17.5lpx', bottom: '17.5lpx' })
                .onChange((value: string) => {
                  this.form.account = value
                  this.validateUsername(value)
                })

            }
            .borderWidth({ bottom: '1lpx' })
            .borderColor({ bottom: $r('app.color.EEEEEE') })

            Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
              Text($r('app.string.login_label_password'))
                .width('48lpx')

              TextInput({
                text: this.form.password,
                placeholder: this.errors.password ? this.errors.password : $r('app.string.login_placeholder_password')
              })
                .height('40lpx')
                .placeholderFont({
                  size: '16lpx'
                })
                .placeholderColor(this.errors.password ? 'rgb(246, 75, 75)' : $r('app.color.999999'))
                .type(InputType.Password)
                .backgroundColor($r('app.color.background_color_over'))
                .margin({ top: '17.5lpx', bottom: '17.5lpx' })
                .onChange((value: string) => {
                  this.form.password = value
                  this.validatePassword(value)
                })
            }
          }
          .padding({ left: '16lpx', right: '16lpx' })
          .margin({ left: '16lpx', right: '16lpx', bottom: '40lpx' })
          .borderRadius('16lpx')
          .backgroundColor($r('app.color.background_color_over'))

          LongBtnComponent({
            btnColor: $r('app.color.longBtn_blue'),
            btnFontColor: $r('app.color.background_color_over'),
            btnBorderColor: $r('app.color.longBtn_blue'),
            btnName: resStr(getContext(this), 'login_btn_submit'),
            onEvent: (data: string) => {
              if (this.validateForm()) {
                this.loginApp()
              }
            }
          })

          // 没有账号，去注册
          Row() {
            Text($r('app.string.login_no_account'))
              .fontSize('14lpx')
              .fontColor($r('app.color.999999'))
            Text($r('app.string.login_go_register'))
              .fontSize('14lpx')
              .fontColor('#2196F3')
              .margin({ left: '4lpx' })
              .onClick(() => {
                router.pushUrl({ url: 'pages/register/index' })
              })
          }
          .margin({ top: '16lpx' })
        }
        .width('100%')
        .height('100%')
        .alignSelf(ItemAlign.Center)
      }.width('100%')
      .height('100%')
      .backgroundColor($r('app.color.card_background'))
    }
  }
}
