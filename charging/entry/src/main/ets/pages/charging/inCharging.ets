import { HeadComponent } from '../../components/headComponent'
import { LongBtnComponent } from '../../components/longBtnComponent'
import { LoadingDialog, promptAction, router } from '@kit.ArkUI'
import { LoadingCustomDialog } from '../../components/loadingCustomDialog'
import { BottomDialog } from '../../components/bottomDialog'
import { textToSpeech } from '@kit.CoreSpeechKit'
import { backgroundTaskManager } from '@kit.BackgroundTasksKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { common, WantAgent, wantAgent } from '@kit.AbilityKit'
import { geoLocationManager } from '@kit.LocationKit'
import { LocalPreferences } from '../../service/LocalPreferences'
import {
  OrderCreateReturning,
  OrderCreateVO,
  OrderDetailReturning
} from '../../model/interface/api/OrderApiInterface'
import { getOrderAmount, getOrderCreate, getOrderDetail, getOrderSpeedUp } from '../../api/OrderApi'
import { notificationManager } from '@kit.NotificationKit'
import { useToastHook } from '../../service'
import { ResultVO } from '../../utils/Http'

const TAG = 'huaweiBackgorund'

@Entry
@Component
export struct InCharging {
  private gradientColor: LinearGradient = new LinearGradient([
    { color: $r('app.color.progressColor1'), offset: 0.4 },
    { color: $r('app.color.progressColor2'), offset: 1 }
  ])
  @State format: string = 'HH:mm:ss'
  @State chargingBtnName: string = '启动充电'
  @State @Watch('onChangeBtnStatus') chargingTime: number = 0
  @State chargingStatus: number = 0
  @State loading: boolean = false
  @State pageLoading: boolean = true
  @State closeDialog: boolean = false
  @State @Watch('onChangeAudio') isSetAudio: boolean = LocalPreferences.get('IsSetAudio') as boolean || false
  @State isShowAudioDialog: boolean = false
  @State areaValue: string = '15秒'
  @State areaIndex: number = 15
  @State areaArrowPosition: ArrowPosition = ArrowPosition.END
  @State isShowChargingToast: boolean = false
  private ttsEngine?: textToSpeech.TextToSpeechEngine
  private context: Context = getContext(this)
  private internalTime?: number
  @State AISpeechTime: number = 0
  private requestId: string = '1'
  @State orderDetail: OrderDetailReturning | null = null
  @State chargingOrder: OrderCreateReturning | null =
    LocalPreferences.get('MyChargingOrder') as OrderCreateReturning || null
  @State timeDetailClock: number | null = null
  @State chargeCapacity: number = 0
  // 统一读取一次路由参数，避免重复 getParams
  @State routeParams: Record<string, Object> = router.getParams() as Record<string, Object> || {} as Record<string, Object>
  @State chargingEndTimes: number | null = null
  @State count: number = 0
  @State orderAmount: number = 0
  @State orderChargeCapacity: number = 0
  @State HHmmss: string = ''
  @State speedUpActive: boolean = false
  @State estimatedMinutes: number = 0
  @State currentPower: number = 0

  onChangeAudio() {}

  // 计算预计剩余时间
  private updateEstimate() {
    if (this.orderDetail && this.orderDetail.chargePower > 0 && this.chargingTime < 100) {
      let remaining = 100 - this.chargingTime
      // 按当前速度估算
      if (this.speedUpActive) {
        this.estimatedMinutes = Math.ceil(remaining * 0.75 / 60)
      } else {
        this.estimatedMinutes = Math.ceil(remaining * 5 / 60)
      }
      this.currentPower = this.orderDetail.chargePower
    } else {
      this.estimatedMinutes = 0
    }
  }

  async getOrderAmount() {
    let res = await getOrderAmount<string>({ orderId: this.chargingOrder?.orderId as string || this.routeParams['orderId'] as string || '' })
    console.info('接口 结束充电', JSON.stringify(res))

    AppStorage.setOrCreate('continueIsShowSheet', false)
    AppStorage.setOrCreate('continueCarStatus', '点击前往')
    AppStorage.setOrCreate('siteItemInfo', null)
    AppStorage.setOrCreate('continueMapBtnIsEnterSpot', '进入仿真充电站')

    this.stopContinuousTask(true)
    clearInterval(this.timeDetailClock)

    LocalPreferences.delete('MyChargingOrder')
    LocalPreferences.flush()
    this.getOrderDetail(this.chargingOrder?.orderId as string || this.routeParams['orderId'] as string || '')
  }

  async getOrderDetail(orderId: string) {
    let res = await getOrderDetail<OrderDetailReturning>({ orderId: orderId })
    if (res) {
      this.orderDetail = res
      this.chargingTime = res.soc ? res.soc : 0
      this.updateEstimate()
      if (res.orderStatus === 0) {
        this.formatTime(res.chargeTime)
        this.chargingBtnName = '结束充电'
      } else if (res.orderStatus === 1) {
        this.chargingBtnName = '订单待支付'
      }
    } else {
      clearInterval(this.timeDetailClock)
    }
  }

  // 加速充电模拟
  async speedUp() {
    const orderId = this.chargingOrder?.orderId as string || this.routeParams['orderId'] as string || ''
    if (!orderId) return
    try {
      await getOrderSpeedUp<string>({ orderId })
      this.speedUpActive = true
      useToastHook('加速模拟已开启，约1分钟充满', '32lpx')
    } catch (e) {
      useToastHook('加速失败', '40lpx')
    }
  }

  initAISpeech() {
    let that = this
    let extraParam: Record<string, Object> = { 'style': 'interaction-broadcast', 'locate': 'CN', 'name': 'EngineName' }
    let initParamsInfo: textToSpeech.CreateEngineParams = {
      language: 'zh-CN',
      person: 0,
      online: 1,
      extraParams: extraParam
    }
    textToSpeech.createEngine(initParamsInfo,
      (err: BusinessError, textToSpeechEngine: textToSpeech.TextToSpeechEngine) => {
        if (!err) {
          this.ttsEngine = textToSpeechEngine
          let speakListener: textToSpeech.SpeakListener = {
            onStart(requestId: string, response: textToSpeech.StartResponse) {
              that.isShowChargingToast = true
            },
            onComplete(requestId: string, response: textToSpeech.CompleteResponse) {
              if (response.type === 1) {
                that.isShowChargingToast = false
              }
            },
            onStop(requestId: string, response: textToSpeech.StopResponse) {},
            onData(requestId: string, audio: ArrayBuffer, response: textToSpeech.SynthesisResponse) {},
            onError(requestId: string, errorCode: number, errorMessage: string) {}
          }
          this.ttsEngine.setListener(speakListener)
        }
      })
  }

  AISpeech(originalText: string, requestId: string) {
    if (this.ttsEngine) {
      let extraParam: Record<string, Object> = {
        'queueMode': 0, 'speed': 1, 'volume': 2, 'pitch': 1,
        'languageContext': 'zh-CN', 'audioType': 'pcm', 'soundChannel': 3, 'playType': 1
      }
      let speakParams: textToSpeech.SpeakParams = { requestId, extraParams: extraParam }
      this.ttsEngine.speak(originalText, speakParams)
    }
  }

  startContinuousTask() {
    let wantAgentInfo: wantAgent.WantAgentInfo = {
      wants: [{ bundleName: 'com.zjhw.charging', abilityName: 'EntryAbility' }],
      actionType: wantAgent.OperationType.START_ABILITY,
      requestCode: 0,
      actionFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG],
    }
    try {
      wantAgent.getWantAgent(wantAgentInfo).then((wantAgentObj: WantAgent) => {
        try {
          let list: Array<string> = ['audioPlayback', 'location']
          backgroundTaskManager.startBackgroundRunning(this.context, list, wantAgentObj)
            .then(() => {
              this.AISpeechTime = 0
              if (this.internalTime === undefined) {
                this.internalTime = setInterval(() => {
                  geoLocationManager.getCurrentLocation()
                  if ((this.AISpeechTime % this.areaIndex) === 0) {
                    let time = new Date()
                    this.requestId = (Math.random() * 10000).toFixed(0) + time.getTime() + ''
                    this.isShowChargingToast = true
                    this.AISpeech(`鸿蒙智能充电温馨提醒您，车辆当前电量${this.chargingTime.toFixed(0)}%`, this.requestId)
                  }
                  this.AISpeechTime++
                }, 1000)
              }
            })
            .catch((error: BusinessError) => {})
        } catch (error) {}
      })
    } catch (error) {}
  }

  async stopContinuousTask(clearPreData: boolean) {
    clearInterval(this.internalTime)
    this.internalTime = undefined
    await backgroundTaskManager.stopBackgroundRunning(this.context).then(() => {
      if (clearPreData) {
        LocalPreferences.put('IsSetAudio', false)
        LocalPreferences.flush()
      }
    }).catch((err: BusinessError) => {})
  }

  dialogControllerProgress: CustomDialogController = new CustomDialogController({
    builder: LoadingDialog({ content: `${this.chargingBtnName}中…` }),
    autoCancel: true,
    backgroundBlurStyle: BlurStyle.COMPONENT_ULTRA_THICK
  })

  onChangeBtnStatus() {
    if (this.chargingTime >= 100) {
      this.chargingBtnName = '结束充电'
      this.getOrderAmount()
      let context = this.getUIContext().getHostContext() as common.UIAbilityContext
      notificationManager.requestEnableNotification(context).then(() => {
        let notificationRequest: notificationManager.NotificationRequest = {
          id: 1,
          notificationSlotType: notificationManager.SlotType.SOCIAL_COMMUNICATION,
          content: {
            notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
            normal: {
              title: '鸿蒙智能充电提示',
              text: '鸿蒙智能充电提醒，当前充电量100%',
              additionalText: '提醒'
            }
          }
        }
        notificationManager.publish(notificationRequest, () => {})
      })
    }
  }

  getOrderCreate(obj: OrderCreateVO) {
    getOrderCreate<OrderCreateReturning>(obj).then((res) => {
      LocalPreferences.put('MyChargingOrder', res)
      this.chargingOrder = res
      this.pageLoading = false
      this.timeDetailClock = setInterval(() => {
        this.getOrderDetail(res.orderId)
      }, 1000)
    }).catch(async (err: ResultVO<string>) => {
      useToastHook(err.msg, '40lpx')
      await this.getOrderDetail(this.chargingOrder?.orderId as string || this.routeParams['orderId'] as string || '')
      this.pageLoading = false
      this.timeDetailClock = setInterval(() => {
        this.getOrderDetail(this.chargingOrder?.orderId as string || this.routeParams['orderId'] as string || '')
      }, 1000)
    })
  }

  formatTime(seconds: number) {
    let HH = Math.floor(seconds / 3600).toString().padStart(2, '0')
    let mm = Math.floor(seconds / 60).toString().padStart(2, '0')
    let ss = Math.floor(seconds % 60).toString().padStart(2, '0')
    this.HHmmss = `${HH}:${mm}:${ss}`
  }

  async notificationEnable() {
    let context = this.getUIContext().getHostContext() as common.UIAbilityContext
    let data = await notificationManager.isNotificationEnabled()
    if (!data) {
      notificationManager.requestEnableNotification(context).then(() => {}).catch(() => {})
    }
  }

  aboutToAppear() {
    router.clear()
  }

  aboutToDisappear(): void {
    clearInterval(this.internalTime)
    clearInterval(this.timeDetailClock)
  }

  async onPageShow() {
    this.pageLoading = true
    this.notificationEnable()
    if (this.routeParams['stationId']) {
      if (this.routeParams['orderId'] as string || '') {
        await this.getOrderDetail(this.chargingOrder?.orderId as string || this.routeParams['orderId'] as string || '')
        this.pageLoading = false
        this.timeDetailClock = setInterval(() => {
          this.getOrderDetail(this.chargingOrder?.orderId as string || this.routeParams['orderId'] as string || '')
        }, 1000)
      } else {
        let QRCode: OrderCreateVO = {
          stationName: this.routeParams['stationName'] as string || '',
          stationId: this.routeParams['stationId'] as string || '',
          portName: this.routeParams['portName'] as string || '',
          portId: this.routeParams['portId'] as string || '',
          isReserve: 0,
        }
        this.getOrderCreate(QRCode)
      }
    } else {
      await this.getOrderDetail(this.chargingOrder?.orderId as string || this.routeParams['orderId'] as string || '')
      this.pageLoading = false
      this.timeDetailClock = setInterval(() => {
        this.getOrderDetail(this.chargingOrder?.orderId as string || this.routeParams['orderId'] as string || '')
      }, 1000)
    }

    await this.stopContinuousTask(false)
    this.initAISpeech()
    if (this.isSetAudio) {
      this.startContinuousTask()
    }
  }

  onPageHide(): void {
    clearInterval(this.internalTime)
    clearInterval(this.timeDetailClock)
  }

  @Builder
  longBtn(): void {
    LongBtnComponent({
      btnColor: $r('app.color.longBtn_blue'),
      btnFontColor: $r('app.color.background_color_over'),
      btnBorderColor: $r('app.color.longBtn_blue'),
      btnName: '保存设置',
      onEvent: () => {
        this.startContinuousTask()
        this.isShowAudioDialog = false
      }
    })
  }

  @Builder
  mainContent(): void {
    Column() {
      Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
        Text('播报内容').width('120lpx')
        Text('充电量').width('120lpx').textAlign(TextAlign.End)
      }
      .padding('16lpx')
      .backgroundColor($r('app.color.background_color_over'))
      .borderRadius('8lpx')

      Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
        Text('间隔时间').width('120lpx')
        Column() {
          Select([{ value: '15秒' }, { value: '30秒' }, { value: '1分钟' }])
            .selected(this.areaIndex)
            .value(this.areaValue)
            .space(0)
            .controlSize(ControlSize.SMALL)
            .alignSelf(ItemAlign.End)
            .font({ size: '14lpx', weight: 400 })
            .fontColor($r('app.color.font_color_black'))
            .arrowPosition(this.areaArrowPosition)
            .onSelect((index: number, text?: string | undefined) => {
              if (text) this.areaValue = text
              if (index === 0) this.areaIndex = 15
              else if (index === 1) this.areaIndex = 30
              else this.areaIndex = 60
            })
            .backgroundColor($r('app.color.background_color_over'))
        }
        .width('50%')
      }
      .padding({ left: '16lpx', top: '16lpx', bottom: '16lpx', right: '0lpx' })
      .margin({ top: '16lpx' })
      .backgroundColor($r('app.color.background_color_over'))
      .borderRadius('8lpx')
    }
    .margin({ left: '16lpx', right: '16lpx', bottom: '40lpx' })
  }

  build() {
    Stack({ alignContent: Alignment.BottomStart }) {
      Column() {
        // 顶部导航栏
        HeadComponent({
          headName: '充电中',
          isHaveBtn: true,
          backUrl: 'pages/order/orderList',
          tabs: 0,
          btnScr: this.isSetAudio ? $r('app.media.inCharging_audio2') : $r('app.media.inCharging_audio1'),
          backRouter: () => {
            clearInterval(this.timeDetailClock)
            clearInterval(this.internalTime)
            router.pushUrl({ url: 'pages/order/orderList' })
          },
          receive: () => {
            if (this.isShowAudioDialog) {
              this.isShowAudioDialog = false
            } else {
              if (this.isSetAudio) {
                this.isShowAudioDialog = true
              } else {
                promptAction.showDialog({
                  title: '',
                  message: '授权访问手机语音功能，是否开启',
                  isModal: true,
                  shadow: ShadowStyle.OUTER_FLOATING_SM,
                  buttons: [
                    { text: '取消', color: $r('app.color.longBtn_blue') },
                    { text: '确定', color: $r('app.color.longBtn_blue') }
                  ]
                }).then((data) => {
                  if (data.index === 1) {
                    this.isSetAudio = true
                    this.isShowAudioDialog = true
                    LocalPreferences.put('IsSetAudio', true)
                    LocalPreferences.flush()
                  }
                }).catch(() => {})
              }
            }
          }
        })

        // 站点信息卡片
        if (this.orderDetail) {
          Row() {
            Column() {
              Text(this.orderDetail.stationName)
                .fontSize('15lpx')
                .fontWeight(FontWeight.Bold)
                .fontColor('#333333')
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Text(`${this.orderDetail.portName} · ${this.orderDetail.chargePower}kW`)
                .fontSize('12lpx')
                .fontColor('#999999')
                .margin({ top: '4lpx' })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
          .padding({ left: '16lpx', right: '16lpx', top: '12lpx', bottom: '12lpx' })
          .margin({ left: '16lpx', right: '16lpx', top: '8lpx' })
          .backgroundColor($r('app.color.background_color_over'))
          .borderRadius('12lpx')
        }

        // 充电进度环
        Scroll() {
          Column() {
            Stack({ alignContent: Alignment.Center }) {
              Column() {
                Image($r('app.media.inCharging_lightning_icon'))
                  .width('40lpx')
                  .height('76lpx')
                  .margin({ bottom: '8lpx' })
                Text(`${this.chargingTime.toFixed(0)}`)
                  .fontSize('48lpx')
                  .fontWeight(400)
                Text('%').position({ bottom: '10lpx', right: '-22.5lpx' })
              }
              Progress({
                value: this.chargingTime, total: 100, type: ProgressType.Ring
              })
                .width('230lpx')
                .margin({ top: '46lpx', bottom: '52lpx' })
                .color(this.gradientColor)
                .style({ strokeWidth: '20lpx', status: ProgressStatus.PROGRESSING, enableScanEffect: true })
            }
            .margin({ top: '12lpx' })

            // 充电时间
            Row() {
              Text(this.HHmmss)
                .width('100%')
                .textAlign(TextAlign.Center)
                .fontSize('28lpx')
                .fontColor($r('app.color.font_color_black'))
            }
            .width('100%')
            .margin({ bottom: '12lpx' })

            // 预计剩余时间
            if (this.estimatedMinutes > 0 && this.chargingTime < 100) {
              Text(`预计还需 ${this.estimatedMinutes} 分钟`)
                .fontSize('13lpx')
                .fontColor('#999999')
                .margin({ bottom: '16lpx' })
            }

            // 实时数据卡片（3列）
            if (this.orderDetail && this.chargingBtnName === '结束充电') {
              Row() {
                Column() {
                  Text(`${this.orderDetail.chargePower}`)
                    .fontSize('18lpx')
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#2196F3')
                  Text('功率(kW)')
                    .fontSize('11lpx')
                    .fontColor('#999999')
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Center)

                Divider().vertical(true).height('32lpx').color('#EEEEEE')

                Column() {
                  Text(`${this.orderDetail.chargeCapacity ? this.orderDetail.chargeCapacity.toFixed(1) : '0.0'}`)
                    .fontSize('18lpx')
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#4CAF50')
                  Text('已充(kWh)')
                    .fontSize('11lpx')
                    .fontColor('#999999')
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Center)

                Divider().vertical(true).height('32lpx').color('#EEEEEE')

                Column() {
                  Text(`¥${this.orderDetail.chargeFee}`)
                    .fontSize('18lpx')
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#FF9800')
                  Text('单价(元/度)')
                    .fontSize('11lpx')
                    .fontColor('#999999')
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Center)
              }
              .width('100%')
              .padding({ top: '12lpx', bottom: '12lpx' })
              .margin({ left: '16lpx', right: '16lpx' })
              .borderRadius('12lpx')
              .backgroundColor($r('app.color.background_color_over'))
            }

            // 操作按钮区
            Column() {
              // 主按钮：结束/支付/完成
              LongBtnComponent({
                btnColor: $r('app.color.longBtn_blue'),
                btnFontColor: $r('app.color.background_color_over'),
                btnBorderColor: $r('app.color.longBtn_blue'),
                btnName: this.chargingBtnName,
                onEvent: () => {
                  if (this.chargingBtnName === '充电已完成') return
                  if (this.chargingBtnName === '订单待支付') {
                    router.pushUrl({
                      url: 'pages/order/orderInfo',
                      params: { orderId: this.orderDetail?.orderId }
                    })
                    return
                  }
                  if (this.chargingBtnName === '结束充电') {
                    this.getOrderAmount()
                  }
                }
              })

              // 加速模拟按钮
              if (this.chargingBtnName === '结束充电' && !this.speedUpActive) {
                Row() {
                  Text('加速模拟')
                    .fontSize('14lpx')
                    .fontColor('#FF9800')
                    .fontWeight(FontWeight.Medium)
                    .padding({ left: '24lpx', right: '24lpx', top: '8lpx', bottom: '8lpx' })
                    .borderRadius('20lpx')
                    .border({ width: '1lpx', color: '#FF9800' })
                    .backgroundColor('rgba(255, 152, 0, 0.08)')
                    .onClick(() => {
                      this.speedUp()
                    })
                }
                .margin({ top: '8lpx' })
              }

              // 加速中提示
              if (this.speedUpActive && this.chargingTime < 100) {
                Text('加速充电中...')
                  .fontSize('13lpx')
                  .fontColor('#FF9800')
                  .margin({ top: '8lpx' })
              }
            }
            .margin({ left: '16lpx', right: '16lpx', top: '16lpx' })

            // 充电结束后的金额统计
            if (this.orderDetail?.orderAmount && this.orderDetail?.orderAmount > 0) {
              Row() {
                Column() {
                  Row() {
                    Text(`${this.orderDetail?.chargeCapacity.toFixed(2)}`)
                      .fontSize('16lpx')
                      .fontColor($r('app.color.progressColor2'))
                    Text('度').fontSize('10lpx').fontColor($r('app.color.progressColor2'))
                  }
                  Text('充电度数').fontSize('12lpx').fontColor($r('app.color.charging_font_color')).margin({ top: '4lpx' })
                }
                .width('100%')

                Column() {}.height('16lpx').width('2lpx').backgroundColor($r('app.color.CECECE')).margin({ left: '12lpx', right: '12lpx' })

                Column() {
                  Row() {
                    Text(`${this.orderDetail?.orderAmount.toFixed(2)}`)
                      .fontSize('16lpx')
                      .fontColor($r('app.color.chargingPrice_color'))
                    Text('元').fontSize('10lpx').fontColor($r('app.color.chargingPrice_color'))
                  }
                  Text('充电金额').fontSize('12lpx').fontColor($r('app.color.charging_font_color')).margin({ top: '4lpx' })
                }
                .width('100%')
              }
              .padding({ top: '16lpx', bottom: '16lpx', left: '12lpx', right: '12lpx' })
              .margin({ left: '16lpx', right: '16lpx', top: '24lpx' })
              .backgroundColor($r('app.color.background_color_over'))
              .borderRadius('8lpx')
            }
          }
        }
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.card_background'))

      // 页面加载遮罩（避免进入时闪旧界面）
      if (this.pageLoading) {
        Column() {
          LoadingProgress()
            .width('48lpx')
            .height('48lpx')
          Text('准备充电...')
            .fontSize('14lpx')
            .fontColor('#999999')
            .margin({ top: '12lpx' })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor($r('app.color.card_background'))
        .zIndex(10)
      }

      // Loading 弹框
      if (this.loading) {
        LoadingCustomDialog({
          dialogTitle: this.chargingBtnName,
          autoCancel: true,
          closeDialog: this.closeDialog
        })
      }

      // 顶部充电进度提示
      if (this.isShowChargingToast) {
        Row() {
          Text(`鸿蒙智能充电温馨提醒您，车辆当前电量${this.chargingTime.toFixed(0)}%`)
            .fontSize('14lpx')
            .margin({ top: '19lpx', bottom: '17lpx', left: '24lpx', right: '24lpx' })
            .textAlign(TextAlign.Start)
            .width('100%')
        }
        .zIndex(1)
        .position({ top: '65lpx', left: '0lpx' })
        .backgroundColor($r('app.color.background_color_over'))
        .margin({ left: '16lpx', right: '16lpx' })
        .shadow({ offsetX: 0, offsetY: 4, radius: 10, color: 'rgba(0,0,0,0.1)' })
      }

      // 语音播报设置弹窗
      if (this.isShowAudioDialog) {
        BottomDialog({
          bdBackgroundColor: $r('app.color.F3F3F3'),
          bdName: '语音播报设置',
          isHaveLongBtn: true,
          MainContent: (): void => { this.mainContent() },
          longBtn: (): void => { this.longBtn() },
          cancelOnclick: () => { this.isShowAudioDialog = false },
        })
      }
    }
  }
}
