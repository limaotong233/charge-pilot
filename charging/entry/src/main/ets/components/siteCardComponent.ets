import { router } from '@kit.ArkUI'
import { addCollectList, cancelCollectList, downLoadFile } from '../api/CollectionApi'
import { enterDetail } from '../api/HomeApi'
import { EnterDetailItem, StationListItemReturning } from '../model/interface/api/HomeApiInterface'
import { useToastHook } from '../service'
import { buffer } from '@kit.ArkTS'

@Component
export struct SiteCardComponent {
  @Prop siteName: string
  @Prop tagList: Array<string> // = ['最快500kw', '对外开放', '互联互通']
  @State rating: number = 0;
  @State imageUrl: string = ''
  @Prop @Watch('onSiteItemInfo') siteItemInfo: StationListItemReturning
  @Prop isShowCollect: boolean
  @Link carStatus: string
  @Prop stationId: string
  @Prop chargeFee: number
  @Prop distanceKm: number
  @Prop chargeType: number
  @Prop usedCount: number
  @Prop portCount: number
  @Prop isCollect: number
  @Prop positionWhere: string
  onEvent: Function = () => {
  }

  // 刷新站点图片
  onSiteItemInfo() {
    if (this.siteItemInfo.fileCode) {
      downLoadFile<ArrayBuffer>({fileCode: this.siteItemInfo.fileCode}).then(async (res) => {
        const base64 = buffer.from(res).toString('base64') //buffer.from(res).toString('base64')
        console.info('接口 图片res', `data:image/png;base64,${base64}`)
        this.imageUrl = `data:image/png;base64,${base64}`
      }).catch((err:Error) => {
        this.imageUrl = ``
      })
    } else {
      this.imageUrl = ``
    }
  }

  // 添加收藏
  AddCollect() {
    addCollectList<string>({ stationId: this.siteItemInfo?.stationId || this.stationId }).then((res) => {
      console.info('接口 添加收藏', res)
      useToastHook('收藏成功', '32lpx')

      if (this.siteItemInfo) {
        this.siteItemInfo.isCollect = 1 //value
        AppStorage.setOrCreate('siteItemInfo', this.siteItemInfo)
      }
      this.isCollect = 1 //value
    })
  }

  // 取消收藏
  CancelCollect() {
    cancelCollectList<string>({ stationId: this.siteItemInfo?.stationId || this.stationId }).then((res) => {
      console.info('接口 取消收藏', res)
      useToastHook('取消收藏', '32lpx')

      if (this.siteItemInfo) {
        this.siteItemInfo.isCollect = 0 //value
        AppStorage.setOrCreate('siteItemInfo', this.siteItemInfo)
      }

      this.isCollect = 0 //value
      this.onEvent()
    })
  }

  // 查询用户进站信息
  enterDetail() {
    enterDetail<EnterDetailItem | StationListItemReturning>({ stationId: '1' }).then((res) => {
      console.info('enterDetail 接口 进站信息', JSON.stringify(res))
      if (res) {
        useToastHook('请先退出站点，再前往', '40lpx')
        return
      } else {
        console.info('enterDetail 接口 进站信息 this.siteItemInfo',JSON.stringify(this.siteItemInfo))
        AppStorage.setOrCreate('continueEndTarget',
          { latitude: this.siteItemInfo.latitude, longitude: this.siteItemInfo.longitude })
        AppStorage.setOrCreate('siteItemInfo', this.siteItemInfo) //this.siteItemInfo
        AppStorage.setOrCreate('continueIsShowSheet', true)

        this.carStatus = '正在前往'
        AppStorage.setOrCreate('continueCarStatus', '正在前往')
        AppStorage.setOrCreate('routerParamsSiteInfo', this.siteItemInfo)
        if (this.positionWhere !== 'map') {
          console.log('enterDetail positionWhere')
          router.pushUrl({
            url: 'pages/Index',
            // params: this.siteItemInfo
          })
        }
      }
    })
  }
 aboutToAppear() {
    if (this.siteItemInfo.fileCode) {
      downLoadFile<ArrayBuffer>({fileCode: this.siteItemInfo.fileCode}).then(async (res) => {
        const base64 = buffer.from(res).toString('base64') //buffer.from(res).toString('base64')
        console.info('接口 图片res', `data:image/png;base64,${base64}`)
        this.imageUrl = `data:image/png;base64,${base64}`
      }).catch((err:Error) => {
        this.imageUrl = ``
        // useToastHook('图片加载失败', '40lpx')
      })
    } else {
      this.imageUrl = ``
    }
  }

  build() {
    if (this.siteItemInfo.delFlag) {
      if (this.siteItemInfo.delFlag === 1) {
        Column() {
          Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
            Image(this.imageUrl ? this.imageUrl : $r('app.media.homeSearch_siteImage'))
              .margin({ right: '12lpx' })
              .borderRadius('10lpx')
              .width('58lpx')
              .height('48lpx')

            Column() {
              Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
                Column() {
                  Text(this.siteItemInfo?.stationName || this.siteName)
                    .fontSize('16lpx')
                    .fontWeight('bold')
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .maxLines(1)
                }

                Column() {
                  Image(this.siteItemInfo?.isCollect === 1 || this.isCollect === 1 ?
                  $r('app.media.siteCollection_star') : $r('app.media.siteCollection_star1'))
                    .width('16lpx')
                    .height('16lpx')
                    .onClick(() => {
                      if (this.siteItemInfo?.isCollect === 1 || this.isCollect === 1) {
                        this.CancelCollect()
                      } else {
                        this.AddCollect()
                      }
                    })
                }
              }
              .margin({ bottom: '8lpx' })

              Row() {
                ForEach(this.tagList, (item: string) => {
                  Column() {
                    Text(item)
                      .fontSize('12lpx')
                      .fontColor($r('app.color.bottom_nav_fontcolor'))
                  }
                  .borderRadius('10lpx')
                  .margin({ right: '4lpx' })
                  .padding({
                    left: '8lpx',
                    right: '8lpx',
                    top: '1lpx',
                    bottom: '1lpx'
                  })
                  .backgroundColor($r('app.color.tag_background'))
                }, (item: string) => item)
              }.alignSelf(ItemAlign.Start)
            }
          }
          .margin({ bottom: '24lpx' })

          Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
            Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Baseline }) {
              Text(`￥${this.siteItemInfo?.chargeFee || this.chargeFee}`)
                .fontSize('20lpx')
                .fontColor($r('app.color.chargingPrice_color'))
              Text('/度起')
                .fontSize('12lpx')
                .fontColor($r('app.color.charging_font_color'))
            }

            Flex({ justifyContent: FlexAlign.End, alignItems: ItemAlign.Center }) {
              Column() {
                Text(`${(this.siteItemInfo?.chargeType === 1 || this.chargeType) ? '快' : '慢'}`)
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
                Text(`${(this.usedCount === this.portCount) ? '忙' : '闲'}${this.siteItemInfo?.usedCount ||
                this.usedCount}/${this.siteItemInfo?.portCount || this.portCount}`)
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

              Text('停车收费按照实际情况')
                .fontColor($r('app.color.charging_font_color'))
                .fontSize('12lpx')
            }
            .width('50%')

            Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
              Image($r('app.media.homeSearch_pilot'))
                .width('16lpx')
                .height('16lpx')
                .margin({ right: '4lpx' })
                .interpolation(ImageInterpolation.High)
              Text(this.carStatus)
                .fontSize('12lpx')
                .fontColor($r('app.color.bottom_nav_fontcolor_active'))
              if (this.carStatus === '点击前往') {
                Text(`${this.distanceKm ? `(${this.distanceKm}Km)` : ''}`)
                  .fontSize('10lpx')
                  .fontColor($r('app.color.bottom_nav_fontcolor_active'))
              }
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
            .onClick((event?: ClickEvent) => {
              console.info('点击 前往', JSON.stringify(event))
              if (this.carStatus === '点击前往') {
                this.enterDetail()
              }
            })
          }
        }
        .backgroundColor($r('app.color.background_color_over'))
        .padding('12lpx')
        .borderRadius('6lpx')
        .onClick((event?: ClickEvent) => {
          console.info('点击 外 前往', JSON.stringify(event))
          router.pushUrl({
            url: 'pages/siteCollection/siteInfo',
            params: {
              stationId: this.siteItemInfo?.stationId || this.stationId
            }

          })
        })
      }
    } else {
      if (this.siteItemInfo.delFlag !== 0) {

        Column() {
          Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
            Image(this.imageUrl ? this.imageUrl : $r('app.media.homeSearch_siteImage'))
              .margin({ right: '12lpx' })
              .borderRadius('10lpx')
              .width('58lpx')
              .height('48lpx')

            Column() {
              Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
                Column() {
                  Text(this.siteItemInfo?.stationName || this.siteName)
                    .fontSize('16lpx')
                    .fontWeight('bold')
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .maxLines(1)
                }

                Column() {
                  // if (this.isShowCollect) {
                  Image(this.siteItemInfo?.isCollect === 1 || this.isCollect === 1 ?
                  $r('app.media.siteCollection_star') : $r('app.media.siteCollection_star1'))
                    .width('16lpx')
                    .height('16lpx')
                    .onClick(() => {
                      if (this.siteItemInfo?.isCollect === 1 || this.isCollect === 1) {
                        this.CancelCollect()
                      } else {
                        this.AddCollect()
                      }
                    })
                }
              }
              .margin({ bottom: '8lpx' })

              Row() {
                ForEach(this.tagList, (item: string) => {
                  Column() {
                    Text(item)
                      .fontSize('12lpx')
                      .fontColor($r('app.color.bottom_nav_fontcolor'))
                  }
                  .borderRadius('10lpx')
                  .margin({ right: '4lpx' })
                  .padding({
                    left: '8lpx',
                    right: '8lpx',
                    top: '1lpx',
                    bottom: '1lpx'
                  })
                  .backgroundColor($r('app.color.tag_background'))
                }, (item: string) => item)
              }.alignSelf(ItemAlign.Start)
            }
          }
          .margin({ bottom: '24lpx' })

          Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
            Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Baseline }) {
              Text(`￥${this.siteItemInfo?.chargeFee || this.chargeFee}`)
                .fontSize('20lpx')
                .fontColor($r('app.color.chargingPrice_color'))
              Text('/度起')
                .fontSize('12lpx')
                .fontColor($r('app.color.charging_font_color'))
            }

            Flex({ justifyContent: FlexAlign.End, alignItems: ItemAlign.Center }) {
              Column() {
                Text(`${(this.siteItemInfo?.chargeType === 1 || this.chargeType) ? '快' : '慢'}`)
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
                Text(`${(this.usedCount === this.portCount) ? '忙' : '闲'}${this.siteItemInfo?.usedCount ||
                this.usedCount}/${this.siteItemInfo?.portCount || this.portCount}`)
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

              Text('停车收费按照实际情况')
                .fontColor($r('app.color.charging_font_color'))
                .fontSize('12lpx')
            }
            .width('50%')

            Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
              Image($r('app.media.homeSearch_pilot'))
                .width('16lpx')
                .height('16lpx')
                .margin({ right: '4lpx' })
                .interpolation(ImageInterpolation.High)
              Text(this.carStatus)
                .fontSize('12lpx')
                .fontColor($r('app.color.bottom_nav_fontcolor_active'))
              if (this.carStatus === '点击前往') {
                Text(`${this.distanceKm ? `(${this.distanceKm}Km)` : ''}`)
                  .fontSize('10lpx')
                  .fontColor($r('app.color.bottom_nav_fontcolor_active'))
              }
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
            .onClick((event?: ClickEvent) => {
              console.info('点击 前往', JSON.stringify(event))
              if (this.carStatus === '点击前往') {
                this.enterDetail()
              }
            })
          }
        }
        .backgroundColor($r('app.color.background_color_over'))
        .padding('12lpx')
        .borderRadius('6lpx')
        .onClick((event?: ClickEvent) => {
          console.info('点击 外 前往', JSON.stringify(event))
          router.pushUrl({
            url: 'pages/siteCollection/siteInfo',
            params: {
              stationId: this.siteItemInfo?.stationId || this.stationId
            }

          })
        })
      }
    }
  }
}