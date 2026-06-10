import { LongBtnComponent } from '../../components/longBtnComponent'
import { RegisterFormItem, RegisterErrorsItem } from '../../model/interface/registerInterface'
import { LoginResult } from '../../model/interface/api/LoginApiInterface'
import { router } from '@kit.ArkUI'
import { useToastHook } from '../../service'
import { register } from '../../api/RegisterApi'
import { login, getUserInfo } from '../../api/LoginApi'
import { LocalPreferences } from '../../service/LocalPreferences'
import { ResultVO } from '../../utils/Http'
import { userInfoReturning } from '../../model/interface/api/LoginApiInterface'
import { resStr } from '../../utils/i18n'

@Entry
@Component
struct Register {
  @State form: RegisterFormItem = {
    account: '',
    userName: '',
    password: '',
    confirmPassword: ''
  }
  @State errors: RegisterErrorsItem = {}

  private validateForm(): boolean {
    this.validateAccount(this.form.account)
    this.validateUserName(this.form.userName)
    this.validatePassword(this.form.password)
    this.validateConfirmPassword(this.form.confirmPassword)
    return !Object.values(this.errors).some(Boolean)
  }

  private validateAccount(value: string) {
    if (!value) {
      this.errors.account = resStr(getContext(this), 'register_error_account_empty')
    } else if (value.length < 3 || value.length > 20) {
      this.errors.account = resStr(getContext(this), 'register_error_account_length')
    } else {
      this.errors.account = undefined
    }
  }

  private validateUserName(value: string) {
    if (!value) {
      this.errors.userName = resStr(getContext(this), 'register_error_nickname_empty')
    } else {
      this.errors.userName = undefined
    }
  }

  private validatePassword(value: string) {
    if (!value) {
      this.errors.password = resStr(getContext(this), 'register_error_password_empty')
    } else if (value.length < 6) {
      this.errors.password = resStr(getContext(this), 'register_error_password_length')
    } else {
      this.errors.password = undefined
    }
  }

  private validateConfirmPassword(value: string) {
    if (!value) {
      this.errors.confirmPassword = resStr(getContext(this), 'register_error_confirm_empty')
    } else if (value !== this.form.password) {
      this.errors.confirmPassword = resStr(getContext(this), 'register_error_confirm_mismatch')
    } else {
      this.errors.confirmPassword = undefined
    }
  }

  // 注册接口
  async registerApp() {
    let registerSuccess = false
    await register<LoginResult>(this.form)
      .then(() => {
        registerSuccess = true
      })
      .catch((err: ResultVO<string>) => {
        useToastHook(err.msg, '40lpx')
      })

    if (!registerSuccess) return

    // 注册成功后自动登录（JWT 已在 Http.ets 中存储）
    LocalPreferences.put('account', this.form.userName || this.form.account)
    LocalPreferences.put('accountPassword', this.form.password)
    LocalPreferences.flush()

    getUserInfo<userInfoReturning>({ v: '' }).then((resUserInfo) => {
      if (resUserInfo) {
        LocalPreferences.put('account', resUserInfo.userName ? resUserInfo.userName : resUserInfo.account)
        LocalPreferences.put('accountNumber', resUserInfo.account)
        LocalPreferences.put('accountImage', resUserInfo.avatar ? resUserInfo.avatar.fileAccessUrl : '')
        LocalPreferences.flush()

        useToastHook(resStr(getContext(this), 'register_success'), '32lpx')
        router.pushUrl({ url: 'pages/Index' })
      }
    }).catch((err: ResultVO<string>) => {
      // 用户信息获取失败，跳转登录页
      useToastHook(resStr(getContext(this), 'register_success_login'), '32lpx')
      router.pushUrl({ url: 'pages/login/index' })
    })
  }

  onPageShow(): void {
    router.clear()
  }

  build() {
    Stack({ alignContent: Alignment.BottomStart }) {
      Column() {
        Column() {
          Image($r('app.media.loginLog'))
            .width('68lpx')
            .height('68lpx')
            .margin({ top: '44lpx', bottom: '40lpx' })

          Text($r('app.string.register_title'))
            .fontSize('20lpx')
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: '24lpx' })

          Column() {
            // 账号
            Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
              Text($r('app.string.login_label_account'))
                .width('56lpx')
              TextInput({
                text: this.form.account,
                placeholder: this.errors.account ? this.errors.account : $r('app.string.register_placeholder_account')
              })
                .height('40lpx')
                .placeholderFont({ size: '14lpx' })
                .placeholderColor(this.errors.account ? 'rgb(246, 75, 75)' : $r('app.color.999999'))
                .backgroundColor($r('app.color.background_color_over'))
                .margin({ top: '17.5lpx', bottom: '17.5lpx' })
                .onChange((value: string) => {
                  this.form.account = value
                  this.validateAccount(value)
                })
            }
            .borderWidth({ bottom: '1lpx' })
            .borderColor({ bottom: $r('app.color.EEEEEE') })

            // 用户名
            Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
              Text($r('app.string.register_label_nickname'))
                .width('56lpx')
              TextInput({
                text: this.form.userName,
                placeholder: this.errors.userName ? this.errors.userName : $r('app.string.register_placeholder_nickname')
              })
                .height('40lpx')
                .placeholderFont({ size: '14lpx' })
                .placeholderColor(this.errors.userName ? 'rgb(246, 75, 75)' : $r('app.color.999999'))
                .backgroundColor($r('app.color.background_color_over'))
                .margin({ top: '17.5lpx', bottom: '17.5lpx' })
                .onChange((value: string) => {
                  this.form.userName = value
                  this.validateUserName(value)
                })
            }
            .borderWidth({ bottom: '1lpx' })
            .borderColor({ bottom: $r('app.color.EEEEEE') })

            // 密码
            Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
              Text($r('app.string.login_label_password'))
                .width('56lpx')
              TextInput({
                text: this.form.password,
                placeholder: this.errors.password ? this.errors.password : $r('app.string.register_placeholder_password')
              })
                .height('40lpx')
                .placeholderFont({ size: '14lpx' })
                .placeholderColor(this.errors.password ? 'rgb(246, 75, 75)' : $r('app.color.999999'))
                .type(InputType.Password)
                .backgroundColor($r('app.color.background_color_over'))
                .margin({ top: '17.5lpx', bottom: '17.5lpx' })
                .onChange((value: string) => {
                  this.form.password = value
                  this.validatePassword(value)
                })
            }
            .borderWidth({ bottom: '1lpx' })
            .borderColor({ bottom: $r('app.color.EEEEEE') })

            // 确认密码
            Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
              Text($r('app.string.register_label_confirm'))
                .width('56lpx')
              TextInput({
                text: this.form.confirmPassword,
                placeholder: this.errors.confirmPassword ? this.errors.confirmPassword : $r('app.string.register_placeholder_confirm')
              })
                .height('40lpx')
                .placeholderFont({ size: '14lpx' })
                .placeholderColor(this.errors.confirmPassword ? 'rgb(246, 75, 75)' : $r('app.color.999999'))
                .type(InputType.Password)
                .backgroundColor($r('app.color.background_color_over'))
                .margin({ top: '17.5lpx', bottom: '17.5lpx' })
                .onChange((value: string) => {
                  this.form.confirmPassword = value
                  this.validateConfirmPassword(value)
                })
            }
          }
          .padding({ left: '16lpx', right: '16lpx' })
          .margin({ left: '16lpx', right: '16lpx', bottom: '32lpx' })
          .borderRadius('16lpx')
          .backgroundColor($r('app.color.background_color_over'))

          LongBtnComponent({
            btnColor: $r('app.color.longBtn_blue'),
            btnFontColor: $r('app.color.background_color_over'),
            btnBorderColor: $r('app.color.longBtn_blue'),
            btnName: resStr(getContext(this), 'register_btn_submit'),
            onEvent: (data: string) => {
              if (this.validateForm()) {
                this.registerApp()
              }
            }
          })

          // 已有账号，去登录
          Row() {
            Text($r('app.string.register_has_account'))
              .fontSize('14lpx')
              .fontColor($r('app.color.999999'))
            Text($r('app.string.register_go_login'))
              .fontSize('14lpx')
              .fontColor('#2196F3')
              .margin({ left: '4lpx' })
              .onClick(() => {
                router.pushUrl({ url: 'pages/login/index' })
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
