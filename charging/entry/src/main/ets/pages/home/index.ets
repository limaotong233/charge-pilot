import { SearchComponent } from '../../components/searchComponent';
import { SiteCardComponent } from '../../components/siteCardComponent';
import { HomeMap } from './components/HomeMap';
import { common } from '@kit.AbilityKit';
import { DataBaseService } from '../../service/DataBaseService';
import {
  StationListItemReturning
} from '../../model/interface/api/HomeApiInterface';
import { router } from '@kit.ArkUI';

let dataBase = DataBaseService.getInstance()


@Component
export struct Home {
  scroller: Scroller = new Scroller()
  private context = getContext(this) as common.UIAbilityContext
  @Link currentIndex: number
  @StorageProp('currentBreakpoint') curBp: string = 'sm'
  @State isShowSheet: boolean = AppStorage.get('continueIsShowSheet') || false
  @State areaValue: string = AppStorage.get('continueAreaValue') || '';
  @State areaIndex: number = AppStorage.get('continueAreaIndex') || 0;
  @State areaArrowPosition: ArrowPosition = ArrowPosition.END
  @State chargeType: string = ''
  @State keyWordList: Array<string> = [] //['电饭锅', '慢充']
  @State @Watch('onHistoryList') historyList: Array<string> = []
  @State keyWord: string = AppStorage.get('continueKeyWord') || ''
  @State carStatus: string = AppStorage.get('continueCarStatus') || '点击前往'
  @State siteItemInfo: StationListItemReturning | undefined = AppStorage.get('siteItemInfo')
  @State distanceKm: number = 0
  @State positionWhere: string = 'map'

  async aboutToAppear() {
    // 获取充电站信息
    let historySearch = await dataBase.get('historySearch') as string
    this.historyList = JSON.parse(historySearch) as string[]
    this.keyWordList = this.historyList
  }
  onClickEvent(data: string) {
  }

  onHistoryList() {
    dataBase.put('historySearch', JSON.stringify(this.historyList))
  }

  @Builder
  areaSelect() {
    Row() {

      Text(this.areaValue ? this.areaValue : '定位中')
        .font({ size: '16lpx', weight: 400 })
        .fontColor($r('app.color.font_color_black'))
        .margin({ right: '8lpx' })
      Image($r('app.media.routeSearch_siteIcon'))
        .width('14lpx')
        .height('14lpx')
    }
    .padding({ left: '12lpx' })
    .width('100%')
  }

  // 快捷关键词
  @Builder
  keywordList() {
    if (this.keyWordList.length > 0) {
      Column() {
        Row() {
          Scroll(this.scroller) {
            Flex({
              direction: FlexDirection.Row,
              justifyContent: FlexAlign.Start,
              alignItems: ItemAlign.Start,
              wrap: FlexWrap.NoWrap
            }) {
              ForEach(this.keyWordList, (item: string, index: number) => {
                Column() {
                  Text(item)
                    .fontColor(this.keyWord === item ? $r('app.color.background_color_over') :
                    $r('app.color.bottom_nav_fontcolor'))
                    .fontSize('12lpx')
                }
                .borderRadius('10lpx')
                .borderColor(this.keyWord === item ? $r('app.color.btn_blue') : $r('app.color.bottom_nav_fontcolor'))
                .backgroundColor(this.keyWord === item ? $r('app.color.btn_blue') :
                $r('app.color.background_color_over'))
                .padding({
                  left: '8lpx',
                  right: '8lpx',
                  top: '2lpx',
                  bottom: '2lpx'
                })
                .borderWidth('1lpx')
                .margin({ right: '8lpx' })
                .onClick(() => {
                  console.info(item)
                  if (item === this.keyWord) {
                    this.keyWord = ''
                    AppStorage.setOrCreate('continueKeyWord', '')
                  } else {
                    this.keyWord = item
                    AppStorage.setOrCreate('continueKeyWord', item)
                    router.clear()
                    router.pushUrl({
                      url: 'pages/home/homeSearch',
                      params: {
                        keyWord: this.keyWord
                      }
                    })
                  }
                })
              }, (index: string) => index)
            }
          }
          .padding({ bottom: '12lpx', top: '6lpx' })
          .margin({ left: '16lpx', right: '16lpx' })
          .scrollable(ScrollDirection.Horizontal) //横向滚动
          .scrollBar(BarState.Off)
        }
        .width('100%')
      }
      .width('100%')
      .borderRadius({
        bottomLeft: this.curBp === 'sm' ? '0lpx' : '16lpx',
        bottomRight: this.curBp === 'sm' ? '0lpx' : '16lpx'
      })
      .backgroundColor($r('app.color.background_color_over'))

    }
  }

  @Builder
  mySiteCardBuilder() {
    Column() {
      SiteCardComponent({
        siteItemInfo: this.siteItemInfo,
        // siteName: this.siteItemInfo?.stationName,//'杭州凤起路直流充电站',
        tagList: [`最快${this.siteItemInfo?.chargeType === 1 ? '5' : '1'}00kw`, '对外开放', '互联互通'],
        isShowCollect: this.siteItemInfo?.isCollect === 1 ? true : false, //true,
        distanceKm: this.distanceKm, //11.9,
        carStatus: this.carStatus,
        usedCount: this.siteItemInfo?.usedCount,
        portCount: this.siteItemInfo?.portCount,
        positionWhere: this.positionWhere
      })
    }
    .width('100%')
    .height('240lpx')
    .borderRadius({ topLeft: '12lpx', topRight: '12lpx' })
    .padding({
      top: '16lpx',
      left: '16lpx',
      right: '16lpx',
      bottom: '68lpx'
    })
    .backgroundColor($r('app.color.card_background'))
  }

  build() {
    if (this.curBp === 'sm') {
      Stack({ alignContent: Alignment.BottomStart }) {
        Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
          SearchComponent({
            areaSelect: (): void => {
              this.areaSelect()
            },
            isHaveArea: true,
            needContinue: true,
            keywordList: (): void => {
              this.keywordList()
            },
            keyWord: this.keyWord,
            historyList: this.historyList
          })
        }.position({ top: 0 }).zIndex(1)

        HomeMap({
          chargeType: this.chargeType,
          currentIndex: this.currentIndex,
          isShowSheet: this.isShowSheet,
          carStatus: this.carStatus,
          siteItem: this.siteItemInfo,
          distance: this.distanceKm,
          areaValue: this.areaValue
        }).width('100%').height('100%').padding({ bottom: this.isShowSheet && this.siteItemInfo ? '230lpx' : '30lpx' })
        // 站点卡片
        if (this.isShowSheet && this.siteItemInfo) {
          this.mySiteCardBuilder()
        }
      }
      .width('100%')
      .height('100%')
    } else {
      Row() {
        if (this.isShowSheet && this.siteItemInfo) {
          Column() {
            SiteCardComponent({
              siteItemInfo: this.siteItemInfo,
              tagList: [`最快${this.siteItemInfo?.chargeType === 1 ? '5' : '1'}00kw`, '对外开放', '互联互通'],
              isShowCollect: this.siteItemInfo?.isCollect === 1 ? true : false,
              distanceKm: this.siteItemInfo?.distance, //11.9,
              carStatus: this.carStatus,
              positionWhere: this.positionWhere,
              usedCount: this.siteItemInfo?.usedCount,
            })
              .margin({ bottom: '16lpx' })
          }
          .position({ top: '0lpx', left: '108lpx' })
          .zIndex(1)
          .width('360lpx')
          .height('100%')
          .padding('16lpx')
          .backgroundColor($r('app.color.card_background'))
          .borderRadius({ topRight: '12lpx' })
        }
        SearchComponent({
          areaSelect: (): void => {
            this.areaSelect()
          },
          isHaveArea: true,
          keywordList: (): void => {
            this.keywordList()
          },
          keyWord: this.keyWord,
          historyList: this.historyList
        })
          .width('360lpx')
          .position({ top: '24lpx', right: '-84lpx' }).zIndex(1)

        HomeMap({
          chargeType: this.chargeType,
          currentIndex: this.currentIndex,
          isShowSheet: this.isShowSheet,
          carStatus: this.carStatus,
          siteItem: this.siteItemInfo,
          distance: this.distanceKm,
          areaValue: this.areaValue
        }).width('100%').height('100%').margin({ left: '108lpx' })
      }
      .padding({ right: this.curBp === 'sm' ? '0lpx' : '108lpx' })
      .width('100%')
    }
  }
}