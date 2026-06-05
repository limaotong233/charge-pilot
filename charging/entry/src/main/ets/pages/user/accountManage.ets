import { router } from '@kit.ArkUI'
import { HeadComponent } from '../../components/headComponent';
import { accountItem } from '../../model/interface/userInterface';
import { LongBtnComponent } from '../../components/longBtnComponent';
import { LocalPreferences } from '../../service/LocalPreferences'

@Entry
@Component
export struct AccountManage {
  @State accountList: Array<accountItem> = [
    { name: '头像', value: '' },
    { name: '账号', value: '' },
  ]
  @State accountImage: string = ''
  @State accountName: string = ''

  aboutToAppear() {
    // 首选项持久化存储
    router.clear()
    this.accountName = LocalPreferences.get('accountNumber') as string
    this.accountImage = LocalPreferences.get('accountImageUrl') as string
  }

  // 退出账号
  leaveLogin(data: string) {
  }

  build() {
    Stack({ alignContent: Alignment.BottomStart }) {
      Column() {
        HeadComponent({
          headName: '账号管理',
          backUrl: 'pages/Index',
          tabs: 1
        })
        Column() {
          ForEach(this.accountList, (item: accountItem, index: number) => {
            Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
              Column() {
                Text(item.name)
              }

              if (item.name === '头像') {
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

        LongBtnComponent({
          btnColor: $r('app.color.background_color_over'),
          btnFontColor: $r('app.color.clear_font_color'),
          btnBorderColor: $r('app.color.CECECE'),
          btnName: '退出账号',
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