import { BottomDialog } from '../../components/bottomDialog';
import { ChargingBottomNav } from '../../components/chargingBottomNavigation';
import { HeadComponent } from '../../components/headComponent';
import { LongBtnComponent } from '../../components/longBtnComponent';
import {
  carInfoItem,
  formIndexItem,
  formItem,
  orderlyPileErrorsItem
} from '../../model/interface/advanceCharginInterface';
import { OrderlyPile } from './orderlyPile';
import { AdvanceCharging2 } from './advanceCharging';
import { CardService } from '../../service/Card'
import { LocalPreferences } from '../../service/LocalPreferences'
import { getReserveBind, getReservePortNameList, getReserveStationNameList } from '../../api/AdvanceChargingApi';
import {
  filteredOptionItem,
  filteredPortOptionItem,
  PortNameListItem,
  StationNameListItem
} from '../../model/interface/api/AdvanceChargingApiInterface';
import { useToastHook } from '../../service';
import { CustomShowToast } from '../../components/customShowToast';
import { resStr } from '../../utils/i18n';


@Entry
@Component
struct AdvanceCharging {
  @State activeName: string = ''
  @State currentIndex: number = 0;
  private tasController: TabsController = new TabsController();
  @State selectIndex: number = 0;
  @State isShowMarkLayer: boolean = false
  @State isShowMarkLayer2: boolean = false
  @State form: formItem = { stationName: '', portName: '' }
  @State formIndex: formIndexItem = { stationIndex: -1, portIndex: -1 }
  @State errors: orderlyPileErrorsItem = { siteName: '', siteNumber: '' }
  @State carInfo: carInfoItem =
    { mileageNumber: 500, capacity: 60, socValue: LocalPreferences.get('SOCValue') as number || 60 }
  @State SOCValue: number = LocalPreferences.get('SOCValue') as number || 60
  @State loading: boolean = false
  @State dialogTitle: string = ''
  @State stationOption: filteredOptionItem[] = []
  @State portOption: filteredPortOptionItem[] = []
  @State @Watch('onCustomShowToast') cusSText: string = ''
  @State cusStatus: string = ''
  @State haveCard: boolean = false
  @State MyStationName: string = LocalPreferences.get('MyStationName') as string || ''
  @State MyPortName: string = LocalPreferences.get('MyPortName') as string || ''
  @State MyStationId: string = LocalPreferences.get('MyStationId') as string || ''
  @State MyPortId: string = LocalPreferences.get('MyPortId') as string || ''
  @State closeDialog: boolean = false

  private validateSiteName(value: string) {
    if (!value) {
      this.errors.siteName = resStr(getContext(this), 'adv_charging_error_station_empty')
    } else {
      this.errors.siteName = undefined
    }
  }

  private validateSiteNumber(value: string) {
    if (!value) {
      this.errors.siteNumber = resStr(getContext(this), 'adv_charging_error_port_empty')
    } else {
      this.errors.siteNumber = undefined
    }
  }

  onCustomShowToast() {
    if (this.cusSText !== '') {
      setTimeout(() => {
        this.cusSText = ''
      }, 2000)
    }
  }

  aboutToAppear(): void {
    this.activeName = resStr(getContext(this), 'adv_charging_my_ordered_pile')
    LocalPreferences.put('SOCValue', 60)
    this.getReserveStationNameList('')
  }

  @Builder
  longBtn() {
    LongBtnComponent({
      btnColor: $r('app.color.longBtn_blue'),
      btnFontColor: $r('app.color.background_color_over'),
      btnBorderColor: $r('app.color.longBtn_blue'),
      btnName: resStr(getContext(this), 'adv_charging_btn_bind'),
      onEvent: (data: string) => {
        this.getReserveBind()
      }
    })
  }

  // 绑定时 选择充电站名称列表
  getReserveStationNameList(val: string) {
    getReserveStationNameList<StationNameListItem>({
      stationName: val,
      currentPage: 1,
      pageSize: 100
    }).then((res: StationNameListItem) => {
      console.info('接口 选择充电站名', JSON.stringify(res))
      this.stationOption = []
      if (res) {
        res.list.forEach((item) => {
          this.stationOption.push({ stationId: item.stationId, stationName: item.stationName, value: item.stationName })
        })
      }
    })
  }

  // 绑定时选择 充电桩名称列表
  getReservePortNameList(id: string) {
    getReservePortNameList<PortNameListItem[]>({ stationId: id }).then((res) => {
      console.info('接口 选择充电站名', JSON.stringify(res))
      this.portOption = []
      this.form.portName = ''
      if (res) {
        res.forEach((item) => {
          this.portOption.push({ portId: item.portId, portName: item.portName, value: item.portName })
        })
      }
    })
  }

  // 绑定充电桩
  getReserveBind() {
    if (this.form.stationName === '') {
      useToastHook(resStr(getContext(this), 'adv_charging_error_station_empty'), '40lpx')
      return
    }
    if (this.form.portName === '') {
      useToastHook(resStr(getContext(this), 'adv_charging_error_port_empty'), '40lpx')
      return
    }
    this.dialogTitle = resStr(getContext(this), 'adv_charging_binding')
    // this.loading = true
    getReserveBind<string>({ stationName: this.form.stationName, portName: this.form.portName }).then((res) => {
      console.info('接口 绑定充电桩', JSON.stringify(res))
      this.dialogTitle = ''
      this.cusSText = resStr(getContext(this), 'adv_charging_toast_bind_success')
      this.cusStatus = 'success'
      this.isShowMarkLayer = false
      this.haveCard = false
      // 保存绑定的站点 电桩信息
      LocalPreferences.put('MyStationName', this.form.stationName)
      LocalPreferences.put('MyPortName', `${this.form.portName.split('-')[1]}号充电桩`)
      LocalPreferences.put('MyStationId', this.formIndex.stationIndex)
      LocalPreferences.put('MyPortId', this.formIndex.portIndex)
      LocalPreferences.flush()

      // 清空底部弹框填写数据
      this.form.stationName = ''
      this.formIndex.stationIndex = -1
      this.formIndex.portIndex = -1
      this.form.portName = ''
      this.portOption = []
      this.stationOption = []
    }).catch((err: Error) => {
      this.dialogTitle = ''
      this.cusSText = resStr(getContext(this), 'adv_charging_toast_bind_fail')
      this.cusStatus = 'error'
      this.isShowMarkLayer = false
      this.haveCard = true
    })
  }

  // 弹框内容
  @Builder
  mainContent() {
    Column() {
      Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
        Text($r('app.string.adv_charging_label_station'))
          .width('120lpx')
        TextInput({ text: this.form.stationName, placeholder: $r('app.string.adv_charging_placeholder_input') })
          .height('40lpx')
          .placeholderFont({
            size: '16lpx'
          })
          .placeholderColor($r('app.color.999999'))
          .backgroundColor($r('app.color.background_color_over'))
          .margin({ top: '17.5lpx', bottom: '17.5lpx' })
          .onChange((value: string) => {
            if (value === '') {
              this.form.stationName = ''
              this.formIndex.stationIndex = -1
              this.formIndex.portIndex = -1
              this.form.portName = ''
              this.portOption = []
            }
            this.validateSiteName(value)
            this.getReserveStationNameList(value)

          })
        Select(this.stationOption)
          .selected(this.formIndex.stationIndex)
          .onSelect((index: number, text: string) => {
            console.info('接口 选择 充电站', text)
            if (text === this.form.stationName) {
              return
            }
            this.form.stationName = text
            this.formIndex.stationIndex = index
            this.getReservePortNameList(this.stationOption[index].stationId)
          })
          .controlSize(ControlSize.SMALL)
          .fontColor($r('app.color.background_color_over'))
          .width('0lpx')
          .backgroundColor($r('app.color.background_color_over'))
          .position({ right: '-14lpx', top: '22lpx' })

      }
      .borderWidth({ bottom: '1lpx' })
      .borderColor({ bottom: $r('app.color.EEEEEE') })

      Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
        Text($r('app.string.adv_charging_label_port'))
          .width('120lpx')
        TextInput({ text: `${this.form.portName}`, placeholder: $r('app.string.adv_charging_placeholder_select') })
          .height('40lpx')
          .placeholderFont({
            size: '16lpx'
          })
          .enabled(false)
          .placeholderColor($r('app.color.999999'))
          .backgroundColor($r('app.color.background_color_over'))
          .margin({ top: '17.5lpx', bottom: '17.5lpx' })
          .onChange((value: string) => {
            this.form.portName = value
            this.validateSiteNumber(value)
          })
        Select(this.portOption)
          .value(this.form.portName)
          .selected(this.formIndex.portIndex)
          .controlSize(ControlSize.SMALL)
          .onSelect((index: number, text: string) => {
            console.info('接口 选择 充电桩', text)
            this.form.portName = text
            this.formIndex.portIndex = index
            this.validateSiteNumber(text)
          })
          .width('0lpx')
          .fontColor($r('app.color.background_color_over'))
          .position({ right: '-14lpx', top: '22lpx' })
          .backgroundColor($r('app.color.background_color_over'))
      }
    }
    .padding({ left: '16lpx', right: '16lpx' })
    .margin({ left: '16lpx', right: '16lpx', bottom: '40lpx' })
    .borderRadius('16lpx')
    .backgroundColor($r('app.color.background_color_over'))
  }

  @Builder
  longBtn2() {
    LongBtnComponent({
      btnColor: $r('app.color.longBtn_blue'),
      btnFontColor: $r('app.color.background_color_over'),
      btnBorderColor: $r('app.color.longBtn_blue'),
      btnName: resStr(getContext(this), 'btn_save_settings'),
      onEvent: (data: string) => {
        // this.dialogControllerProgress.open()
        LocalPreferences.put('SOCValue', this.carInfo.socValue)
        this.SOCValue = this.carInfo.socValue
        this.isShowMarkLayer2 = false
      }
    })
  }

  // 弹框内容
  @Builder
  mainContent2() {
    Column() {
      Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
        Text($r('app.string.adv_charging_label_soc'))
          .fontSize('14lpx')
          .fontColor($r('app.color.charging_font_color'))
          .width('120lpx')
        Text(`${this.carInfo.socValue.toFixed(0)}%`)
          .fontSize('16lpx')
          .fontColor($r('app.color.btn_blue'))
      }
      .padding({ top: '16lpx', bottom: '6lpx' })

      Row() {
        Slider({
          value: this.carInfo.socValue,
          min: 20,
          max: 100,
          step: 5,
          style: SliderStyle.OutSet
        })
          .selectedColor($r('app.color.longBtn_blue'))
          .showSteps(false)
          .onChange((value: number, mode: SliderChangeMode) => {
            this.carInfo.socValue = value
          })
      }
      .width('100%')
    }
    .padding({ left: '16lpx', right: '16lpx' })
    .margin({ left: '16lpx', right: '16lpx', bottom: '40lpx' })
    .borderRadius('16lpx')
    .backgroundColor($r('app.color.background_color_over'))
  }

  build() {
    Stack({ alignContent: Alignment.BottomStart }) {
      Column() {
        HeadComponent({
          headName: resStr(getContext(this), 'adv_charging_head_name'),
          isHaveBtn: false,
          backUrl: 'pages/Index',
          tabs: 1
        })
        // tab
        Tabs({ barPosition: BarPosition.End, index: this.currentIndex, controller: this.tasController }) {
          TabContent() {
            OrderlyPile({
              haveCard: $haveCard,
              onClickBindFunc: (data: boolean) => {
                console.info(`${data}`)
                this.isShowMarkLayer = data
              }
            })
          }

          TabContent() {
            AdvanceCharging2({
              tabs: this.currentIndex,
              activeName: this.activeName,
              SOCValue: this.SOCValue,
              MyStationName: this.MyStationName,
              MyPortName: this.MyPortName,
              MyStationId: this.MyStationId,
              MyPortId: this.MyPortId,
              cusSText: this.cusSText,
              cusStatus: this.cusStatus,
              dialogTitle: this.dialogTitle,
              dialogLoading: this.loading,
              closeDialog: this.closeDialog,
              onClickBindFunc: (data: boolean) => {
                console.info(`${data}`)
                this.isShowMarkLayer2 = data
              }
            })
          }
        }
        .scrollable(false)
        .barOverlap(true)
        .barHeight('63.5lpx')

        ChargingBottomNav({
          activeName: this.activeName,
          onEvent: (data: string, index: number) => {
            console.info('navdata', data)
            console.info('navindex', index)
            this.activeName = data
            this.currentIndex = index
            this.tasController.changeIndex(index)
          }
        })
          .position({ bottom: '-26lpx' })
        // 底部弹框1
        if (this.isShowMarkLayer) {
          BottomDialog({
            bdBackgroundColor: $r('app.color.F3F3F3'),
            bdName: resStr(getContext(this), 'adv_charging_dialog_bind_title'),
            isHaveLongBtn: true,
            MainContent: (): void => {
              this.mainContent()
            },
            longBtn: (): void => {
              this.longBtn()
            },
            cancelOnclick: () => {
              this.isShowMarkLayer = false
              // this.loading = false
            },

          }).position({ bottom: 0 })
        }
        // 底部弹框2预约充电
        if (this.isShowMarkLayer2) {
          BottomDialog({
            bdBackgroundColor: $r('app.color.F3F3F3'),
            bdName: resStr(getContext(this), 'adv_charging_dialog_pref_title'),
            isHaveLongBtn: true,
            MainContent: (): void => {
              this.mainContent2()
            },
            longBtn: (): void => {
              this.longBtn2()
            },
            cancelOnclick: () => {
              this.isShowMarkLayer2 = false
              // this.dialogControllerProgress.close()
            },

          }).position({ bottom: 0 })
        }
      }

      if (this.cusSText !== '') {
        CustomShowToast({
          cusSTBorderRadius: '8lpx',
          cusSTBackgroundColor: this.cusStatus === 'error' ? 'rgba(252, 227, 223, 1)' : 'rgba(100, 187, 92, 0.15)',
          cusSTText: this.cusSText,
          cusSTImage: this.cusStatus === 'error' ? $r('app.media.customShowToast_error') :
          $r('app.media.orderEnd_successIcon'),
          cusSTFontColor: this.cusStatus === 'error' ? $r('app.color.longBtn_red') :
          $r('app.color.charging_font_green_color')
        }).position({ bottom: '48lpx' })
      }
    }
    .height('100%')
    .width('100%')
  }

  onPageShow() {

    let carStatus = CardService.getCardStatus();

    this.getReserveStationNameList('')

    if (carStatus === 'noAppointment') {
      this.activeName = resStr(getContext(this), 'adv_charging_reservation')
      this.currentIndex = 1
    }

    if (carStatus === 'appointment') {
      this.activeName = resStr(getContext(this), 'adv_charging_reservation')
      this.currentIndex = 1
    }

  }
}