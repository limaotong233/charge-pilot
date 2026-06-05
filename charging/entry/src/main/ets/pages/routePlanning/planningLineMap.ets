import { HeadComponent } from '../../components/headComponent'
import { PlanningLineSiteCardComponent } from '../../components/planningLineSiteCardComponent'
import { RoutePlanningMap } from './components/routePlanningMap'
import { mapCommon } from '@kit.MapKit'
import { router } from '@kit.ArkUI';
import { StationListItemReturning } from '../../model/interface/api/HomeApiInterface';


@Entry
@Component
export struct PlanningLineMap {
  @StorageProp('currentBreakpoint') curBp: string = 'sm'
  scroller: Scroller = new Scroller()
  @State isShowSheet: boolean = true
  @State siteList: StationListItemReturning[] = []
  @State planningList: StationListItemReturning[] = []
  @State startSpot: string = AppStorage.get('startSpot') || ''
  @State endSpot: string = AppStorage.get('endSpot') || ''
  @State switch: boolean | undefined = AppStorage.get('switch') || undefined
  @State startLatLon: mapCommon.LatLng = AppStorage.get('startSpotLocation') as mapCommon.LatLng
  @State endLatLon: mapCommon.LatLng = AppStorage.get('endSpotLocation') as mapCommon.LatLng
  @State mileageNumber: number = 0
  @State startSOCValue: number = 0
  @State endSOCValue: number = 0

  aboutToAppear(): void {
    let routerState = router.getState();
    if (routerState.params) {
      let params: Record<string, number> = (routerState.params as Record<string, number>)
      this.mileageNumber = params.mileageNumber;
      this.startSOCValue = params.startSOCValue;
      this.endSOCValue = params.endSOCValue;
    }
  }

  @Builder
  myBuilder() {
    Column() {
      Column() {
        Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
          Row() {
            Image($r('app.media.routePlanning_start'))
              .width('35lpx')
              .height('40lpx')
              .padding({ top: '8lpx' })
              .margin({ right: '0lpx' })
            Text(this.switch ? this.startSpot : this.endSpot)
              .width('200lpx')
              .fontSize('14lpx')
              .fontColor($r('app.color.historyList_font_color'))
          }

          Text(`SOC ${this.startSOCValue}%`)
            .fontSize('12lpx')
            .fontColor($r('app.color.999999'))
        }
        .margin({ bottom: '12lpx' })

        Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
          Text(`途径${this.planningList ? this.planningList.length : 0}个站点`)
            .padding({ left: '8lpx' })
            .fontSize('12lpx')
            .fontColor($r('app.color.999999'))
        }
      }
      .borderRadius('16lpx')
      .backgroundColor($r('app.color.background_color_over'))
      .padding({
        left: '8lpx',
        right: '16lpx',
        top: '16lpx',
        bottom: '16lpx'
      })
      .margin({
        left: '16lpx',
        right: '16lpx',
        top: '16lpx',
        bottom: '8lpx'
      })

      if (this.planningList && this.planningList.length > 0) {
        Column() {
          Scroll(this.scroller) {
            Column() {
              ForEach(this.planningList, (item: StationListItemReturning, index: number) => {
                PlanningLineSiteCardComponent({
                  siteItemInfo: item,
                  siteName: item.stationName, //'杭州凤起路直流充电站',
                  tagList: [`最快${item?.chargeType === 1 ? '5' : '1'}00kw`, '对外开放', '互联互通'],
                  priceCount: item.chargeFee, //12,
                  distanceKm: item.distance,
                  isShowCollect: item.isCollect === 1 ? true : false//true
                })
                  .margin({ bottom: '8lpx', left: '16lpx', right: '16lpx' })
              }, (index: StationListItemReturning) => (index.stationId))
            }
          }
          .height('auto')
          .scrollable(ScrollDirection.Vertical) //纵向滚动
          .scrollBar(BarState.Off)
        }
      }

      Column() {
        Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
          Row() {
            Image($r('app.media.routePlanning_end'))
              .width('35lpx')
              .height('40lpx')
              .padding({ top: '8lpx' })
              .margin({ right: '0lpx' })
            Text(this.switch ? this.endSpot : this.startSpot)
              .width('200lpx')
              .fontSize('14lpx')
              .fontColor($r('app.color.historyList_font_color'))
          }

          Text(`SOC ${this.endSOCValue}%`)
            .fontSize('12lpx')
            .fontColor($r('app.color.999999'))
        }
      }
      .borderRadius('16lpx')
      .backgroundColor($r('app.color.background_color_over'))
      .padding({
        left: '8lpx',
        right: '16lpx',
        top: '8lpx',
        bottom: '8lpx'
      })
      .margin({
        left: '16lpx',
        right: '16lpx',
        top: '0lpx',
        bottom: '8lpx'
      })
    }
    .height('450lpx')
  }

  build() {
    Stack({ alignContent: Alignment.BottomStart }) {
      HeadComponent({
        headName: '路线规划',
      }).zIndex(1).position({ top: '0lpx' })
      if (this.siteList) {

        RoutePlanningMap({
          isShowSheet: this.isShowSheet,
          endTarget: this.switch ? this.endLatLon : this.startLatLon,
          startTarget: this.switch ? this.startLatLon : this.endLatLon,
          startSOCValue: this.startSOCValue,
          endSOCValue: this.endSOCValue,
          mileageNumber: this.mileageNumber,
          siteList: this.siteList,
          planningList: this.planningList
        })
          .width('100%')
          .height('auto')
          .bindSheet($$this.isShowSheet, this.myBuilder(), {
            showClose: false,
            enableOutsideInteractive: true,
            backgroundColor: $r('app.color.card_background'),
            detents: [240, 692],
            onWillDismiss: ((DismissSheetAction: DismissDialogAction) => {
              console.log(`${DismissSheetAction.reason}`)
            }),
          })
      }
    }
  }
}