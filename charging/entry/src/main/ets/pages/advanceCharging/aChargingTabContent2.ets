import { getReserveCancel } from '../../api/AdvanceChargingApi';
import { siteInfoFormItem } from '../../model/interface/advanceCharginInterface';
import { ReserveDetailReturning } from '../../model/interface/api/AdvanceChargingApiInterface';

@Component
export struct aChargingTabContent2 {
  @Link userReserveInfo: ReserveDetailReturning
  @Link longBtnName: string
  @Link cusSText: string
  @Link cusStatus: string
  @Link dialogTitle: string
  @Link dialogLoading: boolean
  @State format: string = 'mm:ss'
  @State siteInfoForm: siteInfoFormItem =
    {
      createTime: '2025-05-13 07:00',
      countCode: 'M982466543457U001',
      carName: '虚拟仿真模拟车SUV',
      advanceStartTime: '2025-05-13 08:30',
      advanceEndTime: '2025-05-13 18:30'
    }
  @State isFree: boolean = true
  @State timerCount: number = 0
  @State @Watch('onChangeNowTime') nowTime: Date = new Date()
  textTimerController: TextTimerController = new TextTimerController();
  @State timerClock: number | null = null;

  // 监听当前时间
  onChangeNowTime() {
    // console.info('接口 当前时间', `${this.nowTime}`)
  }

  // 时间处理
  timeChange(time: string) {
    let nowTime = new Date().getTime()
    let startTime = new Date(time).getTime()
    if (startTime - nowTime <= 1000) {
      clearInterval(this.timerClock)
    }
    return startTime - nowTime <= 1000 ? 0 : startTime - nowTime
  }

  //取消预约
  getReserveCancel() {
    this.dialogLoading = true
    this.dialogTitle = '取消预约中'
    getReserveCancel<string>({ reserveId: this.userReserveInfo.reserveId }).then((res) => {
      console.info('接口 取消预约', JSON.stringify(res))
      this.longBtnName = '预约充电'
      this.cusSText = '取消预约成功'
      this.cusStatus = 'success'
      this.dialogLoading = false
      this.dialogTitle = ''
      AppStorage.setOrCreate('continueCarStatus', '点击前往')
      AppStorage.setOrCreate('continueMapBtnIsEnterSpot', '进入仿真充电站')
      AppStorage.setOrCreate('endTarget', null)
      AppStorage.setOrCreate('siteItemInfo', null)
      AppStorage.setOrCreate('continueIsShowSheet', false)

    }).catch((err: Error) => {
      this.cusSText = '取消预约失败'
      this.cusStatus = 'error'
      this.dialogLoading = false
      this.dialogTitle = ''
    })
  }

  aboutToAppear(): void {
  }

  aboutToDisappear(): void {
    clearInterval(this.timerClock)
  }

  build() {
    Stack({ alignContent: Alignment.BottomStart }) {
      Column() {
        Column() {
          Text((this.userReserveInfo.portStatus === 1 || this.userReserveInfo.portStatus === 2) ? '忙' : '闲')
            .fontSize('14lpx')
            .fontWeight('bold')
            .fontColor($r('app.color.background_color_over'))
        }
        .margin({ top: '13lpx', left: '58lpx' })
        .width('32lpx')
        .height('32lpx')
        .padding({ top: '7lpx', bottom: '7lpx', })
        .alignSelf(ItemAlign.Start)
        .borderRadius('4lpx')
        .backgroundColor((this.userReserveInfo.portStatus === 1 || this.userReserveInfo.portStatus === 2) ?
        $r('app.color.chargingPrice_color') : $r('app.color.charging_font_green_color'))

        // if (this.longBtnName === '未到预约时间' && this.userReserveInfo.portStatus === 0) {
        if (this.userReserveInfo?.defferTime && this.userReserveInfo?.defferTime > 0) {
          Stack({ alignContent: Alignment.Center }) {
            if (this.userReserveInfo?.defferTime >= 3600) {
              Text('未到时间')
            } else {

              TextTimer({
                isCountDown: true,
                // count: this.timerCount,
                count: (Number(this.userReserveInfo.defferTime) * 1000),
                controller: this.textTimerController
              })
                .format(this.format)
                .fontColor($r('app.color.charging_font_color'))
                .fontSize('20lpx')
                .onTimer((utc: number, elapsedTime: number) => {
                })
            }
          }
          .backgroundImage($r('app.media.advanceCharging_round'))
          .backgroundImageSize({ width: '100%', height: '100%' })
          .width('90lpx')
          .height('90lpx')
          .position({ top: '26lpx', left: '177lpx' })
        }
      }
      .backgroundImage((this.userReserveInfo?.defferTime && this.userReserveInfo?.defferTime > 0 ||
        this.userReserveInfo.portStatus === 0) ? $r('app.media.advanceCharging_xian') :
      $r('app.media.advanceCharging_mang'))
      .backgroundImageSize({ width: '100%', height: '100%' })
      .width('435lpx')
      .height('244lpx')
      .position({ top: '3lpx', left: '-42lpx' })

      Column() {
        Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
          Text(this.userReserveInfo.stationName)
            .fontColor($r('app.color.historyList_font_color'))
            .fontSize('14lpx')
            .width('60%')
          if (this.userReserveInfo.portStatus !== 2) {
            Button({ type: ButtonType.Capsule, stateEffect: true }) {
              Row() {
                Text(`取消预约`)
                  .fontSize('12lpx')
                  .fontColor($r('app.color.historyList_font_color'))
                  .height('20lpx')
              }
              .alignItems(VerticalAlign.Center)
              .height('20lpx')
              .margin({ left: '24lpx', right: '24lpx' })
            }
            .backgroundColor($r('app.color.background_color_over'))
            .borderWidth('1lpx')
            .borderColor($r('app.color.CECECE'))
            .height('24lpx')
            .onClick(() => {
              this.getReserveCancel()
            })
          }
        }

        Row() {
          Text(this.userReserveInfo.portName.split('-')[1])
            .fontSize('24lpx')
          Text('号充电桩')
            .fontSize('12lpx')
            .alignSelf(ItemAlign.Baseline)
        }
        .margin({ top: '4lpx', bottom: '16lpx' })
        .width('100%')

        Row() {
          Text(`创建时间:`)
            .fontSize('12lpx')
            .fontColor($r('app.color.historyList_font_color'))
            .margin({ right: '8lpx' })
            .width('72lpx')
          Text(`${this.userReserveInfo.createdTime}`)
            .fontSize('12lpx')
            .fontColor($r('app.color.historyList_font_color'))
        }
        .width('100%')
        .margin({ bottom: '8lpx' })

        Row() {
          Text(`充电桩编码:`)
            .fontSize('12lpx')
            .fontColor($r('app.color.historyList_font_color'))
            .margin({ right: '8lpx' })
            .width('72lpx')
          Text(this.userReserveInfo.portName)
            .fontSize('12lpx')
            .fontColor($r('app.color.historyList_font_color'))
        }
        .width('100%')
        .margin({ bottom: '8lpx' })

        Row() {
          Text(`预约车辆:`)
            .fontSize('12lpx')
            .fontColor($r('app.color.historyList_font_color'))
            .margin({ right: '8lpx' })
            .width('72lpx')
          Text(this.siteInfoForm.carName)
            .fontSize('12lpx')
            .fontColor($r('app.color.historyList_font_color'))
        }
        .width('100%')
        .margin({ bottom: '8lpx' })

        Row() {
          Text(`预约时间:`)
            .fontSize('12lpx')
            .fontColor($r('app.color.historyList_font_color'))
            .margin({ right: '8lpx' })
            .width('72lpx')
          Text(`${this.userReserveInfo.startTime ?
            `${this.userReserveInfo.startTime.split(':')[0]}:${this.userReserveInfo.startTime.split(':')[1]}` :
            '-'}至${this.userReserveInfo.endTime ?
            `${this.userReserveInfo.endTime.split(':')[0]}:${this.userReserveInfo.endTime.split(':')[1]}` : '-'}`)
            .fontSize('12lpx')
            .fontColor($r('app.color.historyList_font_color'))
        }
        .width('100%')
        .margin({ bottom: '8lpx' })
      }
      .margin({
        top: '180lpx',
        left: '16lpx',
        right: '16lpx',
        bottom: '40lpx'
      })
      .padding({
        left: '12lpx',
        top: '12lpx',
        bottom: '8lpx',
        right: '12lpx'
      })
      .borderRadius('8lpx')
      .backgroundColor($r('app.color.background_color_over'))

    }
  }
}