import { HeadComponent } from '../../components/headComponent'
import { LongBtnComponent } from '../../components/longBtnComponent'
import { router } from '@kit.ArkUI'
import { OrderPayVO, OrderDetailReturning } from '../../model/interface/api/OrderApiInterface'
import { getOrderDetail, getOrderPay } from '../../api/OrderApi'
import { pasteboard } from '@kit.BasicServicesKit'
import { useToastHook } from '../../service'
import { ResultVO } from '../../utils/Http'
import { resStr } from '../../utils/i18n'

@Entry
@Component
export struct OrderInfo {
  @State isShowMarkLayer: boolean = false
  @State params: OrderPayVO = router.getParams() as OrderPayVO || { orderId: '' } as OrderPayVO
  @State orderDetail: OrderDetailReturning = {
    orderId: '', stationName: '', portName: '', orderAmount: 0,
    startTime: '', endTime: '', orderNo: '', portId: '',
    orderStatus: -1, payTime: new Date(), chargeCapacity: 0,
    chargePower: 0, chargeFee: 0, userName: '',
    initialValue: 0, paymentMethod: '', chargeTime: 0, soc: 0
  }
  @State socEndValue: number = 0
  @State timeDifferent: string = ''
  @State pageLoading: boolean = true
  private context: Context = getContext(this)

  // 安全格式化金额
  private formatAmount(val: number): string {
    if (val === undefined || val === null || isNaN(val)) return '0.00'
    return Number(val).toFixed(2)
  }

  // 订单详情
  async getOrderDetail() {
    try {
      let res = await getOrderDetail<OrderDetailReturning>({ orderId: this.params.orderId })
      if (res) {
        this.orderDetail = res
        let endSoc = (res.initialValue || 0) + (res.chargeCapacity || 0)
        this.socEndValue = endSoc > 100 ? 100 : endSoc

        let startTime = new Date(res.startTime).getTime()
        let endTime = new Date(res.endTime).getTime()
        let time = Number(((endTime - startTime) / 1000).toFixed(0))
        if (isNaN(time) || time < 0) time = 0
        if (time > 3600) {
          this.timeDifferent = `${(time / 3600).toFixed(0)}${resStr(this.context, 'order_info_unit_hour')}`
        } else if (time > 60) {
          this.timeDifferent = `${(time / 60).toFixed(0)}${resStr(this.context, 'order_info_unit_minute')}`
        } else {
          this.timeDifferent = `${time}${resStr(this.context, 'order_info_unit_second')}`
        }
      }
    } catch (e) {
      useToastHook(resStr(this.context, 'order_info_toast_load_fail'), '40lpx')
    } finally {
      this.pageLoading = false
    }
  }

  // 支付订单
  getOrderPay() {
    if (!this.orderDetail?.orderId) return
    getOrderPay<string>({ orderId: this.orderDetail?.orderId }).then((res) => {
      console.info('接口 支付成功', JSON.stringify(res))
      router.pushUrl({
        url: 'pages/order/orderEnd',
        params: {
          price: this.formatAmount(this.orderDetail?.orderAmount)
        }
      })
    }).catch((err: ResultVO<string>) => {
      useToastHook(err.msg || resStr(this.context, 'order_info_toast_pay_fail'), '40lpx')
    })
  }

  // 复制文本
  async _copy(text: string) {
    let pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text)
    let systemPasteboard = pasteboard.getSystemPasteboard()
    await systemPasteboard.setData(pasteData)
    useToastHook(resStr(this.context, 'order_info_toast_copied'), '40lpx')
  }

  aboutToAppear(): void {
    router.clear()
    this.getOrderDetail()
  }

  build() {
    Stack({ alignContent: Alignment.BottomStart }) {
      Column() {
        HeadComponent({
          headName: resStr(this.context, 'order_info_head_name'),
          isHaveBtn: false,
          backUrl: 'pages/order/orderList',
          receive: () => {}
        })

        if (this.pageLoading) {
          Column() {
            LoadingProgress().width('40lpx').height('40lpx')
            Text(resStr(this.context, 'common_loading')).fontSize('14lpx').fontColor('#999999').margin({ top: '12lpx' })
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        } else {
          Row() {
            Image($r('app.media.order_headIcon'))
              .width('36lpx')
              .height('36lpx')
              .margin({ right: '16lpx' })
            Column() {
              Text(this.orderDetail?.orderStatus === 0 ? resStr(this.context, 'order_info_status_in_progress') :
                this.orderDetail?.orderStatus === 1 ? resStr(this.context, 'order_info_status_pending') :
                  this.orderDetail?.orderStatus === 2 ? resStr(this.context, 'order_info_status_completed') : '')
                .fontSize('16lpx').width('100%')
              Row() {
                Text(`${resStr(this.context, 'order_info_label_order_no')}${this.orderDetail?.orderNo || '-'}`)
                  .fontSize('12lpx')
                  .margin({ right: '8lpx' })
                Image($r('app.media.order_copyIcon'))
                  .width('20lpx')
                  .height('20lpx')
              }
              .width('100%')
              .onClick(() => {
                this._copy(this.orderDetail?.orderNo || '')
              })
            }
            .alignSelf(ItemAlign.Start)
          }
          .padding({ left: '16lpx', right: '16lpx', top: '12lpx', bottom: '8lpx' })
          .width('100%')

          Column() {
            Row() {
              Text(resStr(this.context, 'order_info_label_charging_info'))
                .fontColor($r('app.color.historyList_font_color'))
                .fontSize('16lpx')
            }
            .padding({ left: '16lpx', top: '12lpx', bottom: '8lpx' })
            .borderWidth({ bottom: '1lpx' })
            .borderColor($r('app.color.EEEEEE'))
            .width('100%')
            .margin({ bottom: '16lpx' })

            Text(this.orderDetail?.userName || '-')
              .fontColor($r('app.color.historyList_font_color'))
              .fontSize('14lpx')
              .width('100%')
              .padding({ bottom: '8lpx', left: '16lpx', right: '16lpx' })
            Text(this.orderDetail?.stationName || '-')
              .fontColor($r('app.color.historyList_font_color'))
              .fontSize('14lpx')
              .width('100%')
              .padding({ bottom: '8lpx', left: '16lpx', right: '16lpx' })
            Text(`${resStr(this.context, 'order_info_label_port_code')}${this.orderDetail?.portName || '-'}`)
              .fontColor($r('app.color.historyList_font_color'))
              .fontSize('12lpx')
              .width('100%')
              .padding({ bottom: '16lpx', left: '16lpx', right: '16lpx' })

            Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
              Column() {
                Text(this.orderDetail?.startTime ?
                  `${this.orderDetail?.startTime.split(' ')[0].split('-')[1]}${resStr(this.context, 'order_info_unit_month')}${this.orderDetail?.startTime.split(' ')[0].split('-')[2]}${resStr(this.context, 'order_info_unit_day')}` :
                  `-${resStr(this.context, 'order_info_unit_month')}-${resStr(this.context, 'order_info_unit_day')}`)
                  .fontColor($r('app.color.historyList_font_color'))
                  .fontSize('12lpx')
                  .width('100%')
                Text(this.orderDetail?.startTime && this.orderDetail?.startTime.split(' ').length > 1 ?
                  `${this.orderDetail?.startTime.split(' ')[1].split(':')[0]}:${this.orderDetail?.startTime.split(' ')[1].split(':')[1]}` : '-:-')
                  .fontColor($r('app.color.historyList_font_color'))
                  .fontSize('20lpx')
                  .width('100%')
                  .padding({ top: '8lpx', bottom: '8lpx' })
                Text(`SOC ${this.orderDetail?.initialValue || 0}%`)
                  .fontColor($r('app.color.historyList_font_color'))
                  .fontSize('12lpx')
                  .width('100%')
              }
              .alignSelf(ItemAlign.Start)
              .padding({ left: '16lpx', right: '16lpx', top: '12lpx', bottom: '12lpx' })

              Column() {
                Text(this.timeDifferent || '-')
                  .fontColor($r('app.color.charging_font_color'))
                  .fontSize('12lpx')
                  .width('100%')
                  .textAlign(TextAlign.Center)
                Image($r('app.media.order_lineIcon'))
                  .width('142lpx')
                  .height('8lpx')
                  .margin({ top: '8lpx', bottom: '8lpx' })
                Text(resStr(this.context, 'order_info_label_duration'))
                  .fontColor($r('app.color.charging_font_color'))
                  .fontSize('12lpx')
                  .width('100%')
                  .textAlign(TextAlign.Center)
              }
              .padding({ top: '18lpx', bottom: '18lpx' })

              Column() {
                Text(this.orderDetail?.endTime ?
                  `${this.orderDetail?.endTime.split(' ')[0].split('-')[1]}${resStr(this.context, 'order_info_unit_month')}${this.orderDetail?.endTime.split(' ')[0].split('-')[2]}${resStr(this.context, 'order_info_unit_day')}` :
                  `-${resStr(this.context, 'order_info_unit_month')}-${resStr(this.context, 'order_info_unit_day')}`)
                  .fontColor($r('app.color.historyList_font_color'))
                  .fontSize('12lpx')
                  .width('100%')
                  .textAlign(TextAlign.End)
                Text(this.orderDetail?.endTime && this.orderDetail?.endTime.split(' ').length > 1 ?
                  `${this.orderDetail?.endTime.split(' ')[1].split(':')[0]}:${this.orderDetail?.endTime.split(' ')[1].split(':')[1]}` : '-:-')
                  .fontColor($r('app.color.historyList_font_color'))
                  .fontSize('20lpx')
                  .width('100%')
                  .padding({ top: '8lpx', bottom: '8lpx' })
                  .textAlign(TextAlign.End)
                Text(`SOC ${this.socEndValue.toFixed(0)}%`)
                  .fontColor($r('app.color.historyList_font_color'))
                  .fontSize('12lpx')
                  .width('100%')
                  .textAlign(TextAlign.End)
              }
              .padding({ left: '16lpx', right: '16lpx', top: '12lpx', bottom: '12lpx' })
            }

            Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
              Text(resStr(this.context, 'order_info_label_total_kwh'))
                .fontColor($r('app.color.historyList_font_color'))
                .fontSize('12lpx')
              Row() {
                Text(this.formatAmount(this.orderDetail?.chargeCapacity))
                  .fontColor($r('app.color.historyList_font_color'))
                  .fontSize('20lpx')
                Text($r('app.string.common_unit_kwh'))
                  .fontColor($r('app.color.historyList_font_color'))
                  .fontSize('12lpx')
                  .alignSelf(ItemAlign.Baseline)
              }
            }
            .padding({ top: '12lpx' })
            .borderWidth({ top: '1lpx' })
            .borderColor($r('app.color.EEEEEE'))
            .margin({ top: '16lpx', bottom: '16lpx', left: '16lpx', right: '16lpx' })
          }
          .borderRadius('8lpx')
          .margin({ left: '16lpx', right: '16lpx' })
          .backgroundColor($r('app.color.background_color_over'))

          Column() {
            Row() {
              Text(resStr(this.context, 'order_info_label_fee_info'))
                .fontColor($r('app.color.historyList_font_color'))
                .fontSize('16lpx')
            }
            .padding({ left: '16lpx', top: '12lpx', bottom: '8lpx' })
            .borderWidth({ bottom: '1lpx' })
            .borderColor($r('app.color.EEEEEE'))
            .width('100%')

            Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
              Text(resStr(this.context, 'order_info_label_electricity_fee'))
                .fontColor($r('app.color.historyList_font_color'))
                .fontSize('12lpx')
              Row() {
                Text(this.formatAmount(this.orderDetail?.orderAmount))
                  .fontColor($r('app.color.chargingPrice_color'))
                  .fontSize('20lpx')
                Text($r('app.string.common_unit_yuan'))
                  .fontColor($r('app.color.historyList_font_color'))
                  .fontSize('12lpx')
                  .alignSelf(ItemAlign.Baseline)
              }
            }
            .margin({ top: '16lpx', bottom: '16lpx', left: '16lpx', right: '16lpx' })
          }
          .borderRadius('8lpx')
          .margin({ left: '16lpx', right: '16lpx', top: '16lpx' })
          .backgroundColor($r('app.color.background_color_over'))
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.card_background'))

      // 待支付按钮
      if (this.orderDetail?.orderStatus === 1) {
        LongBtnComponent({
          btnColor: $r('app.color.longBtn_blue'),
          btnFontColor: $r('app.color.background_color_over'),
          btnBorderColor: $r('app.color.longBtn_blue'),
          btnName: resStr(this.context, 'order_info_btn_pay_now'),
          onEvent: (data: string) => {
            this.isShowMarkLayer = true
          }
        })
          .margin({ bottom: '16lpx' })
      }

      // 支付弹窗
      if (this.isShowMarkLayer) {
        Stack({ alignContent: Alignment.BottomStart }) {
          // 半透明遮罩
          Column()
            .width('100%')
            .height('100%')
            .backgroundColor('rgba(25, 25, 25, 0.3)')
            .onClick(() => {
              this.isShowMarkLayer = false
            })

          // 弹窗内容（底部弹出）
          Column() {
            // 标题栏
            Row() {
              Text(resStr(this.context, 'order_info_sheet_title'))
                .fontSize('20lpx')
                .fontWeight(FontWeight.Bold)
              Blank()
              Text('✕')
                .fontSize('20lpx')
                .fontColor('#999999')
                .onClick(() => {
                  this.isShowMarkLayer = false
                })
            }
            .width('100%')
            .padding({ left: '16lpx', right: '16lpx', bottom: '16lpx' })

            // 金额
            Row() {
              Text('￥')
                .fontSize('14lpx')
                .alignSelf(ItemAlign.Baseline)
              Text(this.formatAmount(this.orderDetail?.orderAmount))
                .fontSize('28lpx')
                .fontWeight(FontWeight.Bold)
            }
            .justifyContent(FlexAlign.Center)
            .margin({ bottom: '20lpx' })

            // 充电站名称
            Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
              Text(resStr(this.context, 'order_info_sheet_station_name'))
                .fontColor($r('app.color.charging_font_color'))
                .fontSize('14lpx')
              Text(this.orderDetail?.stationName || '-')
                .fontColor($r('app.color.historyList_font_color'))
                .fontSize('14lpx')
                .width('60%')
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .width('100%')
            .padding({ left: '16lpx', right: '16lpx', top: '12lpx', bottom: '12lpx' })

            // 付款方式
            Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
              Text(resStr(this.context, 'order_info_sheet_payment_method'))
                .fontColor($r('app.color.charging_font_color'))
                .fontSize('14lpx')
              Text(resStr(this.context, 'order_info_sheet_voucher'))
                .fontColor($r('app.color.historyList_font_color'))
                .fontSize('14lpx')
            }
            .width('100%')
            .padding({ left: '16lpx', right: '16lpx', top: '12lpx', bottom: '20lpx' })

            // 确认支付按钮
            LongBtnComponent({
              btnColor: $r('app.color.longBtn_red'),
              btnFontColor: $r('app.color.background_color_over'),
              btnBorderColor: $r('app.color.longBtn_red'),
              btnName: resStr(this.context, 'order_info_btn_confirm_pay'),
              onEvent: () => {
                this.getOrderPay()
              }
            })
          }
          .width('100%')
          .padding({ top: '16lpx', left: '4lpx', right: '4lpx', bottom: '24lpx' })
          .borderRadius({ topLeft: '16lpx', topRight: '16lpx' })
          .backgroundColor($r('app.color.background_color_over'))
        }
        .width('100%')
        .height('100%')
        .zIndex(1)
      }
    }
  }
}
