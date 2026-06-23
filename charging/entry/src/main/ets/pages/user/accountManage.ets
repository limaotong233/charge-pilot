import { router } from '@kit.ArkUI'
import { HeadComponent } from '../../components/headComponent';
import { accountItem } from '../../model/interface/userInterface';
import { LongBtnComponent } from '../../components/longBtnComponent';
import { LocalPreferences } from '../../service/LocalPreferences'
import { resStr } from '../../utils/i18n'
import { useToastHook } from '../../service'

@Entry
@Component
export struct AccountManage {
  @State accountList: Array<accountItem> = [
    { name: 'account_manage_label_avatar', value: '' },
    { name: 'account_manage_label_account', value: '' },
  ]
  @State accountImage: string = ''
  @State accountName: string = ''
  @State ip1: string = ''
  @State ip2: string = ''
  @State ip3: string = ''
  @State ip4: string = ''

  aboutToAppear() {
    // 首选项持久化存储
    router.clear()
    this.accountName = LocalPreferences.get('accountNumber') as string
    this.accountImage = LocalPreferences.get('accountImageUrl') as string
    // 解析已保存的 IP
    const savedIp = (LocalPreferences.get('serverIp') as string) || '192.168.1.121'
    const parts = savedIp.split('.')
    if (parts.length === 4) {
      this.ip1 = parts[0]
      this.ip2 = parts[1]
      this.ip3 = parts[2]
      this.ip4 = parts[3]
    }
  }

  // 退出账号
  leaveLogin(data: string) {
  }

  build() {
    Stack({ alignContent: Alignment.BottomStart }) {
      Column() {
        HeadComponent({
          headName: resStr(getContext(this), 'account_manage_head_name'),
          backUrl: 'pages/Index',
          tabs: 1
        })
        Column() {
          ForEach(this.accountList, (item: accountItem, index: number) => {
            Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
              Column() {
                Text(resStr(getContext(this), item.name))
              }

              if (item.name === 'account_manage_label_avatar') {
                Flex({ justifyContent: FlexAlign.End, alignItems: ItemAlign.Center }) {
                  Column() {
                    Image(this.accountImage !== '' ? this.accountImage : $r('app.media.userAccount_headIcon'))
                      .width('32lpx')
                      .height('32lpx')
                      .borderRadius('32lpx')

                  }

                  // Column() {
                  //   Image($r('app.media.userAccount_RightIcon'))
                  //     .width('16lpx')
                  //     .height('16lpx')
                  //     .margin({ left: '8lpx' })
                  // }
                }
                .width('50%')
              } else {
                Flex({ justifyContent: FlexAlign.End, alignItems: ItemAlign.Center }) {
                  Text(this.accountName !== '' ? this.accountName : item.value)
                }
                .width('50%')
              }
            }
            .margin({ left: '16lpx', right: '16lpx' })
            .padding({ top: '12lpx', bottom: '12lpx' })
            .borderWidth({ bottom: index === this.accountList.length - 1 ? '0' : '1lpx' })
            .borderColor({ bottom: $r('app.color.EEEEEE') })
          }, (index: string) => index)
        }
        .margin('16lpx')
        .borderRadius('16lpx')
        .backgroundColor($r('app.color.background_color_over'))

        // 服务器 IP 配置
        Column() {
          Text('服务器地址')
            .width('100%')
            .padding({ left: '16lpx', top: '12lpx', bottom: '8lpx' })

          Flex({ justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
            TextInput({ placeholder: '192' })
              .type(InputType.PhoneNumber)
              .textAlign(TextAlign.Center)
              .backgroundColor('#F5F5F5')
              .borderRadius('8lpx')
              .width('60lpx')
              .height('40lpx')
              .fontSize('16lpx')
              .onChange((v: string) => { this.ip1 = v })

            Text('.').fontSize('20lpx').fontWeight(FontWeight.Bold).margin({ left: '4lpx', right: '4lpx' })

            TextInput({ placeholder: '168' })
              .type(InputType.PhoneNumber)
              .textAlign(TextAlign.Center)
              .backgroundColor('#F5F5F5')
              .borderRadius('8lpx')
              .width('60lpx')
              .height('40lpx')
              .fontSize('16lpx')
              .onChange((v: string) => { this.ip2 = v })

            Text('.').fontSize('20lpx').fontWeight(FontWeight.Bold).margin({ left: '4lpx', right: '4lpx' })

            TextInput({ placeholder: '1' })
              .type(InputType.PhoneNumber)
              .textAlign(TextAlign.Center)
              .backgroundColor('#F5F5F5')
              .borderRadius('8lpx')
              .width('60lpx')
              .height('40lpx')
              .fontSize('16lpx')
              .onChange((v: string) => { this.ip3 = v })

            Text('.').fontSize('20lpx').fontWeight(FontWeight.Bold).margin({ left: '4lpx', right: '4lpx' })

            TextInput({ placeholder: '121' })
              .type(InputType.PhoneNumber)
              .textAlign(TextAlign.Center)
              .backgroundColor('#F5F5F5')
              .borderRadius('8lpx')
              .width('60lpx')
              .height('40lpx')
              .fontSize('16lpx')
              .onChange((v: string) => { this.ip4 = v })
          }
          .width('100%')
          .padding({ left: '16lpx', right: '16lpx', bottom: '12lpx' })

          // 保存按钮
          Text('保存')
            .fontSize('14lpx')
            .fontColor(Color.White)
            .backgroundColor('#4f6ef7')
            .borderRadius('8lpx')
            .textAlign(TextAlign.Center)
            .width('100%')
            .height('36lpx')
            .margin({ left: '16lpx', right: '16lpx', bottom: '12lpx' })
            .onClick(() => {
              if (this.ip1.length > 0 && this.ip2.length > 0 && this.ip3.length > 0 && this.ip4.length > 0) {
                const ip = `${this.ip1}.${this.ip2}.${this.ip3}.${this.ip4}`
                LocalPreferences.put('serverIp', ip)
                LocalPreferences.flush()
                useToastHook(`已更新为 ${ip}`, '32lpx')
              } else {
                useToastHook('请填写完整的 IP 地址', '32lpx')
              }
            })
        }
        .margin('16lpx')
        .borderRadius('16lpx')
        .backgroundColor($r('app.color.background_color_over'))

        LongBtnComponent({
          btnColor: $r('app.color.background_color_over'),
          btnFontColor: $r('app.color.clear_font_color'),
          btnBorderColor: $r('app.color.CECECE'),
          btnName: resStr(getContext(this), 'account_manage_btn_logout'),
          onEvent: (data: string) => {

            console.info('退出账号', data)
            AppStorage.setOrCreate('continueCarStatus', '点击前往')
            AppStorage.setOrCreate('continueIsShowSheet', false)
            AppStorage.setOrCreate('siteItemInfo', null)
            AppStorage.setOrCreate('continueEndTarget', undefined)
            AppStorage.setOrCreate('routerParamsSiteInfo', undefined)
            AppStorage.setOrCreate('continueMapBtnIsEnterSpot', '进入仿真充电站')
            LocalPreferences.delete('accessToken')
            LocalPreferences.delete('refreshToken')
            LocalPreferences.delete('account')
            LocalPreferences.delete('accountPassword')
            LocalPreferences.delete('accountImage')
            LocalPreferences.delete('accountNumber')
            LocalPreferences.delete('accountImageUrl')
            LocalPreferences.flush()
            router.pushUrl({
              url: 'pages/login/index'
            })
          }
        }).position({ bottom: '16lpx' })
      }
      .backgroundColor($r('app.color.card_background'))
      .height('100%')
      .width('100%')
    }
  }
}