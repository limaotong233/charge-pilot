import { OrderListItem } from '../../../model/interface/api/OrderApiInterface'
import { LocalPreferences } from '../../../service/LocalPreferences'
import { router } from '@kit.ArkUI'

@Component
export struct OrderItemCard {
  @Prop orderDetail: OrderListItem

  build() {
    Column() {
      Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
        Text(this.orderDetail.stationName)
          .fontColor($r('app.color.historyList_font_color'))
          .fontSize('14lpx')
          .fontWeight('bold')
          .width('90%')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Row() {
          Text(this.orderDetail.orderStatus === 0 ? '进行中' :
            this.orderDetail.orderStatus === 1 ? '待支付' : this.orderDetail.orderStatus === 2 ? `已完成` : '')
            .fontColor(this.orderDetail.orderStatus === 0 ? $r('app.color.F9A01E') :
              this.orderDetail.orderStatus === 1 ? $r('app.color.F9A01E') :
                this.orderDetail.orderStatus === 2 ? $r('app.color.longBtn_blue') : $r('app.color.F9A01E'))
            .fontSize('12lpx')
            .margin({ right: '8lpx' })
          Image($r('app.media.userAccount_RightIcon'))
            .width('7lpx')
            .height('13lpx')
        }

      }.margin({ bottom: '16lpx' })

      Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
        Column() {
          Text(`用户名：${LocalPreferences.get('account')}`)
            .fontSize('12lpx')
            .fontColor($r('app.color.historyList_font_color'))
            .margin({ bottom: '8lpx' })
            .textAlign(TextAlign.Start)
            .width('100%')
          Text(`充电量：${this.orderDetail.chargeCapacity ? `${Number(this.orderDetail.chargeCapacity).toFixed(2)} KWh` :
            '--'}`)
            .fontSize('12lpx')
            .fontColor($r('app.color.historyList_font_color'))
            .margin({ bottom: '8lpx' })
            .textAlign(TextAlign.Start)
            .width('100%')
          if (this.orderDetail.orderStatus === 2) {
            Text(`支付时间：${this.orderDetail.payTime}`)
              .fontSize('12lpx')
              .fontColor($r('app.color.historyList_font_color'))
              .textAlign(TextAlign.Start)
              .width('100%')
          }
        }
        .width('70%')

        Column() {
          Text(`￥${Number(this.orderDetail.orderAmount).toFixed(2)}`)
            .fontSize('16lpx')
            .fontColor($r('app.color.historyList_font_color'))
            .fontWeight('bold')
            .margin({ top: '5lpx' })
          Text('卡券抵扣')
            .margin({ top: '15lpx' })
            .borderRadius('10lpx')
            .borderWidth('1lpx')
            .borderColor($r('app.color.charging_font_color'))
            .padding({
              top: '4lpx',
              bottom: '4lpx',
              left: '12lpx',
              right: '12lpx'
            })
            .fontSize('10lpx')
            .fontColor($r('app.color.historyList_font_color'))
        }
      }
      .width('100%')

      if (this.orderDetail.orderStatus === 1) {
        Column() {
          Text('立即支付')
            .fontSize('14lpx')
            .fontColor($r('app.color.btn_blue'))
            .margin({ top: '8lpx' })
            .textAlign(TextAlign.Center)
        }
        .margin({ top: '16lpx' })
        .width('100%')
        .borderWidth({ top: '1lpx' })
        .borderColor($r('app.color.EEEEEE'))
        .onClick(() => {
          router.pushUrl({
            url: 'pages/order/orderInfo',
            params: {
              orderId: this.orderDetail.orderId
            }
          })
        })
      }
    }
    .padding({
      top: '12lpx',
      bottom: '12lpx',
      left: '16lpx',
      right: '16lpx'
    })
    .borderRadius('8lpx')
    .width('100%')
    .backgroundColor($r('app.color.background_color_over'))
    .onClick(() => {
      if (this.orderDetail.orderStatus === 0) {
        router.pushUrl({
          url: 'pages/charging/inCharging',
          params: {
            orderId: this.orderDetail.orderId
          }
        })
      } else {
        router.pushUrl({
          url: 'pages/order/orderInfo',
          params: {
            orderId: this.orderDetail.orderId
          }
        })
      }
    })
  }
}