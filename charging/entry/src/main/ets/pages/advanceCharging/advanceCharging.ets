import { LongBtnComponent } from '../../components/longBtnComponent'
import { customDataFormat, formatDate } from '../../utils/dataFormat'
import { promptAction, router } from '@kit.ArkUI'
import { aChargingTabContent2 } from './aChargingTabContent2'
import { LocalPreferences } from '../../service/LocalPreferences'
import { useToastHook } from '../../service'
import { ReserveAddVO, ReserveDetailReturning } from '../../model/interface/api/AdvanceChargingApiInterface'
import { getReserveAdd, getReserveDetail } from '../../api/AdvanceChargingApi'
import {
  OrderCreateReturning,
  OrderCreateVO,
  OrderListReturning,
  OrderListVO
} from '../../model/interface/api/OrderApiInterface'
import { getOrderCreate, getOrderList } from '../../api/OrderApi'
import { CardService, CardFormData } from '../../service/Card'
import { ResultVO } from '../../utils/Http'
import { resStr } from '../../utils/i18n'

@Component
export struct AdvanceCharging2 {
  @Link @Watch('onChangeTab') tabs: number
  @Link activeName: string
  @Link SOCValue: number
  @Link cusSText: string
  @Link cusStatus: string
  @Link MyStationName: string
  @Link MyPortName: string
  @Link MyStationId: string
  @Link MyPortId: string
  @Link dialogTitle: string
  @Link dialogLoading: boolean
  @Link closeDialog: boolean
  @State isShowMarkLayer: boolean = false
  @State startTime: string = customDataFormat(new Date(new Date().getTime() + (5 * 60 * 1000)))
  @State endTime: string = ''
  @State longBtnName: string = '预约充电'
  @State loading: boolean = false
  @State userReserveInfo: ReserveDetailReturning = {
    reserveId: '',
    stationId: '',
    portId: '',
    stationName: '',
    portName: '',
    startTime: null,
    endTime: null,
    createdTime: null,
    portStatus: null,
    defferTime: null
  }
  @State timerClock: number | null = null
  @State selectedDate: Date = new Date(new Date().getTime() + (5 * 60 * 1000));
  selectedDate2: Date = new Date();
  onClickBindFunc: Function = (data: boolean) => {
  }

  onCustomShowToast() {
    if (this.cusSText !== '') {
      setTimeout(() => {
        this.cusSText = ''
      }, 2000)
    }
  }

  onChangeTab() {
    this.MyStationName = LocalPreferences.get('MyStationName') as string || ''
    this.MyPortName = LocalPreferences.get('MyPortName') as string || ''
    this.MyStationId = LocalPreferences.get('MyStationId') as string || ''
    this.MyPortId = LocalPreferences.get('MyPortId') as string || ''
    if (this.tabs === 1) {
      this.getReserveDetail()
    }
  }

  // 预约充电时间段
  getReserveAdd() {
    if (this.MyStationId === '' || this.MyPortId === '') {
      useToastHook(resStr(getContext(this), 'adv2_toast_bind_first'), '64lpx')
      return
    }
    let data: ReserveAddVO = {
      stationId: this.MyStationId,
      portId: this.MyPortId,
      startTime: formatDate(this.selectedDate),
      endTime: formatDate(this.selectedDate2),
      socValue: this.SOCValue
    }
    console.info('接口 预约时间', JSON.stringify(data))
    getReserveAdd<string>(data).then((res) => {
      console.info('接口 预约充电', JSON.stringify(res))
      this.longBtnName = resStr(getContext(this), 'charging_btn_start')
      this.getReserveDetail()
      this.timerClock = setInterval(() => {
        this.getReserveDetail()
      }, 1000)

    }).catch((err: ResultVO<string>) => {
      // useToastHook(err.msg, '40lpx')
      console.info('接口 err', JSON.stringify(err))
      this.cusSText = err.msg
      this.cusStatus = 'error'
    })
  }

  // 用户预约信息
  getReserveDetail() {
    let nowTime = new Date().getTime()
    let carFormDate: CardFormData = {
      name: '', // 和卡片布局中对应
      pileNum: '', // 和卡片布局中对应
      status: '',
      beginTime: '',
      endTime: '',
    }
    getReserveDetail<ReserveDetailReturning>({ id: '1' }).then((res) => {
      console.info('接口 用户预约信息', JSON.stringify(res))
      if (res) {
        this.userReserveInfo = res
        let startT = new Date(res.startTime as string).getTime()
        let endT = new Date(res.endTime as string).getTime()
        if (nowTime < startT) {
          this.longBtnName = resStr(getContext(this), 'adv2_btn_not_due')
        } else if (nowTime > endT) {
          this.longBtnName = resStr(getContext(this), 'adv2_btn_expired')
        } else {

          if (res.portStatus === 1) {
            this.longBtnName = resStr(getContext(this), 'charging_btn_start')
          } else if (res.portStatus === 2) {
            this.longBtnName = resStr(getContext(this), 'common_status_charging')
          } else {
            this.longBtnName = resStr(getContext(this), 'adv2_btn_waiting_vehicle')
          }
        }
        carFormDate = {
          name: res.stationName, // 和卡片布局中对应
          pileNum: res.portName.split('-')[1], // 和卡片布局中对应
          status: res.portStatus === 0 ? resStr(getContext(this), 'common_label_idle') : resStr(getContext(this), 'common_label_busy'),
          beginTime: res.startTime + '',
          endTime: res.endTime + '',
        }
      } else {
        this.longBtnName = resStr(getContext(this), 'adv_charging_reservation')
        this.selectedDate = new Date(new Date().getTime() + (5 * 60 * 1000));
        this.selectedDate2 = new Date()
        this.startTime = customDataFormat(new Date(new Date().getTime() + (5 * 60 * 1000)))
        this.endTime = ''
        clearInterval(this.timerClock)
        this.getOrderList()
      }
      this.setCardData(carFormDate)
    }).catch((err: Error) => {
      console.info('接口 用户预约信息err', JSON.stringify(err))
      clearInterval(this.timerClock)
    })
  }

  // 创建订单 == 启动充电
  getOrderCreate() {
    let data: OrderCreateVO = {
      stationId: this.userReserveInfo.stationId,
      stationName: this.userReserveInfo.stationName,
      portId: this.userReserveInfo.portId,
      portName: this.userReserveInfo.portName,
      isReserve: 1//this.userReserveInfo.reserveId
    }
    getOrderCreate<OrderCreateReturning>(data).then((res) => {
      console.info('接口 创建订单', JSON.stringify(res))
      clearInterval(this.timerClock)
      LocalPreferences.put('MyChargingOrder', res)
      LocalPreferences.flush()
      this.closeDialog = false
      router.pushUrl({
        url: 'pages/charging/inCharging'
      })
    }).catch((err: ResultVO<string>) => {
      // useToastHook(err.msg, '40lpx')
      this.cusSText = 'error'
      this.cusStatus = err.msg
    })
  }

  // 查询是否有进行中 获取订单列表
  async getOrderList() {
    let t: OrderListVO = {
      currentPage: 1,
      pageSize: 5,
      orderStatus: 0 // 进行中
    }
    let res = await getOrderList<OrderListReturning>(t)
    console.info('接口 订单列表', JSON.stringify(res))
    if (res) {
      if (res.list.length > 0) {
        this.longBtnName = resStr(getContext(this), 'adv2_btn_order_in_progress')
      }
    }
  }

  aboutToAppear(): void {
    this.onChangeTab()

    this.timerClock = setInterval(() => {
      this.getReserveDetail()
    }, 1000)
  }

  aboutToDisappear(): void {
    clearInterval(this.timerClock)
  }

  onPageHide(): void {
    clearInterval(this.timerClock)
  }

  setCardData(carFormDate: CardFormData) {
    let formID = LocalPreferences.get('formId')
    console.log(`LocalPreferences LongBtnComponent ${formID}`)

    if (formID) {
      CardService.setCardData(carFormDate, formID + '')
    }
  }

  build() {
    Stack({ alignContent: Alignment.BottomStart }) {
      Column() {
        if (this.longBtnName === resStr(getContext(this), 'adv_charging_reservation') || this.longBtnName === resStr(getContext(this), 'adv2_btn_order_in_progress')) {
          Flex({ justifyContent: FlexAlign.End, alignItems: ItemAlign.End }) {
            Column() {
              Text($r('app.string.adv2_car_name'))
                .width('100%')
                .height('24lpx')
                .fontSize('14lpx')
                .fontWeight('bold')
              Row() {
                Text(`SOC值：${this.SOCValue}%`)
                  .fontSize('10lpx')
                  .margin({ top: '4lpx' })
              }
              .margin({ bottom: '16lpx' })
              .width('100%')

              Row() {
                Button({ type: ButtonType.Capsule, stateEffect: true }) {
                  Row() {
                    Text($r('app.string.adv2_btn_settings')).fontSize('12lpx').fontColor($r('app.color.historyList_font_color')).height('20lpx')
                  }.alignItems(VerticalAlign.Center).height('20lpx').margin({ left: '12lpx', right: '12lpx' })
                }
                .backgroundColor($r('app.color.background_color_over'))
                .borderWidth('1lpx')
                .borderColor($r('app.color.CECECE'))
                .height('24lpx')
                .width('72lpx')
                .onClick(() => {
                  this.onClickBindFunc(true)
                })
              }
              .width('100%')
            }.alignSelf(ItemAlign.Start)
            .margin({ right: '25lpx', top: '12lpx', bottom: '12lpx' })
            .position({ top: '0lpx', left: '0lpx' })

            Column() {
              Image($r('app.media.charging_car_red'))
                .width('173lpx')
                .height('128lpx')
            }
          }
          .padding({ left: '12lpx', right: '0lpx' })
          .margin({
            top: '16lpx',
            left: '16lpx',
            right: '16lpx',
            bottom: '16lpx'
          })
          // .width('100%')
          .borderRadius('8lpx')
          .backgroundColor($r('app.color.background_color_over'))

          Flex({ justifyContent: FlexAlign.SpaceBetween }) {
            Text(resStr(getContext(this), 'adv_charging_my_ordered_pile'))
              .fontSize('14lpx')
            // .margin({right: '24lpx'})
            Row() {
              Text(`${this.MyStationName}`)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .wordBreak(WordBreak.BREAK_ALL)
                .fontColor($r('app.color.historyList_font_color'))
                .fontSize('14lpx')
                .width('115lpx')
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Text(`${this.MyPortName}`)
                .fontSize('14lpx')
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .wordBreak(WordBreak.BREAK_ALL)
                .fontColor($r('app.color.historyList_font_color'))
              // .width('170lpx')
              Image($r('app.media.userAccount_RightIcon'))
                .width('14lpx')
                .height('14lpx')
                .margin({ left: '8lpx' })
            }
            .onClick(() => {
              this.tabs = 0
              this.activeName = '我的有序桩'
            })
          }
          // .width('100%')
          .borderRadius('8lpx')
          .backgroundColor($r('app.color.background_color_over'))
          .padding({
            left: '16lpx',
            right: '16lpx',
            top: '22lpx',
            bottom: '22lpx'
          })
          .margin({ left: '16lpx', right: '16lpx', bottom: '8lpx' })

          Column() {
            Flex({ justifyContent: FlexAlign.SpaceBetween }) {

              Text($r('app.string.adv2_label_start_time'))
                .fontSize('14lpx')
                .width('70lpx')
              Row() {
                Text(`${this.startTime}`)
                  .fontColor($r('app.color.historyList_font_color'))
                // .width('180lpx')
                Image($r('app.media.userAccount_RightIcon'))
                  .width('14lpx')
                  .height('14lpx')
                  .margin({ left: '8lpx' })
              }
              .onClick(() => {
                DatePickerDialog.show({
                  useMilitaryTime: true,
                  start: new Date(),
                  end: new Date('2100-12-31'),
                  selected: this.selectedDate,
                  showTime: true,
                  onDateAccept: (value: Date) => {
                    if (value < new Date()) {
                      useToastHook(resStr(getContext(this), 'adv2_toast_start_not_early'), '40lpx')
                      return
                    }
                    let end = value.getTime() + (60 * 60 * 1000)
                    this.selectedDate = new Date(value)
                    this.startTime = customDataFormat(value)
                    this.endTime = customDataFormat(new Date(end))
                    this.selectedDate2 = new Date(end)

                    console.info(`startTIme${this.selectedDate2} ${this.selectedDate2 < value} ${value}`)
                  },
                  onDateChange: (value: Date) => {
                    if (value < new Date()) {
                      useToastHook(resStr(getContext(this), 'adv2_toast_start_not_early'), '40lpx')
                      return
                    }
                  }
                })
              })
            }
            .padding({ top: '16lpx', bottom: '16lpx' })
            .borderWidth({ bottom: '1lpx' })
            .borderColor({ bottom: $r('app.color.EEEEEE') })

            Flex({ justifyContent: FlexAlign.SpaceBetween }) {

              Text($r('app.string.adv2_label_end_time'))
                .fontSize('14lpx')
              Row() {
                Text(this.endTime)
                  .fontColor($r('app.color.historyList_font_color'))
                Image($r('app.media.userAccount_RightIcon'))
                  .width('14lpx')
                  .height('14lpx')
                  .margin({ left: '8lpx' })
              }
            }
            .padding({ top: '16lpx', bottom: '16lpx' })
          }
          .borderRadius('8lpx')
          .backgroundColor($r('app.color.background_color_over'))
          .padding({
            left: '16lpx',
            right: '16lpx',
            top: '4lpx',
            bottom: '4lpx'
          })
          .margin({ left: '16lpx', right: '16lpx', bottom: '40lpx' })
        } else {
          aChargingTabContent2({
            userReserveInfo: this.userReserveInfo,
            longBtnName: this.longBtnName,
            cusSText: this.cusSText,
            cusStatus: this.cusStatus,
            dialogTitle: this.dialogTitle,
            dialogLoading: this.dialogLoading
          })
        }


        // 长按钮
        LongBtnComponent({
          btnColor: $r('app.color.longBtn_blue'),
          btnFontColor: $r('app.color.background_color_over'),
          btnBorderColor: $r('app.color.longBtn_blue'),
          btnName: this.longBtnName,
          onEvent: (data: string) => {
            if (this.longBtnName === resStr(getContext(this), 'adv_charging_reservation') && (this.startTime === '' || this.endTime === '')) {
              promptAction.showToast({
                message: resStr(getContext(this), 'adv2_toast_select_time'),
                duration: 2000
              })
              return
            }
            console.info(`接口 时间差 ${this.selectedDate2.getTime() - this.selectedDate.getTime()}`)
            if (this.longBtnName === resStr(getContext(this), 'adv_charging_reservation') && (this.MyStationName === '' || this.MyPortName === '')) {
              promptAction.showToast({
                message: resStr(getContext(this), 'adv2_toast_bind_pile'),
                duration: 2000
              })
              return
            }
            if (this.longBtnName === resStr(getContext(this), 'adv_charging_reservation')) {
              this.getReserveAdd()
            } else if (this.longBtnName === resStr(getContext(this), 'charging_btn_start')) {
              this.getOrderCreate()
            }
          }
        })

      }.width('100%')
      .height('100%')
      .backgroundColor($r('app.color.card_background'))
    }
  }
}