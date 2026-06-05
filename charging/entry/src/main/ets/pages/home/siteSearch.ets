import { SearchComponent } from '../../components/searchComponent'
import { SiteCardComponent } from '../../components/siteCardComponent';
import { HeadComponent } from '../../components/headComponent';
import {
  CollectionListItem,
  CollectionListReturning,
  CollectionListVO
} from '../../model/interface/api/CollectionApiInterface';
import { getCollectList } from '../../api/CollectionApi';
import { StationListItemReturning } from '../../model/interface/api/HomeApiInterface';
import { DataBaseService } from '../../service/DataBaseService';
import { getDistance } from '../../utils/tools';
import { hilog, hiTraceMeter } from '@kit.PerformanceAnalysisKit';
import { ListColumn } from '../../utils/ListColumn';
import { Tmp } from '../../model/class';
import { getStationDetail } from '../../api/HomeApi';
import { JSON } from '@kit.ArkTS';

let dataBase = DataBaseService.getInstance()

@Entry
@Component
export struct SiteSearch {
  scroller: Scroller = new Scroller()
  @State @Watch('onChangeKeyWord') keyWord: string = ''
  @State @Watch('onChangeTabName') tabName: string = '常去站点'
  @State tab1: string = '常去站点'
  @State tab2: string = '收藏站点'
  @State historyList: Array<string> = []
  @State carStatus: string = '点击前往'
  @State spotCollectList: CollectionListItem[] = []
  @State offsetOnSpotList: StationListItemReturning[] = []
  @State lazyLoading: boolean = false
  @State allLoaded: boolean = false
  @State currentPage: number = 1

  onChangeKeyWord() {
    this.onChangeTabName()
  }

  async onChangeTabName() {
    this.allLoaded = false
    this.lazyLoading = false
    if (this.tabName === '常去站点') {
      this.offsetOnSpotList = []
        // JSON.parse(await dataBase.get('oftenGoList') as string) as StationListItemReturning[] || []
      let list: StationListItemReturning[] = [...this.offsetOnSpotList] //
      let item = JSON.parse(await dataBase.get('oftenGoListItem') as string) as StationListItemReturning

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
        dataBase.put('oftenGoList', JSON.stringify(list))
        this.offsetOnSpotList = list
        console.info('接口 常去', JSON.stringify(item))
      })

    } else {
      this.currentPage = 1
      this.lazyLoading = false;
      this.allLoaded = false
      this.spotCollectList = []
      this.offsetOnSpotList = []
      await this.getCollectList()
    }

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
      stationName: this.keyWord
    }
    let res = await getCollectList<CollectionListReturning>(extraData)

    if (res) {
      if (res.list.length === 0) {
        this.allLoaded = true
      } else {
        let temList: CollectionListItem[] = []
        for (let t = 0; t < res.list.length; t++) {
          if (res.list[t].delFlag != 1) {
            continue
          }
          temList.push(res.list[t])
          // 计算距离
          let tempList = await getDistance([{ latitude: res.list[t].latitude, longitude: res.list[t].longitude }])

          if (tempList) {
            res.list[t].distance = Number(((tempList[0].cells[0].distance as number) / 1000)?.toFixed(2))
          } else {
            res.list[t].distance = 0
          }
        }

        this.spotCollectList = [...this.spotCollectList, ...temList]
        this.currentPage++
        console.info('接口 收藏列表', JSON.stringify(res))
      }
    }
    this.lazyLoading = false
  }

  async aboutToAppear() {
    // 避免耗时接口
    hiTraceMeter.startTrace('getStringSyncAfter', 1)
    this.getUIContext().getHostContext()!.resourceManager.getStringSync($r('app.string.test'))
    // this.getUIContext().getHostContext()!.resourceManager.getStringSync($r('app.string.test').id)
    hiTraceMeter.finishTrace('getStringSyncAfter', 1)
    // 经行耗时操作
    this.count

  }

  async onPageShow() {
    this.onChangeTabName()
    // this.offsetOnSpotList = JSON.parse(await dataBase.get('oftenGoList') as string) as StationListItemReturning[] || []
  }

  count(): number {
    let temp: number = 0;
    for (let i = 0; i < 10000000; i++) {
      temp += 1;
    }
    return temp;
  }

  // 搜索按钮
  @Builder
  cancelBtn() {
    Column() {
      Text('搜索')
        .fontColor($r('app.color.bottom_nav_fontcolor'))
        .fontSize('16lpx')
        .width('32lpx')
        .margin({ left: '16lpx' })
        .onClick(() => {
          console.info('查找站点', this.keyWord)
          this.onChangeTabName()
        })
    }
  }

  @Builder
  searchListMain(num: Tmp) {
    ForEach(num.list, (item: StationListItemReturning) => {
      ListItem() {
        if (item.delFlag === 1) {
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
              console.info('接口 -取消收藏 刷新列表')
            }
          }).margin({ bottom: '16lpx' })
        }
      }

    }, (item: StationListItemReturning, index: number) => (index + ''))
  }

  build() {
    Column() {
      HeadComponent({
        headName: '查找站点',
        isHaveBtn: false
      })
      SearchComponent({
        cancelBtn: (): void => {
          this.cancelBtn()
        },
        keyWord: this.keyWord,
        historyList: this.historyList
      })
      Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
        Flex({ justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
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
        .onClick(() => {
          this.tabName = this.tab1
        })

        Column() {
        }
        .backgroundColor($r('app.color.aeaeae'))
        .width('2lpx')
        .height('16lpx')
        .borderColor($r('app.color.bottom_nav_fontcolor'))

        Flex({ justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
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
        if (this.offsetOnSpotList.length > 0) {
          Scroll(this.scroller) {
            Column() {
              List() {
                this.searchListMain({ list: this.offsetOnSpotList })
              }
              .scrollBarWidth(0)
            }
            .height('97%')
          }
          .padding({
            left: '16lpx',
            top: '14lpx',
            right: '16lpx',
            bottom: '150lpx'
          })
          .scrollable(ScrollDirection.Vertical) //纵向滚动
          .scrollBar(BarState.Off)
          .height('97%')
          .onWillScroll(() => { // onWillScroll回调中执行耗时操作
            hiTraceMeter.startTrace('scrollSlide', 1001);
            hilog.info(0x0000, 'sample', '%{public}s', 'scroll textItem')
            //耗时操作
            this.count()

            hiTraceMeter.finishTrace('scrollSlider', 1001)
          })
        }
      } else {
        if (this.spotCollectList.length > 0) {
          ListColumn({
            listMain: this.searchListMain,
            num: { list: this.spotCollectList },
            list: this.spotCollectList,
            carStatus: this.carStatus,
            allLoaded: this.allLoaded,
            lazyLoading: this.lazyLoading,
            historyList: this.historyList,
            paddingLeft: '16lpx',
            paddingRight: '16lpx',
            paddingTop: '16lpx',
            paddingBottom: '170lpx',
            onEvent: () => {
              this.getCollectList()
            },
            getCollectList: () => {
              this.currentPage = 1
              this.lazyLoading = false
              this.allLoaded = false
              this.spotCollectList = []
              this.getCollectList()
            }
          })
        }
      }
      if (this.lazyLoading) {
        Row() {
          LoadingProgress()
            .width('30lpx')
            .height('30lpx')
          Text('加载中')
            .margin({ left: '10lpx' })
        }.justifyContent(FlexAlign.Center)
        .padding('15lpx')
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

    }.backgroundColor($r('app.color.card_background'))
    .height('100%')
  }
}