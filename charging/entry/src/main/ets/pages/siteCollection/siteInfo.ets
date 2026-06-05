import { enterDetail, getStationDetail, getStationPortList } from '../../api/HomeApi'
import { HeadComponent } from '../../components/headComponent'
import { router } from '@kit.ArkUI'
import {
  StationDetailReturning,
  StationDetailVO,
  StationListItemReturning,
  StationPortListReturning,
} from '../../model/interface/api/HomeApiInterface'
import { useToastHook } from '../../service'
import { getDistance } from '../../utils/tools'
import { addCollectList, cancelCollectList, downLoadFile } from '../../api/CollectionApi'
import { buffer } from '@kit.ArkTS'

@Entry
@Component
export struct SiteInfo {
  scroller: Scroller = new Scroller()
  @State isCollectSite: boolean = true
  @State activeName: string = '站点详情'
  @State siteList: StationPortListReturning[] = []
  @State stationDetail: StationDetailReturning | null = null
  @State siteItemInfo: StationListItemReturning | null = null
  @State imageUrl: string = ''

  // 添加收藏
  AddCollect() {
    addCollectList<string>({ stationId: this.stationDetail?.stationId as string }).then((res) => {
      console.info('接口 添加收藏', res)
      useToastHook('收藏成功', '32lpx')
      this.getStationDetailReturning()
    })
  }

  // 取消收藏
  CancelCollect() {
    cancelCollectList<string>({ stationId: this.stationDetail?.stationId as string }).then((res) => {
      console.info('接口 取消收藏', res)
      useToastHook('取消收藏', '32lpx')
      this.getStationDetailReturning()
    })
  }

  // 查询用户进站信息
  enterDetail() {
    enterDetail<StationListItemReturning>({ stationId: '1' }).then((res) => {
      console.info('接口 进站信息', JSON.stringify(res))
      if (res) {
        this.siteItemInfo = res as StationListItemReturning
        useToastHook('请先退出站点，再前往', '40lpx')
        return
      } else {
        AppStorage.setOrCreate('continueEndTarget',
          { latitude: this.stationDetail?.latitude, longitude: this.stationDetail?.longitude })
        AppStorage.setOrCreate('siteItemInfo', this.stationDetail) //this.siteItemInfo
        AppStorage.setOrCreate('continueIsShowSheet', true)

        // this.carStatus = '正在前往'
        AppStorage.setOrCreate('continueCarStatus', '正在前往')
        AppStorage.setOrCreate('routerParamsSiteInfo', this.stationDetail)
        router.pushUrl({
          url: 'pages/Index',
          // params: this.stationDetail
        })
      }
    })
  }

  // 获取充电站详情
  getStationDetailReturning() {
    let params = router.getParams() as StationDetailVO
    if (params) {
      getStationDetail<StationDetailReturning>({ stationId: params.stationId }).then(async (res) => {
        let tempList = await getDistance([{ latitude: res.latitude, longitude: res.longitude }])

        if (tempList) {
          res.distance = Number(((tempList[0].cells[0].distance as number) / 1000)?.toFixed(2))
        } else {
          res.distance = 0
        }
        this.stationDetail = res
        downLoadFile<ArrayBuffer>({fileCode: res.fileCode}).then(async (res) => {
          const base64 = buffer.from(res).toString('base64')
          console.info('接口 图片res', `data:image/png;base64,${base64}`)
          this.imageUrl = `data:image/png;base64,${base64}`
        }).catch((err:Error) => {
          this.imageUrl = ''
          // useToastHook('图片加载失败', '40lpx')
        })
      })
      getStationPortList<StationPortListReturning[]>({ stationId: params.stationId }).then((res) => {
        console.info('接口 portList', JSON.stringify(res))
        this.siteList = res
      })
    }
  }

  aboutToAppear(): void {
    this.getStationDetailReturning()
  }

  build() {
    Column() {
      HeadComponent({
        headName: '站点详情',
        isHaveBtn: true,
        btnScr: this.stationDetail?.isCollect === 1 ? $r('app.media.siteCollection_star') :
        $r('app.media.siteCollection_star1'),
        receive: () => {
          if (this.stationDetail?.isCollect === 1) {
            this.CancelCollect()
          } else {
            this.AddCollect()
          }
        }
      })
      // if (true) {
      if (this.stationDetail) {
        Column() {
          Image(this.imageUrl ? this.imageUrl : $r('app.media.siteInfo_icon'))
            .width('304lpx')
            .height('172lpx')
          Text(this.stationDetail?.stationName)
            .wordBreak(WordBreak.BREAK_ALL)
            .textAlign(TextAlign.JUSTIFY)
            .fontSize('16lpx')
            .fontColor($r('app.color.historyList_font_color'))
            .margin({ top: '8lpx', bottom: '8lpx' })
            .width('100%')
          Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
            Column() {
              Row() {
                Image($r('app.media.siteInfo_timeIcon'))
                  .width('16lpx')
                  .height('16lpx')
                  .margin({ right: '8lpx' })
                Text(this.stationDetail?.openTime.split(' ')[1] || '00:00 ~ 24:00营业')
                  .fontSize('12lpx')
                  .fontColor($r('app.color.charging_font_color'))
              }
              .width('100%')
              .margin({ bottom: '4lpx' })

              Row() {
                Image($r('app.media.siteInfo_kwIcon'))
                  .width('16lpx')
                  .height('16lpx')
                  .margin({ right: '8lpx' })
                Text(`最大功率${this.stationDetail?.chargePower || 0}kw`)
                  .fontSize('12lpx')
                  .fontColor($r('app.color.charging_font_color'))
              }
              .width('100%')
            }
            .width('50%')

            Flex({ justifyContent: FlexAlign.End, alignItems: ItemAlign.Center }) {
              Column() {
                Text(this.stationDetail?.chargeType === 1 ? `快` : `慢`)
                  .fontColor($r('app.color.background_color_over'))
                  .fontSize('12lpx')
                  .fontWeight(400)
              }
              .backgroundColor($r('app.color.charging_font_green_color'))
              .borderColor($r('app.color.charging_font_green_color'))
              .borderWidth('1lpx')
              .borderRadius({ topLeft: '4lpx', bottomLeft: '4lpx' })
              .padding({
                left: '6lpx',
                right: '6lpx',
                top: '5lpx',
                bottom: '5lpx'
              })

              Column() {
                Text(`${this.stationDetail?.usedCount === this.stationDetail?.portCount ? '忙' :
                  '闲'}${this.stationDetail?.usedCount}/${this.stationDetail?.portCount}`)
                  .fontSize('12lpx')
              }
              .borderColor($r('app.color.tag_background'))
              .borderWidth({
                top: '1lpx',
                left: '0',
                right: '1lpx',
                bottom: '1lpx'
              })
              .backgroundColor($r('app.color.background_color_over'))
              .borderRadius({ topRight: '4lpx', bottomRight: '4lpx' })
              .padding({
                left: '8lpx',
                right: '8lpx',
                top: '5lpx',
                bottom: '5lpx'
              })
            }
          }
          .margin({ bottom: '12lpx' })

          Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
            Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
              Column() {
                Text('P')
                  .fontColor($r('app.color.bottom_nav_fontcolor_active'))
                  .fontSize('12lpx')
              }
              .backgroundColor('rgba(10, 89, 247, 0.1)')
              .padding({
                left: '7lpx',
                right: '7lpx',
                top: '3lpx',
                bottom: '3lpx'
              })
              .borderRadius('2lpx')
              .margin({ right: '8lpx' })

              Row() {
                Text(`鸿蒙智能充电停车场`)
                  .fontColor($r('app.color.charging_font_color'))
                  .fontSize('12lpx')
              }
            }
            .width('60%')

            Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
              Image($r('app.media.homeSearch_pilot'))
                .width('16lpx')
                .height('16lpx')
                .margin({ right: '4lpx' })
              Text(`${this.stationDetail?.distance ? `${this.stationDetail.distance}Km` : ''}`)
                .fontSize('10lpx')
                .fontColor($r('app.color.bottom_nav_fontcolor_active'))
            }
            .alignSelf(ItemAlign.End)
            .padding({
              left: '8lpx',
              right: '8lpx',
              top: '4lpx',
              bottom: '4lpx'
            })
            .width('auto')
            .borderColor($r('app.color.bottom_nav_fontcolor_active'))
            .borderWidth('1lpx')
            .borderRadius('20lpx')
            .backgroundColor('rgba(10, 89, 247, 0.1)')
            .onClick(() => {
              this.enterDetail()
            })
          }
        }
        .padding('12lpx')
        .margin('16lpx')
        .borderRadius('8lpx')
        .backgroundColor($r('app.color.background_color_over'))

        Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
          Text('站点详情')
            .width('50%')
            .fontSize('12lpx')
            .fontColor(this.activeName === '站点详情' ? $r('app.color.historyList_font_color') :
            $r('app.color.charging_font_color'))
            .padding({ top: '10lpx', bottom: '10lpx' })
            .textAlign(TextAlign.Center)
            .backgroundColor(this.activeName === '站点详情' ? $r('app.color.background_color_over') :
            $r('app.color.tag_background'))
            .borderRadius({ topLeft: '8lpx', topRight: this.activeName === '站点详情' ? '8lpx' : '0lpx' })
            .onClick(() => {
              this.activeName = '站点详情'
            })
          Text('终端列表')
            .width('50%')
            .fontSize('12lpx')
            .fontColor(this.activeName === '终端列表' ? $r('app.color.historyList_font_color') :
            $r('app.color.charging_font_color'))
            .padding({ top: '10lpx', bottom: '10lpx' })
            .textAlign(TextAlign.Center)
            .backgroundColor(this.activeName === '终端列表' ? $r('app.color.background_color_over') :
            $r('app.color.tag_background'))
            .borderRadius({ topLeft: this.activeName === '终端列表' ? '8lpx' : '0lpx', topRight: '8lpx' })
            .onClick(() => {
              this.activeName = '终端列表'
            })
        }
        .borderRadius({ topLeft: '8lpx', topRight: '8lpx' })
        .backgroundColor($r('app.color.tag_background'))
        .margin({ left: '16lpx', right: '16lpx' })
        .borderWidth({ bottom: '1lpx' })
        .borderColor($r('app.color.tag_background'))

        if (this.activeName === '站点详情') {
          Column() {
            Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
              Column() {
                Text('充电费用')
                  .fontSize('12lpx')
                  .fontColor($r('app.color.historyList_font_color'))
                  .margin({ bottom: '4lpx' })
                  .width('100%')

                Text(`当前时段 ${this.stationDetail?.openTime.split(' ')[1] || '00:00-24:00'}`)
                  .fontSize('10lpx')
                  .fontColor($r('app.color.charging_font_color'))
                  .width('100%')
              }
              .width('50%')

              Row() {
                Text(`￥${this.stationDetail?.chargeFee}`)
                  .fontSize('20lpx')
                  .fontColor($r('app.color.chargingPrice_color'))
                  .width('100%')
                  .textAlign(TextAlign.End)
                Text('/度起')
                  .fontSize('12lpx')
                  .fontColor($r('app.color.charging_font_color'))
                  .width('100%')
                  .textAlign(TextAlign.End)
              }
              .width('50%')
            }
            .padding({ bottom: '12lpx' })
            .borderWidth({ bottom: '1lpx' })
            .borderColor({ bottom: 'rgba(0,0,0,0.05)' })

            Text('营业信息')
              .fontSize('12lpx')
              .fontColor($r('app.color.historyList_font_color'))
              .margin({ top: '12lpx' })
              .width('100%')
            Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
              Text('服务提供')
                .padding({
                  top: '6lpx',
                  bottom: '6lpx',
                  left: '8lpx',
                  right: '8lpx'
                })
                .fontSize('10lpx')
                .borderRadius('4lpx')
                .fontColor($r('app.color.charging_font_color'))
                .backgroundColor($r('app.color.tag_background'))
              Text(this.stationDetail?.serviceProvider || '--')
                .fontSize('10lpx')
                .fontColor($r('app.color.charging_font_color'))
            }.margin({ top: '8lpx' })

            Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
              Text('开放时间')
                .padding({
                  top: '6lpx',
                  bottom: '6lpx',
                  left: '8lpx',
                  right: '8lpx'
                })
                .fontSize('10lpx')
                .borderRadius('4lpx')
                .fontColor($r('app.color.charging_font_color'))
                .backgroundColor($r('app.color.tag_background'))
              Text(`${this.stationDetail?.openTime || '--'}`)
                .fontSize('10lpx')
                .fontColor($r('app.color.charging_font_color'))
            }.margin({ top: '8lpx' })

            Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
              Text('支付方式')
                .padding({
                  top: '6lpx',
                  bottom: '6lpx',
                  left: '8lpx',
                  right: '8lpx'
                })
                .fontSize('10lpx')
                .borderRadius('4lpx')
                .fontColor($r('app.color.charging_font_color'))
                .backgroundColor($r('app.color.tag_background'))
              Text(this.stationDetail?.paymentMethod || '--')
                .fontSize('10lpx')
                .fontColor($r('app.color.charging_font_color'))
            }.margin({ top: '8lpx' })

            Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
              Text('发票类型')
                .padding({
                  top: '6lpx',
                  bottom: '6lpx',
                  left: '8lpx',
                  right: '8lpx'
                })
                .fontSize('10lpx')
                .borderRadius('4lpx')
                .fontColor($r('app.color.charging_font_color'))
                .backgroundColor($r('app.color.tag_background'))
              Text(this.stationDetail?.invoiceType || '--')
                .fontSize('10lpx')
                .fontColor($r('app.color.charging_font_color'))
            }.margin({ top: '8lpx' })
          }
          .height('308lpx')
          .padding('12lpx')
          .margin({ left: '16lpx', right: '16lpx' })
          .borderRadius({ bottomLeft: '8lpx', bottomRight: '8lpx' })
          .backgroundColor($r('app.color.background_color_over'))
        } else {
          Column() {
            Scroll(this.scroller) {
              Column() {
                ForEach(this.siteList, (item: StationPortListReturning, index: number) => {
                  Column() {
                    Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
                      Column() {
                        Column() {
                          Image(item.portStatus === 1 ? $r('app.media.siteInfo_redIcon') :
                          $r('app.media.siteInfo_greenIcon'))
                            .width('48lpx')
                            .height('48lpx')
                            .margin({ left: '8lpx', right: '8lpx' })
                        }
                        .width('100%')
                        .backgroundColor(item.portStatus === 1 ? 'rgba(237, 111, 33, 0.15)' :
                          'rgba(100, 189, 92, 0.15)')
                        .borderRadius({ topLeft: '8lpx', topRight: '8lpx' })

                        Text(item.portStatus === 1 ? '充电中' : '空闲')
                          .width('100%')
                          .padding({ top: '4lpx', bottom: '4lpx' })
                          .fontSize('10lpx')
                          .fontColor($r('app.color.background_color_over'))
                          .backgroundColor(item.portStatus === 1 ? 'rgba(237, 111, 33, 1)' : 'rgba(100, 189, 92, 1)')
                          .textAlign(TextAlign.Center)
                          .borderRadius({ bottomLeft: '8lpx', bottomRight: '8lpx' })
                      }
                      .width('72lpx')
                      .margin({ right: '20lpx' })

                      Column() {
                        Text(`${item.portName.split('-')[1]}号充电桩` || '--')
                          .fontSize('10lpx')
                          .fontColor($r('app.color.historyList_font_color'))
                          .margin({ bottom: '10lpx' })
                          .width('100%')
                        Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
                          Text(`桩编码：${item.portName || '--'}`)
                            .fontSize('10lpx')
                            .fontColor($r('app.color.charging_font_color'))
                          Text('直流')
                            .fontSize('10lpx')
                            .fontColor($r('app.color.longBtn_blue'))
                            .borderRadius('10lpx')
                            .borderWidth('1lpx')
                            .borderColor($r('app.color.longBtn_blue'))
                            .backgroundColor('rgba(10, 89, 247, 0.1)')
                            .padding({
                              top: '4lpx',
                              bottom: '4lpx',
                              left: '12lpx',
                              right: '12lpx'
                            })
                            .textAlign(TextAlign.Center)
                        }
                        .width('100%')

                        Text(`最大功率：${item.chargePower}`)
                          .fontSize('10lpx')
                          .fontColor($r('app.color.charging_font_color'))
                          .width('100%')
                      }
                      .width('100%')
                    }.padding({ top: '12lpx', bottom: '12lpx' })
                    .borderWidth({ bottom: item.portStatus === 1 ? '0lpx' : '1lpx' })
                    .borderColor('rgba(0,0,0,0.05)')
                  }
                  .padding({ left: '12lpx', right: '12lpx' })
                  .margin({ left: '16lpx', right: '16lpx' })
                  .borderRadius({ bottomLeft: '8lpx', bottomRight: '8lpx' })
                  .backgroundColor($r('app.color.background_color_over'))
                }, (index: string) => index)
              }
            }
            .scrollable(ScrollDirection.Vertical) //纵向滚动
            .scrollBar(BarState.Off)
          }
          .height('308lpx')
          .width('100%')
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.card_background'))
  }
}

