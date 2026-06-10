import { LengthMetrics, router } from '@kit.ArkUI'
import { toosItem } from '../../model/interface/userInterface'
import { CustomCustomerDialog } from './customer'
import { LocalPreferences } from '../../service/LocalPreferences'
import { geoLocationManager } from '@kit.LocationKit'
import { resStr } from '../../utils/i18n'

@Component
export struct User {
  @State account: string = LocalPreferences.get('account') as string
  dialogController: CustomDialogController | null = new CustomDialogController({
    builder: CustomCustomerDialog(),
    autoCancel: true,
    onWillDismiss: (dismissDialogAction: DismissDialogAction) => {
      console.info('reason=' + JSON.stringify(dismissDialogAction.reason))
      console.info('dialog onWillDismiss')
      if (dismissDialogAction.reason == DismissReason.PRESS_BACK) {
        dismissDialogAction.dismiss();
      }
      if (dismissDialogAction.reason == DismissReason.TOUCH_OUTSIDE) {
        dismissDialogAction.dismiss();
      }
    },
    alignment: DialogAlignment.Center,
    offset: { dx: 0, dy: -20 },
    customStyle: false,
    cornerRadius: 20,
    width: '328lpx',
    height: '240lpx',
    backgroundColor: Color.White,
  })
  @StorageProp('currentBreakpoint') curBp: string = 'sm'
  @State toolsList: Array<toosItem> = [
    { type: 0, name: 'user_tool_find_station', url: 'pages/home/siteSearch' },
    { type: 1, name: 'user_tool_route_planning', url: 'pages/routePlanning/index' },
    { type: 2, name: 'user_tool_station_collection', url: 'pages/siteCollection/collectSpots' },
    { type: 3, name: 'user_tool_coupons', url: 'pages/cardCoupons/index' },
    { type: 4, name: 'user_tool_advance_charging', url: 'pages/advanceCharging/index' },
    { type: 5, name: 'user_tool_orders', url: 'pages/order/orderList' },
    { type: 6, name: 'user_tool_charging_tutorial', url: 'pages/tutorial/index' },
    { type: 7, name: 'user_tool_customer_service', url: 'pages/BackgroundVoice' },
    { type: 8, name: 'user_tool_charging_analytics', url: 'pages/analytics/index' },
  ]
  @Prop accountImage: string // = LocalPreferences.get('accountImageUrl') as string

  async aboutToAppear() {
    let location = await geoLocationManager.getCurrentLocation();
    AppStorage.setOrCreate('startSpot', resStr(getContext(this), 'user_default_location'))
    AppStorage.setOrCreate('startSpotLocation', location)
    AppStorage.setOrCreate('endSpot', '')
    AppStorage.setOrCreate('endSpotLocation', null)

  }


  build() {
    Stack({ alignContent: Alignment.BottomStart }) {
      Column() {
        Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
          Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
            Image(this.accountImage ? this.accountImage : $r('app.media.userAccount_headIcon'))
              .width('48lpx')
              .height('48lpx')
              .borderRadius('48lpx')
            Column() {
              Row() {
                Text(this.account)
              }
              .width('100%')

              Row() {
                Text($r('app.string.user_btn_account_manage'))
                  .fontSize('12lpx')
              }
              .borderRadius('16lpx')
              .alignSelf(ItemAlign.Start)
              .backgroundColor($r('app.color.tag_background'))
              .padding({
                left: '16lpx',
                right: '16lpx',
                top: '3lpx',
                bottom: '3lpx'
              })
              .margin({ top: '8lpx' })
            }
            .width('80%')
            .margin({ left: '12lpx' })
          }

          Image($r('app.media.user_rightIcon'))
            .width('20lpx')
            .height('20lpx')
        }
        .padding({
          left: '12lpx',
          right: '12lpx',
          bottom: '16lpx',
          top: '16lpx'
        })
        .margin({top: '16lpx'})
        .borderRadius('16lpx')
        .width('100%')
        .backgroundColor($r('app.color.background_color_over'))
        .onClick(() => {
          router.pushUrl({
            url: 'pages/user/accountManage'
          })
        })

        Row() {
          Text($r('app.string.user_label_common_tools'))
        }
        .width('100%')
        .margin({ top: '24lpx', bottom: '13lpx' })
        .alignSelf(ItemAlign.Start)

        Flex({
          justifyContent: FlexAlign.SpaceBetween,
          wrap: FlexWrap.Wrap,
          space: { main: LengthMetrics.lpx(0), cross: LengthMetrics.lpx(0) }
        }) {
          ForEach(this.toolsList, (item: toosItem, index: number) => {
            Column() {
              Image($r(`app.media.user_toolType${item.type}`))
                .width('24lpx')
                .height('24lpx')
                .margin({ bottom: '8lpx', left: '17lpx', right: '17lpx' })
              Text(resStr(getContext(this), this.toolsList[index].name))
                .fontSize('12lpx')
                .fontColor($r('app.color.bottom_nav_fontcolor'))
            }
            .margin({ top: '12lpx', left: '12lpx', right: '12lpx' })
            .onClick(() => {
              if (item.type === 1) {
                AppStorage.setOrCreate('switch', true)
              }
              if (item.type === 7) {
                if (this.dialogController != null) {
                  this.dialogController.open();
                }
                return
              }
              router.clear()
              router.pushUrl({
                url: item.url
              })
            })
          }, (index: string) => index)
        }
        .padding({ bottom: '12lpx' })
        .width('100%')
        .borderRadius('16lpx')
        .backgroundColor($r('app.color.background_color_over'))
      }
      .margin({ left: this.curBp === 'sm' ? '0lpx' : '108lpx' })
      .padding({ left: '16lpx', right: this.curBp === 'sm' ? '16lpx' : '124lpx' })
      .backgroundColor($r('app.color.card_background'))
      .height('100%')
      .width('100%')
    }
  }
}