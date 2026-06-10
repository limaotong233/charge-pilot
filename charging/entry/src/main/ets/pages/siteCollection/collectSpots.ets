import { cancelCollectList, getCollectList } from '../../api/CollectionApi'
import { HeadComponent } from '../../components/headComponent'
import { SiteCardComponent } from '../../components/siteCardComponent'
import {
  CollectionListReturning,
  CollectionListVO,
  CollectionListItem
} from '../../model/interface/api/CollectionApiInterface'
import { useToastHook } from '../../service'
import { mapCommon, navi } from '@kit.MapKit'
import { geoLocationManager } from '@kit.LocationKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { getDistance } from '../../utils/tools'
import { resStr } from '../../utils/i18n'

@Entry
@Component
export struct CollectSpots {
  scroller: Scroller = new Scroller()
  @State spotList: CollectionListItem[] = []
  @State carStatus: string = ''
  @State lazyLoading: boolean = false
  @State allLoaded: boolean = false
  @State currentPage: number = 1
  @State positionWhere: string = 'CollectSpots'

  // 取消收藏
  CancelCollect(id: string) {
    cancelCollectList<string>({ stationId: id }).then((res) => {
      console.info('接口 取消收藏', res)
      this.currentPage = 1
      this.lazyLoading = false
      this.allLoaded = false
      this.spotList = []
      this.getCollectList()
      useToastHook(resStr(getContext(this), 'common_cancel_collect'), '32lpx')
    })
  }

  //计算两点之间直线距离 origins:mapCommon.LatLng[],
  async getDistance(destinations: mapCommon.LatLng[]) {

    let location = await geoLocationManager.getCurrentLocation();
    console.log('接口 计算距离', JSON.stringify(location))

    let params: navi.DrivingMatrixParams = {
      'origins': [location],
      'destinations': destinations,
      'language': 'zh_CN'
    }

    return await navi.getDrivingMatrix(params).then((result) => {
      console.log('接口 getDrivingMatrix success', JSON.stringify(result))
      return result.rows
    }).catch((err: BusinessError) => {
      console.log('接口 getDrivingMatrix error', JSON.stringify(err))
    })
  }

  // 获取收藏站点的列表
  async getCollectList() {
    if (this.lazyLoading || this.allLoaded) {
      return
    }
    this.lazyLoading = true
    let extraData: CollectionListVO = {
      currentPage: this.currentPage,
      pageSize: 5,
      stationName: ''
    }
    let res = await getCollectList<CollectionListReturning>(extraData)

    if (res) {
      if (res.list.length === 0) {
        this.allLoaded = true
      } else {


        for (let i = 0; i < res.list.length; i++) {
          let item = res.list[i];
          if (item.delFlag != 1) {
            continue
          }
          // 计算距离
          console.log('接口 getCollectList', JSON.stringify(item))
          let tempList = await getDistance([{ latitude: item.latitude, longitude: item.longitude }])

          if (tempList) {
            item.distance = Number(((tempList[0].cells[0].distance as number) / 1000)?.toFixed(2))
          } else {
            item.distance = 0
          }
        }

        this.spotList = [...this.spotList, ...res.list]
        this.currentPage++
        console.info('接口 收藏列表', JSON.stringify(res))
      }
    }
    this.lazyLoading = false
  }

  onPageShow(): void {
    this.carStatus = resStr(getContext(this), 'common_go_to')
    this.getCollectList()
  }

  build() {
    Column() {
      HeadComponent({
        headName: resStr(getContext(this), 'collect_head_name'),
      })
      if (this.spotList.length > 0) {
        Column() {
          List() {
            ForEach(this.spotList, (item: CollectionListItem, index: number) => {
              ListItem() {
                Column() {
                  if (item.delFlag === 1) {
                    SiteCardComponent({
                      siteItemInfo: item,
                      siteName: item.stationName,
                      tagList: [`最快${item.chargeType === 1 ? '5' : '1'}00kw`, '对外开放', '互联互通'],
                      isShowCollect: false,
                      carStatus: this.carStatus,
                      distanceKm: item.distance, //11,
                      stationId: item.stationId,
                      chargeFee: item.chargeFee,
                      chargeType: item.chargeType,
                      usedCount: item.usedCount,
                      portCount: item.portCount,
                      positionWhere: this.positionWhere
                    }).borderRadius({ bottomLeft: 0, bottomRight: 0 })
                  } else {
                    Row() {
                      Image($r('app.media.siteCollection_delete'))
                        .width('48lpx')
                        .height('48lpx')
                        .margin({ right: '12lpx' })
                      Text($r('app.string.collect_invalid_station'))
                        .fontColor($r('app.color.historyList_font_color'))
                        .fontSize('16lpx')
                        .fontWeight('bold')
                    }
                    .padding('12lpx')
                    .width('100%')
                  }
                  Column() {
                    Flex({ justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
                      Image($r('app.media.siteCollection_star'))
                        .width('16lpx')
                        .height('16lpx')
                        .margin({ right: '8lpx' })
                      Text($r('app.string.collect_btn_cancel'))
                        .fontSize('16lpx')
                        .fontColor($r('app.color.F9A01E'))
                    }
                    .padding({
                      left: '16lpx',
                      right: '16lpx',
                      top: '8lpx',
                      bottom: '8lpx'
                    })
                    .borderWidth('1lpx')
                    .borderColor($r('app.color.F9A01E'))
                    .borderRadius('20lpx')
                    .width('128lpx')
                    .backgroundColor('rgba(249, 160, 30, 0.1)')
                    .margin({ top: '16lpx', bottom: '16lpx' })
                    .onClick(() => {
                      this.CancelCollect(item.stationId)
                    })
                  }
                  .borderWidth({ top: '1lpx' })
                  .borderColor($r('app.color.EEEEEE'))
                  .width('100%')
                }
                .margin({ bottom: '16lpx' })
                .borderRadius({ bottomLeft: '8lpx', bottomRight: '8lpx' })
                .backgroundColor($r('app.color.background_color_over'))

              }
            }, (item: CollectionListItem) => item.stationId)
            // 加载指示器
            if (this.lazyLoading) {
              ListItem() {
                Row() {
                  LoadingProgress()
                    .width('30lpx')
                    .height('30lpx')
                  Text($r('app.string.common_loading_short'))
                    .margin({ left: '10lpx' })
                }.justifyContent(FlexAlign.Center)
                .padding('15lpx')
              }
            }
          }
          .onReachEnd(() => {
            // 核心懒加载触发点
            this.getCollectList()
            console.info('接口底部触发', JSON.stringify(this.currentPage), JSON.stringify(this.lazyLoading),
              JSON.stringify(this.allLoaded))
          })
          // .height('100%')
          .scrollBarWidth(0)

          // 底部提示
          Text(this.allLoaded ? resStr(getContext(this), 'collect_all_loaded') : `${this.spotList.length}` + resStr(getContext(this), 'collect_data_loaded'))
            .padding({ top: '10lpx', bottom: '16lpx' })
            .fontSize('10lpx')
            .fontColor($r('app.color.999999'))// .height('100%')
            .margin({ bottom: '56lpx' })
        }
        .margin('16lpx')
        .height('88%')

      } else {
        if (this.lazyLoading) {
          ListItem() {
            Row() {
              LoadingProgress()
                .width('30lpx')
                .height('30lpx')
              Text('加载中')
                .margin({ left: '10lpx' })
            }.justifyContent(FlexAlign.Center)
            .padding('15lpx')
          }
        } else {

          Column() {
            Image($r('app.media.siteSearch_blockIcon'))
              .margin({ top: '48lpx' })
              .width('120lpx')
              .height('120lpx')
            Text($r('app.string.collect_empty'))
              .fontSize('12lpx')
              .fontColor($r('app.color.999999'))
          }
          .width('100%')
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.card_background'))
  }
}