import { LongBtnComponent } from '../../components/longBtnComponent'
import { router } from '@kit.ArkUI'
import { OrderPayPrice } from '../../model/interface/api/OrderApiInterface'
import { resStr } from '../../utils/i18n'

@Entry
@Component
export struct OrderEnd {
  @State params: OrderPayPrice = router.getParams() as OrderPayPrice || { price: '0' } as OrderPayPrice
  private context: Context = getContext(this)

  // 安全获取价格数值
  private getPrice(): number {
    let val = Number(this.params.price)
    if (isNaN(val)) return 0
    return val
  }

  build() {
    Column() {
      Column() {
        Row() {
          Image($r('app.media.orderEnd_successIcon'))
            .margin({ top: '100lpx', bottom: '6lpx' })
            .width('48lpx')
            .height('48lpx')
        }

        Row() {
          Text(resStr(getContext(this), 'order_end_title'))
            .fontSize('12lpx')
        }

        Row() {
          Text('￥')
            .fontSize('14lpx')
          Text(this.getPrice().toFixed(2))
            .fontSize('24lpx')
        }
        .padding({ top: '10lpx', bottom: '20lpx' })
        .margin({ top: '15lpx', bottom: '51lpx' })

        Column() {
          Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
            Text(resStr(getContext(this), 'order_end_label_total'))
              .fontColor($r('app.color.charging_font_color'))
              .fontSize('14lpx')
            Row() {
              Text('￥')
                .fontColor($r('app.color.historyList_font_color'))
                .fontSize('14lpx')
              Text(this.getPrice().toFixed(2))
                .fontColor($r('app.color.historyList_font_color'))
                .fontSize('14lpx')
            }
          }
          .borderWidth({ bottom: '1lpx' })
          .borderColor($r('app.color.EEEEEE'))
          .padding({ top: '17.5lpx', bottom: '12.5lpx' })
          .margin({ left: '16lpx', right: '16lpx' })

          Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
            Text(resStr(getContext(this), 'order_end_label_voucher_deduction'))
              .fontColor($r('app.color.charging_font_color'))
              .fontSize('14lpx')
            Row() {
              Text(resStr(getContext(this), 'order_end_label_voucher_100'))
                .fontColor($r('app.color.historyList_font_color'))
                .fontSize('14lpx')
                .margin({ right: '8lpx' })
              Text(`x${Math.ceil(this.getPrice() / 100)}`)
                .fontColor($r('app.color.historyList_font_color'))
                .fontSize('14lpx')
            }
          }
          .borderWidth({ bottom: '1lpx' })
          .borderColor($r('app.color.EEEEEE'))
          .padding({ top: '17.5lpx', bottom: '12.5lpx' })
          .margin({ left: '16lpx', right: '16lpx' })

          Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
            Text(resStr(getContext(this), 'order_end_label_discount'))
              .fontColor($r('app.color.charging_font_color'))
              .fontSize('14lpx')
            Row() {
              Text('-￥')
                .fontColor($r('app.color.chargingPrice_color'))
                .fontSize('14lpx')
              Text(this.getPrice().toFixed(2))
                .fontColor($r('app.color.chargingPrice_color'))
                .fontSize('14lpx')
            }
          }
          .padding({ top: '17.5lpx', bottom: '12.5lpx' })
          .margin({ left: '16lpx', right: '16lpx' })
        }
        .borderRadius('8lpx')
        .margin({ left: '16lpx', right: '16lpx', top: '16lpx' })
        .backgroundColor($r('app.color.background_color_over'))
      }
      .width('100%')

      LongBtnComponent({
        btnColor: $r('app.color.F7F5F5'),
        btnFontColor: $r('app.color.longBtn_red'),
        btnBorderColor: $r('app.color.CECECE'),
        btnName: resStr(getContext(this), 'order_end_btn_done'),
        onEvent: (data: string) => {
          router.pushUrl({
            url: 'pages/Index'
          })
        }
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.card_background'))
  }
}
