import { LongBtnComponent } from '../../components/longBtnComponent'
import { promptAction } from '@kit.ArkUI'
import { getReserveBindDetail, getReserveUnbind } from '../../api/AdvanceChargingApi'
import { BindDetailReturning } from '../../model/interface/api/AdvanceChargingApiInterface'
import { CustomShowToast } from '../../components/customShowToast'
import { LocalPreferences } from '../../service/LocalPreferences'

// @Entry
@Component
export struct OrderlyPile {
  @Link @Watch('onChangeHaveCard') haveCard: boolean // = false
  @State @Watch('onCustomShowToast') cusSText: string = ''
  @State cusStatus: string = ''
  @State btnBackColor: Resource = $r('app.color.background_color_over')
  @State btnFontColor: Resource = $r('app.color.item_title_font')
  @State btnBorderColor: Resource = $r('app.color.CECECE')
  @State bindDetail: BindDetailReturning = {
    id: '',
    userId: '',
    stationId: '',
    portId: '',
    stationName: '',
    portName: ''
  }
  onClickBindFunc: Function = (data: boolean) => {
  }

  onChangeHaveCard() {
    this.getReserveBindDetail()
  }

  onCustomShowToast() {
    if (this.cusSText !== '') {
      setTimeout(() => {
        this.cusSText = ''
      }, 2000)
    }
  }

  //查询绑定的充电桩
  async getReserveBindDetail() {
    let res = await getReserveBindDetail<BindDetailReturning>({ id: '1' })
    // .then((res) => {
    if (res) {
      this.bindDetail = res
      this.haveCard = false
      LocalPreferences.put('MyStationName', res.stationName)
      LocalPreferences.put('MyPortName', `${res.portName.split('-')[1]}号充电桩`)
      LocalPreferences.put('MyStationId', res.stationId)
      LocalPreferences.put('MyPortId', res.portId)
      LocalPreferences.flush()

    } else {
      this.haveCard = true
    }
    console.info('接口 查询绑定的充电桩', JSON.stringify(res), JSON.stringify(this.haveCard))
    // })
  }

  // 解绑接口
  getReserveUnbind(id: string) {
    getReserveUnbind<string>({ id }).then((res) => {
      console.info('接口 解绑充电桩', JSON.stringify(res))
      this.haveCard = true
      this.cusStatus = 'success'
      this.cusSText = '解绑成功'
      LocalPreferences.delete('MyStationName')
      LocalPreferences.delete('MyPortName')
      LocalPreferences.delete('MyStationId')
      LocalPreferences.delete('MyPortId')
      LocalPreferences.flush()

    }).catch((err: Error) => {
      this.cusStatus = 'error'
      this.cusSText = '解绑失败'

    })
  }

  aboutToAppear(): void {
    this.getReserveBindDetail()
  }

  build() {
    Stack({ alignContent: Alignment.BottomStart }) {
      Column() {
        if (this.haveCard) {
          Column() {
            Row() {
              Image($r('app.media.charging_pile_block'))
                .width('120lpx')
                .height('120lpx')
                .margin({ top: '40lpx' })
            }.justifyContent(FlexAlign.Center)
            .onClick(() => {

            })

            Text(`暂无有序桩`)
              .fontSize('14lpx')
              .margin({ bottom: '8lpx' })
              .fontColor($r('app.color.999999'))
              .fontWeight('bold')
            Text('点击下方按钮进行绑定')
              .fontSize('12lpx')
              .fontColor($r('app.color.999999'))
              .margin({ bottom: '24lpx' })

            LongBtnComponent({
              btnColor: $r('app.color.longBtn_blue'),
              btnFontColor: $r('app.color.background_color_over'),
              btnBorderColor: $r('app.color.longBtn_blue'),
              btnName: '绑定我的有序桩',
              onEvent: (data: string) => {
                this.onClickBindFunc(true)
              }
            })
          }
          .width('100%')
        } else {
          Column() {
            Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
              Column() {
                Text(this.bindDetail.stationName)
                  .width('100%')
                  .fontSize('14lpx')
                  .fontWeight('bold')
                Row() {
                  Text(this.bindDetail.portName.split('-')[1])
                    .fontSize('24lpx')
                    .fontWeight('bold')
                  Text('号充电桩')
                    .fontSize('12lpx')
                    .alignSelf(ItemAlign.Baseline)
                }
                .margin({ bottom: '24lpx', top: '8lpx' })
                .width('100%')

                Row() {
                  Button({ type: ButtonType.Capsule, stateEffect: true }) {
                    Row() {
                      Text('解绑').fontSize('12lpx').fontColor(this.btnFontColor).height('20lpx')
                    }.alignItems(VerticalAlign.Center).height('20lpx').margin({ left: '12lpx', right: '12lpx' })
                  }
                  .borderColor(this.btnBorderColor)
                  .borderWidth('1lpx')
                  .borderRadius('12lpx')
                  .backgroundColor(this.btnBackColor)
                  .height('24lpx')
                  .width('72lpx')
                  .onClick(() => {

                    this.btnBackColor = $r('app.color.longBtn_blue')
                    this.btnFontColor = $r('app.color.background_color_over')
                    this.btnBorderColor = $r('app.color.longBtn_blue')
                    promptAction.showDialog({
                      title: '',
                      message: '此操作将无法恢复，是否继续解绑',
                      isModal: true,
                      shadow: ShadowStyle.OUTER_FLOATING_SM,
                      buttons: [
                        {
                          text: '取消',
                          color: $r('app.color.longBtn_blue'),
                        },
                        {
                          text: '确定',
                          color: $r('app.color.longBtn_blue')
                        }
                      ]
                    }).then((data) => {
                      console.info(`解绑${data.index}￥${this.haveCard}`)
                      // 确定按钮
                      if (data.index === 1) {
                        this.getReserveUnbind(this.bindDetail.id)
                      } else {
                        this.btnBackColor = $r('app.color.background_color_over')
                        this.btnFontColor = $r('app.color.item_title_font')
                        this.btnBorderColor = $r('app.color.CECECE')
                      }
                    }).catch((err: Error) => {
                    })
                  })
                }
                .width('100%')
              }.alignSelf(ItemAlign.Start)
              .margin({ right: '25lpx', top: '12lpx', bottom: '12lpx' })

              Column() {
                Image($r('app.media.charging_post'))
                  .width('59lpx')
                  .height('120lpx')
                  .margin({ right: '16lpx' })
              }
              .margin({ top: '4lpx', bottom: '4lpx' })
            }
            .padding({ left: '12lpx', right: '16lpx' })
            .margin({ top: '16lpx', left: '16lpx', right: '16lpx' })
            // .width('100%')
            .borderRadius('8lpx')
            .backgroundColor($r('app.color.background_color_over'))
          }
          .width('100%')
        }

      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.card_background'))

      if (this.cusSText !== '') {
        CustomShowToast({
          cusSTBorderRadius: '8lpx',
          cusSTBackgroundColor: this.cusStatus === 'error' ? 'rgba(252, 227, 223, 1)' : 'rgba(100, 187, 92, 0.15)',
          cusSTText: this.cusSText,
          cusSTImage: this.cusStatus === 'error' ? $r('app.media.customShowToast_error') :
          $r('app.media.orderEnd_successIcon'),
          cusSTFontColor: this.cusStatus === 'error' ? $r('app.color.longBtn_red') :
          $r('app.color.charging_font_green_color')
        }).position({ bottom: '100lpx' })
      }
    }
  }
}