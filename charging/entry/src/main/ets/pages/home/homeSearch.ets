import { SearchComponent } from '../../components/searchComponent'
import { LengthMetrics, router } from '@kit.ArkUI';
import { SiteCardComponent } from '../../components/siteCardComponent';
import { JSON } from '@kit.ArkTS';
import { LongBtnComponent } from '../../components/longBtnComponent';
import { DataBaseService } from '../../service/DataBaseService'
import {
  StationListItemReturning,
  StationListReturning,
  StationListVO
} from '../../model/interface/api/HomeApiInterface';
import { getStationDetail, getStationList } from '../../api/HomeApi';
import {
  CollectionListItem,
  CollectionListReturning,
  CollectionListVO
} from '../../model/interface/api/CollectionApiInterface';
import { getCollectList } from '../../api/CollectionApi';
import { ListColumn } from '../../utils/ListColumn';
import { getDistance } from '../../utils/tools';
import { hiTraceMeter } from '@kit.PerformanceAnalysisKit';
import { Tmp } from '../../model/class';

let dataBase = DataBaseService.getInstance()

@Entry
@Component
export struct HomeSearch {
  scroller: Scroller = new Scroller()
  @State @Watch('onChangeKeyWord') keyWord: string = ''
  @State @Watch('onChangeTabName') tabName: string = '常去站点'
  @State tab1: string = '常去站点'
  @State tab2: string = '收藏站点'
  @State @Watch('onHistoryList') historyList: Array<string> = []
  @State carStatus: string = '点击前往'
  @State spotList: CollectionListItem[] = []
  @State oftenGOList: StationListItemReturning[] = []
  @State searchStationList: StationListItemReturning[] = [] //new MyDataSource()
  @State lazyLoading: boolean = false
  @State allLoaded: boolean = false
  @State currentPage: number = 1
  @State sortBy: string = 'comprehensive'

  async onChangeTabName() {
    if (this.tabName === '收藏站点') {
      this.currentPage = 1;
      this.lazyLoading = false;
      this.allLoaded = false
      this.spotList = []
      await this.getCollectList()
    } else if (this.tabName === '常去站点') {
      console.info('接口 常去')
      this.oftenGOList = []
      let list: StationListItemReturning[] = [...this.oftenGOList] //
      let item = JSON.parse(await dataBase.get('oftenGoListItem') as string) as StationListItemReturning
      console.info('接口 常去', JSON.stringify(item))
      getStationDetail<StationListItemReturning>({ stationId: item.stationId }).then(async (res2) => {
        console.info('接口 常去 查询站点', JSON.stringify(res2))
        if (res2.delFlag === 0) return
        item = res2
        if (list.length >= 3) {
          return
        }
        if (list.length > 0) {
          list.forEach((element) => {
            if (element.stationId === item.stationId) {
              return
            } else {
              list.push(item)
            }
          })
        } else {
          list.push(item)
        }

        this.oftenGOList = list
        dataBase.put('oftenGoList', JSON.stringify(list))
      })
    }
  }

  onChangeKeyWord() {
    this.tabName = ''
    this.currentPage = 1
    this.allLoaded = false
    this.lazyLoading = false
    this.searchStationList = [] //new MyDataSource()
    if (this.keyWord === '') {
    } else {

      hiTraceMeter.startTrace('hiTraceMeter', 1)
      this.getStationListPort()
      hiTraceMeter.finishTrace('hiTraceMeter', 1)
    }
  }

  onHistoryList() {
    dataBase.put('historySearch', JSON.stringify(this.historyList))
    // dataBase.put('continueHistorySearch', JSON.stringify(this.historyList))
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

        for (let t = 0; t < res.list.length; t++) {
          // 计算距离
          let tempList = await getDistance([{ latitude: res.list[t].latitude, longitude: res.list[t].longitude }])

          if (tempList) {
            res.list[t].distance = Number(((tempList[0].cells[0].distance as number) / 1000)?.toFixed(2))
          } else {
            res.list[t].distance = 0
          }
        }
        this.spotList.push(...res.list)
        this.currentPage++
      }
    }
    this.lazyLoading = false
  }

  async onPageShow() {
    let baseData = DataBaseService.getInstance()
    let historySearch = await baseData.get('historySearch') as string
    this.historyList = JSON.parse(historySearch) as string[]

    this.oftenGOList = JSON.parse(await dataBase.get('oftenGoList') as string) as StationListItemReturning[] || []
    console.info('接口 常去', JSON.stringify(this.oftenGOList))
  }

  // 切换排序方式
  onChangeSort(sortType: string) {
    if (this.sortBy === sortType) return
    this.sortBy = sortType
    this.currentPage = 1
    this.allLoaded = false
    this.lazyLoading = false
    this.searchStationList = []
    this.getStationListPort()
  }

  // 获取充电站列表
  async getStationListPort() {
    if (this.lazyLoading || this.allLoaded) {
      return
    }
    this.lazyLoading = true

    // 获取用户位置（用于距离排序）
    let userLat: number | null = null
    let userLng: number | null = null
    let startTarget = AppStorage.get('continueStartTarget') as Record<string, number>
    if (startTarget && startTarget.latitude) {
      userLat = startTarget.latitude
      userLng = startTarget.longitude
    }

    let t: StationListVO = {
      currentPage: this.currentPage,
      pageSize: 5,
      stationName: this.keyWord,
      chargeType: null,
      sortBy: this.sortBy,
      latitude: userLat,
      longitude: userLng
    }
    try {
      let res = await getStationList<StationListReturning>(t)
      if (res) {
        if (res.list.length === 0) {
          this.allLoaded = true
        } else {
          for (let t = 0; t < res.list.length; t++) {
            // 计算距离
            let tempList = await getDistance([{ latitude: res.list[t].latitude, longitude: res.list[t].longitude }])

            if (tempList) {
              res.list[t].distance = Number(((tempList[0].cells[0].distance as number) / 1000)?.toFixed(2))
            } else {
              res.list[t].distance = 0
            }
          }

          this.searchStationList = [...this.searchStationList, ...res.list]
          this.currentPage++
        }
        console.info('接口 搜索站点', JSON.stringify(res))
      }
    } catch (e) {
      console.error('搜索站点失败', JSON.stringify(e))
    } finally {
      this.lazyLoading = false
    }
  }

  async aboutToAppear() {


  }

  // 取消按钮
  @Builder
  cancelBtn() {
    Column() {
      Text('取消')
        .fontColor($r('app.color.bottom_nav_fontcolor'))
        .fontSize('16lpx')
        .width('32lpx')
        .margin({ left: '16lpx' })
        .onClick(() => {
          router.clear()
          router.pushUrl({
            url: 'pages/Index',
            params: {
              keyWord: this.keyWord
            }
          })
        })
    }
  }

  @Builder
  searchListMain(num: Tmp) {
    ForEach(num.list, (item: StationListItemReturning) => {
      ListItem() {
        SiteCardComponent({
          siteItemInfo: item,
          siteName: item.stationName,
          tagList: [`最快${item?.chargeType === 1 ? '5' : '1'}00kw`, '对外开放', '互联互通'],
          isShowCollect: true,
          carStatus: this.carStatus,
          distanceKm: item.distance, //11,
          stationId: item.stationId,
          chargeFee: item.chargeFee,
          chargeType: item.chargeType,
          usedCount: item.usedCount,
          portCount: item.portCount,
          isCollect: item.isCollect,
          onEvent: () => {
            this.currentPage = 1
            this.lazyLoading = false
            this.allLoaded = false
            this.getCollectList()
            this.getStationListPort()
            console.info('接口 -取消收藏 刷新列表')
          }
        }).margin({ bottom: '16lpx' })
      }
    }, (item: StationListItemReturning, index: number) => (index + ''))
  }

  build() {
    Column() {
      SearchComponent({
        isHaveArea: false,
        cancelBtn: (): void => {
          this.cancelBtn()
        },
        keyWord: this.keyWord,
        historyList: this.historyList
      })
      Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
        Flex({ justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
          // Image($r('app.media.homeSearch_SiteActive'))
          Image(this.tabName === this.tab1 ? $r('app.media.homeSearch_SiteActive') : $r('app.media.homeSearch_Site'))
            .width('24lpx')
            .height('24lpx')
            .margin({ left: '8lpx', bottom: '2lpx' })
          Text(this.tab1)
            .margin({ left: '8lpx' })
            .fontSize('12lpx')
            .fontColor(this.tabName === this.tab1 ? $r('app.color.bottom_nav_fontcolor_active') :
              ('app.color.bottom_nav_fontcolor'))
        }
        .height('24lpx')
        .padding({ top: '4lpx', bottom: '4lpx' })
        .onClick(async () => {
          this.tabName = this.tab1
        })

        Column() {
        }
        .backgroundColor($r('app.color.aeaeae'))
        .width('2lpx')
        .height('16lpx')
        .borderColor($r('app.color.bottom_nav_fontcolor'))

        Flex({ justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
          // Image($r('app.media.homeSearch_collectActive'))
          Image(this.tabName === this.tab2 ? $r('app.media.homeSearch_collectActive') :
          $r('app.media.homeSearch_collect'))
            .width('24lpx')
            .height('24lpx')
            .margin({ left: '8lpx' })
          Text(this.tab2)
            .margin({ left: '8lpx' })
            .fontSize('12lpx')
            .fontColor(this.tabName === this.tab2 ? $r('app.color.bottom_nav_fontcolor_active') :
            $r('app.color.bottom_nav_fontcolor'))
        }
        .height('24lpx')
        .onClick(() => {
          this.tabName = this.tab2
        })
      }
      .padding({ top: '4lpx', bottom: '4lpx' })
      .margin({ top: '1lpx', bottom: '2lpx' })
      .backgroundColor($r('app.color.background_color_over'))

      if (this.tabName === this.tab1) {
        Column() {
          if (this.oftenGOList.length > 0) {
            List() {
              this.searchListMain({ list: this.oftenGOList })
            }
            .height('100%')
            .scrollBarWidth(0)
          } else {
            Column() {
              Image($r('app.media.siteSearch_blockIcon'))
                .margin({ top: '48lpx' })
                .width('120lpx')
                .height('120lpx')
              Text('没有找到相关站点')
                .fontSize('12lpx')
                .fontColor($r('app.color.999999'))
            }
            .width('100%')
          }
        }
        .height('89%')
        .margin({ bottom: '56lpx' })
        .padding({
          left: '16lpx',
          top: '16lpx',
          right: '16lpx',
          bottom: '42lpx'
        })
      } else if (this.tabName === this.tab2) {
        // 长列表
        if (this.spotList.length > 0) {
          ListColumn({
            listMain: this.searchListMain,
            num: { list: this.spotList },
            list: this.spotList,
            carStatus: this.carStatus,
            allLoaded: this.allLoaded,
            lazyLoading: this.lazyLoading,
            historyList: this.historyList,
            paddingLeft: '16lpx',
            paddingRight: '16lpx',
            paddingTop: '16lpx',
            paddingBottom: '130lpx',
            onEvent: () => {
              this.getCollectList()
            },
            getCollectList: () => {
              this.currentPage = 1
              this.lazyLoading = false
              this.allLoaded = false
              this.spotList = []
              this.getCollectList()
            }
          })
        } else {
          Column() {
            Image($r('app.media.siteSearch_blockIcon'))
              .margin({ top: '48lpx' })
              .width('120lpx')
              .height('120lpx')
            Text('没有找到相关站点')
              .fontSize('12lpx')
              .fontColor($r('app.color.999999'))
          }
          .width('100%')
        }

      } else {
        Column() {
          Column() {
            Row() {
              Image($r('app.media.homeSearch_clock'))
                .margin({right: '6lpx'})
                .width('14lpx')
                .height('14lpx')
              Text(`搜索历史(${this.historyList.length})`).fontSize('12lpx')
            }
            .borderColor({ bottom: 'rgba(0,0,0,0.05)' })
            .borderWidth({ bottom: this.historyList.length === 0 ? '0lpx' : '1lpx' })
            .padding({ top: '13lpx', bottom: '13lpx' })
            .width('100%')

            Row() {
              Scroll(this.scroller) {
                Flex({
                  direction: FlexDirection.Row,
                  justifyContent: FlexAlign.Start,
                  wrap: FlexWrap.NoWrap,
                  space: { main: LengthMetrics.lpx(8), cross: LengthMetrics.lpx(8) }
                }) {

                  ForEach(this.historyList, (item: string) => {
                    Text(item)
                      .fontSize('12lpx')
                      .fontColor($r('app.color.historyList_font_color'))
                      .borderRadius('10lpx')
                      .padding({
                        left: '8lpx',
                        right: '8lpx',
                        top: '6lpx',
                        bottom: '6lpx'
                      })
                      .backgroundColor('rgba(0,0,0,0.05)')
                      .onClick(() => {
                        this.keyWord = item
                      })
                  }, (item: string, index: number) => item + index)
                }
                .padding({ top: '13lpx', bottom: '13lpx' })
              }
              .scrollable(ScrollDirection.Horizontal) //横向滚动
              .scrollBar(BarState.Off)
            }
            .width('100%')
          }
          .padding({ left: '16lpx', right: '16lpx' })
          .backgroundColor($r('app.color.background_color_over'))
          .width('100%')
          .zIndex(1)

          // 排序选项
          Row() {
            Text('综合')
              .fontSize('12lpx')
              .fontColor(this.sortBy === 'comprehensive' ? '#2196F3' : '#999999')
              .fontWeight(this.sortBy === 'comprehensive' ? FontWeight.Medium : FontWeight.Normal)
              .padding({ left: '12lpx', right: '12lpx', top: '6lpx', bottom: '6lpx' })
              .backgroundColor(this.sortBy === 'comprehensive' ? 'rgba(33, 150, 243, 0.08)' : 'transparent')
              .borderRadius('14lpx')
              .onClick(() => { this.onChangeSort('comprehensive') })

            Text('距离优先')
              .fontSize('12lpx')
              .fontColor(this.sortBy === 'distance' ? '#2196F3' : '#999999')
              .fontWeight(this.sortBy === 'distance' ? FontWeight.Medium : FontWeight.Normal)
              .padding({ left: '12lpx', right: '12lpx', top: '6lpx', bottom: '6lpx' })
              .backgroundColor(this.sortBy === 'distance' ? 'rgba(33, 150, 243, 0.08)' : 'transparent')
              .borderRadius('14lpx')
              .onClick(() => { this.onChangeSort('distance') })

            Text('价格优先')
              .fontSize('12lpx')
              .fontColor(this.sortBy === 'price' ? '#2196F3' : '#999999')
              .fontWeight(this.sortBy === 'price' ? FontWeight.Medium : FontWeight.Normal)
              .padding({ left: '12lpx', right: '12lpx', top: '6lpx', bottom: '6lpx' })
              .backgroundColor(this.sortBy === 'price' ? 'rgba(33, 150, 243, 0.08)' : 'transparent')
              .borderRadius('14lpx')
              .onClick(() => { this.onChangeSort('price') })
          }
          .width('100%')
          .padding({ left: '16lpx', right: '16lpx', top: '8lpx', bottom: '4lpx' })

          //长列表
          ListColumn({
            listMain: this.searchListMain,
            num: { list: this.searchStationList },
            list: this.searchStationList,
            carStatus: this.carStatus,
            allLoaded: this.allLoaded,
            lazyLoading: this.lazyLoading,
            historyList: this.historyList,
            paddingLeft: '16lpx',
            paddingRight: '16lpx',
            paddingTop: '16lpx',
            paddingBottom: this.historyList.length > 0 ? '145lpx' : '100lpx',
            onEvent: () => {
              this.getStationListPort()
            },
            getStationListPort: () => {
              this.currentPage = 1
              this.lazyLoading = false
              this.allLoaded = false
              this.searchStationList = []
              this.getStationListPort()
            }
          })

          LongBtnComponent({
            btnColor: $r('app.color.background_color_over'),
            btnFontColor: $r('app.color.clear_font_color'),
            btnBorderColor: $r('app.color.CECECE'),
            btnName: '清空搜索历史',
            onEvent: (data: string) => {
              this.tabName = ''
              this.allLoaded = false
              this.lazyLoading = false
              // this.currentPage = 1
              this.searchStationList = []
              this.historyList = []
              this.keyWord = ''

              dataBase.delete('historySearch')
            }
          })
            .padding({ top: '0lpx', bottom: '40lpx' })
            .backgroundColor($r('app.color.card_background'))
            .position({ bottom: '-50lpx' })
            .zIndex(2)
        }.alignSelf(ItemAlign.Center)
        .height('650lpx')
      }

    }.backgroundColor($r('app.color.card_background'))
    .height('100%')
  }
}